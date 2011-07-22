
var sid = null;
if(typeof WebSocket != 'undefined') var ws = new WebSocket(ws_url);
else{
    alert('use Google Chrome or Safari');
}

ws.onmessage = function(e){
    var data = JSON.parse(e.data);
    console.log(data);
    if(data.type == 'init'){
        sid = data.sid;
    }
    else if(data.type == 'line'){
        if(data.sid != sid) draw_line(data);
    }
};
ws.onclose = function(){
    console.log("websocket closed");
    alert("websocket closed");
};
ws.onopen = function(){
    console.log("websocket connected!!");
};

var ctx;
var sketch = {
    p_pos : {
        x : null,
        y : null,
        clear : function(){
            this.x = null; 
            this.y = null;
        }
    },
    drawing : false
};

var draw_line = function(data){
    ctx.strokeStyle = data.strokeStyle;
    ctx.lineWidth = data.lineWidth;
    ctx.lineCap = data.lineCap;
    ctx.beginPath();
    ctx.moveTo(data.from.x, data.from.y);
    ctx.lineTo(data.to.x, data.to.y);
    ctx.closePath();
    ctx.stroke();
};

$(function(){
    $('#stroke select#size').val(4);
    draw_img('./shokai-big.jpg');
    $('input#btn_draw').click(function(){
        draw_img($('input#img_url').val());
    });
    $('canvas#img').mousedown(function(){
        sketch.drawing = true;
    });
    $('body').mouseup(function(){
        sketch.drawing = false;
        sketch.p_pos.clear();
    });
    $('canvas#img').mousemove(function(e){
        if(!sketch.drawing) return;
		var rect = e.target.getBoundingClientRect();
		var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        console.log(x + ', ' + y);

        if(sketch.p_pos.x && sketch.p_pos.y){
            var line_data = {
                type : 'line',
                strokeStyle : $('#stroke select#color').val(),
                lineWidth : $('#stroke select#size').val(),
                lineCap : 'square',
                from : {x : x, y : y},
                to : {x : sketch.p_pos.x, y : sketch.p_pos.y}
            };
            draw_line(line_data);
            ws.send(JSON.stringify(line_data));
        }
        sketch.p_pos.x = x;
        sketch.p_pos.y = y;
    });
});

var draw_img = function(img_url){
    var img_tag = $('canvas#img');
    ctx = img_tag[0].getContext('2d');
    var img = new Image();
    img.onload = function(){
        img_tag.attr('width', img.width).attr('height', img.height);
        ctx.drawImage(img, 0, 0, img.width, img.height);
    };
    img.src = img_url;
};

