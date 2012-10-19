
// usage: log('inside coolFunc', this, arguments);
window.log = function(){
log.history = log.history || [];   // store logs to an array for reference
log.history.push(arguments);
if(this.console) {
arguments.callee = arguments.callee.caller;
console.log( Array.prototype.slice.call(arguments) );
}
};
(function(b){function c(){}for(var d="assert,count,debug,dir,dirxml,error,exception,group,groupCollapsed,groupEnd,info,log,markTimeline,profile,profileEnd,time,timeEnd,trace,warn".split(","),a;a=d.pop();)b[a]=b[a]||c})(window.console=window.console||{});



/*
 * jQuery Extended Selectors plugin. (c) Keith Clark freely distributable under the terms of the MIT license.
 * Adds missing -of-type pseudo-class selectors to jQuery 
 * github.com/keithclark/JQuery-Extended-Selectors  -  twitter.com/keithclarkcouk  -  keithclark.co.uk
 */
(function(g){function e(a,b){for(var c=a,d=0;a=a[b];)c.tagName==a.tagName&&d++;return d}function h(a,b,c){a=e(a,c);if(b=="odd"||b=="even")c=2,a-=b!="odd";else{var d=b.indexOf("n");d>-1?(c=parseInt(b,10)||parseInt(b.substring(0,d)+"1",10),a-=(parseInt(b.substring(d+1),10)||0)-1):(c=a+1,a-=parseInt(b,10)-1)}return(c<0?a<=0:a>=0)&&a%c==0}var f={"first-of-type":function(a){return e(a,"previousSibling")==0},"last-of-type":function(a){return e(a,"nextSibling")==0},"only-of-type":function(a){return f["first-of-type"](a)&&
f["last-of-type"](a)},"nth-of-type":function(a,b,c){return h(a,c[3],"previousSibling")},"nth-last-of-type":function(a,b,c){return h(a,c[3],"nextSibling")}};g.extend(g.expr[":"],f)})(jQuery);



/*! http://mths.be/placeholder v1.8.5 by @mathias */
(function(g,a,$){var f='placeholder' in a.createElement('input'),b='placeholder' in a.createElement('textarea');if(f&&b){$.fn.placeholder=function(){return this};$.fn.placeholder.input=$.fn.placeholder.textarea=true}else{$.fn.placeholder=function(){return this.filter((f?'textarea':':input')+'[placeholder]').bind('focus.placeholder',c).bind('blur.placeholder',e).trigger('blur.placeholder').end()};$.fn.placeholder.input=f;$.fn.placeholder.textarea=b;$(function(){$('form').bind('submit.placeholder',function(){var h=$('.placeholder',this).each(c);setTimeout(function(){h.each(e)},10)})});$(g).bind('unload.placeholder',function(){$('.placeholder').val('')})}function d(i){var h={},j=/^jQuery\d+$/;$.each(i.attributes,function(l,k){if(k.specified&&!j.test(k.name)){h[k.name]=k.value}});return h}function c(){var h=$(this);if(h.val()===h.attr('placeholder')&&h.hasClass('placeholder')){if(h.data('placeholder-password')){h.hide().next().show().focus().attr('id',h.removeAttr('id').data('placeholder-id'))}else{h.val('').removeClass('placeholder')}}}function e(){var l,k=$(this),h=k,j=this.id;if(k.val()===''){if(k.is(':password')){if(!k.data('placeholder-textinput')){try{l=k.clone().attr({type:'text'})}catch(i){l=$('<input>').attr($.extend(d(this),{type:'text'}))}l.removeAttr('name').data('placeholder-password',true).data('placeholder-id',j).bind('focus.placeholder',c);k.data('placeholder-textinput',l).data('placeholder-id',j).before(l)}k=k.removeAttr('id').hide().prev().attr('id',j).show()}k.addClass('placeholder').val(k.attr('placeholder'))}else{k.removeClass('placeholder')}}}(this,document,jQuery));



