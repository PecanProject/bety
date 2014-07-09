jQuery(function(){jQuery(".ui-dialog-titlebar").hide();});

jQuery('body').click(function(e){
  x = e.clientX ;
  y = e.clientY+jQuery(document).scrollTop();
  jQuery('.dialog-all').each(function(){
    if(jQuery(this).dialog("isOpen")){
      minx = jQuery(this).offset().left -5;
      maxx = jQuery(this).offset().left + jQuery(this).dialog("option","width") + 5;
      miny = jQuery(this).offset().top -5;
      maxy = jQuery(this).offset().top + jQuery(this).dialog("option","height") + 5;
      tminx = jQuery("#feedback-tab").offset().left-5;
      tmaxx = jQuery("#feedback-tab").offset().left+ jQuery("#feedback-tab").width() + 5;
      tminy = jQuery("#feedback-tab").offset().top-5 ;
      tmaxy = jQuery("#feedback-tab").offset().top+ jQuery("#feedback-tab").height() + 5;
      inthis = x>=minx && x<=maxx && y>=miny && y<=maxy;
      intab = x>=tminx && x<=tmaxx && y>=tminy && y<=tmaxy;
      if(!inthis && !intab)
        jQuery(this).dialog("close");
	}
  });
});

jQuery(".dialog-cancel").click(function(){
  jQuery(".dialog-all").dialog("close");
  return false;
});

jQuery(".dialog-all").dialog({
  autoOpen: false,
  modal: false,
  draggable: false,
  resizable: false,
  dialogClass: "fixed-dialog",
  show:{
    effect:"fade",
    duration:300,
  },
  hide:{
    effect:"fade",
    duration:300,
  },
  position: {
    my: "left+10 center",
    at: "right center",
    of: "#feedback-tab",
  },
  close: function(){
    jQuery("#feedback_email_feedback_subject").val("");
    jQuery("#feedback_email_feedback_text").val("");
  }
});

jQuery( ".dialog-form" ).dialog({
  height: 340,
  width: 250,
});

jQuery( "#dialog-main" ).dialog({
  height: 220,
  width: 150,
});

jQuery(".hr").css({
  "border-top":"1px solid #000000",
  "display":"inline-block",
  "width":"39%",
  "margin":"0px",
});

jQuery(".dialog-close").css({
  "float":"right",
  "color":"#aaa",
  "margin-bottom":"10px",
  "font-size":"16px",
  "font-weight":"bold",
  "cursor":"pointer",
});

jQuery(".fixed-dialog").css
({
  "position": "fixed", 
  "left": "0px", 
  "top": "50%",	
  "margin-top": "-62px",
});

jQuery(".fixed-dialog form").css
({
  "margin-top": "10px",
});

jQuery("#feedback-tab").click(function(){
  if(!jQuery("#dialog-main").dialog("isOpen")){
    jQuery(".dialog-all").dialog("close");
    jQuery("#dialog-main").dialog("open");
  }
  else
    jQuery(".dialog-all").dialog("close");
});

jQuery("#suggest").click(function(){	
  jQuery(".dialog-form").dialog("open");
  jQuery("#form-title").html("Suggest a Feature");
  jQuery("#feedback_email_type").val("Suggest a Feature");
  jQuery("#dialog-main").dialog("close");
});

jQuery("#contact").click(function(){	
  jQuery(".dialog-form").dialog("open");
  jQuery("#form-title").html("Contact Us");
  jQuery("#feedback_email_type").val("Contact");
  jQuery("#dialog-main").dialog("close");
});

jQuery("#report").click(function(){
  jQuery(".dialog-form").dialog("open");
  jQuery("#form-title").html("Report a Problem");
  jQuery("#feedback_email_type").val("Report a Problem");
  jQuery("#dialog-main").dialog("close");
});

jQuery(".dialog-close").click(function(){
  jQuery(".dialog-all").dialog("close");
});

jQuery(".feedback-submit").click(function(){
  jQuery(".feedback-spinner").html("&nbsp;processing&nbsp;<img height='10px' width='10px' src='http://d3fildg3jlcvty.cloudfront.net/20140604-01/graphics/ajax-loader.gif' />");
  jQuery(".dialog-cancel").attr("disabled","disabled");
  setTimeout(function(){jQuery(".feedback-submit").attr("disabled","disabled");},500);
});
