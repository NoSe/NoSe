
#ifndef _TUNNEL_MOTE_MSG_
#define _TUNNEL_MOTE_MSG_

#include "CC2420.h"

// Data size
#define TOSH_DATA_LENGTH 46

// Neighbors discovery message is sent every 10s
#define NEIGHBORS_DISCOVERY_TIME_S	10

// Neighbors list is cleared after 60s
#define NEIGHBORS_DISCOVERY_CLENUP_S	60

enum {
	// 0x3E - 62 reserved for time sync protocol

	AM_DISCOVERY_REQUEST		= 121,
	AM_DISCOVERY_RESPONSE		= 122,

	AM_DATA_REQUEST			= 200,
	AM_DATA_RESPONSE		= 201,

	AM_COMMAND_MSG			= 123,
	AM_NEIGHBORS_MSG		= 124
};

typedef enum {
	STATE_IDLE		= 0,
	STATE_HELLO		= 1
} state_t;

typedef struct data_response_msg {
} data_response_msg_t;

typedef struct command_msg {
	nx_uint8_t 	type;
} command_msg_t;

typedef struct neighbors_msg {
	nx_uint8_t 	length;
	nx_uint16_t	node[ ( TOSH_DATA_LENGTH - 1 ) / 2 ];
} neighbors_msg_t;

#endif