/**
* hoverIntent r6 // 2011.02.26 // jQuery 1.5.1+
* <http://cherne.net/brian/resources/jquery.hoverIntent.html>
* 
* @param  f  onMouseOver function || An object with configuration options
* @param  g  onMouseOut function  || Nothing (use configuration options object)
* @author    Brian Cherne brian(at)cherne(dot)net
*/
(function($){$.fn.hoverIntent=function(f,g){var cfg={sensitivity:7,interval:100,timeout:0};cfg=$.extend(cfg,g?{over:f,out:g}:f);var cX,cY,pX,pY;var track=function(ev){cX=ev.pageX;cY=ev.pageY};var compare=function(ev,ob){ob.hoverIntent_t=clearTimeout(ob.hoverIntent_t);if((Math.abs(pX-cX)+Math.abs(pY-cY))<cfg.sensitivity){$(ob).unbind("mousemove",track);ob.hoverIntent_s=1;return cfg.over.apply(ob,[ev])}else{pX=cX;pY=cY;ob.hoverIntent_t=setTimeout(function(){compare(ev,ob)},cfg.interval)}};var delay=function(ev,ob){ob.hoverIntent_t=clearTimeout(ob.hoverIntent_t);ob.hoverIntent_s=0;return cfg.out.apply(ob,[ev])};var handleHover=function(e){var ev=jQuery.extend({},e);var ob=this;if(ob.hoverIntent_t){ob.hoverIntent_t=clearTimeout(ob.hoverIntent_t)}if(e.type=="mouseenter"){pX=ev.pageX;pY=ev.pageY;$(ob).bind("mousemove",track);if(ob.hoverIntent_s!=1){ob.hoverIntent_t=setTimeout(function(){compare(ev,ob)},cfg.interval)}}else{$(ob).unbind("mousemove",track);if(ob.hoverIntent_s==1){ob.hoverIntent_t=setTimeout(function(){delay(ev,ob)},cfg.timeout)}}};return this.bind('mouseenter',handleHover).bind('mouseleave',handleHover)}})(jQuery);




/*
 * Superfish v1.4.8 - jQuery menu widget
 * Copyright (c) 2008 Joel Birch
 *
 * Dual licensed under the MIT and GPL licenses:
 * 	http://www.opensource.org/licenses/mit-license.php
 * 	http://www.gnu.org/licenses/gpl.html
 *
 * CHANGELOG: http://users.tpg.com.au/j_birch/plugins/superfish/changelog.txt
 */

(function(a){a.fn.superfish=function(b){var c=a.fn.superfish,d=c.c,e=a(['<span class="',d.arrowClass,'"> &#187;</span>'].join("")),f=function(){var b=a(this),c=h(b);clearTimeout(c.sfTimer);b.showSuperfishUl().siblings().hideSuperfishUl()},g=function(){var b=a(this),d=h(b),e=c.op;clearTimeout(d.sfTimer);d.sfTimer=setTimeout(function(){e.retainPath=a.inArray(b[0],e.$path)>-1;b.hideSuperfishUl();if(e.$path.length&&b.parents(["li.",e.hoverClass].join("")).length<1){f.call(e.$path)}},e.delay)},h=function(a){var b=a.parents(["ul.",d.menuClass,":first"].join(""))[0];c.op=c.o[b.serial];return b},i=function(a){a.addClass(d.anchorClass).append(e.clone())};return this.each(function(){var e=this.serial=c.o.length;var h=a.extend({},c.defaults,b);h.$path=a("li."+h.pathClass,this).slice(0,h.pathLevels).each(function(){a(this).addClass([h.hoverClass,d.bcClass].join(" ")).filter("li:has(ul)").removeClass(h.pathClass)});c.o[e]=c.op=h;a("li:has(ul)",this)[a.fn.hoverIntent&&!h.disableHI?"hoverIntent":"hover"](f,g).each(function(){if(h.autoArrows)i(a(">a:first-child",this))}).not("."+d.bcClass).hideSuperfishUl();var j=a("a",this);j.each(function(a){var b=j.eq(a).parents("li");j.eq(a).focus(function(){f.call(b)}).blur(function(){g.call(b)})});h.onInit.call(this)}).each(function(){var b=[d.menuClass];if(c.op.dropShadows&&!(a.browser.msie&&a.browser.version<7))b.push(d.shadowClass);a(this).addClass(b.join(" "))})};var b=a.fn.superfish;b.o=[];b.op={};b.IE7fix=function(){var c=b.op;if(a.browser.msie&&a.browser.version>6&&c.dropShadows&&c.animation.opacity!=undefined)this.toggleClass(b.c.shadowClass+"-off")};b.c={bcClass:"sf-breadcrumb",menuClass:"sf-js-enabled",anchorClass:"sf-with-ul",arrowClass:"sf-sub-indicator",shadowClass:"sf-shadow"};b.defaults={hoverClass:"sfHover",pathClass:"overideThisToUse",pathLevels:1,delay:800,animation:{opacity:"show"},speed:"normal",autoArrows:true,dropShadows:true,disableHI:false,onInit:function(){},onBeforeShow:function(){},onShow:function(){},onHide:function(){}};a.fn.extend({hideSuperfishUl:function(){var c=b.op,d=c.retainPath===true?c.$path:"";c.retainPath=false;var e=a(["li.",c.hoverClass].join(""),this).add(this).not(d).removeClass(c.hoverClass).find(">ul").hide().css("visibility","hidden");c.onHide.call(e);return this},showSuperfishUl:function(){var a=b.op,c=b.c.shadowClass+"-off",d=this.addClass(a.hoverClass).find(">ul:hidden").css("visibility","visible");b.IE7fix.call(d);a.onBeforeShow.call(d);d.animate(a.animation,a.speed,function(){b.IE7fix.call(d);a.onShow.call(d)});return this}})})(jQuery);





