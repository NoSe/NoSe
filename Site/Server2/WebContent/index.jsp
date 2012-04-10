<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
 <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Flot Examples</title>
    <!-- <link href="layout.css" rel="stylesheet" type="text/css">-->
    <!--[if lte IE 8]><script language="javascript" type="text/javascript" src="../excanvas.min.js"></script><![endif]-->
    <script language="javascript" type="text/javascript" src="js/flot/jquery.js"></script>
    
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.selection.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.pie.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.symbol.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.threshold.js"></script>

	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/jquery-ui.min.js" type="text/javascript"></script>
	<script src="http://jquery-ui.googlecode.com/svn/tags/latest/external/jquery.bgiframe-2.1.2.js" type="text/javascript"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.16/i18n/jquery-ui-i18n.min.js" type="text/javascript"></script>
			
 </head>
    <body>
    <h1>Flot Examples</h1>
    
    <!-- <p><input id="enableTooltip" type="checkbox">Show values</p>-->
    
    <div id="addnote" style="bgcolor:rgb(200, 200, 200);">
    	<input type="button" value="Add note" onclick="javascript: addNote();" />
    	<input type="text" id="content" />
    </div>

    <div id="selectPoints">
	    <input value="Approva" type="button" onclick="markApproved();">
	    <input value="Scarta" type="button" onclick="markDiscarded();">
	    <input value="Da validare" type="button" onclick="markToApprove();">
    </div>

    <!-- <p><input name="selection" id="zoomIn" type="radio">Zoom In</p>-->

	<div id="hover"></div>

    <div id="note">
	   	Click here and verify the note
    </div>
    
    <table>
		<tr>
			<td colspan="2">Panoramica</td>
		</tr>
		<tr>
			<td colspan="2"><div id="overview" style="margin-left:50px;margin-top:20px;width:400px;height:50px"></div></td>
		</tr>
		<tr>
			<td>Grafico</td>
			<td>Stato</td>
		</tr>
		<tr>
			<td><div id="placeholder" style="width:600px;height:300px;"></div></td>
			<td><div id="piechart" style="width:600px;height:300px;"></div></td>
		</tr>
		<tr>
			<td colspan="2">Dati pubblicati</td>
		</tr>
		<tr>
			<td style="center:true;" colspan="2"><div id="final" style="width:600px;height:300px;"></div></td>
		</tr>
    </table>
    
<script type="text/javascript">

//$.extend(true, {}, options, {
//    xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }
//}));

var maxY = 0;

var minY = 0;

var notes = new Array();

var currentNote = null;

var plot = null;

var selectedPoints = new Array();

var previousPoint = null;

// Main dataset
var d = generateData();
var dataApproved;
var serieApproved;

function markAs(type) {
	
	if ( currentNote == null ) {
		alert("Seleziona un'area del grafico prima");
		return;
	}

	selectRangeDatapoints(currentNote['min'], currentNote['max']);
		
    for ( key in selectedPoints ) {
    	var value = selectedPoints[key];
    	var datapoint = d[value['index']];
    	datapoint[2] = type;
    }
    
    selectedPoints = [];

	refreshPlot();

}

function markApproved() {
	markAs(0);
}

function markDiscarded() {
	markAs(1);
}

function markToApprove() {
	markAs(2);
}

function generateData() {
	var d = [];
    var date = new Date(2011, 1, 1, 0, 0, 0, 0);
    var now = new Date();
    var value = 100;
    for (; date.getTime() < now.getTime(); ) {
    	date = new Date(date.getTime() + 1000 * 60 * 60 * 24 * 7);
    	d.push([ date.getTime(), value, (Math.random() * 2).toFixed(0) ]);
        value = value + Math.random() * 10 - 5;
        if (value < -500)
        	value = -500;
        if (value > 500)
        	value = 500;
    }
    return d;
}

function refreshPlot() {

	currentNote = null;

	createPlot();

	$("#selectPoints").hide('blind', {}, 500);

	$("#addnote").hide('blind', {}, 500);

}

