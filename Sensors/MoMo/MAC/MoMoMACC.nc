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
    
    /* Interfaces for sending and receiving packets */
    components CC2420ActiveMessageC as RadioManager;
    MoMoMACP.AMPacket                -> RadioManager;
    MoMoMACP.SubPacket               -> RadioManager;
    
    MoMoMACP.CCAControlAck           -> RadioManager.RadioBackoff[ MODULE_MAC_ACK ];
    MoMoMACP.SendAck                 -> RadioManager.AMSend[ MODULE_MAC_ACK ];
    MoMoMACP.ReceiveAck              -> RadioManager.Receive[ MODULE_MAC_ACK ];
    
    MoMoMACP.CCAControlSync          -> RadioManager.RadioBackoff[ MODULE_MAC_SYNC ];
    MoMoMACP.SendSync                -> RadioManager.AMSend[ MODULE_MAC_SYNC ];
    MoMoMACP.ReceiveSync             -> RadioManager.Receive[ MODULE_MAC_SYNC ];
    
    MoMoMACP.CCAControlData          -> RadioManager.RadioBackoff[ MODULE_MAC_DATA ];
    MoMoMACP.SubSend                 -> RadioManager.AMSend[ MODULE_MAC_DATA ];
    MoMoMACP.SubReceive		         -> RadioManager.Receive[ MODULE_MAC_DATA ];
    
    components CC2420PacketC;
    MoMoMACP.CC2420PacketBody        -> CC2420PacketC;
    
    /* Node local time */
    components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC;
    LocalTime32khzC.Counter          -> Counter32khz32C;
	MoMoMACP.LocalTime               -> LocalTime32khzC;

    /* Radio control and management */
    components RadioControlC;
    MoMoMACP.SubControl              -> RadioControlC;
    MoMoMACP.LPLControl              -> RadioControlC;
    
    /* Timer for protocol states */
    components new Alarm32khz32C() as SlotTimer;
    MoMoMACP.SlotTimer               -> SlotTimer; 
    
    /* Node and neighbors informations */
    components NodeControlC;
    MoMoMACP.NodeControl             -> NodeControlC;
    
    components ForceAwakeC;
    MoMoMACP.ForceAwake              -> ForceAwakeC;

}
