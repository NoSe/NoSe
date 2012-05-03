<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
 <head>

    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">

    <title>Plot example</title>
    
    <script language="javascript" type="text/javascript" src="js/flot/jquery.js"></script>
    
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.selection.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.pie.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.symbol.js"></script>
    <script language="javascript" type="text/javascript" src="js/flot/jquery.flot.threshold.js"></script>
			
	<script type='text/javascript' src='/NoSe/dwr/interface/DWRMetrics.js'></script>
  	<script type='text/javascript' src='/NoSe/dwr/engine.js'></script>

	<script type='text/javascript'>
	
	/**
	 * Function : dump()
	 * Arguments: The data - array,hash(associative array),object
	 *    The level - OPTIONAL
	 * Returns  : The textual representation of the array.
	 * This function was inspired by the print_r function of PHP.
	 * This will accept some data as the argument and return a
	 * text that will be a more readable version of the
	 * array/hash/object that is given.
	 * Docs: http://www.openjs.com/scripts/others/dump_function_php_print_r.php
	 */
	function dump(arr,level) {
		 
		var dumped_text = "";
		if(!level) level = 0;
		
		//The padding given at the beginning of the line.
		var level_padding = "";
		for(var j=0;j<level+1;j++) level_padding += "&nbsp;&nbsp;&nbsp;&nbsp;";
		
		if(typeof(arr) == 'object') { //Array/Hashes/Objects 
			for(var item in arr) {
				var value = arr[item];
				
				if(typeof(value) == 'object') { //If it is an array,
					dumped_text += level_padding + "'" + item + "' ...<br/>";
					dumped_text += dump(value,level+1);
				} else {
					dumped_text += level_padding + "'" + item + "' => \"" + value + "\"<br/>";
				}
			}
		} else { //Stings/Chars/Numbers etc.
			dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
		}
		return dumped_text;
	 }
		
	$(function () {
				
		DWRMetrics.getMetrics(0, new Date().getTime(), "device", "metrics",  {
			callback: function(list) {
				var content = "";
				for (var l in list) {
					content += "" + dump(list[l]) + "<br/>";
				}
				$('#pippo').html(content);
				// alert(list.length);
			},
			errorHandler: function(message) {
				alert("Error: " + message);
			}
		});
		
	});
	</script>
	
 </head>
    <body>
    <h1>Plot Examples</h1>

	<div id="pippo">
	</div>

 </body>
</html>