function addNote() {
	
	if ( currentNote == null ) {
		alert("Seleziona un'area del grafico prima");
		return;
	}

	var content = $( "#content" ).val();
	currentNote['label'] = content;
	notes.push(currentNote);
	
	refreshPlot();
	
}

// Helper for returning the weekends in a period
function weekendAreas(axes) {
    var markings = [];
    var d = new Date(axes.xaxis.min);
    // go to the first Saturday
    d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 1) % 7))
    d.setUTCSeconds(0);
    d.setUTCMinutes(0);
    d.setUTCHours(0);
    var i = d.getTime();
    do {
        // when we don't set yaxis, the rectangle automatically
        // extends to infinity upwards and downwards
        markings.push({ xaxis: { from: i, to: i + 2 * 24 * 60 * 60 * 1000 } });
        i += 7 * 24 * 60 * 60 * 1000;
    } while (i < axes.xaxis.max);
    
    // setup background areas
	for ( var i = 0; i < notes.length; i ++ ) {
		markings.push({ color: '#000', lineWidth: 1, xaxis: { from: notes[i]['min'], to: notes[i]['min'] } });
		markings.push({ color: '#000', lineWidth: 1, xaxis: { from: notes[i]['max'], to: notes[i]['max'] } });
		markings.push({ color: 'rgb(200, 200, 200)', lineWidth: 1, xaxis: { from: notes[i]['min'], to: notes[i]['max'] } });
	}

    return markings;
}

function prepareData() {

	dataApproved = [];

	for ( var i = 0; i < d.length; i ++ ) {
		if ( d[i][2] == 0 ) {
			dataApproved.push([ d[i][0], d[i][1], "circle", "rgb(0, 200, 0)" ]);
		}
		if ( d[i][2] == 1 ) {
			dataApproved.push([ d[i][0], d[i][1], function (ctx, x, y, radius, shadow) {
	            // pi * r^2 = (2s)^2  =>  s = r * sqrt(pi)/2
	            var size = radius * Math.sqrt(Math.PI) / 2;
	            ctx.rect(x - size, y - size, size + size, size + size);
	        }, "rgb(200, 0, 0)" ]);
		}
		if ( d[i][2] == 2 ) {
			dataApproved.push([ d[i][0], d[i][1], function (ctx, x, y, radius, shadow) {
	            // pi * r^2 = 2s^2  =>  s = r * sqrt(pi/2)
	            var size = radius * Math.sqrt(Math.PI / 2);
	            ctx.moveTo(x - size, y);
	            ctx.lineTo(x, y - size);
	            ctx.lineTo(x + size, y);
	            ctx.lineTo(x, y + size);
	            ctx.lineTo(x - size, y);
	        }, "rgb(20, 20, 30)" ]);
		}
	}

	serieApproved = {
	   	data: dataApproved, 
	   	label: "Pressure",
	   	color: "rgb(50, 50, 50)",
	    // threshold: { below: 500, color: "rgb(200, 20, 30)" },
	   	points: { show: true /*, symbol: "circle"*/ },
	    lines: { show: true },
	    pointsize: 4
	};

	// symbol: "square"
	// symbol: "diamond" } },
	// symbol: "triangle" } },
	// symbol: "cross"

	//Dataset
	data = [ serieApproved ];

}

