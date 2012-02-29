// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
// ready, set, go... 

document.observe("dom:loaded", function() {
       $$("#content tr:even").each(function(el){el.addClassName("alt");});  
});

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

/* 
  popup.js

  A lightweight general purpose JavaScript DOM element popup class.

  Webpage:
    http;//www.methods.co.nz/popup/popup.html

  Inspired by:
    Lightbox2: http://www.huddletogether.com/projects/lightbox2/
    Lightbox Gone Wild: http://particletree.com/features/lightbox-gone-wild/
    Tooltip: http://blog.innerewut.de/pages/tooltip
    Prototype library: http://www.prototypejs.org/
    Scriptaculous library: http://script.aculo.us/

  Attributions:
    - Uses the getPageSize() function from Lightbox v2.02 by Lokesh Dhakar
      (http://www.huddletogether.com/projects/lightbox2/).
    - Adapted the the modal overlay technique used in Lightbox v2.02 by Lokesh
      Dhakar (http://www.huddletogether.com/projects/lightbox2/).

  Version: 1.0.1

  Author:    Stuart Rackham <srackham@methods.co.nz>
  License:   This source code is released under the MIT license.

  Copyright (c) Stuart Rackham 2007

*/

var Popup = Class.create();
Popup.zIndex = 1000;  // z-index of first popup.

