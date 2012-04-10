#include "MoMoMsg.h"

configuration MoMoMACC {
    
    provides {
		interface SplitControl;
		interface Send;
        interface Receive;
    }
}

implementation {
    
    components LedsC, MoMoMACP, MainC;
    
    SplitControl                     = MoMoMACP;
    Send                             = MoMoMACP.Send;
    Receive                          = MoMoMACP.Receive;
    
    MoMoMACP.Boot                    -> MainC;
    MoMoMACP.Leds                    -> LedsC;
    
    components CC2420ActiveMessageC as RadioManager;
    MoMoMACP.RadioControl            -> RadioManager;
    MoMoMACP.AMPacket                -> RadioManager;
    MoMoMACP.Packet                  -> RadioManager;
    MoMoMACP.Acks                    -> RadioManager;
    MoMoMACP.CCAControl              -> RadioManager.RadioBackoff[ MODULE_MAC ];
    MoMoMACP.SendData                -> RadioManager.AMSend[ MODULE_MAC ];
    MoMoMACP.ReceiveData             -> RadioManager.Receive[ MODULE_MAC ];

    components NodeControlC;
    MoMoMACP.LocalAddress            -> NodeControlC;
    
    components CarrierSenseC;
    MoMoMACP.CarrierSense            -> CarrierSenseC;
    
    components new TimerMilliC() as TimerSend;
    MoMoMACP.TimerSend               -> TimerSend;

#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    MoMoMACP.DutyCycle               -> RadioManager;
#else
    components DummyLplC;
    MoMoMACP.DutyCycle               -> DummyLplC;
#endif
}
