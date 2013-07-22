function fullscreenmap(isfullscreen){
  isfullscreen = !isfullscreen
  if(isfullscreen){
    document.getElementById('mapcont').setAttribute('style','margin: 0px; width: 95%; height: 800px');
  } else{
    document.getElementById('mapcont').setAttribute('style','margin: 10px 100px; width: 80%; height: 600px');
  }
}

function downloaddata(){
  var sm = document.getElementById('selectmap');
  var opt = sm.options[sm.selectedIndex];
  var db = document.getElementById('downloadbutton')
  switch(opt.value){
    case 0:
      //cornstover yield county
      db.href = 'temp_models/cornstover_yield_county.csv';
    break;
    case 1:
      //miscanthus yield county
      db.href = 'temp_models/miscanthus_yield_county.csv';
    break;
    case 2:
      //switchgrass yield county
      db.href = ''
    break;
    case 3:
      //energycane yield county
    break;
    case 4:
      //least cost crop
    break;
    case 5:
      //cornstover cost county
    break;
    case 6:
      //miscanthus cost county
    break;
    case 7:
      //switchgrass cost county
    break;
    case 8:
      //energycane cost county
    break;
    case 9:
      //energycane yield(grid)
    break;
    case 10:
      //miscanthus yield(grid)
    break;
    case 11:
      //cornstover yield(grid) missing
    break;
    case 12:
      //poplar yield grid
    break;    
  }

}

function initialize() {
map = new google.maps.Map(document.getElementById('googft-mapCanvas'), {
center: new google.maps.LatLng(38.7, -88),
zoom: 6,
mapTypeId: google.maps.MapTypeId.ROADMAP
});
map.controls[google.maps.ControlPosition.RIGHT_BOTTOM].push(document.getElementById('googft-legend'));


layers = [];
layers[0] = cornstoveryield= new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 22,
templateId: 14
}
});


layers[1] = miscanthusyield = new google.maps.FusionTablesLayer({
map: map,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 23,
templateId: 15
}
});


layers[2] = switchgrassyield = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 24,
templateId: 16
}
});

layers[3] = energycaneyield = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: "col9\x3e\x3e0 \x3e\x3d 0.01"
},
options: {
styleId: 25,
templateId: 17
}
});

layers[4] = lcc = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 17,
templateId: 18
}
});


layers[5] = cornstovercost = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 18,
templateId: 19
}
});

layers[6] = miscanthuscost = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 19,
templateId: 20
}
});


layers[7] = switchgrasscost = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: ""
},
options: {
styleId: 20,
templateId: 21
}
});

layers[8] = energycanecost = new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
where: "energycane_cost > 0.0"
},
options: {
styleId: 21,
templateId: 22
}
});

var bz_sugarcane_bounds = new google.maps.LatLngBounds(
   new google.maps.LatLng(-45,-135), // south-west
   new google.maps.LatLng(65,-25) // north-east
   );

  layers[9]= bz_sugarcane =
  	 new google.maps.GroundOverlay( '../bety/images/lmodelout/energycane_yield_grid.png'
  		, bz_sugarcane_bounds, overlayOptions );
     bz_sugarcane.setMap(null);


/////////// setup of us_miscanthus map  
var us_miscanthus_bounds = new google.maps.LatLngBounds(
new google.maps.LatLng(-45,-135), // south-west
new google.maps.LatLng(65,-25) // north-east
);

layers[10] = us_miscanthus =
	 new google.maps.GroundOverlay( '../bety/images/lmodelout/miscanthus_yield_grid.png'
	 	, us_miscanthus_bounds, overlayOptions );
   us_miscanthus.setMap(null);

layers[11] = cornstovergrid =
	 new google.maps.GroundOverlay('../bety/images/lmodelout/cornstover_yield_grid.png'
	 	,us_miscanthus_bounds,overlayOptions);
 cornstovergrid.setMap(null);

