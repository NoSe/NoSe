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
    MoMoMACP.AMPacket                -> RadioManager;
    MoMoMACP.Packet                  -> RadioManager;
    MoMoMACP.Acks                    -> RadioManager;
    MoMoMACP.CCAControl              -> RadioManager.RadioBackoff[ MODULE_MAC ];
    MoMoMACP.SendData                -> RadioManager.AMSend[ MODULE_MAC ];
    MoMoMACP.ReceiveData             -> RadioManager.Receive[ MODULE_MAC ];
    MoMoMACP.SendAck                 -> RadioManager.AMSend[ MODULE_MAC_ACK ];
    MoMoMACP.ReceiveAck              -> RadioManager.Receive[ MODULE_MAC_ACK ];
    
    components CC2420TimeSyncMessageC;
    MoMoMACP.SendDataSync            -> CC2420TimeSyncMessageC.TimeSyncAMSendMilli[ MODULE_MAC_SYNC ];
    MoMoMACP.CheckDataSync           -> CC2420TimeSyncMessageC;
    MoMoMACP.ReceiveDataSync		 -> RadioManager.Receive[ MODULE_MAC_SYNC ];
    
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
