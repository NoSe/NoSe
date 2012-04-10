========================================================================
README:  MoMo (Monumental Monitoring) Application
Created: 1-September-2009
Author:  Michele Nati (michele.nati@gmail.com)
Requirements: TinyOS-2.0.1 - JAVA 1.4 or higher
========================================================================

This README is intended to give an overview of the organizational
structure of the MoMo (Monumental Monitoring) application as well as 
how to best utilize and customize some of the features it contains.  
This document is divided into three sections. The first section 
contains an overview of how the application is organized and what it 
is capable of doing. The second section gives instructions on how to 
install the application and interact with it from your PC. The third
section demonstrates how to customize the application to meet your 
particular needs.

------------------------------------------------------------------------
Organizational Structure and Overview
------------------------------------------------------------------------

The MoMo application is actually made up of three separate mini 
applications: one mote base station application (Sink), one mote sampling 
application (Collector), and one java based application used to interact 
with the mote applications (for sending commands to the Sink and collecting 
the received data packets). The code for all the three applications is 
divided up among several directories:

Monumental Monitoring (MoMo)
./Sink				-> TOS Application for the Sink node
./Collector			-> TOS Application for the Collector nodes
./java				-> JAVA Application mentioned above
./Collector/sampleLog		-> Storage (Flash) and Data Acquisition 
				   (Sensors) tools implementation

Protocol Stack
./include			-> Common definitions
./interfaces			-> Common interfaces
./MAC				-> MAC Layer implementation
./LL				-> Link Layer implementation
./Queue				-> FIFO queue (between Link Layer and MAC) 
				   implementation
./Multiplexer,Arbiter		-> Radio Arbitration code

Additional Tools
./Application/TestBed		-> TOS Application for MoMo indoor testbed
./Prober			-> JAVA Application for capturing packets 
				   exchanges among network nodes

Documentation
./docs

The code specific to the base station (Sink node) application is contained 
under the 'Sink' directory, and code for the sampling application
(Collector node) is found under 'Collector'.  Code shared between them is 
found in the directories listed under the Protocol Stack implementation 
components. Code for the java application is found in the 'java' directory.

Following a brief description of the protocol. When a new Collector node
is turned on in the network, it starts a JOIN procedure for discovering its 
Sink node. The Sink node is selected based on some customizable parameters.
When a new Collector node joins a given Sink node, a configuration 
procedure is started by the Sink. This procedure permits to configure the 
behaviour of the node just added.

What sensors are sampled, the periodicity of sampling, and the sink 
interval for collecting metrics from the Collector nodes, they are all 
configurable options that can easily be set by the user at compile time 
or sent to the sink at execution time by means of the java application.

The Sink node is always awake. Conversely, two working modes 
are provided for the Collector node.
1) Real-time: the node follows a given duty cycle using the low power 
listening communication (LPL). When a communication between the Sink and 
the Collector node is required, the Sink node sends out a sequence of 
preambles for waking up the target node (or all the nodes in case of 
broadcast transmissions).
2) Periodic: the Collector node always sleeps unless when a communication 
with the Sink node occurs. When the Sink node needs to communicate with the 
given Collector node, a flag in the ACK packets sent from the Sink to the 
target node is set to 1. With this flag activate, at the end of each 
transmission, the Collector node remains awake and waits for a packet from 
the Sink.

The working mode and the duty cycle of the Collector nodes may also be 
configured by the Sink node.

The Collector application periodically takes some sensor readings, logs 
them to flash, and waits for a given interval, at the end of which it sends 
out to the Sink over the radio all the collected readings. Whenever the 
Sink node receives any packet from the Collector application, it forwards 
these packets back to the java application for further processing.

This application is robust in the sense that a reliable MAC protocol is 
implemented for the exchange of data. Each data transmission is confirmed 
by an explicit SW acknowledgement.

------------------------------------------------------------------------
Installation Instructions and Running the Applications
------------------------------------------------------------------------

The default configuration of the Sink/Collector application has been 
designed to compile and run on any platform that supports 
LowPowerListening and has a LogStorage component defined for its 
external flash (i.e. telos, mica2, micaz, eyesIFX, etc.).  For purposes
of illustration the instructions below are given for installation on the
telosb platform, but could be applicable (with very few modifications) 
to other platforms as well.

First of all, you need to unpack the source files in the tinyos-2.x root 
of your development environment.

To run the Sink application with its default configuration 
do the following:

1) Install the Sink application on a mote and connect it to your
PC via whatever serial interface you normally use to communicate with it.
IMPORTANT: the base station mote must be installed with address you choose
for the sink when you program the collector nodes.

cd MoMo/Sink
./program.sh USB-serial-device TOS_NODE_ID

2) Install the Collector application on a mote.  You can install this 
application on any number of motes, remembering to change the TOS_NODE_ID
of each installation instance. The address values assigned to each node 
should be greater than the number of nodes in the network (i.e. if you are 
planning to use ten (10) nodes then the address set considered should be 
start from 11). In the following example we are considering 3 nodes, then 
the assigned addresses should be the followings.

cd MoMo/Collector
./program.sh USB-serial-device 4
./program.sh USB-serial-device 5
./program.sh USB-serial-device 6

In order to permit future extensions of the network size, the assigned 
addresses may start from a greater value. For instance, using a starting 
value equal to 127, you should build a network of 128 nodes.

When a new node joins a given sink, a new address is assigned to it (and 
equal to the number of nodes already joined that sink plus 1). The address 
initially assigned to the node is used as node unique ID.

3) Compile and run the java application.  

cd java
java SinkCollector USB-serial-device


The purpose of the java application is twofold:
- collecting and displaying packets sent to the sink
- reprogramming the network nodes with the parameters required by the user.

While the java application is running its listening part is always able
to receive packets.

After starting the java application you will be presented with a 
prompt that looks like:

Enter 'p' to program nodes:
>>

Just type 'p' and hit enter in order to insert commands values to send
to the nodes. You will be required to insert the following commands values:
- version: 	- GET_AVERAGE for requiring the nodes to send an average of 
		their collected metrics
	   	- GET_ALL_SAMPLES for requiring the nodes to send all 
	   	the collected metrics
	   	- TOS_NODE_ID network address of the node the user requires 
		to remain awake (in this case the cmd_type should get the 
		value MM_FORCE_AWAKE) - 0 is for requiring all the nodes to 
		remain awake
- cmd_type:	- MM_GET_TEMPERATURE requires temperature readings
		- MM_GET_HUMIDITY requires humidity readings
		- MM_GET_PHOTO requires photo readings
		- MM_GET_SOLAR requires solar readings
		- MM_FORCE_AWAKE requires to the given node (version value)
		to remain awake
- lpl_duty:     - PERIODIC requires to the nodes to work in periodic mode
		- any value ranging from 1 to 100 to assign the given LPL 
		duty cycle to the nodes
- thr:		- threshold value; for readings greater than this value an 
		alarm is generated
- sampling_p:	- expressed in seconds is the time after which each reading 
		is taken from the selected interface
- collecting_p:	- expressed in seconds is the time after which each 
		collector node sends its readings to the sink

EXAMPLES

1) Change the way the node collects the required metrics from 
GET_ALL_SAMPLES to GET_AVERAGE and modify the lpl duty cycle value:

version		: GET_AVERAGE
cmd_type	: MM_GET_HUMIDITY (if you are not already getting readings 
		from this interface, the interface will be switched to 
		this)
lpl_duty	: 50 (initial default value was 25)
thr		: 0 (no alarm will be raised)
sampling_p	: 9 (the node gets a reading every 9 seconds)
collecting_p	: 60 (the collected metrics will be sent to the sink every
		60 seconds)

2) Change the working mode of the nodes from low power listening (Real-time, RT) to PERIODIC

version		: GET_AVERAGE (the node sends out to the sink just an
		average of the collected readings)
cmd_type	: MM_GET_HUMIDITY (if you are not already getting readings 
		from this interface, the interface will be switched to 
		this)
lpl_duty	: 0 (0 is used for PERIODIC mode) 
thr		: 0 (no alarm will be raised)
sampling_p	: 9 (the node gets a reading every 9 seconds)
collecting_p	: 60 (the collected metrics will be sent to the sink every
		60 seconds)


3) Require to force the awake mode of a given node (i.e. the given node 
(1), working in PERIODIC mode, reamins awake at the end of each 
transmission)

version		: 1 (0 is used for indicating all the nodes)
cmd_type	: MM_FORCE_AWAKE
lpl_duty	: 0 (not used)
thr		: 0 (not used)
sampling_p	: 0 (not used)
collecting_p	: 0 (not used)

4) Restore the RT working mode of the node 1 (that you already required to
remains awake at the end of each transmission)

version		: GET_AVERAGE (the node sends out to the sink just an
		average of the collected readings)
