#ifndef LOGENTRY_H
#define LOGENTRY_H

#include "message.h"

typedef nx_struct log_entry_t {
	nx_uint8_t	len;
	message_t	msg;
} log_entry_t;

#endif //LOGENTRY_H

