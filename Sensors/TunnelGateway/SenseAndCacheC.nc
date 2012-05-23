
#include "StorageVolumes.h"

configuration SenseAndCacheC {
	uses {
		interface Read<uint16_t>;
		interface GlobalTime<TMilli>;
	}
	provides {
		interface SenseAndCache;
	}
}
implementation {

	// Main component
	components SenseAndCacheP;
	SenseAndCache = SenseAndCacheP.SenseAndCache;
	Read = SenseAndCacheP.Read;
	GlobalTime = SenseAndCacheP.GlobalTime;

	// Flash storage
	components new LogStorageC(VOLUME_LOGCHANNELS, TRUE);	
	SenseAndCacheP.LogRead -> LogStorageC;
	SenseAndCacheP.LogWrite -> LogStorageC;
		
}
