#include "MoMoMsg.h"

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
    
    components NodeControlC, DutyCycleControlC;
	Collector.NodeControl             -> NodeControlC;
	Collector.DutyCycleControl        -> DutyCycleControlC;
    
    components MoMoLLC;
    Collector.SubControl              -> MoMoLLC.SplitControl;
    Collector.SubSend                 -> MoMoLLC.Send;
    Collector.SubReceive              -> MoMoLLC.Receive;
    
    components new TimerMilliC() as CollectingTimer;
    Collector.CollectingTimer         -> CollectingTimer;

	//------------------------------------------------------
	// Data Acquisition
	//------------------------------------------------------    
    //components new HamamatsuS1087ParC() as Sensor; //MN: light sensor
    //components new DemoSensorC() as Sensor; //MN: voltage sensor
    components new SensirionSht11C() as TempSensor; //MN: temperature and humitiy sensor
	Collector.TempRead                -> TempSensor.Temperature;
	
	components new TimerMilliC() as SamplingTimer;
	Collector.SamplingTimer           -> SamplingTimer;
}
