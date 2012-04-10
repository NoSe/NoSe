#include "MoMoMsg.h"

configuration MoMoMACC {
    
    provides {
		interface SplitControl;
		interface Send;
        interface Receive;
    }
    
    uses {
        interface MoMoQueue<momo_queue_info_t> as Queue;
    }
}

implementation {

#ifdef MM_DEBUG
    components LedsC;
#else
    components NoLedsC as LedsC;
#endif

    components MoMoMACP, MainC;
    
    SplitControl                     = MoMoMACP;
    Send                             = MoMoMACP.Send;
    Receive                          = MoMoMACP.Receive;
    
    Queue                            = MoMoMACP;
    
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
    MoMoMACP.NodeControl             -> NodeControlC;
    
    components CarrierSenseC;
    MoMoMACP.CarrierSense            -> CarrierSenseC;
        
    components new TimerMilliC() as WaitingTimer;
    MoMoMACP.WaitingTimer            -> WaitingTimer;

#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    MoMoMACP.DutyCycle               -> RadioManager;
#else
    components DummyLplC;
    MoMoMACP.DutyCycle               -> DummyLplC;
#endif
}
