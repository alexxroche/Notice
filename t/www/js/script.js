google.load("jquery", "1.3.1");
google.setOnLoadCallback(function()
{
    // Apply some CSS3 to keep the CSS file CSS 2.1 valid
    $("h1").css("text-shadow", "0px 2px 6px #000");
    $("h2 a").css("text-shadow", "0px 2px 6px #000");

    // Color changer
    $(".css-switcher-web").click(function(){
        $("link").attr("href", "/css/splash.css");
        return false;
    });
    
    $(".css-switcher-print").click(function(){
        $("link").attr("href", "/css/print.css");
        return false;
    });
    
    $(".css-switcher-mobile").click(function(){
        $("link").attr("href", "/css/mobile.css");
        return false;
    });

});
