#ifndef _MM_ERROR_H_
#define _MM_ERROR_H_

enum {
	E_QUEUE_FULL		= 121, //Queue is full - an overflow is occurred
	E_SENDING_BURST		= 122, //The node is sending a burst of packets - the previous packet has been sent successfully
	E_MAX_RETRY_DATA	= 123, //The max number of permitted attempts for managing the current packet has been reached - the packet should be dropped
	E_BUSY_CHANNEL		= 124, //The channel is busy - other trasmissions are occurring
	E_ACK_LOST			= 125, //The confirmation ack for the sent packet has been lost
	E_TX_PROBLEM		= 126, //The node fails to send the packet that it is currently managing
	E_SYNC_LOST			= 127, //The synchornization packet has been lost
};

#endif
