
#include "SenseAndCache.h"

interface SenseAndCache {

	/**
	 * Clean the whole storage memory
	 */	
	command void erase();

	/**
	 * Cleanup of storage result	
	 */
	event void eraseDone(error_t err);

	/**
	 * Take data from connected sensor and save on storage
	 */
	command void pushData();

	/**
	 * End data pushed
	 */
	event void pushDataDone(error_t err);

	/**
	 * Get data from log
	 */
	command void getData();

	/**
	 * Receive data from log: entry is not NULL when err is SUCCESS
	 */
	event void getDataDone(error_t err, log_entry_t * entry);	

	/**
	 * Notify that data was consumed: it can move to next entry
	 */
	command void moveNext();

}
