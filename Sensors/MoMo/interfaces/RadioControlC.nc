#include "MoMoLLconst.h"

configuration RadioControlC {

    provides {
        interface SplitControl;
        interface LPLControl;
        interface DutyCycleControl;
    }
    
     uses {
        interface MoMoQueue<momo_queue_info_t> as LLQueue;
    }
}

implementation {

    components RadioControlC, LedsC, RadioControlP;
    
    SplitControl                         = RadioControlP;
    LPLControl                           = RadioControlP;
    DutyCycleControl                     = RadioControlP;
    LLQueue                              = RadioControlP;
    
    RadioControlP.Leds                  -> LedsC;
        
    components CC2420CsmaC;
    RadioControlP.DynamicControl        -> CC2420CsmaC;
     
    components new StateC() as RadioState;
    RadioControlP.RadioState            -> RadioState;
    
    components new TimerMilliC() as WaitingTimer;
    RadioControlP.WaitingTimer          -> WaitingTimer;
        
#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    components CC2420ActiveMessageC as RadioManager;
    RadioControlP.LPL                   -> RadioManager;
    RadioControlP.SubControl            -> RadioManager;
#else
    components DummyLplC as LplC;
    RadioControlP.LPL                   -> LplC;
    RadioControlP.SubControl            -> LplC;
#endif

    components new MoMoRadioArbitrationC() as MACCapture;
    components new MoMoRadioArbitrationC() as AppCapture;
	RadioControlP.MACCapture            -> MACCapture;
	RadioControlP.AppCapture            -> AppCapture;
}