/*
 * Pufferfish v1 - Superfish jQuery menu widget extention
 * Copyright (c) 2012 Eric J Hansel
 *
 * Dual licensed under the MIT and GPL licenses:
 * 	http://www.opensource.org/licenses/mit-license.php
 * 	http://www.gnu.org/licenses/gpl.html
 *
 */


/*
(function($){
    $.fn.extend({        
        pufferfish: function() {   
            return this.each(function() {   
                var obj = $(this);   
                $(this).addClass('pufferfishEnabled');
                var items = $('li', obj);
                $(items).each(function(){
                    var hasUl = $(this).has('ul');
                    $(hasUl).prepend('<a class="menuDrop" href="#"><span>drop down</span></a>').closest('li').addClass('hasDrop');        
                    $(hasUl).each(function(){ 
                        $('.menuDrop',this).click(function(){
                            var htmlClass = $('html');
                            if($(htmlClass).hasClass('touch')){
                                var menuToAnimate = $(this).siblings('ul');
                                var menuOpacity = $(this).siblings('ul').css('display');
                                console.log($(this).siblings('ul'));
                                console.log(menuOpacity);
                                if( !$(menuToAnimate).is(":animated") ) {
                                    $(menuToAnimate).animate({
                                        //opacity: 'toggle',
                                        visibility: 'toggle'
                                        
                                    },300);
                                };
                                return false;
                            }else{
                                return false;
                            };
                        });
                        
                    });
                });  
            });
        }
    });
})(jQuery);*/



(function($){
    $.fn.extend({        
        pufferfish: function() {   
            return this.each(function() {
                var obj = $(this);
                var htmlClass = $('html');
                if($(htmlClass).hasClass('touch')){
                    var items = $('li', obj);
                    $(obj).addClass('pufferfishEnabled');
                    //$('a', obj).on('click',function(event){
                    //    event.stopPropagation();
                    //});
                    $(items).each(function(){
                        var hasUl = $(this).has('ul');
                        $('ul', this).css('display','none');
                        $(hasUl).prepend('<a class="menuDrop" href="#"><span>drop down</span></a>').closest('li').addClass('hasDrop');        
                        $(hasUl).each(function(){ 
                            $('.menuDrop',this).on('click', function(){
                                var menuToAnimate = $(this).parent('li');
                                if( !$(menuToAnimate).hasClass('sfHover') ) {
                                    $(menuToAnimate).addClass('sfHover');
                                    $(this).siblings('ul').css('display','block');
                                    $(this).parent().siblings('li').removeClass('sfHover');
                                    $(this).parent().siblings('li').find('li').removeClass('sfHover');
                                    $(this).parent().siblings('li').find('ul').css('display','none');
                                }else{
                                    $(menuToAnimate).removeClass('sfHover');
                                    $(this).siblings('ul').css('display','none');
                                    $(this).siblings('ul').find('li').removeClass('sfHover');
                                    $(this).siblings('ul').find('ul').css('display','none');
                                };
                                return false;
                            });

                        });
                        /*
                        $(document).on('click',function(){
                            var menuWithDrop = $('.menuDrop').parent('li');
                            if($(menuWithDrop).hasClass('sfHover')){
                                $(menuWithDrop).removeClass('sfHover');
                                $(menuWithDrop).find('ul').css('display','none');
                            };
                            
                            console.log('Document Clicked');
                        });
                        */
                    }); 
                }else{
                    $(obj).superfish();
                }
            });
        }
    });
})(jQuery);