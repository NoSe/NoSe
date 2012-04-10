
#include "CC2420.h"

#ifndef _TEST_CONTACT_MSG_
#define _TEST_CONTACT_MSG_

#define CT_START_DELAY      1000
#define CT_MAX_JITTER		2000
#define CT_PROBE_DELAY      3000
#define CT_FLASH_TIMER      2000

#define CT_FLUSH_LOG_CMD	1
#define CT_SYNC_NODE_CMD	2


//#define CT_FIRST_POWER      3
#define CT_LAST_POWER       31
#define CT_POWER_STEP       4

//#define TOSH_DATA_LENGTH    46

/**
 * Enum the message type used by the application
 *
 **/

enum {
	AM_CONTACT_MSG  = 121,
	AM_RADIO_MSG    = 123,
	AM_CMD_MSG		= 124,
};

/**
 * Message sent over the radio and used for collecting info about the contact
 *
 **/

typedef struct radio_msg {
	nx_int32_t		time_stamp_m;
	nx_int32_t		time_stamp_l;
    nx_uint8_t		channel_ID;
	nx_uint8_t		pot;
	nx_uint8_t		pkt_ID;
	nx_uint8_t		payload[ TOSH_DATA_LENGTH - 11 ];
} radio_msg_t;

/**
 * Message used for storing info about the contact
 *
 **/

typedef struct contact_msg
{
	nx_int32_t		time_stamp_m;
	nx_int32_t		time_stamp_l;
    nx_uint16_t		source;
	nx_uint16_t		neigh_ID;
    nx_uint8_t		pkt_ID;
	nx_uint8_t		rssi;
	nx_uint8_t		lqi;
    nx_uint8_t		channel_ID;
    nx_uint8_t		pot;
	nx_uint8_t		len;
} contact_msg_t;

/**
 * Message used for sending commands from host to node through the USB connection
 *
 **/

typedef struct cmd_msg {
	nx_uint8_t		cmd_type;
	nx_int32_t		ref_time_m;
	nx_int32_t		ref_time_l;
} cmd_msg_t;

#endif
