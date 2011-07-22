$(function(){
    $('input#btn_go').click(function(){
        location.href = app_root + '/' + $('input#img_url').val();
    });
});