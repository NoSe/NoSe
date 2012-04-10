#ifndef _MM_LL_CONST_H_
#define _MM_LL_CONST_H_

enum {
	BACKOFF_LL_NODE = 5000, //Maximum link layer random backoff time for regular nodes
	BACKOFF_LL_SINK = 100,  //Maximum link layer random backoff time for sink node
	MM_QUEUE		= 20,   //Link layer queue length
};

//Link layer states
enum {
	LL_IDLE			= 0, //Node is not managing any packet - it may manage new packets
	LL_SENDING		= 1, //A packet has been sent to the mac layer that is trying to send it - any new packet may be managed
	LL_BACKOFF		= 2, //Node is backing off - the same packet will be managed again after the backoff time expires
	LL_STOPPING		= 4, //Upper layers are turning off this module - any new packet may be managed
	LL_STOPPED		= 5, //This module has been turned off
};

typedef struct queue_info {
	uint8_t         len;
	uint8_t         num_fail;
	message_t *		msg;
} momo_queue_info_t;

#endif
