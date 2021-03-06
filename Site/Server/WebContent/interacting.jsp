<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<%@ page import="com.mongodb.DB" %>
<%@ page import="com.mongodb.DBCollection" %>
<%@ page import="com.mongodb.DBCursor" %>
<%@ page import="com.mongodb.DBObject" %>
<%@ page import="com.mongodb.BasicDBObject" %>
<%@ page import="com.mongodb.Mongo" %>
<%@ page import="com.mongodb.MongoException" %>
<%@ page import="java.util.Date" %>

<html>
 <head>  
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Flot Examples</title>
    <link href="layout.css" rel="stylesheet" type="text/css">
    <!--[if lte IE 8]><script language="javascript" type="text/javascript" src="../excanvas.min.js"></script><![endif]-->
    <script language="javascript" type="text/javascript" src="../jquery.js"></script>
    <script language="javascript" type="text/javascript" src="../jquery.flot.js"></script>
 </head>
    <body>
    <h1>Flot Examples</h1>

    <div id="placeholder" style="width:600px;height:300px"></div>

    <p>One of the goals of Flot is to support user interactions. Try
    pointing and clicking on the points.</p>

    <p id="hoverdata">Mouse hovers at
    (<span id="x">0</span>, <span id="y">0</span>). <span id="clickdata"></span></p>

    <p>A tooltip is easy to build with a bit of jQuery code and the
    data returned from the plot.</p>

    <p><input id="enableTooltip" type="checkbox">Enable tooltip</p>

<script type="text/javascript">
$(function () {

	/*
    var sin = [], cos = [];
    for (var i = 0; i < 14; i += 0.5) {
        sin.push([i, Math.sin(i)]);
        cos.push([i, Math.cos(i)]);
    }
    */
    
    var data = [];

<%
	Mongo mongo = new Mongo();
	DB db = mongo.getDB( "nose" );
	DBCollection collection = db.getCollection("metrics");
	DBObject query = new BasicDBObject("date", new BasicDBObject("$gt", new Date(new Date().getTime() - 10000)));
	DBCursor curs = collection.find(); // query);
	int i = 0;
	while ( curs.hasNext() ) {
		DBObject object = curs.next();
%>
		data.push([<%=i++%>, <%=object.get("value")%>]);
<%	
	}
	// mongo.close();
%>

    var plot = $.plot($("#placeholder"),
           [ { data: data, label: "metrics(x)"} ], {
               series: {
                   lines: { show: true },
                   points: { show: true }
               },
               grid: { hoverable: true, clickable: true },

               xaxis: { zoomRange: [0.1, 100], panRange: [0, 100] },
               yaxis: { zoomRange: [0.1, 100], panRange: [0, 100] },
               
               // xaxis: { zoomRange: [-1, 20], panRange: [-10, 10] },
               // yaxis: { zoomRange: [0.1, 10], panRange: [-10, 10] },
               
               zoom: {
                   interactive: true
               },
               pan: {
                   interactive: true
               }
               
             });

    function showTooltip(x, y, contents) {
        $('<div id="tooltip">' + contents + '</div>').css( {
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

    var previousPoint = null;
    $("#placeholder").bind("plothover", function (event, pos, item) {
        $("#x").text(pos.x.toFixed(2));
        $("#y").text(pos.y.toFixed(2));

        if ($("#enableTooltip:checked").length > 0) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    
                    $("#tooltip").remove();
                    var x = item.datapoint[0].toFixed(2),
                        y = item.datapoint[1].toFixed(2);
                    
                    showTooltip(item.pageX, item.pageY,
                                item.series.label + " of " + x + " = " + y);
                }
            }
            else {
                $("#tooltip").remove();
                previousPoint = null;            
            }
        }
    });

    $("#placeholder").bind("plotclick", function (event, pos, item) {
        if (item) {
            $("#clickdata").text("You clicked point " + item.dataIndex + " in " + item.series.label + ".");
            plot.highlight(item.series, item.datapoint);
        }
    });
    
    // show pan/zoom messages to illustrate events 
    $("#placeholder").bind('plotpan', function (event, plot) {
        var axes = plot.getAxes();
        alert(axes);
        /*
        $(".message").html("Panning to x: "  + axes.xaxis.min.toFixed(2)
                           + " &ndash; " + axes.xaxis.max.toFixed(2)
                           + " and y: " + axes.yaxis.min.toFixed(2)
                           + " &ndash; " + axes.yaxis.max.toFixed(2));
       	*/
    });

    $("#placeholder").bind('plotzoom', function (event, plot) {
        var axes = plot.getAxes();
        alert(axes);
        /*
        $(".message").html("Zooming to x: "  + axes.xaxis.min.toFixed(2)
                           + " &ndash; " + axes.xaxis.max.toFixed(2)
                           + " and y: " + axes.yaxis.min.toFixed(2)
                           + " &ndash; " + axes.yaxis.max.toFixed(2));
       */
    });
    
});
</script>

 </body>
</html>
