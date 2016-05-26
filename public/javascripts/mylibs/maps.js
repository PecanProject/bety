function fullscreenmap(isfullscreen) {
    isfullscreen = !isfullscreen
    if(isfullscreen) {
        document.getElementById('mapcont').setAttribute('style', 'margin: 0px; width: 95%; height: 800px');
    } else{
        document.getElementById('mapcont').setAttribute('style', 'margin: 10px 100px; width: 80%; height: 600px');
    }
}

function downloaddata() {
    var sm = document.getElementById('selectmap');
    var opt = sm.options[sm.selectedIndex];
    var db = document.getElementById('downloadbutton');

    // There is no download button if the user is not logged in:
    if (db == null) return;

    switch(parseInt(opt.value)) {
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
        db.href = 'temp_models/switchgrass_yield_county.csv'
        break;
    case 3:
        //energycane yield county
        db.href = 'temp_models/energycane_yield_county.csv';
        break;
    case 4:
        //least cost crop
        db.href = 'temp_models/least_cost_crop_county.csv';
        break;
    case 5:
        //cornstover cost county
        db.href = 'temp_models/cornstover_cost_county.csv';
        break;
    case 6:
        //miscanthus cost county
        db.href = 'temp_models/miscanthus_cost_county.csv';
        break;
    case 7:
        //switchgrass cost county
        db.href = 'temp_models/switchgrass_cost_county.csv';
        break;
    case 8:
        //energycane cost county
        db.href = 'temp_models/energycane_cost_county.csv';
        break;
    case 9:
        //energycane yield(grid)
        db.href = 'temp_models/energycane_yield_grid.csv';
        break;
    case 10:
        //miscanthus yield(grid)
        db.href = 'temp_models/miscanthus_yield_grid.csv';
        break;
    case 11:
        //cornstover yield(grid) missing
        db.href = "";
        break;
    case 12:
        //poplar yield grid
        db.href = 'temp_models/poplar_yield_grid.csv';
        break;
    case 13:
        //willow yield grid
        db.href = 'images/lmodelout/willow_yield_grid.csv';
        break;
    case 14:
        //switchgrass yield grid
        db.href = 'temp_models/switchgrass_yield_grid.csv';
        break;
    case 15:
        //switchgrass evapotranspiration grid (no county data file)
        db.href = 'temp_models/switchgrass_evapotranspiration_grid.csv';
        break;
    case 16:
        //miscanthus evapotranspiration county
        db.href = 'temp_models/miscanthus_evapotranspiration_county.csv';
        break;
    case 17:
        //cornstover evapotranspiration grid
        db.href = 'temp_models/cornstover_evapotranspiration_grid.csv';
        break;
    case 18:
        //willow yield county
        db.href = 'images/lmodelout/willow_yield_county.csv';
        break;
    case 19:
        //poplar yield county
        db.href = 'images/lmodelout/poplar_yield_county.csv';
        break;
    default:
        db.href = "";
        console.log("Unexpected option value in downloaddata function");
        break;
    }

    var download_button = jQuery('#downloadbutton');
    if (db.href == "") {
        download_button.hide();
    }
    else {
        download_button.show();
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
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col6\x3e\x3e0 \x3e\x3d 1 and col6\x3e\x3e0 \x3c\x3d 12"
        },
        options: {
            styleId: 2,
            templateId: 2
        }
    });


    layers[1] = miscanthusyield = new google.maps.FusionTablesLayer({
        map: map,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col7\x3e\x3e0 \x3e\x3d 1 and col7\x3e\x3e0 \x3c\x3d 40"
        },
        options: {
            styleId: 3,
            templateId: 3
        }
    });


    layers[2] = switchgrassyield = new google.maps.FusionTablesLayer({
        map: null,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col8\x3e\x3e0 \x3e\x3d 1 and col8\x3e\x3e0 \x3c\x3d 20"
        },
        options: {
            styleId: 4,
            templateId: 4
        }
    });

    layers[3] = energycaneyield = new google.maps.FusionTablesLayer({
        map: null,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col9\x3e\x3e0 \x3e\x3d 1 and col9\x3e\x3e0 \x3c\x3d 50"
        },
        options: {
            styleId: 5,
            templateId: 5
        }
    });

    // layers[4]    Least Cost Crop --- NO LONGER USED

    layers[5] = cornstovercost = new google.maps.FusionTablesLayer({
        map: null,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col6\x3e\x3e0 \x3e\x3d 1 and col6\x3e\x3e0 \x3c\x3d 12 and col10\x3e\x3e0 \x3e\x3d 1 and col10\x3e\x3e0 \x3c\x3d 500"
        },
        options: {
            styleId: 6,
            templateId: 6
        }
    });

    layers[6] = miscanthuscost = new google.maps.FusionTablesLayer({
        map: null,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col11\x3e\x3e0 \x3e\x3d 1 and col11\x3e\x3e0 \x3c\x3d 200"
        },
        options: {
            styleId: 7,
            templateId: 7
        }
    });


    layers[7] = switchgrasscost = new google.maps.FusionTablesLayer({
        map: null,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col8\x3e\x3e0 \x3e\x3d 1 and col8\x3e\x3e0 \x3c\x3d 50 and col12\x3e\x3e0 \x3e\x3d 1 and col12\x3e\x3e0 \x3c\x3d 200"
        },
        options: {
            styleId: 8,
            templateId: 8
        }
    });

    layers[8] = energycanecost = new google.maps.FusionTablesLayer({
        map: null,
        heatmap: { enabled: false },
        query: {
            select: "col16\x3e\x3e1",
            from: "1DAaufoEP405M_MNXAJuLxT-NqSvqQQRf30TRcXs",
            where: "col13\x3e\x3e0 \x3e\x3d 1 and col13\x3e\x3e0 \x3c\x3d 200" // "energycane_cost > 0.0"
        },
        options: {
            styleId: 9,
            templateId: 9
        }
    });

    var bz_sugarcane_bounds = new google.maps.LatLngBounds(
        new google.maps.LatLng(-45, -135), // south-west
        new google.maps.LatLng(65, -25) // north-east
    );

    layers[9]= bz_sugarcane =
        new google.maps.GroundOverlay( 'images/lmodelout/energycane_yield_grid.png',
                                       bz_sugarcane_bounds, overlayOptions );
    bz_sugarcane.setMap(null);


    /////////// setup of us_miscanthus map  
    var us_miscanthus_bounds = new google.maps.LatLngBounds(
        new google.maps.LatLng(-45, -135), // south-west
        new google.maps.LatLng(65, -25) // north-east
    );

    layers[10] = us_miscanthus =
        new google.maps.GroundOverlay( 'images/lmodelout/miscanthus_yield_grid.png',
                                       us_miscanthus_bounds, overlayOptions );
    us_miscanthus.setMap(null);

    layers[11] = cornstovergrid =
        new google.maps.GroundOverlay('images/lmodelout/cornstover_yield_grid.png',
                                      us_miscanthus_bounds, overlayOptions);
    cornstovergrid.setMap(null);

    layers[12] = poplaryield = new google.maps.GroundOverlay('images/lmodelout/poplar_yield_grid.png',
                                                             us_miscanthus_bounds, overlayOptions);
    poplaryield.setMap(null);

    layers[13] = willowyield = new google.maps.GroundOverlay('images/lmodelout/willow_yield_grid.png',
                                                             us_miscanthus_bounds, overlayOptions);
    willowyield.setMap(null);

    layers[14] = switchgrassyieldgrid = new google.maps.GroundOverlay('images/lmodelout/switchgrass_yield_grid.png',
                                                                      us_miscanthus_bounds, overlayOptions);
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
            templateId: 2
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
            templateId: 2
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
    for(var i = 0; i < layers.length; i++) {
        if (layers[i] == null) {
            continue;
        }
        layers[i].setMap(null)
    }
}

