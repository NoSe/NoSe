
#ifndef _MM_MAC_CONST_H_
#define _MM_MAC_CONST_H_

#include "MoMoErrors.h"
#include "MoMoMACMsg.h"
//MN: riorganizzare in deversi file
#define USE_MM_MAX_RETRY

//#define BACKOFF_NODE		1024	//Maximum backoff period for regular nodes (ms)
//#define BACKOFF_SINK		31		//Maximum backoff period for sink node (ms)
//#define MM_MAX_NUM_NEIGH  10		//Maximum number of neighbors for each given cluster
//#define MM_SINK			0		//Sink ID

enum {
	WAITING_TIME		= 5000,		//The time the node remains awake upon force_awake request
	CS_LENGTH			= 32767,	//Carrier sense lenght (not currently used)
	MM_SLEEP			= 3000,		//Sleep time in low power listening mode
	MM_DUTY				= 25,		//Duty cycle value in low power listening mode
	MM_ALWAYS_ON		= 0,		//Node is always on - low power listening is enabled with sleep time equal to 0
	MM_MAX_RETRY		= 100,		//Maximum number of retry attemp before discarding a packet
	MM_SLOT_LENGTH		= 1640,		//50 TO refine with estimation of the time needed to send the message
	MM_GUARD_TIME		= 164,		//5 - 10 msec - propagation + computation delay
};

enum {
	MM_SOURCE		= 1,
};

enum {
	MODULE_MAC_ACK  = 0,
	MODULE_MAC_SYNC = 1,
	MODULE_MAC_DATA = 2,
};

//MAC Layer states
enum {
	MT_MM_IDLE			= 0,	//Node is IDLE - a packet may be accepted from both upper and lower layer
	MT_MM_TX_DATA_UNI   = 1,	//Node is transmitting a data packet to a given destination
	MT_MM_TX_DATA_BR	= 2,	//Node is broadcasting a data packet to all its neighbors
	MT_MM_TX_SYNC		= 3,	//Node is transmitting a synchronization packet
	MT_MM_WAIT_SYNC		= 4,	//Node decided to participate in a contention - waits for a sync packet before sending its reply
	MT_MM_WAIT_ACK_UNI  = 5,	//Node is waiting an ack message from a given node
	MT_MM_WAIT_ACK_BR   = 6,	//Node is collecting ack messages from all its neighbors
	MT_MM_TX_ACK		= 7,	//Node is transmitting an ack message to the sender of the received packet
};

#endif
