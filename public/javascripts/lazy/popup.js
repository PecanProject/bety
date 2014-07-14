jQuery(function($){
  var outerdiv =$("<div id =\"popup-dialog\"><div id=\"popup-show\" style=\"width:600px\"></div></div>");
  $('head').append("<style>tr.popup-highlight td{background-color: #F2FA05 !important;}</style>");
  $('body').append(outerdiv);
  $("#popup-dialog").dialog({
    autoOpen: false,
    width:800,
    modal:true,
    buttons: {
      Close: function() {
        $(this).dialog( "close" );
      }
    },
    close:function(){
      $("#popup-show").empty();
      $(".popup-highlight").each(function(){
        $(this).removeClass("popup-highlight");
      })
    },
  });
  $(".ui-dialog-titlebar").hide();
  addpopup();
  $("#simple_search_table").on('mouseover',function(){addpopup();});
  var $outerdiv = $("#popup-dialog");
  var $innerdiv = $("#popup-show");

  function addpopup(){  
    $('#simple_search_table table tr').on('mouseenter','td',function(){ 
      var elem = $(this);
      var id = setTimeout(function(){popup(elem);},1000);
      elem.find('a').each(function(){
        $(this).hover(function(){
          clearTimeout(id);
          if(!$outerdiv.dialog("isOpen"))
            $("#popup-show").empty();
          $(this).parent().removeClass("popup-highlight");
        });
      });
      elem.find('select').each(function(){
        $(this).hover(function(){
          clearTimeout(id);
          if(!$outerdiv.dialog("isOpen"))
            $innerdiv.empty();
          $(this).parent().removeClass("popup-highlight");
        });
      });
      $(this).on('mouseleave',function(){       
        clearTimeout(id);
        if(!$outerdiv.dialog("isOpen")){
          $innerdiv.empty();
          $(this).parent().removeClass("popup-highlight");
        }
      });
    });
  } 

  function popup(elem){
    var row = elem.parent();
    var last = row.find('td:last');
    var show_link = last.find('a:first');
    while(show_link.attr("alt")!="show"){
      show_link=show_link.next();
      if(!show_link.is('a'))
        return false;
    }
    var url = show_link.attr("href");
    var source = url + " div.content div.container div.sixteen.columns";
    $innerdiv.empty();
    $innerdiv.load(source,function(){
      row.addClass("popup-highlight");
      $("#popup-show button").css({'font-size':'14px'});
      $("#popup-show h1").css({
        'font-size': '28px',
        'line-height': '1em',
        'color': '#007eac',
      });
      $outerdiv.dialog("open");
      $innerdiv.css({'height':'auto'});
    });
  }
  
  $('body').click(function(e){
  x = e.clientX;
  y = e.clientY+$(document).scrollTop();
  tminx = $outerdiv.offset().left-5;
  tmaxx = $outerdiv.offset().left+ $outerdiv.width() + 5;
  tminy = $outerdiv.offset().top-5 ;
  tmaxy = $outerdiv.offset().top+ $outerdiv.height() + 5;
  inthis = x>=tminx && x<=tmaxx && y>=tminy && y<=tmaxy;
  if(!inthis)
    $outerdiv.dialog("close");   
  });
});