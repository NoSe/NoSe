
interface SenseAndCache<val_t> {

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
	 * Start flush process: 0 or more 'dataArrived' events are espected
	 */
	command void startFlush();

	/**
	 * Notify arrival of data flushing.
	 * If return value is true, data is removed and pointer is advanced
	 * If return value is false, data is not removed and flush is stopped
	 */
	event void dataArrived(val_t data);

	/**
	 * Notify that flush is ended and no more data are in the storage
	 */
	event void flushTerminated();	

}
