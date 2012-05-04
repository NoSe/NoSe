
#include "CC2420.h"

#ifndef _TEST_CONNECTIVITY_MSG_
#define _TEST_CONNECTIVITY_MSG_

#define CT_START_DELAY      3000
#define CT_PROBE_DELAY      1500
#define CT_FLASH_TIMER      2000

//#define CT_FIRST_CHANNEL    11
#define CT_LAST_CHANNEL     22 //26
#define CT_CHANNEL_STEP     1

//#define CT_FIRST_POWER      3
#define CT_LAST_POWER       31
#define CT_POWER_STEP       4

//#define TOSH_DATA_LENGTH    46

enum {
	AM_CHANNEL_MSG  = 121,
    AM_TEST_MSG     = 122,
	AM_RADIO_MSG    = 123,
	AM_CMD_MSG		= 124,
};

typedef struct radio_msg {
    nx_uint8_t		channel_ID;
	nx_uint8_t		pot;
	nx_uint8_t		pkt_ID;
    nx_uint8_t      num_pkts;
	nx_uint8_t		payload[ TOSH_DATA_LENGTH - 4 ];
} radio_msg_t;


typedef struct channel_msg
{
    nx_uint16_t		source;
	nx_uint16_t		neigh_ID;
    nx_uint8_t		pkt_ID;
    nx_uint8_t      num_pkts;
	nx_uint8_t		rssi;
	nx_uint8_t		lqi;
    nx_uint8_t		channel_ID;
    nx_uint8_t		pot;
	nx_uint8_t		len;
} channel_msg_t;

typedef struct test_msg
{
    nx_uint16_t		source;
    nx_uint8_t      num_pkts;
} test_msg_t;

typedef struct cmd_msg {
	nx_uint8_t		cmd_type;
} cmd_msg_t;

#endif
