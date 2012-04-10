
#include "CarrierSense.h"

configuration CarrierSenseC {

    provides {
        //interface SplitControl;
        interface CarrierSense;
    }
}

implementation {

    components MainC, LedsC, CarrierSenseP;
    
    CarrierSenseP.Boot              -> MainC;
	CarrierSenseP.Leds				-> LedsC;
    
    components new Alarm32khz16C() as CCAAlarmC;
    CarrierSenseP.CCATimer          -> CCAAlarmC;
    
    components CC2420TransmitP, CC2420ReceiveP;
    CarrierSenseP.EnergyIndicator   -> CC2420TransmitP.EnergyIndicator;
    
    CarrierSenseP.PacketIndicator   -> CC2420ReceiveP.PacketIndicator;
    
    CarrierSense                    = CarrierSenseP;

}
