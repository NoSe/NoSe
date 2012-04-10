#include "MoMoMsg.h"

configuration MoMoMACC {
    
    provides {
		interface SplitControl;
		interface Send;
        interface Receive;
        interface Packet;
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
    Packet                           = MoMoMACP;
    
    Queue                            = MoMoMACP;
    
    MoMoMACP.Boot                    -> MainC;
    MoMoMACP.Leds                    -> LedsC;
    
    components CC2420ActiveMessageC as RadioManager;
    MoMoMACP.AMPacket                -> RadioManager;
    MoMoMACP.SubPacket                -> RadioManager;
    MoMoMACP.CCAControlData          -> RadioManager.RadioBackoff[ MODULE_MAC_SYNC ];
    MoMoMACP.CCAControlAck           -> RadioManager.RadioBackoff[ MODULE_MAC_ACK ];
    MoMoMACP.SendAck                 -> RadioManager.AMSend[ MODULE_MAC_ACK ];
    MoMoMACP.ReceiveAck              -> RadioManager.Receive[ MODULE_MAC_ACK ];
    
    components CC2420TimeSyncMessageC;
    MoMoMACP.SubSend                 -> CC2420TimeSyncMessageC.TimeSyncAMSendMilli[ MODULE_MAC_SYNC ];
    MoMoMACP.SubReceive		         -> RadioManager.Receive[ MODULE_MAC_SYNC ];
    MoMoMACP.CheckDataSync           -> CC2420TimeSyncMessageC;
    
    components LocalTimeMilliC;
	MoMoMACP.LocalTime               -> LocalTimeMilliC;

    components RadioControlC;
    MoMoMACP.RadioControl            -> RadioControlC;
    
    components NodeControlC;
    MoMoMACP.NodeControl             -> NodeControlC;
    
    components new TimerMilliC() as WaitAckTimer;
    MoMoMACP.WaitAckTimer            -> WaitAckTimer;
    
    components new TimerMilliC() as SendingAckTimer;
    MoMoMACP.SendingAckTimer         -> SendingAckTimer;

}
