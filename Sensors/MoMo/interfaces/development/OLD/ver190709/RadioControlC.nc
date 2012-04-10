#include "MoMoMACconst.h"

configuration RadioControlC {

    provides {
        interface RadioControl;
    }    
}

implementation {

    components LedsC, RadioControlP;
    
    RadioControl                      = RadioControlP;
    
    RadioControlP.Leds               -> LedsC;

    components PowerCycleP;
    RadioControlP.NodeDuty           -> PowerCycleP.NodeDuty;
    
    components CC2420ActiveMessageC as RadioManager;
    RadioControlP.SubControl         -> RadioManager;
    
#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    RadioControlP.DutyCycle          -> RadioManager;
#else
    components DummyLplC;
    RadioControlP.DutyCycle          -> DummyLplC;
#endif

	components new MoMoRadioArbitrationC();
	RadioControlP.RadioCapture		 -> MoMoRadioArbitrationC;

}
