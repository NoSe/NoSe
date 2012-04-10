#include "MoMoMsg.h"

configuration MoMoSinkAppC {}

implementation {

#ifdef MM_DEBUG
    components LedsC;
#else
    components NoLedsC as LedsC;
#endif

    components MainC, MoMoSinkC as Sink;
    
    Sink.Boot                    -> MainC;
    Sink.Leds                    -> LedsC;
    
    components ActiveMessageC;
    Sink.AMPacket                -> ActiveMessageC;
        
    components new TimerMilliC() as PollingTimer;
    Sink.PollingTimer            -> PollingTimer;
    
    components NodeControlC;
    Sink.NodeControl             -> NodeControlC;
    
    components new QueueC( message_t, MM_APP_QUEUE ) as MsgQueue;
    Sink.MsgQueue                -> MsgQueue;
    
    //------------------------------------------------------
	// Link Layer Communication
	//------------------------------------------------------
    components MoMoLLC;
    Sink.SubControl              -> MoMoLLC.SplitControl;
    Sink.SubSend                 -> MoMoLLC.Send;
    Sink.SubReceive              -> MoMoLLC.Receive;

	//------------------------------------------------------
	// Serial Communication
	//------------------------------------------------------
	components SerialActiveMessageC;
	components new SerialAMSenderC( AM_UART_SEND_MSG ) as UartSender;
	components new SerialAMReceiverC( AM_UART_RECEIVE_MSG ) as UartReceiver;
	
	Sink.UartControl             -> SerialActiveMessageC;
	Sink.SendUart                -> UartSender;
	Sink.ReceiveUart             -> UartReceiver;
	
	//------------------------------------------------------
	// Serial Command
	//------------------------------------------------------
    components ForceAwakeC;
    Sink.ForceAwake              -> ForceAwakeC;

}
