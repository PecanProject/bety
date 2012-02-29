/*

Image Caption v1.3
(c) Arc90, Inc.

http://www.arc90.com
http://lab.arc90.com

Licensed under : Creative Commons Attribution 2.5 http://creativecommons.org/licenses/by/2.5/

*/

/* Globals */
var arc90_navigator = navigator.userAgent.toLowerCase();
var arc90_isOpera = arc90_navigator.indexOf('opera') >= 0? true: false;
var arc90_isIE = arc90_navigator.indexOf('msie') >= 0 && !arc90_isOpera? true: false;
var arc90_isSafari = arc90_navigator.indexOf('safari') >= 0 || arc90_navigator.indexOf('khtml') >= 0? true: false;

function arc90_imgcaption() {
var O = document.getElementsByTagName('P'); // For safari???
for (var i = 0, l = O.length; i < l; i++)
	O[i].appendChild(arc90_newNode('span'));

	var O = document.getElementsByTagName('IMG');
	for (i = 0, l = O.length; i < l; i++) {
		var o = O[i];
		if (o != null && o.className && o.className.indexOf('imgcaption') >= 0) {
			try {
				var f = o.className.replace(/(.*)float(l|r)(.*)/, '$2');
				var s = arc90_newNode('div', 'arc90_imcaption'+ i, 'arc90_imgcaption'+ (f.length == 1? ' float'+ f: ' floatl'));

				var I = o.cloneNode(true);
				I.className = 'arc90_imgcaptionIMG';

				s.appendChild(I);
				
				var x = arc90_newNode('p', '', 'arc90_imgcaptionTXT');
				var y = arc90_newNode('p', '', 'arc90_imgcaptionALT');
				var z = arc90_newNode('span', '', 'arc90_imgcaptionALT');

				if (o.alt != '') {
					z.innerHTML = arc90_gtlt(o.alt);
					y.appendChild(z);
					s.appendChild(y);
				}

				if (o.title != '') {
					x.innerHTML = arc90_gtlt(o.title);
					s.appendChild(x);
				}

				o.parentNode.insertBefore(s, o);
				o.parentNode.removeChild(o);

				if (document.all || arc90_isSafari) {
					var w = parseInt(I.offsetWidth);
					if (w != '')
						s.style.width = w +'px';
				} else {
					w = arc90_getStyle(I, 'width', 'width');
					if (w != '') {
						s.style.width = (parseInt(w)) + 'px';
						x.style.width = (parseInt(w)) + 'px';
						y.style.width = (parseInt(w)) + 'px';
					}
				}
			} catch (err) { o = null; }
		}
	}
var O = document.getElementsByTagName('P'); // For safari???
for (i = 0, l = O.length; i < l; i++)
	O[i].appendChild(arc90_newNode('span'));
}

function arc90_gtlt(s) {
	s = s.replace(/&gt;/g, '>');
	s = s.replace(/&lt;/g, '<');
	return s;
}

function arc90_getStyle(obj, styleIE, styleMoz) {
	if (arc90_isString(obj)) obj = document.getElementById(obj);
	if (window.getComputedStyle)
		return document.defaultView.getComputedStyle(obj, null).getPropertyValue(styleMoz);
	else if (obj.currentStyle)
		return obj.currentStyle[styleIE];
}

function arc90_findDimension(obj, pType) {
	if (arc90_isString(obj)) obj = document.getElementById(obj);
	var cur = 0;
	if(obj.offsetParent)
		while(obj.offsetParent) {
			switch(pType.toLowerCase()) {
			case "width":
				cur += obj.offsetWidth; break;
			case "height":
				cur += obj.offsetHeight; break;
			case "top":
				cur += obj.offsetTop; break;
			case "left":
				cur += obj.offsetLeft; break;
			}
			obj = obj.offsetParent;
		}
	return cur;
}

/* Events */
function arc90_isString(o) { return (typeof(o) == "string"); }

function arc90_addEvent(e, meth, func, cap) {
	if (arc90_isString(e))	e = document.getElementById(e);

	if (e.addEventListener){
		e.addEventListener(meth, func, cap);
    	return true;
	}	else if (e.attachEvent)
		return e.attachEvent("on"+ meth, func);
	return false;
}

/* Nodes */
function arc90_newNode(t, i, s, x, c) {
	var node = document.createElement(t);
	if (x != null && x != '') {
		var n = document.createTextNode(x);
		node.appendChild(n);
	}
	if (i != null && i != '')
		node.id = i;
	if (s != null && s != '')
		node.className = s;
	if (c != null && c != '')
		node.appendChild(c);
	return node;
}

/* Onload */
arc90_addEvent(window, 'load', arc90_imgcaption);