Popup.prototype = {

  /*
    Popup creation
  */
  initialize: function(popup, link) {
    var options = Object.extend({
      modal: false,
      effect: 'fade',
      hidden: true,
      closebox: 'popup_closebox',       // CSS class name of click-to-close elements.
      draghandle: 'popup_draghandle'    // CSS class name of drag handle elements.
    }, arguments[2] || {});
    options.position = options.position || (options.modal ? 'center' : 'auto');
    options.trigger = options.trigger || (options.modal ? 'click' : 'mouseover');
    options.duration = this.first_value(options.duration, Popup.duration, 0.5);
    options.show_duration = this.first_value(options.show_duration, options.duration);
    options.hide_duration = this.first_value(options.hide_duration, options.duration);
    options.opacity = this.first_value(options.opacity, Popup.opacity, 0.5);
    options.show_delay = this.first_value(options.show_delay, Popup.show_delay, 500);
    options.hide_delay = this.first_value(options.hide_delay, Popup.hide_delay, 200);
    options.cursor_margin = this.first_value(options.cursor_margin, Popup.cursor_margin, 5);
    this.options = options;
    if (link) {
      this.link = $(link);
    }
    this.popup = $(popup);
    this.popup.popup = this;  // Make the popup object a property of the DOM popup element.
    if (options.hidden) {
      this.popup.hide();
    }
    if (options.closebox) {
      this.closeboxes = document.getElementsByClassName(options.closebox, this.popup);
      if (this.popup.hasClassName(options.closebox)) {
        this.closeboxes[this.closeboxes.length] = this.popup;
      }
    }
    else {
      this.closeboxes = [];
    }
    if (options.draghandle) {
      var draghandles = document.getElementsByClassName(options.draghandle, this.popup);
      for (i = 0; i < draghandles.length; i++) {
        new Draggable(this.popup, { handle: draghandles[i] });
      }
      if (this.popup.hasClassName(options.draghandle)) {
        new Draggable(this.popup, { handle: this.popup });
      }
    }
    this.register_events();
  },


  /*
    Event functions
  */

  register_events: function() {
    var trigger_function;
    if (this.is_auto_open()) {
      trigger_function = this.start_show_timer;
      if (this.link) {
        Event.observe(this.link, 'mouseout', this.stop_show_timer.bindAsEventListener(this));
      }
    }
    else {
      trigger_function = this.show;
    }
    if (this.link) {
      Event.observe(this.link, this.options.trigger, trigger_function.bindAsEventListener(this));
    }
    if (!this.options.modal) {
      Event.observe(this.popup, 'click', this.bring_to_front.bindAsEventListener(this));
    }
    if (this.closeboxes.length > 0) {
      for (var i = 0; i < this.closeboxes.length; i++) {
        Event.observe(this.closeboxes[i], 'click', this.hide.bindAsEventListener(this));
      }
    }
    else {
      if (this.link) {
        Event.observe(this.link, 'mouseout', this.start_hide_timer.bindAsEventListener(this));
      }
      Event.observe(this.popup, 'mouseover', this.stop_hide_timer.bindAsEventListener(this));
      Event.observe(this.popup, 'mouseout', this.start_hide_timer.bindAsEventListener(this));
    }
  },

  bring_to_front: function(event) {
    // Bring to front if not already there.
    if (Number(this.popup.style.zIndex) < Popup.zIndex - 1) {
      this.popup.style.zIndex = Popup.zIndex++;
    }
  },

  start_show_timer: function(event) {
    // NOTE: event is bound to this.show but it's state changes between being
    // bound here and arriving at this.show -- specifically, the mouse
    // coordinates are reset to zero). I've no idea why. Anyway, this is the
    // reason for passing the event mouse coordinates as properties of this.
    this.stop_show_timer(event);
    this.mouse_x = Event.pointerX(event);
    this.mouse_y = Event.pointerY(event);
    this.show_timer = setTimeout(this.show.bind(this, event), this.options.show_delay);
  },

  stop_show_timer: function(event) {
    if (this.show_timer) {
      clearTimeout(this.show_timer);
      this.show_timer = null;
    }
  },

  start_hide_timer: function(event) {
    this.stop_hide_timer(event);
    this.hide_timer = setTimeout(this.hide.bind(this, event), this.options.hide_delay);
  },

  stop_hide_timer: function(event) {
    if (this.hide_timer) {
      clearTimeout(this.hide_timer);
      this.hide_timer = null;
    }
  },

  show: function(event) {
    this.stop_show_timer(event);
    this.stop_hide_timer(event);
    if (this.is_open) {
      return;
    }
    if (this.options.modal) {
      this.show_overlay();
    }
    var pos;
    if (!event) {
      // We only arrive here if this.show has been called externally.
      pos = this.get_popup_position();
    }
    else if (this.is_auto_open()) {
      // Because auto-open popups calls this.show indirectly via start_show_timer.
      pos = this.get_popup_position(this.mouse_x, this.mouse_y);
    }
    else {
      pos = this.get_popup_position(Event.pointerX(event), Event.pointerY(event));
    }
    Element.setStyle(this.popup, { top: pos.y, left: pos.x, zIndex: Popup.zIndex++ });
    this.is_open = true;
    switch (this.options.effect) {
      case 'slide':
        Effect.SlideDown(this.popup, {duration: this.options.show_duration});
        break;
      case 'grow':
        Effect.Grow(this.popup, {duration: this.options.show_duration});
        break;
      case 'blind':
        Effect.BlindDown(this.popup, {duration: this.options.show_duration});
        break;
      case 'fade':
      default:
        Effect.Appear(this.popup, {duration: this.options.show_duration});
        break;
    }
  },
  
  hide: function(event){
    this.is_open = false;
    switch (this.options.effect) {
      case 'slide':
        Effect.SlideUp(this.popup, {duration: this.options.hide_duration});
        break;
      case 'grow':
        Effect.Shrink(this.popup, {duration: this.options.hide_duration});
        break;
      case 'blind':
        Effect.BlindUp(this.popup, {duration: this.options.hide_duration});
        break;
      case 'fade':
      default:
        Effect.Fade(this.popup, {duration: this.options.hide_duration});
        break;
    }
    if (this.options.modal) {
      this.hide_overlay();
    }
  },


  /*
    Helper functions
  */

  // Return the first function argument that is not undefined.
  // Because when zero numerical value are possible you can't use || chains.
  first_value: function() {
    for (var i = 0; i < arguments.length; i++) {
      if (arguments[i] !== undefined) {
        return arguments[i];
      }
    }
    return undefined;
  },

  is_auto_open: function() {
    return this.options.trigger == 'mouseover';
  },

  show_overlay: function() {
    if (!Popup.overlay) {
      var overlay = document.createElement('div');
      overlay.setAttribute('id','popup_overlay');
      overlay.style.display = 'none';
      document.body.appendChild(overlay);
      Popup.overlay = overlay;
      Popup.overlay_levels = [];
    }
    Popup.overlay.style.height = this.get_page_dimensions().height + 'px';
    var z = Popup.zIndex++;
    Popup.overlay.style.zIndex = z;
    Popup.overlay_levels.push(z);
    if ( Popup.overlay_levels.length == 1) { // Opening the first modal popup.
      // Queue the global overlay effect to ensure correct execution order.
      new Effect.Appear(Popup.overlay,
        { duration: this.options.show_duration,
          to: this.options.opacity,
          queue: {position: 'end', scope: 'popup_overlay'}
        });
    }
    else { // There is another modal popup at a lower level so move the overlay forward.
      Popup.overlay.style.zIndex = z;
    }
  },
		
  hide_overlay: function() {
    Popup.overlay_levels.pop();
    var z = Popup.overlay_levels.pop();
    if (z) { // There is another modal popup at a lower level so move the overlay back.
      Popup.overlay_levels.push(z);
      Popup.overlay.style.zIndex = z;
    }
    else { // The last modal popup is being closed so hide the overlay
      // Queue the global overlay effect to ensure correct execution order.
      new Effect.Fade(Popup.overlay,
        { duration: this.options.hide_duration,
          queue: {position: 'end', scope: 'popup_overlay'}
        });
    }
  },


  /*
    Positioning functions
  */

  // Return the top and left CSS position strings as an {x,y} object that the
  // popup should be shown at.  mouse_x and mouse_y are the mouse x,y coordinates
  // numbers when the popup was triggered.
  get_popup_position: function(mouse_x, mouse_y) {
    var pos;
    switch (this.options.position) {
      case 'auto':
        pos = this.get_auto_position(mouse_x, mouse_y);
        break;
      case 'center':
        pos = this.get_center_position();
        break;
      case 'below':
        pos = this.get_below_position();
        break;
      default:
        // Check for x,y postion format (x and y can be any valid CSS left or
        // top property value).
        if (mo = this.options.position.match(/^\s*([^\s,]+)\s*,\s*([^\s,]+)\s*$/)) {
          pos = {x: mo[1], y: mo[2]};
          // If possible convert to numbers.
          pos.x = Number(pos.x) || pos.x;
          pos.y = Number(pos.y) || pos.y;
        }
        else {
          pos = {x: 0, y: 0};
        }
        break;
    }
    if (typeof pos.x == 'number') {
      pos.x += 'px';
    }
    if (typeof pos.y == 'number') {
      pos.y += 'px';
    }
    return pos;
  },

  get_below_position: function() {
    var pos = Position.cumulativeOffset(this.link);
    return {x: pos[0], y: pos[1] + Element.getHeight(this.link)};
  },

  get_center_position: function() {
    dim = Element.getDimensions(this.popup);
    var popup_width = dim.width;
    var popup_height = dim.height;
    dim = this.get_viewport_dimensions();
    var viewport_width = dim.width;
    var viewport_height = dim.height;

    var x;
    if (popup_width >= viewport_width) {
      x = 0;
    }
    else {
      x = (viewport_width - popup_width)/2;
    }

    var y;
    if (popup_height >= viewport_height) {
      y = 0;
    }
    else {
      y = (viewport_height - popup_height)/2;
    }

    return {x: x, y: y}; 
  },

  get_auto_position: function(mouse_x, mouse_y) {
    dim = Element.getDimensions(this.popup);
    var popup_width = dim.width;
    var popup_height = dim.height;
    dim = this.get_viewport_dimensions();
    var viewport_width = dim.width;
    var viewport_height = dim.height;

    var available_right = viewport_width - (mouse_x + this.options.cursor_margin);
    var available_left = mouse_x - this.options.cursor_margin;
    var available_top = mouse_y - this.options.cursor_margin;
    var available_bottom = viewport_height - (mouse_x + this.options.cursor_margin);
    var offset = this.options.cursor_margin;
    var x = mouse_x;
    var y = mouse_y;

    if (popup_width >= viewport_width) {
      x = 0;
    }
    else if (popup_width <= available_right) {
      x += offset;
    }
    else if (popup_width <= available_left) {
      x -= popup_width + offset;
    }
    else if (available_right >= available_left) {
      x = viewport_width - popup_width;
    }
    else {
      x = 0;
    }

    if (popup_height >= viewport_height) {
      y = 0;
    }
    else if (popup_height <= available_bottom) {
      y += offset;
    }
    else if (popup_height <= available_top) {
      y -= popup_height + offset;
    }
    else if (available_bottom >= available_top) {
      y = viewport_height - popup_height;
    }
    else {
      y = 0;
    }

    return {x: x, y: y}; 
  },
  
  get_viewport_dimensions: function() {
		var dim = this.getPageSize();
    return {width: dim[2], height: dim[3]};
  },

  get_page_dimensions: function() {
		var dim = this.getPageSize();
    return {width: dim[0], height: dim[1]};
  },

  // This function from Lightbox v2.02 by Lokesh Dhakar
  // (http://www.huddletogether.com/projects/lightbox2/).
  //
  // Returns array with page width, height and window width, height
  // Core code from - quirksmode.org
  // Edit for Firefox by pHaez
  //
  getPageSize: function() {
    var xScroll, yScroll;

    if (window.innerHeight && window.scrollMaxY) {	
      xScroll = document.body.scrollWidth;
      yScroll = window.innerHeight + window.scrollMaxY;
    } else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
      xScroll = document.body.scrollWidth;
      yScroll = document.body.scrollHeight;
    } else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
      xScroll = document.body.offsetWidth;
      yScroll = document.body.offsetHeight;
    }

    var windowWidth, windowHeight;
    if (self.innerHeight) {	// all except Explorer
      windowWidth = self.innerWidth;
      windowHeight = self.innerHeight;
    } else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
      windowWidth = document.documentElement.clientWidth;
      windowHeight = document.documentElement.clientHeight;
    } else if (document.body) { // other Explorers
      windowWidth = document.body.clientWidth;
      windowHeight = document.body.clientHeight;
    }	
    
    // for small pages with total height less then height of the viewport
    if(yScroll < windowHeight){
      pageHeight = windowHeight;
    } else { 
      pageHeight = yScroll;
    }

    // for small pages with total width less then width of the viewport
    if(xScroll < windowWidth){	
      pageWidth = windowWidth;
    } else {
      pageWidth = xScroll;
    }

    arrayPageSize = new Array(pageWidth,pageHeight,windowWidth,windowHeight);
    return arrayPageSize;
  }

}

