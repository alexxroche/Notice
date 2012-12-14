package Notice::C::Docs;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Notice::C::Docs

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This is an example of one of the ways that read files can be managed.
It should be easy to log which users accessed which files and when, (and from where.)

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/^(?!main)/);
    my $page_loaded = 0;
    eval {
        use Time::HiRes qw ( time );
        $page_loaded = time;
    };
    if($@){
        $page_loaded = time;
    }

    # debug message
    if($self->param('i18n') && $self->param('debug')){ 
        $self->tt_params({warning => '<span class="small lang i18n">Lang:' . $self->param('i18n') . '</span>'}); 
    }
    $self->run_modes( "AUTOLOAD" => \&main);
}

=head2 RUN MODES

=head3 main

  * Display the welcome message for the account that they are in
  * Display the side menu and the search menu at the top,
    (if that is enabled for their account and user.)

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $relative_path = '/docs/';
    my $path = '';
    my $q = $self->query();
    if($q->param('path')){
        $path = $q->param('path') . '/';
        $relative_path .= $q->param('path');
    }
    use Cwd;
    my $dir = getcwd;
    my $fullpath = $dir . $relative_path;
	my $message = '';
    if($self->param('id')){ $message = "You are trying to download " . $self->param('id'); }
    my $no_wrapper = 1;
    
    if($self->authen->is_authenticated){
        $no_wrapper = 0;
    }else{
        #my $dest = $self->query->url;
        #return $self->redirect("$dest/login");
        return $self->forward('login');
        exit;
        $message = 'Welcome - you probably want to login <a href="' . $self->query->url . '/main/login">here</a>';
         $self->tt_params({
            no_wrapper => $no_wrapper,
            message => $message,
        });
        return $self->tt_process();
    }
    if($q->param('debug')){
        use Data::Dumper;
        my $dump .= Dumper(\%{ $q });
        $dump=~s/\n/<br \/>\n/g;
        $message .= $dump;
    }
    # We can just show them the list of files
    unless($self->param('id') || $q->param('id')){
        $message = "Would you like to download one of the files? :<br />";
        
        if(1==2){ $fullpath = `readlink -mn $fullpath`;}
        unless(-d "$fullpath"){ 
            $message = "Can't find $fullpath\n";
            $self->tt_params({ message => $message });
            return $self->tt_process();
        }
        my @files;
        eval {
            no warnings 'uninitialized';
            opendir LIST, $fullpath;
            @files =
             map  $_->[0]       ,          # ↑ extract file names
             sort { $a->[1] <=> $b->[1] }  # ↑ sort ascending after mdate 
             map  [$_, -M $_]   ,          # ↑ pre-build list for sorting 
             grep ! /^\.\.?$/   ,          # ↑ extract file names except ./..
            readdir LIST;              # ↑ read directory entries
            closedir(LIST);
        }; 
        if(@_){
            @files = `ls $fullpath`;
        }

        if(@files){ $message .= "<ul>"; }
        if($path){
            $path=~s/^\/*//;
            $path=~s/\/\//\//g;
            my $parent= $path;
            if( length($path) <= 1 || $path=~m/^\/*$/){ 
                $path='';
            }elsif($path=~m/^\/*[^\/]+\/*$/){ 
                #$parent=~s/\/[^\/]+\/*$//; 
                $message .= qq |<li><a class="blue green" href="/cgi-bin/index.cgi/Docs">..</a><br /></li>|;
            }elsif($path=~m/^\/*([^\/]+\/)+\/*$/){ 
                $parent=~s/\/*[^\/]+\/*$//;
                $message .= qq |<li><a class="blue green" href="/cgi-bin/index.cgi/Docs?path=$parent">..</a><br /></li>|;
            }
           # else($path=~m/.+\//){ $parent=~s/\/[^\/]+\/*$//; }
        }
        foreach my $file (sort @files) {
            chomp($file);
            if( -d "$fullpath/$file"){
                $message .=qq |<li><a class="blue green" href="/cgi-bin/index.cgi/Docs?path=$path$file">$file</a><br /></li>|;
            }else{
                $message .=qq |<li><a class="black" href="/cgi-bin/index.cgi/Docs/download/$path$file">$file</a><br /></li>|;
            }
        }
        if(@files){ $message .= "</ul>"; }

       $self->tt_params({
        no_wrapper => $no_wrapper,
        page => $message,
              });
        return $self->tt_process();
    }
    my $ef_acid = '0';
    if($self->param('ef_acid')){ 
        $ef_acid = $self->param('ef_acid');
    }elsif($self->session->param('ef_acid')){
        $ef_acid = $self->session->param('ef_acid');
    }

# Should not get here, but just in case...
$message .= "<br />We have no bananas today<br />";
    $self->tt_params({
    #greeting => $greeting,
    welcome => "um, that should not happen",
    no_wrapper => $no_wrapper,
	message => $message,
		  });
    return $self->tt_process();
    
}

sub download: Runmode {
   my ($self) = @_;
    use Cwd;
    my $dir = getcwd;
    my $fullpath = $dir . "/docs";
    my $path = '';
    my $downloadfile = $self->param('id');
    if(defined $self->param('fid') || defined $self->param('eid') || defined $self->param('did') || defined $self->param('sid') ){
        if( defined $self->param('id') ){ $path ='/'. $self->param('id'); $downloadfile = $self->param('id'); }
        if( defined $self->param('sid')){ $path .='/'.$self->param('sid'); $downloadfile = $self->param('sid'); }
        if( defined $self->param('did')){ $path .='/'.$self->param('did'); $downloadfile = $self->param('did'); }
        if( defined $self->param('eid')){ $path .='/'.$self->param('eid'); $downloadfile = $self->param('eid'); }
        if( defined $self->param('fid')){ $path .='/'.$self->param('fid');
                $downloadfile = $self->param('fid'); 
                $downloadfile =~s/^.*\///;
        }
        $path=~s/$downloadfile$//;
        $fullpath .= $path;
    }else{
        $downloadfile = $self->param('id');
    }
# we should also check $q->param('id');
my $fullpathdownloadfile = "$fullpath/$downloadfile";
my $output = '';
my $buffer = '';
open my $fh, '<', $fullpathdownloadfile
  or return $self->tt_process('error.tmpl', { error => "Error: Failed to download file <b>$downloadfile</b>:<br />$!<br />$fullpathdownloadfile
"});
while (my $bytesread = read($fh, $buffer, 1024)) { $output .= $buffer; }
close $fh
  or return $self->tt_process('error.tmpl', { error => "Error: Failed <b>$downloadfile<b>:<br>$!<br>"});
my  $downloadfilesize = (stat($fullpathdownloadfile))[7]
  or return $self->tt_process('error.tmpl', { error => "Error: Failed to get file size for <b>$downloadfile<b>:<br>$!<br>"});
$self->header_props(
                    '-type'                => 'application/x-download',
                    '-content-disposition' => "attachment;filename=$downloadfile",
                    '-content_length'      => $downloadfilesize,
                   );
return $output;
}


1;

__END__

=head1 BUGS AND LIMITATIONS

If the download request has multiple // then it breaks - we should just deal with that

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
or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

