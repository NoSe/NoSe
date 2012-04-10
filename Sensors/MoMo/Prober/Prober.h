
#ifndef _PROBER_H_
#define _PROBER_H_

#include "/Users/Michele/Documents/Lavoro/TinyOS/MOTUS/tinyos-2.x/MoMo/Application/MoMoMsg.h"
#include "/Users/Michele/Documents/Lavoro/TinyOS/MOTUS/tinyos-2.x/MoMo/MAC/MoMoMACMsg.h"

typedef nx_struct report_msg {
	nx_union  {
		MM_data_msg_t		data;			// 11 bytes
		MM_ctrl_msg_t		ctrl;			// 12 bytes
		MM_join_msg_t		join;			// 4 Bytes
	};
} report_msg_t;

typedef nx_struct header_msg {
	nx_union  {
		MM_mac_ack_msg_t	ack;			// 2 bytes
		MM_mac_header_msg_t header;			// 3 bytes
	};
} header_msg_t;


enum {
	AM_REPORT_MSG		= 1,
	AM_HEADER_MSG		= 2,
};

#endif