// Title: tigra menu
// Description: See the demo at url
// URL: http://www.softcomplex.com/products/tigra_menu/
// Version: 2.0 (commented source)
// Date: 04-05-2003 (mm-dd-yyyy)
// Tech. Support: http://www.softcomplex.com/forum/forumdisplay.php?fid=40
// Notes: This script is free. Visit official site for further details.

// --------------------------------------------------------------------------------
// global collection containing all menus on current page
var A_MENUS = [];

// --------------------------------------------------------------------------------
// menu class
function menu (a_items, a_tpl) {

	// browser check
	if (!document.body || !document.body.style)
		return;

	// store items structure
	this.a_config = a_items;

	// store template structure
	this.a_tpl = a_tpl;

	// get menu id
	this.n_id = A_MENUS.length;

	// declare collections
	this.a_index = [];
	this.a_children = [];

	// assigh methods and event handlers
	this.expand      = menu_expand;
	this.collapse    = menu_collapse;

	this.onclick     = menu_onclick;
	this.onmouseout  = menu_onmouseout;
	this.onmouseover = menu_onmouseover;
	this.onmousedown = menu_onmousedown;

	// default level scope description structure 
	this.a_tpl_def = {
		'block_top'  : 16,
		'block_left' : 16,
		'top'        : 20,
		'left'       : 4,
		'width'      : 120,
		'height'     : 22,
		'hide_delay' : 0,
		'expd_delay' : 0,
		'css'        : {
			'inner' : '',
			'outer' : ''
		}
	};
	
	// assign methods and properties required to imulate parent item
	this.getprop = function (s_key) {
		return this.a_tpl_def[s_key];
	};

	this.o_root = this;
	this.n_depth = -1;
	this.n_x = 0;
	this.n_y = 0;

	// 	init items recursively
	for (n_order = 0; n_order < a_items.length; n_order++){
		new menu_item(this, n_order);
	}

	// register self in global collection
	A_MENUS[this.n_id] = this;

	// make root level visible
	for (var n_order = 0; n_order < this.a_children.length; n_order++)
		this.a_children[n_order].e_oelement.style.visibility = 'visible';
}