layers[12] = poplaryield = new google.maps.GroundOverlay('../bety/images/lmodelout/poplar_yield_grid.png'
		,us_miscanthus_bounds,overlayOptions);
  poplaryield.setMap(null);

layers[13] = willowyield = new google.maps.GroundOverlay('../bety/images/lmodelout/willow_yield_grid.png'
		,us_miscanthus_bounds,overlayOptions);
willowyield.setMap(null);

layers[14] = switchgrassyieldgrid = new google.maps.GroundOverlay('../bety/images/lmodelout/switchgrass_yield_grid.png'
		,us_miscanthus_bounds,overlayOptions);
switchgrassyieldgrid.setMap(null);



layers[15] = switchgrassaet= new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1Fo8NF6YZGvoavrUqLcsuF3rfEH4P7fM1R74TidQ",
where: ""
},
options: {
styleId: 2,
templateId: 2
}
});

layers[16] = miscanthusaet= new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1Fo8NF6YZGvoavrUqLcsuF3rfEH4P7fM1R74TidQ",
where: ""
},
options: {
styleId: 3,
templateId: 3
}
});

layers[17] = cornstoveraet= new google.maps.FusionTablesLayer({
map: null,
heatmap: { enabled: false },
query: {
select: "col16\x3e\x3e1",
from: "1Fo8NF6YZGvoavrUqLcsuF3rfEH4P7fM1R74TidQ",
where: ""
},
options: {
styleId: 4,
templateId: 4
}
});

layers[18] = willowyield   = new google.maps.FusionTablesLayer({
  map: null,
  heatmap: { enabled: false },
  query: {
    select: "col16\x3e\x3e2",
    from: "1g4LIgl6GmDRbNLXcXumGkwUpx9FdFkUI30sldKw",
    where: ""
  },
  options: {
    styleId: 3,
    templateId: 3
  }
});

layers[19] = poplaryield =  new google.maps.FusionTablesLayer({
  map: null,
  heatmap: { enabled: false },
  query: {
    select: "col16\x3e\x3e2",
    from: "1g4LIgl6GmDRbNLXcXumGkwUpx9FdFkUI30sldKw",
    where: "col8\x3e\x3e1 \x3e\x3d 0"
  },
  options: {
    styleId: 2,
    templateId: 2
  }
});






updatemap();
}

google.maps.event.addDomListener(window, 'load', initialize);






function reset() {
  for(var i = 0; i <layers.length;i++){
    layers[i].setMap(null)
  }
}

function makeyieldlegend(legend, max){
  var colors = ['0000ff','ead1dc','ff0000'];
  for (i=0;i<colors.length;i++){

    var swatchdiv = document.createElement('div');
    var swatch = document.createElement('span');
    swatchdiv.appendChild(swatch)

    swatch.setAttribute('class','googft-legend-swatch')
    swatch.setAttribute('style',"background-color: #" + colors[i])
    var legrange = document.createElement('span');
    legrange.setAttribute('class','googft-legend-range');
    legrange.innerHTML=Math.round(max*(i)/colors.length) 
                        +" - "+
                         Math.round(max*(i+1)/colors.length)
                         + " Mg/ha";
    swatchdiv.appendChild(legrange);
    
    swatchdiv.appendChild(document.createElement('br'));
    legend.appendChild(swatchdiv)
  }
}
function makecroplegend(legend){
  var colors=['#ffffff','#f1c232','#6aa84f','#0000ff','#ff00ff']
  var crops = ['No Crop','Cornstover','Miscanthus','Switchgrass','Energycane']
  for(i = 0;i<colors.length;i++){
    var swatchdiv = document.createElement('div');
    var swatch = document.createElement('span');
    swatch.setAttribute('class','googft-legend-swatch');
    swatch.setAttribute('style','background-color: ' + colors[i]);
    var crop = document.createElement('span');
    crop.setAttribute('class','googft-legend-range');
    crop.innerHTML = crops[i];
    swatchdiv.appendChild(swatch);
    swatchdiv.appendChild(crop);

    legend.appendChild(swatchdiv);
  }
}
function makecostlegend(legend){
  var colors = ['#00ff00','#ffff00','#ff9900','#ff0000'];
  var texts = ["< 50","<100","<150",">150"]
  for(i=0;i<colors.length;i++){
    var swatchdiv = document.createElement('div');
    var swatch = document.createElement('span');
    swatch.setAttribute('class','googft-legend-swatch');
    swatch.setAttribute('style','background-color: ' + colors[i]);
    var range = document.createElement('span');
    range.setAttribute('class','googft-legend-range');
    range.innerHTML = texts[i];
    swatchdiv.appendChild(swatch);
    swatchdiv.appendChild(range);
    swatchdiv.appendChild(document.createElement('br'));

    legend.appendChild(swatchdiv);
  }
}