function createPlot(range) {

	prepareData();
	
	var xaxis = {
		mode: "time", 
		tickLength: 5
	};
	
	if ( range != null ) {
		xaxis['min'] = range.from;
		xaxis['max'] = range.to;
	}
		
    var options = {
    		
   		// lines: { show: true },
   		
   		points: { 
   			show: true, 
   			radius: 3,
   		},
   		        
   		xaxis: xaxis,

   		selection: { mode: "x" },
   		grid: { 
           	hoverable: true,
           	clickable: true,
   			markings: weekendAreas 
   		}
   		
   	};

    // plot it
    plot = $.plot($("#placeholder"), data, options);
    
    for ( var i = 0; i < d.length; i ++ ) {
    	if ( i == 0 ) {
    		maxY = d[i][1];
    		minY = d[i][1];
    	}
    	else {
    		if (maxY < d[i][1]) {
    			maxY = d[i][1];
    		}
    		if (minY > d[i][1]) {
    			minY = d[i][1];
    		}
    	}
    }
    
    // Add labels for notes
	for ( var i = 0; i < notes.length; i ++ ) {
        var offset = plot.pointOffset({ x: notes[i]['min'], y: maxY});
        $("#placeholder").append('<div style="position:absolute;left:' + (offset.left + 4) + 'px;top:' + offset.top + 'px;color:rgb(0, 0, 0);font-size:smaller"><a href="javascript: show(' + i + ');">Note</a></div>');
	}
    
    // draw a little arrow on top of the last label to demonstrate
    // canvas drawing
    /*
    var ctx = plot.getCanvas().getContext("2d");
    ctx.beginPath();
    o.left += 4;
    ctx.moveTo(o.left, o.top);
    ctx.lineTo(o.left, o.top - 10);
    ctx.lineTo(o.left + 10, o.top - 5);
    ctx.lineTo(o.left, o.top);
    ctx.fillStyle = "#000";
    ctx.fill();
    */
    
    
    for ( key in selectedPoints ) {
    	var value = selectedPoints[key];
    	var datapoint = d[value['index']];
    	plot.highlight(plot.getData()[0], datapoint);
    }
    
    plotPie();
    
    plotFinal();
	
}

function pieHover(event, pos, obj) 
{
	if (!obj)
		return;
	percent = parseFloat(obj.series.percent).toFixed(2);
	$("#hover").html('<span style="font-weight: bold; color: '+obj.series.color+'">'+obj.series.label+' ('+percent+'%)</span>');
}

function plotPie() {
	
	var approved = 0;
	var discarded = 0;
	var toapprove = 0;
	
	for ( var i = 0; i < d.length; i ++ ) {
		if ( d[i][2] == 0 ) {
			approved ++;
		}
		if ( d[i][2] == 1 ) {
			discarded ++;
		}
		if ( d[i][2] == 2 ) {
			toapprove ++;
		}
	}
	
	var piedata = [];
	
	piedata.push({ label: "Approvati", data: approved, color: "rgb(0, 200, 0)" });
	piedata.push({ label: "Scartati", data: discarded, color: "rgb(200, 0, 0)" });
	piedata.push({ label: "Da approvare", data: toapprove, color: "rgb(20, 20, 30)" });
	
	$.plot($("#piechart"), piedata,
	{
        series: {
            pie: { 
                show: true
            }
        },
        grid: {
            // clickable: true,
            hoverable: true
        }
	});
	$("#piechart").bind("plothover", pieHover);
	// $("#piechart").bind("plotclick", pieClick);
}

function plotFinal() {
	
	var dataFinal = [];

	for ( var i = 0; i < d.length; i ++ ) {
		if ( d[i][2] == 0 ) {
			dataFinal.push([ d[i][0], d[i][1] ]);
		}
	}

	var serieFinal = {
	   	data: dataFinal, 
	   	label: "Pressure",
	   	color: "rgb(50, 50, 50)",
	   	points: { show: true, symbol: "circle" },
	    lines: { show: true },
	    pointsize: 2
	};

	//Dataset
	var finalPlot = [ serieFinal ];
	
	var xaxis = {
		mode: "time", 
		tickLength: 5
	};
					
	var options = {
   		points: { 
   			show: true, 
   			radius: 3,
   		},
   		xaxis: xaxis,
   		selection: { mode: "x" },
   		grid: { 
           	hoverable: true
   		}
   	};

    $.plot($("#final"), finalPlot, options);
	    
}

