#!/bin/bash

if [ -e "$1" ]; then  
	echo "Start program $1 as ID $2"
	make tmote reinstall,$2 bsl,$1
	# > /dev/null 2> /dev/null
	echo "Programmed $1 as ID $2"
else
	echo "Port $1 absent"
fi

