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
    
    components NodeControlC;
	Collector.NodeControl             -> NodeControlC;
	
	//------------------------------------------------------
	// Radio Control interfaces
	// (for switching over differents operating mode)
	//------------------------------------------------------
	components RadioControlC;
	Collector.DutyCycleControl        -> RadioControlC;
	Collector.LPLControl              -> RadioControlC;
    
    
    components new TimerMilliC() as DeferTimer;
    Collector.DeferTimer              -> DeferTimer;
    components RandomC;
    Collector.Random                  -> RandomC;
    
    //------------------------------------------------------
	// Link Layer Communication
	//------------------------------------------------------
    components MoMoLLC;
    Collector.SubControl              -> MoMoLLC.SplitControl;
    Collector.SubSend                 -> MoMoLLC.Send;
    Collector.SubReceive              -> MoMoLLC.Receive;
    
	//------------------------------------------------------
	// Data Acquisition
	//------------------------------------------------------
	components new TimerMilliC() as CollectingTimer;
    Collector.CollectingTimer         -> CollectingTimer;
    
    //local time for generating time stamps
    components LocalTimeMilliC;
    Collector.LocalTime               -> LocalTimeMilliC;
    
	components new SamplePeriodicLogC(VOLUME_SENSOR_SAMPLES);
	
	Collector.SampleLogConfiguration  -> SamplePeriodicLogC;
	Collector.SampleLogRead           -> SamplePeriodicLogC;
	
	components new QueueC( sensor_sample_t, 5 ) as SampleQueue;
    Collector.SampleQueue             -> SampleQueue;
  }
