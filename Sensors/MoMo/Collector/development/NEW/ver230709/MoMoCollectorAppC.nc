#include "MoMoMsg.h"
#include "SensorSample.h"
#include "StorageVolumes.h"

configuration MoMoCollectorAppC {}

implementation {

#ifdef MM_DEBUG
    components LedsC;
#else
    components NoLedsC as LedsC;
#endif

    components MainC, MoMoCollectorC as Collector;
    
    Collector.Boot                    -> MainC;
    Collector.Leds                    -> LedsC;
    
    components ActiveMessageC;
    Collector.AMPacket                -> ActiveMessageC;
    
    components NodeControlC, RadioControlC;
	Collector.NodeControl             -> NodeControlC;
	Collector.DutyCycleControl        -> RadioControlC;
    
    components MoMoLLC;
    Collector.SubControl              -> MoMoLLC.SplitControl;
    Collector.SubSend                 -> MoMoLLC.Send;
    Collector.SubReceive              -> MoMoLLC.Receive;
    
    components new TimerMilliC() as DeferTimer;
    Collector.DeferTimer              -> DeferTimer;
    components RandomC;
    Collector.Random                  -> RandomC;
    
	//------------------------------------------------------
	// Data Acquisition
	//------------------------------------------------------
	components new TimerMilliC() as CollectingTimer;
    Collector.CollectingTimer         -> CollectingTimer;
    
    components LocalTimeMilliC;
    Collector.LocalTime               -> LocalTimeMilliC;
    
	components new SamplePeriodicLogC(VOLUME_SENSOR_SAMPLES);
	
	Collector.SampleLogConfiguration  -> SamplePeriodicLogC;
	Collector.SampleLogRead           -> SamplePeriodicLogC;
  }
