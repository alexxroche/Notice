function suggest_passwd(i,q,s){
if(!s||s.length<=0){s=16;}try{ if(document.getElementById(i).value.length<=0){var pw=randomPassword(s); if(!q){alert(pw +' might be a good password');}else{
document.getElementById(i).title = "This is just a suggestion";} document.getElementById(i).value = pw}}catch(e){}
}
