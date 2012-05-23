
#include "SenseAndCache.h"

module SenseAndCacheP {
	provides {
		interface SenseAndCache;
	}
	uses {
		interface Boot;

		// Sensor
		interface Read<uint16_t>;
		
		// Flash storage
		interface LogRead;
    		interface LogWrite;

		// Time
		interface GlobalTime<TMilli>;

	}
}
implementation {

	// This flag is true when erase or flush procedure is running
	sense_cache_state_t state;

	// Value readed
	log_entry_t readed_value;

	// Value sensed
	log_entry_t sensed_value;

	// Flag to use again data readed
	bool useagain;

	// Global time
	uint32_t global_time;

	event void Boot.booted() {
		useagain = FALSE;
		state = SC_IDLE;
	}

	//---------------------------------------
	// Erase command
	//---------------------------------------

	task void eraseCache() {
		if ( state != SC_IDLE ) {
			signal SenseAndCache.eraseDone(EBUSY);
			return;
		}
		state = SC_CLEAR;
		if ( call LogWrite.erase() != SUCCESS ) {
			state = SC_IDLE;
			signal SenseAndCache.eraseDone(FAIL);
		}
	}

	command void SenseAndCache.erase() {
		post eraseCache();
	}

	event void LogWrite.eraseDone(error_t err) {
		state = SC_IDLE;
		signal SenseAndCache.eraseDone(err);
	}

	//---------------------------------------
	// Push sensed data
	//---------------------------------------

	task void senseData() {
		if ( state != SC_IDLE ) {
			signal SenseAndCache.pushDataDone(EBUSY);
			return;
		}
		state = SC_SENSING;
		if ( call Read.read() != SUCCESS ) {
			state = SC_IDLE;
			signal SenseAndCache.pushDataDone(FAIL);
		}
	}

	task void saveData() {
      		if ( call LogWrite.append(& sensed_value, sizeof(log_entry_t)) != SUCCESS) {
			state = SC_IDLE;
			signal SenseAndCache.pushDataDone(FAIL);
			return;
      		}
	}

	command void SenseAndCache.pushData() {
		post senseData();
	}

	event void Read.readDone( error_t result, uint16_t val ) {
		sensed_value.is_valid = call GlobalTime.getGlobalTime(& global_time);
		sensed_value.time = global_time;
		sensed_value.value = val;
		post saveData();
	}

    	event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t err) {
		if ( (len == sizeof(log_entry_t)) && (buf == & sensed_value) ) {
	    		state = SC_IDLE;
			signal SenseAndCache.pushDataDone(err);
		}
	}

	//---------------------------------------
	// Flush procedure
	//---------------------------------------

	task void continueGetData() {
		if ( useagain == TRUE ) {
			state = SC_IDLE;
			signal SenseAndCache.getDataDone(SUCCESS, & readed_value);
			return;
		}

		if (call LogRead.read(& readed_value, sizeof(log_entry_t)) != SUCCESS) {
			state = SC_IDLE;
			signal SenseAndCache.getDataDone(FAIL, NULL);
		}
	}

	task void getData() {
		if ( state != SC_IDLE ) {
			signal SenseAndCache.getDataDone(FAIL, NULL);
			return;
		}
		state = SC_READING;
		post continueGetData();
	}

	event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
		if ( (buf == & readed_value) && (len == sizeof(log_entry_t)) ) {
			useagain = TRUE;
			state = SC_IDLE;
			signal SenseAndCache.getDataDone(SUCCESS, & readed_value);
		}
	}

	command void SenseAndCache.moveNext() {
		useagain = FALSE;
	}
	
	command void SenseAndCache.getData() {
		post getData();
	}

	event void LogRead.seekDone(error_t err) {}
          	
	event void LogWrite.syncDone(error_t err) {}
	    
}

