
generic module SenseAndCacheP(uint8_t log_entry_size) {
	provides {
		interface SenseAndCache;
	}
	uses {
		interface Boot;

		// Sense timer
		interface Timer<TMilli> as SenseTimer;
		
		// Flash storage
		interface LogRead;
    		interface LogWrite;
	}
}
implementation {

	bool  	m_busy;
	uint8_t log_entry[log_entry_size];
	uint8_t log_entry_in[log_entry_size];

	event void Boot.booted() {
		m_busy = FALSE;
	}

	event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
		/*
		if ( (len == log_entry_size) && (buf == &m_entry) ) {
			call SendStats.send( AM_BROADCAST_ADDR, & m_entry.msg, m_entry.len );
		}
		*/
	}

	event void SenseTimer.fired() {
	}

	event void LogRead.seekDone(error_t err) {}
    
	event void LogWrite.eraseDone(error_t err) {
		m_busy = FALSE;
		signal SenseAndCache.clearDone(err);
	}
    
    	event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t err) {
    		m_busy = FALSE;
	}
  	
	event void LogWrite.syncDone(error_t err) {}

	task void flushFlashMemory() {
		if (call LogRead.read(log_entry, sizeof(uint8_t) * log_entry_size) != SUCCESS) {
			post flushFlashMemory();
		}
	}
	
	task void appendData() {
		if ( m_busy == TRUE )
			return;
		m_busy = TRUE;
      		if (call LogWrite.append(log_entry_in, sizeof(uint8_t) * log_entry_size) != SUCCESS) {
			m_busy = FALSE;
      		}
	}

	command void SenseAndCache.clear() {
		post flushFlashMemory();
	}
    
}

