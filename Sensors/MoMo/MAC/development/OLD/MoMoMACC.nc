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
    
    components ActiveMessageC;
    MoMoMACP.RadioControl            -> ActiveMessageC;
    MoMoMACP.AMPacket                -> ActiveMessageC;
    MoMoMACP.Packet                  -> ActiveMessageC;
    
    components ActiveMessageAddressC;
    MoMoMACP.LocalAddress            -> ActiveMessageAddressC;
    
    components CC2420CsmaC;
    MoMoMACP.CCAControl              -> CC2420CsmaC;
        
    //components CC2420PacketC;
    //MoMoMACP.Acks                    -> CC2420PacketC.Acks;
    
    components CarrierSenseC;
    MoMoMACP.CarrierSense            -> CarrierSenseC;
    
    components new TimerMilliC() as TimerSend;
    MoMoMACP.TimerSend               -> TimerSend;
    
    //components CC2420ReceiveC;
    //MoMoMACP.ReceiveData             -> CC2420ReceiveC;

#ifndef TOSSIM
#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    components DefaultLplC as LPLC;
#else
    components DummyLplC as LPLC;
#endif
#else
    components DummyLplC as LPLC; 
#endif

    MoMoMACP.LPL                     -> LPLC;
    MoMoMACP.SendData                -> LPLC.Send;
    MoMoMACP.ReceiveData             -> LPLC.Receive;
}
