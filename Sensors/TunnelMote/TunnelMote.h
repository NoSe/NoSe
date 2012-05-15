
#include "CC2420.h"

// #define TOSH_DATA_LENGTH 46

#ifndef _TUNNEL_MOTE_MSG_
#define _TUNNEL_MOTE_MSG_

enum {
	AM_DISCOVERY_REQUEST		= 121,
	AM_DISCOVERY_RESPONSE		= 122,
	AM_COMMAND_MSG			= 123,
	AM_NEIGHBORS_MSG		= 124
};

typedef enum {
	STATE_IDLE		= 0,
	STATE_HELLO		= 1
} state_t;

typedef struct command_msg {
	nx_uint8_t 	type;
} command_msg_t;

typedef struct neighbors_msg {
	nx_uint8_t 	length;
	nx_uint16_t	node[ ( TOSH_DATA_LENGTH - 1 ) / 2 ];
} neighbors_msg_t;

#endif
