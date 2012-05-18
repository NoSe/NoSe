
#include "StorageVolumes.h"

generic configuration SenseAndCacheC(typedef val_t @integer(), uint8_t log_entry_size) {
	uses {
		interface Read<val_t>;
	}
	provides {
		interface SenseAndCache<val_t>;
	}
}
implementation {

	components new SenseAndCacheP(val_t, log_entry_size);
	SenseAndCache = SenseAndCacheP.SenseAndCache;
	Read = SenseAndCacheP.Read;

	// Flash storage
	components new LogStorageC(VOLUME_LOGCHANNELS, TRUE);	
	
	SenseAndCacheP.LogRead -> LogStorageC;
	SenseAndCacheP.LogWrite -> LogStorageC;
		
}