// --------------------------------------------------------------------------------
function menu_collapse (n_id) {
	// cancel item open delay
	clearTimeout(this.o_showtimer);

	// by default collapse to root level
	var n_tolevel = (n_id ? this.a_index[n_id].n_depth : 0);
	
	// hide all items over the level specified
	for (n_id = 0; n_id < this.a_index.length; n_id++) {
		var o_curritem = this.a_index[n_id];
		if (o_curritem.n_depth > n_tolevel && o_curritem.b_visible) {
			o_curritem.e_oelement.style.visibility = 'hidden';
			o_curritem.b_visible = false;
		}
	}

	// reset current item if mouse has gone out of items
	if (!n_id)
		this.o_current = null;
}

// --------------------------------------------------------------------------------
function menu_expand (n_id) {

	// expand only when mouse is over some menu item
	if (this.o_hidetimer)
		return;

	// lookup current item
	var o_item = this.a_index[n_id];

	// close previously opened items
	if (this.o_current && this.o_current.n_depth >= o_item.n_depth)
		this.collapse(o_item.n_id);
	this.o_current = o_item;

	// exit if there are no children to open
	if (!o_item.a_children)
		return;

	// show direct child items
	for (var n_order = 0; n_order < o_item.a_children.length; n_order++) {
		var o_curritem = o_item.a_children[n_order];
		o_curritem.e_oelement.style.visibility = 'visible';
		o_curritem.b_visible = true;
	}
}

// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------
function menu_onclick (n_id) {
	// don't go anywhere if item has no link defined
	return Boolean(this.a_index[n_id].a_config[1]);
}

// --------------------------------------------------------------------------------
function menu_onmouseout (n_id) {

	// lookup new item's object	
	var o_item = this.a_index[n_id];

	// apply rollout
	o_item.e_oelement.className = o_item.getstyle(0, 0);
	o_item.e_ielement.className = o_item.getstyle(1, 0);
	
	// update status line	
	o_item.upstatus(7);

	// run mouseover timer
	this.o_hidetimer = setTimeout('A_MENUS['+ this.n_id +'].collapse();',
		o_item.getprop('hide_delay'));
}

// --------------------------------------------------------------------------------
function menu_onmouseover (n_id) {

	// cancel mouseoute menu close and item open delay
	clearTimeout(this.o_hidetimer);
	this.o_hidetimer = null;
	clearTimeout(this.o_showtimer);

	// lookup new item's object	
	var o_item = this.a_index[n_id];

	// update status line	
	o_item.upstatus();

	// apply rollover
	o_item.e_oelement.className = o_item.getstyle(0, 1);
	o_item.e_ielement.className = o_item.getstyle(1, 1);
	
	// if onclick open is set then no more actions required
	if (o_item.getprop('expd_delay') < 0)
		return;

	// run expand timer
	this.o_showtimer = setTimeout('A_MENUS['+ this.n_id +'].expand(' + n_id + ');',
		o_item.getprop('expd_delay'));

}

// --------------------------------------------------------------------------------
// called when mouse button is pressed on menu item
// --------------------------------------------------------------------------------
function menu_onmousedown (n_id) {
	
	// lookup new item's object	
	var o_item = this.a_index[n_id];

	// apply mouse down style
	o_item.e_oelement.className = o_item.getstyle(0, 2);
	o_item.e_ielement.className = o_item.getstyle(1, 2);

	this.expand(n_id);
//	this.items[id].switch_style('onmousedown');
}


