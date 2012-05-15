
#include "StorageVolumes.h"

generic configuration SenseAndCacheC(uint8_t log_entry_size) {
	provides {
		interface SenseAndCache;
	}
}
implementation {

	components new SenseAndCacheP(log_entry_size);
	SenseAndCache = SenseAndCacheP.SenseAndCache;

	// Flash storage
	components new LogStorageC(VOLUME_LOGCHANNELS, TRUE);	
	
	SenseAndCacheP.LogRead -> LogStorageC;
	SenseAndCacheP.LogWrite -> LogStorageC;

	components new TimerMilliC() as SenseTimer;
	SenseAndCacheP.SenseTimer -> SenseTimer;
		
}
