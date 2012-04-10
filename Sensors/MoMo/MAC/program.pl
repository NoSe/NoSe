#!/usr/bin/perl 

$file = shift( @ARGV );
$id = shift( @ARGV );

if ( -e $file ) {
	($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime(time);
	$start = $hour * 60 * 60 + $minute * 60 + $second;
	print "Start program $file as ID $id...\n";
	`make tmote reinstall,$id bsl,$file > /dev/null 2> /dev/null`;
	($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime(time);
	$stop = $hour * 60 * 60 + $minute * 60 + $second;
	print "Programmed $file as ID $id in " . ( $stop - $start ) . " seconds\n\n";
}
else {
	print "Cannot program $file as $id\n\n";
}

