

// sync target's visibility with the state of checkbox
function sync(cb, target) {
  var checked = cb.attr('checked');
  var displayed = target.css('display') != 'none';
  if (checked != displayed) {
    if (checked)
      target.show();
    else
      target.hide();
  } 
}

// sync target's visibility with the inverse of the state of checkbox
function unsync(cb, target) {
  var checked = cb.attr('checked');
  var displayed = target.css('display') != 'none';
  if (checked == displayed) {
    if (checked)
      target.hide();
    else
      target.show();
  }
}

// associate the state of checkbox with the visibility of target
function associate(cb, target) {
  sync(cb, target);
  cb.click(function() {
    sync(cb, target);
  });
}

// select the appropriate image based on the options selected
function syncImage() {

  jQuery('.diagram').hide();
  var showNonKeys = jQuery('#showNonKeys').attr('checked'); 
  if (showNonKeys && jQuery('#realLargeImg').size() > 0) 
    jQuery('#realLargeImg').show();
  else 
    jQuery('#realCompactImg').show();    
  
    
}

// our 'ready' handler makes the page consistent




