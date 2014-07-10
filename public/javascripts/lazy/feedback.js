jQuery( document ).ready(function($) {

$(".ui-dialog-titlebar").hide();

$('body').click(function(e){
  x = e.clientX ;
  y = e.clientY+$(document).scrollTop();
  tminx = $("#feedback-tab").offset().left-5;
  tmaxx = $("#feedback-tab").offset().left+ $("#feedback-tab").width() + 5;
  tminy = $("#feedback-tab").offset().top-5 ;
  tmaxy = $("#feedback-tab").offset().top+ $("#feedback-tab").height() + 5;
  intab = x>=tminx && x<=tmaxx && y>=tminy && y<=tmaxy;
  $('.dialog-all').each(function(){
    if($(this).dialog("isOpen")){
      minx = $(this).offset().left -5;
      maxx = $(this).offset().left + $(this).dialog("option","width") + 5;
      miny = $(this).offset().top -5;
      maxy = $(this).offset().top + $(this).dialog("option","height") + 5;
      inthis = x>=minx && x<=maxx && y>=miny && y<=maxy;
      if(!inthis && !intab)
        $(this).dialog("close");
    }
  });
  if(!$('#dialog-main').dialog("isOpen") && 
    !$('.dialog-form-suggest').dialog("isOpen")&& 
    !$('.dialog-form-problem').dialog("isOpen")&& 
    !$('.dialog-form-contact').dialog("isOpen") && !intab)
    $('#feedback-tab').stop().animate({left:-18});
});

$(document).mousemove(function(e){
  xpos = e.pageX;
  if(xpos<10)
    $('#feedback-tab').stop().animate({left:0},'fast');
});

$(".hr").css({
  "border-top":"1px solid #000000",
  "display":"inline-block",
  "width":"39%",
  "margin":"0px",
});

$(".dialog-close").css({
  "float":"right",
  "color":"#aaa",
  "margin-bottom":"10px",
  "font-size":"16px",
  "font-weight":"bold",
  "cursor":"pointer",
});

$(".fixed-dialog").css
({
  "position": "fixed", 
  "left": "0px", 
  "top": "50%", 
  "margin-top": "-62px",
  "background" : "rgba(220,220,220,0.8)",
});

$(".fixed-dialog form").css
({
  "margin-top": "10px",
});
$(".feedback-submit").css
({
  "float":"right",
});

$(".dialog-cancel").click(function(){
  $('form').trigger('reset');
  $(".dialog-all").dialog("close");
});
$("#feedback-tab").click(function(){
  if(!$("#dialog-main").dialog("isOpen")){
    $(".dialog-all").dialog("close");
    $("#dialog-main").dialog("open");
  }
  else
    $(".dialog-all").dialog("close");
});

$("#suggest").click(function(){	
  $(".dialog-form-suggest").dialog("open");
  $("#dialog-main").dialog("close");
});

$("#contact").click(function(){	
  $(".dialog-form-contact").dialog("open");
  $("#dialog-main").dialog("close");
});

$("#report").click(function(){
  $(".dialog-form-problem").dialog("open");
  $("#dialog-main").dialog("close");
});

$(".dialog-close").click(function(){
  $('form').trigger('reset');
  $(".dialog-all").dialog("close");
});

$(".feedback-submit").click(function(){
  $(".feedback-spinner").html("&nbsp;processing&nbsp;<img height='10px' width='10px' src='http://d3fildg3jlcvty.cloudfront.net/20140604-01/graphics/ajax-loader.gif' />");
  $(".dialog-cancel").attr("disabled","disabled");
  setTimeout(function(){$(".feedback-submit").attr("disabled","disabled");},500);
});

});
