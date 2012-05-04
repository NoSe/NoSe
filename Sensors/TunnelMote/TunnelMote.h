
#include "CC2420.h"

#ifndef _TUNNEL_MOTE_MSG_
#define _TUNNEL_MOTE_MSG_

enum {
	AM_DISCOVERY_REQUEST_MSG  	= 121,
    	AM_DISCOVERY_RESPONSE_MSG       = 122,
	AM_DISCOVERY_HELLO    		= 123
};

typedef struct response_msg {
	nx_uint8_t 	lenght
	nx_uint16_t	nodes[ ( TOSH_DATA_LENGTH - 1 ) / 2 ]
} radio_msg_t;

#endif
