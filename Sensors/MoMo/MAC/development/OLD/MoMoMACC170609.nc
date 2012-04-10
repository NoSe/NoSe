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
    MoMoMACP.SubPacket               -> RadioManager;
    MoMoMACP.CCAControlData          -> RadioManager.RadioBackoff[ MODULE_MAC_SYNC ];
    MoMoMACP.CCAControlAck           -> RadioManager.RadioBackoff[ MODULE_MAC_ACK ];
    MoMoMACP.SendAck                 -> RadioManager.AMSend[ MODULE_MAC_ACK ];
    MoMoMACP.ReceiveAck              -> RadioManager.Receive[ MODULE_MAC_ACK ];
    
    components CC2420TimeSyncMessageC as RadioManagerSync;
    //MoMoMACP.SubSend                 -> RadioManagerSync.TimeSyncAMSend32khz[ MODULE_MAC_SYNC ];
    MoMoMACP.SubSend                 -> RadioManagerSync.TimeSyncAMSendMilli[ MODULE_MAC_SYNC ];
    MoMoMACP.SubReceive		         -> RadioManagerSync.Receive[ MODULE_MAC_SYNC ];
    MoMoMACP.CheckDataSync           -> RadioManagerSync;
    
    components CC2420PacketC;
    MoMoMACP.CC2420PacketBody        -> CC2420PacketC;
    
    /*
    components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC;
    LocalTime32khzC.Counter          -> Counter32khz32C;
	MoMoMACP.LocalTime               -> LocalTime32khzC;
	*/
	components LocalTimeMilliC;
	MoMoMACP.LocalTime               -> LocalTimeMilliC;

    components RadioControlC;
    MoMoMACP.RadioControl            -> RadioControlC;
    
    components NodeControlC;
    MoMoMACP.NodeControl             -> NodeControlC;
 
    //components new Alarm32khz32C() as SlotTimer;
    components new AlarmMilli16C() as SlotTimer;
    MoMoMACP.SlotTimer               -> SlotTimer;
    
    
}