function updatemap() {
  select = document.getElementById('selectmap')
  reset();
  var opt = select.options[select.selectedIndex]
  layers[opt.value].setMap(map);
  document.getElementById('maptitle').innerHTML = opt.text;
  var leg = document.getElementById('googft-legend')
    leg.style.display='';
    while (leg.firstChild){
      leg.removeChild(leg.firstChild);
    }
  if (opt.value<4){
    var legendtitle = document.createElement('p');
    legendtitle.id='googft-legend-title';
    legendtitle.innerHTML=opt.text;
    leg.appendChild(legendtitle);
    var yields = ['12','34','20','46']
    makeyieldlegend(leg, yields[opt.value]);
    //make gradient legend
  }else if (opt.value == 4){
    var legendtitle = document.createElement('p');
    legendtitle.id='googft-legend-title';
    legendtitle.innerHTML=opt.text;
    leg.appendChild(legendtitle);
    makecroplegend(leg);

    //make crop legend
  } else if (opt.value<9){
    var legendtitle = document.createElement('p');
    legendtitle.id='googft-legend-title';
    legendtitle.innerHTML=opt.text;
    leg.appendChild(legendtitle);
    makecostlegend(leg);
    //make cost legend
  }else if (opt.value == 9){
    var imgdiv = document.createElement('img');
    imgdiv.setAttribute('src','../bety/images/lmodelout/energycane_yield_grid.png-legend.png')
    leg.appendChild(imgdiv);
    //make energycane legend
  } else if (opt.value == 10){
    var imgdiv = document.createElement('img');
    imgdiv.setAttribute('src','../bety/images/lmodelout/miscanthus_yield_grid.png-legend.png')
    leg.appendChild(imgdiv);
    //miscanthus legend
	} else if (opt.value == 12){
		var imgdiv = document.createElement('img');
		imgdiv.setAttribute('src','../bety/images/lmodelout/poplar_yield_grid.png-legend.png')
		leg.appendChild(imgdiv);
		//poplar
	}else if (opt.value == 13){
		var imgdiv = document.createElement('img');
    imgdiv.setAttribute('src','../bety/images/lmodelout/willow_yield_grid.png-legend.png')
    leg.appendChild(imgdiv);
    //willow
  }else if (opt.value == 14){
  	var imgdiv = document.createElement('img');
    imgdiv.setAttribute('src','../bety/images/lmodelout/switchgrass_yield_grid.png-legend.png')
    leg.appendChild(imgdiv);
	} else if (opt.value <18){
  	leg.style.display='none';
  } else if (opt.value == 18){
    var legendtitle = document.createElement('p');
    legendtitle.id='googft-legend-title';
    legendtitle.innerHTML=opt.text;
    leg.appendChild(legendtitle);
    makeyieldlegend(leg,12)
  } else if (opt.value == 19){
    var legendtitle = document.createElement('p');
    legendtitle.id='googft-legend-title';
    legendtitle.innerHTML=opt.text;
    leg.appendChild(legendtitle);
    makeyieldlegend(leg,15)
  }
  downloaddata();
}