function togglePlot(series, dataIndex, datapoint) {
	var key = series.label + "-" + dataIndex;
	if ( selectedPoints[key] == null ) {
		selectedPoints[key] = { 
			// series: series,
			// datapoint: datapoint,
			index: dataIndex
		};
        plot.highlight(series, datapoint);
	}
	else {
		delete selectedPoints[key];
        plot.unhighlight(series, datapoint);
	}
}

function selectRangeDatapoints(min, max) {
	var series = plot.getData()[0];
	for ( var i = 0; i < dataApproved.length; i ++ ) {
		var datapoint = dataApproved[i];
		if ( datapoint[0] >= min && datapoint[0] <= max ) {
			togglePlot(series, i, datapoint);
		}
	}
}

function formatDate(d, fmt, monthNames) {
	
    var leftPad = function(n) {
        n = "" + n;
        return n.length == 1 ? "0" + n : n;
    };
    
    var r = [];
    var escape = false, padNext = false;
    var hours = d.getUTCHours();
    var isAM = hours < 12;
    if (monthNames == null)
        monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    if (fmt.search(/%p|%P/) != -1) {
        if (hours > 12) {
            hours = hours - 12;
        } else if (hours == 0) {
            hours = 12;
        }
    }
    for (var i = 0; i < fmt.length; ++i) {
        var c = fmt.charAt(i);
        
        if (escape) {
            switch (c) {
            case 'h': c = "" + hours; break;
            case 'H': c = leftPad(hours); break;
            case 'M': c = leftPad(d.getUTCMinutes()); break;
            case 'S': c = leftPad(d.getUTCSeconds()); break;
            case 'd': c = "" + d.getUTCDate(); break;
            case 'm': c = "" + (d.getUTCMonth() + 1); break;
            case 'y': c = "" + d.getUTCFullYear(); break;
            case 'b': c = "" + monthNames[d.getUTCMonth()]; break;
            case 'p': c = (isAM) ? ("" + "am") : ("" + "pm"); break;
            case 'P': c = (isAM) ? ("" + "AM") : ("" + "PM"); break;
            case '0': c = ""; padNext = true; break;
            }
            if (c && padNext) {
                c = leftPad(c);
                padNext = false;
            }
            r.push(c);
            if (!padNext)
                escape = false;
        }
        else {
            if (c == "%")
                escape = true;
            else
                r.push(c);
        }
    }
    return r.join("");
}

/* Show tooltip */
function showTooltip(name, x, y, contents) {
			
    $('<div id="' + name + '">' + contents + '</div>').css( {
        position: 'absolute',
        display: 'none',
        top: y + 5,
        left: x + 5,
        border: '1px solid #fdd',
        padding: '2px',
        'background-color': '#fee',
        opacity: 0.80
    }).appendTo("body").fadeIn(200);
}

function dump(arr,level) {
	var dumped_text = "";
	if(!level) level = 0;
	
	//The padding given at the beginning of the line.
	var level_padding = "";
	for(var j=0;j<level+1;j++) level_padding += "    ";
	
	if(typeof(arr) == 'object') { //Array/Hashes/Objects 
		for(var item in arr) {
			var value = arr[item];
			
			if(typeof(value) == 'object') { //If it is an array,
				dumped_text += level_padding + "'" + item + "' ...\n";
				dumped_text += dump(value,level+1);
			} else {
				dumped_text += level_padding + "'" + item + "' => \"" + value + "\"\n";
			}
		}
	} else { //Stings/Chars/Numbers etc.
		dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
	}
	return dumped_text;
}

function show(index) {

	// most effect types need no options passed by default
	var options = {};
	
	// run the effect
	$( "#note" ).show( 'blind', options, 500 );
	
	var content = notes[index]['label'];
		
	$( "#note" ).text(content);
	
}