cmd_type	: MM_GET_SOLAR (if you are not already getting readings 
		from this interface, the interface will be switched to 
		this)
lpl_duty	: 75 (this duty cycle is three time faster than the 
		default one which was equal to 25) 
thr		: 0 (no alarm will be raised)
sampling_p	: 9 (the node gets a reading every 9 seconds)
collecting_p	: 60 (the collected metrics will be sent to the sink every
		60 seconds)


The data packets received by the sink are showed with the following format:
pkt_num cmd_type source_node_addr unique_node_ID sample_value age

------------------------------------------------------------------------
Changing the default Configuration
------------------------------------------------------------------------

The MoMo Application is set up by default to work with a cluster dimension 
(i.e. the maximum number of nodes for each given sink) equal to 10 neighbors. 
The Collector nodes acquire readings from temperature sensor 
(constant MM_GET_FROM_SENSOR equal to 1). Every 9 seconds (MM_SAMPLING_TIME 
equal to 9) a new sample is taken and stored in flash. Every 60 seconds 
(MM_COLLECTING_TIME equal to 60) each collector node tries to get the 
channel and send to the sink all its collected metrics.

The code for using the sensors can be found in the ./Collector/sampleLog 
directory. The pattern followed by the set of files found in this directory 
can be used to setup other types of sensors for sampling by the MoMo 
application. For every new sensor added the value of the MM_ACTIVE_SENSORS 
constant should be incremented by one. To change them via the makefile add 
lines such as the following to your Makefile in Collector application 
directory:

PFLAGS += -DMM_ACTIVE_SENSORS=N
where N is equal to 4 plus the number of sensor interfaces added.

To change the default parameters via the makefile add lines such as 
the following to your makefile in the Sink application directory
(it is important that the line regarding the maximum number of neighbors, 
MM_MAX_NUM_NEIGH, be changed in the Makefile both in Sink and Collector 
application directory):


PFLAGS += -DMM_GET_FROM_SENSOR=1	#0 = HUMIDITY - 1 = TEMPERATURE - 2 
					= PHOTO - 3 = SOLAR
PFLAGS += -DMM_SAMPLING_TIME=9		#value is in seconds
PFLAGS += -DMM_COLLECTING_TIME=60 	#value is in seconds
PFLAGS += -DMM_MAX_NUM_NEIGH=10

More protocol parameters may be changed via the MoMoMsg.h configuration
file found in the ./Application directory or by means of other 
configuration files that you may found in the corresponding directory 
of the Protocol Stack.

------------------------------------------------------------------------
Additional Tools
------------------------------------------------------------------------

1) ./Application/TestBed
In order to use this application you need to copy the provided JAMES 
application in the directory JAMESVigna that should be placed in the folder 
apps of the tinyos-2.x distribution. You may find the packed JAMES 
application in the ./utility directory.
Please refer to the file topo.pdf for a distribution of all the nodes 
available for the testbed.
Configure the array noSourceNodes in the file MoMoTestC.nc for selecting
the available nodes for the testbed.
Configure the address of the Sink via the Makefile found in the current 
directory (in this case the join procedure has been disabled).

PFLAGS += -DMM_SINK=9

Other useful values to configure via the Makefile are:

PFLAGS += -DMM_MAX_JITTER=30
represents the maximum random jitter used by the Collector nodes for 
sending their data packets;

PFLAGS += -DBACKOFF_NODE=10240
PFLAGS += -DBACKOFF_SINK=1024
represent the maximum random backoff value used at MAC Layer in case of 
channel busy respectively by the Collector and Sink nodes. These values 
are expressed in binary milliseconds (1 second = 1024 binary milliseconds).

More parameters you may configure via the Makefile have been already discussed.

Compile the application:
make tmote

Upload the *.exe file of your application in our JAMES testbed management system:
http://62.123.237.211:8180/James/
(an account is required).

For data processing use the tools you may found in the ./utility/java 
directory in the following way (assuming that test.txt is the results file)
java analyzeMoMo test.txt

The format of the showed results is the following:
time_stamp id_metric node_id packet_payload

2) ./Prober
Install a node with the standard tinyos-2.x BaseStation application 
remembering to use the same communication channel used by the MoMo 
application. This value may be set via the Makefile of the application 
by adding the following line:
CFLAGS += -DCC2420_DEF_CHANNEL=value_of_the_used_channel

Launch the Prober java application by means the following command:
java Prober -comm serial@USB-serial-device:telosb
to show the content of all the packet exchanged by the nodes in the network.

