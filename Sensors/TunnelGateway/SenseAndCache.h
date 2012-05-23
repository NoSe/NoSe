
#ifndef _SENSE_AND_CACHE_H_
#define _SENSE_AND_CACHE_H_

typedef struct log_entry {
	uint16_t value;
	uint8_t is_valid;
	uint32_t time;
} log_entry_t;

typedef enum {
	SC_IDLE		= 0,
	SC_SENSING	= 1,
	SC_READING	= 2,
	SC_CLEAR	= 3
} sense_cache_state_t;

#endif

