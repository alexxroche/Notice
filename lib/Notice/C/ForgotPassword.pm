package Notice::C::ForgotPassword;

use warnings;
use strict;
use base 'Notice';
use Data::Dumper;
my $surl;

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This is another superfluous part of the login system.
It should be pruned out.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $surl = ($self->query->self_url);
    $surl =~s/\?.*$//; #strip any GET values
}

=head2 RUN MODES

=head3 main

 Reset your passphrase - The string has a date value, so that we can know how long
    it has been available. (And we can remove this vulnerability with a script each night).

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $q = $self->query();
    my $count=0; #how many resets have they done?


    if($self->param('id')){ 
        if($self->param('id') eq 'reset'){
            $self->tt_params({ error=>'<br />Reset ALL the things?<br />I did not think so. (p.s. logged you)', message => '<br />'});
            return $self->tt_process('Notice/C/ForgotPassword/reset.tmpl');
        }
        my $message = "reset request form " . $self->param('id') . ' ';
        my $reset_str = $self->param('id');
        my $rc = $self->resultset('People')->search({ 'pe_loggedin' => "$reset_str" })->first;
        if($rc && defined $rc->pe_id){
            my $pe_id = $rc->pe_id;
            $self->tt_params({ message => 'To reset your passphrase - '});
            return $self->tt_process('Notice/C/ForgotPassword/reset.tmpl');
        }else{
            $self->tt_params({ error=>'<br />Y U trying crack?', message => 'Not a valid reset string. (p.s. Logged you)'});
            return $self->tt_process();
        }
    }elsif($q->param('email')){

# 1. check to see if $pe_email is already in the process of doing a reset
   # people.pe_passwd < their passphrase (the "oh wait, I've just remembered it")
   # people.pe_loggedin YYYYMMDDHHMMSS_IP_hash_digit+
   #  pe_loggedin is set to the date that they first log in, but we don't need that
   # ( pe_confirmed works with exactly the same string, but can NOT be used for password reset;
   #  -  but if they do a password reset that is the same thing as email validation, so we do that as well. )
   # This is a unique string that we generate and include in the email that we send
        my $rc = $self->resultset('People')->search({ 'pe_email' => $q->param('email') })->first;

        if($rc && defined $rc->pe_loggedin && 
           $rc->pe_loggedin=~m/^\d{14}_[^_]{3,32}_[a-f0-9]{32}_\d*?$/){
        # then we are alreday in a recovery - the date tells us how long ago that was
        # so that we can make a judgement - maybe our email was lost and they need us
        # to send it again - maybe they just pressed F5 by mistake.

        
        #for now we just remind them
            $self->tt_params({ 
                error => 'email already sent',
                message => 'A reset email WAS sent ALREADY. If you think that it has been lost then check back with us in an hour.' 
            });
            return $self->tt_process();
        }elsif($rc && defined $rc->pe_id && $rc->pe_id=~m/^\d+$/){
 
# 2. create string
            use Digest::MD5 qw(md5_hex);
            use DateTime;
            my $source_ip = $ENV{REMOTE_ADDR};
            my $now = DateTime->now( time_zone => 'UTC' )->strftime("%Y%m%d%H%M%S");
            # NOTE we should have a more universal source of sudo-random data
            my $ud_md5 = md5_hex(rand().`ps auwx | gzip -c`); 
               $ud_md5 = substr($ud_md5,0,32);
            if(defined $rc->pe_loggedin && $rc->pe_loggedin=~m/^(\d+)$/){ $count = $1; }
            if(!$count || int($count) < 0 ){ $count = 0; warn "ForgotPassword reset count"; } 
            my $pe_loggedin= $now . '_' . $source_ip . '_' . $ud_md5 . '_' . $count;
            my %update = ( pe_loggedin => $pe_loggedin );

# 3. create email

            my $body = qq |Dear Notice user,\n Someone, (possibly you) has requested a passphrase reset.
                Click <a href="$surl/reset/$pe_loggedin">$surl/reset/$pe_loggedin</a> to reset your passphrase.\n
                \n(And may we suggest that you install KeePass to store passphrases, and <a href="http://bit.ly/SSGPpF">SpiderOak</a>
                to make sure that you don't lose your precious KeePass database.)|; #'

            my %email = (
                from => 'no-reply@bin.notice.alexx.net',
                to => $rc->pe_email,
                subject => '[notice] Forgotten Password',
                body    => $body
            );
# 4. update the user table
            $rc->update( \%update );
            
# 5. send the email
            use Notice::C::Email;
            my $sent = $self->Notice::C::Email::_send(\%email);

            if($sent){
                $self->tt_params({ 
                    error => 'email sent',
                    message => 'A reset email has been sent to the address that you supplied, <br /> or will be once this part is written' . $sent
                });
            }else{
                $self->tt_params({ error => 'No reset sent', message => $sent});
            }
            return $self->tt_process();
        }else{
            # do we give a meaningful error (which will leak data about out user base
            # OR do we give the SAME reply as a positive reset? (but this means that user typos are eaten and lost

            $self->tt_params({
                error => 'email NOT sent',
                message => 'A reset email would be sent if we knew you. If you think that it has been an error then check that you typed your address correctly.'
            });
            return $self->tt_process();
        }

    }

    $self->tt_params({
	message => 'Please remind me who you are by',
	title   => 'Whom might you be?'
		  });
    return $self->tt_process();
    
}

sub reset: Runmode {
    my ($self) = @_;
    my $q = $self->query();
    if($q->param('passphrase1')){
        # we are doing an update
        my $pe_loggedin = $self->param('id');
        my $pf1 = $q->param('passphrase1');
        my $pf2 = $q->param('passphrase2');
        # check that passphrase1 matches passphrase2
        if($pf1 eq $pf2 && $pe_loggedin=~m/^\d{14}_[^_]{3,32}_[a-f0-9]{32}_\d*?$/){


            # update passphrase in people.pe_passwd
            use Notice::C::Users;
            my $error = $self->Notice::C::Users::_set_passphrase('',$pf1,$pe_loggedin);
            if($error){
                $self->tt_params({ error => $error });
            }else{
                $surl=~s/ForgotPassword.*$/main/;
                my $error = qq |You can now login in <a href="$surl">Here</a>|;
                $self->tt_params({
                        error => $error,
                        message => 'Reset Done!<br />'
                });
            }
        }elsif($pf1 ne $pf2){
            $self->tt_params({ error => 'PassPhrases did not match - You can <a class="red" href="#" onclick="history.back()">go back</a> and try again' });
        }else{
            $self->tt_params({ error => 'Bad things - probably you: Error: Notice::ForgotPassPhrase::_string_error' });
        }
        return $self->tt_process();
    }else{
        return $self->forward('main');
    }
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
Please fix any bugs or add any features you need. 
You can report them through GitHub or CPAN.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut


