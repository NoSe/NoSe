#!/bin/perl

$FIRST_ID = shift ( @ARGV );
$LAST_ID = shift ( @ARGV );

for ($i=$FIRST_ID; $i<$LAST_ID; $i++) {
    
    system("tos-set-symbols --objcopy msp430-objcopy --objdump msp430-objdump --target ihex build/telosb/main.ihex build/telosb/main.ihex.out-$i TOS_NODE_ID=$i ActiveMessageAddressC__addr=$i");
}
