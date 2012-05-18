
generic module SenseAndCacheP(typedef val_t @integer(), uint8_t log_entry_size) {
	provides {
		interface SenseAndCache<val_t>;
	}
	uses {
		interface Boot;

		// Sensor
		interface Read<val_t>;
		
		// Flash storage
		interface LogRead;
    		interface LogWrite;

	}
}
implementation {

	// This flag is true when erase or flush procedure is running
	bool m_busy;

	val_t readed_value;
	val_t sensed_value;

	event void Boot.booted() {
		m_busy = FALSE;
	}

	//---------------------------------------
	// Erase command
	//---------------------------------------

	task void eraseCache() {
		if ( m_busy == TRUE ) {
			signal SenseAndCache.eraseDone(EBUSY);
			return;
		}
		m_busy = TRUE;
		if ( call LogWrite.erase() != SUCCESS ) {
			m_busy = FALSE;
			signal SenseAndCache.eraseDone(FAIL);
		}
	}

	command void SenseAndCache.erase() {
		post eraseCache();
	}

	event void LogWrite.eraseDone(error_t err) {
		m_busy = FALSE;
		signal SenseAndCache.eraseDone(err);
	}

	//---------------------------------------
	// Push sensed data
	//---------------------------------------

	task void senseData() {
		if ( call Read.read() != SUCCESS ) {
			signal SenseAndCache.pushDataDone(FAIL);
		}
	}

	task void saveData() {
		if ( m_busy == TRUE ) {
			signal SenseAndCache.pushDataDone(EBUSY);
			return;
		}
		m_busy = TRUE;
      		if ( call LogWrite.append(& sensed_value, sizeof(val_t)) != SUCCESS) {
			m_busy = FALSE;
			signal SenseAndCache.pushDataDone(FAIL);
			return;
      		}
	}

	command void SenseAndCache.pushData() {
		post senseData();
	}

	event void Read.readDone( error_t result, val_t val ) {
		sensed_value = val;
		post saveData();
	}

    	event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t err) {
    		m_busy = FALSE;
		signal SenseAndCache.pushDataDone(err);
	}

	//---------------------------------------
	// Flush procedure
	//---------------------------------------

	task void continueFlush() {
		if (call LogRead.read(& readed_value, sizeof(val_t)) != SUCCESS) {
			m_busy = FALSE;
			signal SenseAndCache.flushTerminated();
		}
	}

	task void startFlush() {
		if ( m_busy == TRUE ) {
			signal SenseAndCache.flushTerminated();
			return;
		}
		m_busy = TRUE;
		post continueFlush();
	}

	event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
		if ( (buf == & readed_value) && (len == sizeof(val_t)) ) {
			signal SenseAndCache.dataArrived(readed_value);
			post continueFlush();
		}
		else {
			signal SenseAndCache.flushTerminated();
		}
	}
	
	command void SenseAndCache.startFlush() {
		post startFlush();
	}

	event void LogRead.seekDone(error_t err) {}
          	
	event void LogWrite.syncDone(error_t err) {}
	    
}