$(function () {

	$("#note").hide();
	
	$("#addnote").hide();
		
	$("#selectPoints").hide();
	
	/*
	notes.push({
		min: 1198710000000,
		max: 1202252400000,
		label: 'First note kasjd lakjdòla jsòdlja òkdjaòs jaòsjòlaskjò laksjdfklajsdk'
	});

	notes.push({
		min: 1202252400000,
		max: (1202252400000 + 885600000),
		label: 'alskdj wur lwe lakjflksd fljkshlkfhskdjlh jkshd sahdfljk sjkshsjkhdfsdklfh'
	});
	*/
        
    // Create plot
    createPlot();
    
    /*
    {
    	series: {
            lines: { show: true },
            points: { show: true }
        },
        // bars: { show: true, barWidth: 0.5, fill: 0.9 },
        xaxis: { ticks: [], autoscaleMargin: 0.02 },
        yaxis: { min: -200, max: 6000 },
        grid: {
        }
    }
    */
    
    var overview = $.plot($("#overview"), [ dataApproved ], {
        series: {
            lines: { show: true, lineWidth: 1 },
            shadowSize: 0
        },
        xaxis: { ticks: [], mode: "time" },
        yaxis: { ticks: [], autoscaleMargin: 0.1 },
        selection: { mode: "x" }
    });

    $("#placeholder").bind("plotselected", function (event, ranges) {
    	
    	currentNote = new Object();
    	currentNote['min'] = ranges.xaxis.from; 
    	currentNote['max'] = ranges.xaxis.to; 
    	
    	$("#addnote").show('blind', {}, 500);

    	$("#selectPoints").show('blind', {}, 500);

    	/*
        if ($("#zoomIn:checked").length > 0) {
        	
        	// Re-create plot
        	createPlot(ranges.xaxis);
            
            // don't fire event on the overview to prevent eternal loop
            overview.setSelection(ranges, true);
            
            return;
        }
    	*/
                
    });
    
    $("#overview").bind("plotselected", function (event, ranges) {
    	
    	createPlot(ranges.xaxis);

        // plot.setSelection(ranges);
        
    });
        
    $("#placeholder").bind("plothover", function (event, pos, item) {
    	
        $("#x").text(pos.x.toFixed(2));
        $("#y").text(pos.y.toFixed(2));

       if (item) {
           if (previousPoint != item.dataIndex) {
               previousPoint = item.dataIndex;
               
               $("#tooltip").remove();
               var x = item.datapoint[0].toFixed(2),
                   y = item.datapoint[1].toFixed(2);

       		var date = new Date(item.datapoint[0]);
       		
       		var type = d[item.dataIndex][2];

       		if ( type == 0 ) {
       			type = "APPROVATO";
       		}
			else if ( type == 1 ) {
       			type = "ELIMINATO";
       		}
       		else if ( type == 2 ) {
       			type = "DA APPROVARE";
       		}

       		var content = item.series.label + "(" + type + ") of " + formatDate(date, "%d/%m/%y - %H:%M:%S") + " = " + y;

               showTooltip('tooltip', item.pageX, item.pageY, content);
           }
       }
       else {
           $("#tooltip").remove();
           previousPoint = null;            
       }
    });

    $("#final").bind("plothover", function (event, pos, item) {
    	
        $("#x").text(pos.x.toFixed(2));
        $("#y").text(pos.y.toFixed(2));

        if (item) {
            if (previousPoint != item.dataIndex) {
                previousPoint = item.dataIndex;
                
                $("#tooltipfinal").remove();
                var x = item.datapoint[0].toFixed(2),
                    y = item.datapoint[1].toFixed(2);

        		var date = new Date(item.datapoint[0]);
        		
        		var type = "APPROVATO";

        		var content = item.series.label + "(" + type + ") of " + formatDate(date, "%d/%m/%y - %H:%M:%S") + " = " + y;

                showTooltip('tooltipfinal', item.pageX, item.pageY, content);
            }
        }
        else {
            $("#tooltipfinal").remove();
            previousPoint = null;            
        }
    });

    /*
    $("#placeholder").bind("plotclick", function (event, pos, item) {
        if (item) {
        	var series = item.series.originSeries; 
        	togglePlot(series, item.dataIndex, item.datapoint);
        }
    });
    */
    
});
</script>

 </body>
</html>
