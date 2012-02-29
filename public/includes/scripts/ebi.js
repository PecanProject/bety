// ready, set, go... 

jQuery(document).ready(function(){
       jQuery("#content tr:even").addClass("alt");  
});

/*
$j(function() { 
		   
		   // remove noscripts 
		   $j('.noscript').remove(); 
		   
		   // ie7 minimum for fancy stuff 
		   var lowIE = false; 
		   if (jQuery.browser.msie) { 
		   	if (parseInt(jQuery.browser.version) < 10) { 
				lowIE = true; 
				} 
			} 
			
			if (!lowIE) { 
			
			// smooth scrolling 
			//$('#banner').click( function() { $.scrollTo($("#content"), 400, { easing:'easeInOutCirc' }); }); 
			$.localScroll({ duration:500, easing:'easeInOutCirc' }); 
			
			// add striping to tables and highlight a row on rollover 
			
			};
});*/

  function showHide(element) {
    em = $(element);
    if (em.className.indexOf('hidden') == -1) {
      Effect.BlindUp(em);
      em.className = 'hidden';
      $('show_'+element).innerHTML = $('show_'+element).innerHTML.replace('[-] Hide','[+] View');
    } else {
      Effect.BlindDown(em);
      em.className = '';
      $('show_'+element).innerHTML = $('show_'+element).innerHTML.replace('[+] View','[-] Hide');
    }
  };