function makeyieldlegend(legend, max) {
    
    var legendParameters = [
        { "color": "ff9900", "maximum": 5 },
        { "color": "ffff00", "maximum": 10 },
        { "color": "00ffff", "maximum": 15 },
        { "color": "0000ff", "maximum": 20 },
        { "color": "9900ff", "maximum": 30 },
        { "color": "ff00ff", "maximum": 50 },
        { "color": "00ff00", "maximum": 75 },
        { "color": "ff0000", "maximum": 100 }
    ];

    for (i=0;
         i < legendParameters.length && (i == 0 || legendParameters[i - 1]["maximum"] < max);
         i++) {

        var swatchdiv = document.createElement('div');
        var swatch = document.createElement('span');
        swatchdiv.appendChild(swatch)

        swatch.setAttribute('class', 'googft-legend-swatch')
        swatch.setAttribute('style', "background-color: #" + legendParameters[i]["color"])
        var legrange = document.createElement('span');
        legrange.setAttribute('class', 'googft-legend-range');
        legrange.innerHTML = (i == 0 ? "0" : legendParameters[i - 1]["maximum"]) +
            " to " + legendParameters[i]["maximum"] + " Mg/ha/yr";
        swatchdiv.appendChild(legrange);
        
        swatchdiv.appendChild(document.createElement('br'));
        legend.appendChild(swatchdiv)
    }
}
function makecroplegend(legend) {
    var colors=['#ffffff', '#00ff00', '#ffff00', '#ff9900', '#ff0000']
    var crops = ['No Crop', 'Cornstover', 'Miscanthus', 'Switchgrass', 'Energycane']
    for(i = 0; i < colors.length; i++) {
        var swatchdiv = document.createElement('div');
        var swatch = document.createElement('span');
        swatch.setAttribute('class', 'googft-legend-swatch');
        swatch.setAttribute('style', 'background-color: ' + colors[i]);
        var crop = document.createElement('span');
        crop.setAttribute('class', 'googft-legend-range');
        crop.innerHTML = crops[i];
        swatchdiv.appendChild(swatch);
        swatchdiv.appendChild(crop);

        legend.appendChild(swatchdiv);
    }
}
function makecostlegend(legend) {
    var legendParameters = [
        { "color": "ffffff", "maximum": 25 },
        { "color": "d9ead3", "maximum": 50 },
        { "color": "b6d7a8", "maximum": 75 },
        { "color": "93c47d", "maximum": 100 },
        { "color": "6aa84f", "maximum": 125 },
        { "color": "38761d", "maximum": 150 },
        { "color": "274e13", "maximum": 175 },
        { "color": "000000", "maximum": 200 }
    ];

    for (i=0; i < legendParameters.length; i++) {
        var swatchdiv = document.createElement('div');
        var swatch = document.createElement('span');
        swatch.setAttribute('class', 'googft-legend-swatch');
        swatch.setAttribute('style', 'background-color: #' + legendParameters[i]["color"]);
        var range = document.createElement('span');
        range.setAttribute('class', 'googft-legend-range');
        range.innerHTML = (i == 0 ? "0" : legendParameters[i - 1]["maximum"]) +
            " to " + legendParameters[i]["maximum"] + " $/ha";
        swatchdiv.appendChild(swatch);
        swatchdiv.appendChild(range);
        swatchdiv.appendChild(document.createElement('br'));

        legend.appendChild(swatchdiv);
    }
}
function makeaetlegend(legend) {
    var colors = ['#ff0000', '#ffff00', '#ffffff', '#00ff00', '#0000ff'];
    var texts = ["250", "440", "625", "812", "1000"];
    for (i = 0; i < colors.length; i++) {
        var swatchdiv = document.createElement('div');
        var swatch = document.createElement('span');
        swatch.setAttribute('class', 'googft-legend-swatch');
        swatch.setAttribute('style', 'background-color: ' + colors[i]);
        var range = document.createElement('span');
        range.setAttribute('class', 'googft-legend-range');
        range.innerHTML = texts[i] + ' mm/yr';
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
    while (leg.firstChild) {
        leg.removeChild(leg.firstChild);
    }
    if (opt.value < 4) {
        var legendtitle = document.createElement('p');
        legendtitle.id='googft-legend-title';
        legendtitle.innerHTML=opt.text;
        leg.appendChild(legendtitle);
        var yields = [11.75, 34, 19.8, 45.67 ] // maximum yield value in layers 0 - 3
        makeyieldlegend(leg, yields[opt.value]);
        //make gradient legend
    } else if (opt.value == 4) {
        var legendtitle = document.createElement('p');
        legendtitle.id='googft-legend-title';
        legendtitle.innerHTML=opt.text;
        leg.appendChild(legendtitle);
        makecroplegend(leg);

        //make crop legend
    } else if (opt.value < 9) {
        var legendtitle = document.createElement('p');
        legendtitle.id='googft-legend-title';
        legendtitle.innerHTML=opt.text;
        leg.appendChild(legendtitle);
        makecostlegend(leg);
        //make cost legend
    } else if (opt.value == 9) {
        var imgdiv = document.createElement('img');
        imgdiv.setAttribute('src', 'images/lmodelout/energycane_yield_grid.png-legend.png')
        leg.appendChild(imgdiv);
        //make energycane legend
    } else if (opt.value == 10) {
        var imgdiv = document.createElement('img');
        imgdiv.setAttribute('src', 'images/lmodelout/miscanthus_yield_grid.png-legend.png')
        leg.appendChild(imgdiv);
        //miscanthus legend
    } else if (opt.value == 12) {
        var imgdiv = document.createElement('img');
        imgdiv.setAttribute('src', 'images/lmodelout/poplar_yield_grid.png-legend.png')
        leg.appendChild(imgdiv);
        //poplar
    } else if (opt.value == 13) {
        var imgdiv = document.createElement('img');
        imgdiv.setAttribute('src', 'images/lmodelout/willow_yield_grid.png-legend.png')
        leg.appendChild(imgdiv);
        //willow
    } else if (opt.value == 14) {
        var imgdiv = document.createElement('img');
        imgdiv.setAttribute('src', 'images/lmodelout/switchgrass_yield_grid.png-legend.png')
        leg.appendChild(imgdiv);
    } else {
        makeaetlegend(leg);
    }
    downloaddata();
}
