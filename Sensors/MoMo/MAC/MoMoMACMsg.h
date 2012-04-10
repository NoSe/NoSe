#ifndef _MM_MAC_MSG_H_
#define _MM_MAC_MSG_H_

//Software ack message
typedef nx_struct MM_mac_ack_msg {
	nx_uint8_t		force_awake;	//1 - requires the receiving node to remain awake after this transmission
	nx_uint16_t		node_id;
} MM_mac_ack_msg_t;

//Synchronization message
typedef nx_struct MM_mac_sync_msg {
} MM_mac_sync_msg_t;

//Header for every sent packet
typedef nx_struct MM_mac_header_msg {
	nx_uint8_t		type;			//Application layer packet type
	nx_uint16_t		unique_id;		//Sending node unique id
} MM_mac_header_msg_t;

#endif