// --------------------------------------------------------------------------------
// menu item Class
function menu_item (o_parent, n_order) {

	// store parameters passed to the constructor
	this.n_depth  = o_parent.n_depth + 1;
	this.a_config = o_parent.a_config[n_order + (this.n_depth ? 3 : 0)];

	// return if required parameters are missing
	if (!this.a_config) return;

	// store info from parent item
	this.o_root    = o_parent.o_root;
	this.o_parent  = o_parent;
	this.n_order   = n_order;

	// register in global and parent's collections
	this.n_id = this.o_root.a_index.length;
	this.o_root.a_index[this.n_id] = this;
	o_parent.a_children[n_order] = this;

	// calculate item's coordinates
	var o_root = this.o_root,
		a_tpl  = this.o_root.a_tpl;

	// assign methods
	this.getprop  = mitem_getprop;
	this.getstyle = mitem_getstyle;
	this.upstatus = mitem_upstatus;

	this.n_x = n_order
		? o_parent.a_children[n_order - 1].n_x + this.getprop('left')
		: o_parent.n_x + this.getprop('block_left');

	this.n_y = n_order
		? o_parent.a_children[n_order - 1].n_y + this.getprop('top')
		: o_parent.n_y + this.getprop('block_top');
	
	// lonux extension start
	var href=this.a_config[1];
	var target='_self';
	if(this.a_config[2]){
		switch (this.a_config[2]['tw']) {
			case '0':
			break;
			case '1':
				href='javascript:popupWindow(\''+this.a_config[1]+'\',0,0,\'yes\',\'yes\',\'yes\',\'yes\',\'yes\')';
				target='';
			break;
			case '2':
				href='javascript:popupWindow(\''+this.a_config[1]+'\',0,0,\'no\',\'no\',\'no\',\'no\',\'no\')';
				target='';
			break;
			case '3':
				href='';
				target='';
			break;
		}
	}
	// lonux extension end
	
	// generate item's HMTL
	var html_row =
		'<a id="e' + o_root.n_id + '_'
			// lonux extension start
			+ this.n_id +'o" class="' + this.getstyle(0, 0) + '" href="' + href + '"'
			+ ' target="' + target + '"' 
			// lonux extension end

//			+ this.n_id +'o" class="' + this.getstyle(0, 0) + '" href="' + this.a_config[1] + '"'
//			+ (this.a_config[2] && this.a_config[2]['tw'] ? ' target="'
//			+ this.a_config[2]['tw'] + '"' : '') 
			+ ' style="position: absolute; top: '
			+ this.n_y + 'px; left: ' + this.n_x + 'px; width: '
			+ this.getprop('width') + 'px; height: '
			+ this.getprop('height') + 'px; visibility: hidden;'
			+' z-index: ' + this.n_depth + ';" '
			+ 'onclick="return A_MENUS[' + o_root.n_id + '].onclick('
			+ this.n_id + ');" onmouseout="A_MENUS[' + o_root.n_id + '].onmouseout('
			+ this.n_id + ');" onmouseover="A_MENUS[' + o_root.n_id + '].onmouseover('
			+ this.n_id + ');" onmousedown="A_MENUS[' + o_root.n_id + '].onmousedown('
			+ this.n_id + ');"><div  id="e' + o_root.n_id + '_'
			+ this.n_id +'i" class="' + this.getstyle(1, 0) + '">'
			+ this.a_config[0] + "</div></a>\n";

	document.write(html_row);
		
	this.e_ielement = document.getElementById('e' + o_root.n_id + '_' + this.n_id + 'i');
	this.e_oelement = document.getElementById('e' + o_root.n_id + '_' + this.n_id + 'o');

	this.b_visible = !this.n_depth;

	// no more initialization if leaf
	if (this.a_config.length < 4)
		return;

	// node specific methods and properties
	this.a_children = [];

	// init downline recursively
	for (var n_order = 0; n_order < this.a_config.length - 3; n_order++)
		new menu_item(this, n_order);
}

// --------------------------------------------------------------------------------
// reads property from template file, inherits from parent level if not found
// ------------------------------------------------------------------------------------------
function mitem_getprop (s_key) {

	// check if value is defined for current level
	var s_value = null,
		a_level = this.o_root.a_tpl[this.n_depth];

	// return value if explicitly defined
	if (a_level)
		s_value = a_level[s_key];

	// request recursively from parent levels if not defined
	return (s_value == null ? this.o_parent.getprop(s_key) : s_value);
}
// --------------------------------------------------------------------------------
// reads property from template file, inherits from parent level if not found
// ------------------------------------------------------------------------------------------
function mitem_getstyle (n_pos, n_state) {

	var a_css = this.getprop('css');
	var a_oclass = a_css[n_pos ? 'inner' : 'outer'];

	// same class for all states	
	if (typeof(a_oclass) == 'string')
		return a_oclass;

	// inherit class from previous state if not explicitly defined
	for (var n_currst = n_state; n_currst >= 0; n_currst--)
		if (a_oclass[n_currst])
			return a_oclass[n_currst];
}

// ------------------------------------------------------------------------------------------
// updates status bar message of the browser
// ------------------------------------------------------------------------------------------
function mitem_upstatus (b_clear) {
	window.setTimeout("window.status=unescape('" + (b_clear
		? ''
		: (this.a_config[2] && this.a_config[2]['sb']
			? escape(this.a_config[2]['sb'])
			: escape(this.a_config[0]) + (this.a_config[1]
				? ' ('+ escape(this.a_config[1]) + ')'
				: ''))) + "')", 10);
}

// --------------------------------------------------------------------------------
// that's all folks


var topmenu_MENU_POS = [{ 'height':26,
                          'width':155,
                          'block_top':0,
                          'block_left':0,
                          'top':0,
                          'left':155,
                          'hide_delay':600,
                          'expd_delay':100,
                          'css':{ 'outer':['topmenu_l0oout','topmenu_l0oover'],
                                  'inner':['topmenu_l0iout','topmenu_l0iover']}},
                        { 'height':26,
                          'width':155,
                          'block_top':26,
                          'block_left':0,
                          'top':26,
                          'left':0,
                          'css':{ 'outer':['topmenu_l1oout','topmenu_l1oover'],
                          'inner':['topmenu_l1iout','topmenu_l1iover']}},
                        { 'block_top':0,
                          'block_left':155}]
