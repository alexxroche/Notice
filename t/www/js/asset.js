function check_pwc (password,submit) {
    var hasErr = false;
    if ( password.match(/[a-z]+/) && password.match(/[A-Z]/) ) {
	jQuery('#pwc_1').css('color', 'green').fadeOut(900);
	jQuery('#pwc_j').css('color', 'gold').fadeOut(500);
    }else{
	jQuery('#pwc_1').fadeIn();
	jQuery('#pwc_1').css('color', 'red');
	if(!password.match(/\d{1}/)){
		jQuery('#pwc_j').css('color', 'blue').show();
	}
	if(submit){ hasErr=true; }
    }
    if ( password.match(/\d{1}/) ) {
	jQuery('#pwc_2').css('color', 'green').fadeOut(600);
	jQuery('#pwc_j').css('color', 'gold').fadeOut(500);
    }else{ 
	jQuery('#pwc_2').fadeIn();
	jQuery('#pwc_2').css('color', 'red');
	if(submit){ hasErr=true; }
    }       
    if ( password.length >= 6){ 
	jQuery('#pwc_l').css('color', 'green').fadeOut(600);
	jQuery('#pwc_j2').css('color', 'gold').fadeOut(500);
    }else{
	jQuery('#pwc_j2').css('color', 'blue').fadeIn(500);
	jQuery('#pwc_l').fadeIn();
        jQuery('#pwc_l').css('color', 'red');
        if(submit){ hasErr=true; }
    }
    if (password.match(/[a-z]+/) && password.match(/[A-Z]/) && password.match(/\d{1}/) && password.length >= 6){
	jQuery('#pwc').fadeOut();
    }else{
	jQuery('#pwc').fadeIn();
        jQuery('#pwc').css('color', 'blue');
	if(submit){ hasErr=true; }
    }
    return hasErr;
}               


function ac_select() {
  if ( $("#ac_select option:selected").val() != "") {
                $(".ac_ad").hide();
                if($("#ac_select :selected").is(".apreq")){
                        $("#approval_req").show().css('color', 'red');
                        $("#ac_select").addClass('opthi');
                        $("#msgdiv").html('<span class="message qwide">This account requires approval from an Administrator</span>');
                        $(".message").addClass('opthi');
                        $(".message").fadeOut(5000);
                }else{
                        $("#approval_req").hide();
                        $(".message").hide();
                        $("#ac_select").removeClass('opthi');
                }
        }else{
            if(!$("#ac_select option:selected").is(".apreq")){
                $(".message").hide();
                $("#ac_select").removeClass('opthi');
            }
            $(".ac_ad").fadeIn(1000);
        }
}


// Trying to get focus to work again!
$("#display").load("?control=msgs", {}, function() { $('#pe_email').focus(); });
$(document).load(function() { $('#pe_email').focus(); });
// well that failed
$(document).ready(function() {
   $(".headmsg").fadeOut(5000);
   $(".warning").fadeOut(7000);
   $('#pe_email').focus(); //seems to have stopped working 20101121

    $("#signup_table").hide();
    $("#approval_req").hide();
    $(".stripe tr").mouseover(function(){$(this).addClass("over");}).mouseout(function(){$(this).removeClass("over");});
    $(".stripe tr:even").addClass("alt");
    $(".ac_ad").hide();
    $("#signup_table").fadeIn(1000);
    $("#top_error").fadeOut(5000);

    if($("#ac_select :selected").is(".apreq")){
	$("#signup_table").after('<span class="message qwide">This account requires approval from an Administrator</span>');
    	$("#ac_select").addClass('opthi');
    	$(".message").addClass('opthi');
    };


    //$("#ac_select").change(function() {
    $("#ac_select").keyup(function(){ ac_select(); });
    $("#ac_select").bind($.browser.msie ? 'propertychange': 'change', function() { ac_select(); });

    jQuery('#password').keyup(function(){
        var password = jQuery('#pw_hid').val();
        if(password.match(/.+/)){ check_pwc(password); }
    });

     $("#submit").click(function(){
	        $(".error").hide();
	        var hasError = false;
	        var emailVal = $("#email").val();
	        var pwVal = $("#pw_hid").val();
	        var checkVal = $("#pw_c_hid").val();
		//var pwcf = check_pwc($('#pw_hid').val(),'submit');
		var pwcf = check_pwc(pwVal,'submit');
	        if (emailVal == '' || !emailVal.match(/[^\@\s]+\@([a-z0-9-]+\.)+[a-z]{2,8}/i) ) {
		    $("#signup_table").after('<span class="error">Please enter a valid email address.</span>');
                    hasError = true;
	        } else if (pwVal == '') {
	            $("#signup_table").after('<span class="error">Please enter a password.</span>');
	            hasError = true;
	        } else if(pwcf != ''){
		    $("#pwc").after('<span class="error">Please enter a valid password.</span>');
		    hasError = true;
	        } else if (checkVal == '') {
	            $("#signup_table").after('<span class="error">Please re-enter your password.</span>');
	            hasError = true;
	        } else if (pwVal != checkVal ) {
	            $("#signup_table").after('<span class="error">Passwords do not match.</span>');
	            hasError = true;
		}
    		$("span.error").fadeOut(4000);
	        if(hasError == true) {return false;}
	    });
});

function obscure_this(f,g,e){var a=window.event?event.keyCode:f.keyCode,j=document.getElementById(g).value.replace(/^\**/,""),c=document.getElementById(e).value,b=document.getElementById(g).value.length,h=document.getElementById(e).value.length,d=b>h?b:h;switch(a){case a>=16&&a<=19:break;case a>=37&&a<=40:break}if(h>b){if(a==8)b+=1;else if(a!=32&&a!=46)b-=1;c=c.substr(0,b);if(a!=8&&a!=32&&a!=46)b+=1;d=b}if(a==8&&d>=0){d-=1;c=c.substr(0,d)}else if(d>=0)c+=j;b="";if(d>=1)for(i=0;i<d;i++)b+="*";document.getElementById(e).value= c;if(a!=8)for(e=f=(new Date).getTime();e-f<250;){if(document.onkeypress)return;e=(new Date).getTime()}document.getElementById(g).value=b};
