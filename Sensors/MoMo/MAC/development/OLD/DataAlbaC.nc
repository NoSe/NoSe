
configuration DataAlbaC {
	provides {
		interface SplitControl;
		interface IrisSend;
		interface IrisReceive;
		interface Packet;
		interface IrisNotification;
	}
	uses {
		interface Alarm<T32khz,uint16_t> as SlotTimer;
		interface IrisPhy;
		interface IrisBackoff;
		
		interface Packet as SubPacket;
		interface IrisQueue<iris_queue_info_t> as Queue;
		interface AlbaPosition;
#ifdef USE_ALBA_REMOTE
		interface AlbaDebug;
#endif

		interface Send as SendRts;
		interface Send as SendColl;
		interface Send as SendCts;
		interface Send as SendData;
		interface Send as SendAck;

		interface Receive as ReceiveRts;
		interface Receive as ReceiveColl;
		interface Receive as ReceiveCts;
		interface Receive as ReceiveData;
		interface Receive as ReceiveAck;

	}
}
implementation {

	components ActiveMessageAddressC as Address;
	components RandomC;
	components CC2420PacketC;
	components LedsC;
	components DataAlbaP;
	components IrisPhyC;
#ifdef USE_ALBA_REMOTE
	components AlbaDebugC;
#endif
	
	SplitControl				= DataAlbaP;
	IrisSend					= DataAlbaP;
	IrisReceive					= DataAlbaP;
	IrisPhy						= DataAlbaP;
	IrisBackoff					= DataAlbaP;
	IrisNotification			= DataAlbaP;
		
	Packet						= DataAlbaP;
	SubPacket					= DataAlbaP;
	Queue						= DataAlbaP;
	
	AlbaPosition				= DataAlbaP;
#ifdef USE_ALBA_REMOTE
	AlbaDebug					= DataAlbaP;
#endif

	DataAlbaP.CC2420PacketBody	-> CC2420PacketC;
	DataAlbaP.Leds				-> LedsC;
	
	SendRts						= DataAlbaP.SendRts;
	SendColl					= DataAlbaP.SendColl;
	SendCts						= DataAlbaP.SendCts;
	SendData					= DataAlbaP.SendData;
	SendAck						= DataAlbaP.SendAck;

	ReceiveRts					= DataAlbaP.ReceiveRts;
	ReceiveColl					= DataAlbaP.ReceiveColl;
	ReceiveCts					= DataAlbaP.ReceiveCts;
	ReceiveData					= DataAlbaP.ReceiveData;
	ReceiveAck					= DataAlbaP.ReceiveAck;
	
	DataAlbaP.IrisPhyPacket			-> IrisPhyC;
	DataAlbaP.IrisDutyCycleControl	-> IrisPhyC;
	
	SlotTimer					= DataAlbaP.SlotTimer;
	
	DataAlbaP.IrisSlot				-> IrisPhyC;
	DataAlbaP.ClockLocalTime		-> IrisPhyC;

	DataAlbaP.Random				-> RandomC;

	DataAlbaP.ActiveMessageAddress	-> Address;
	
	components IrisTimersC;
	DataAlbaP.IrisTimers		-> IrisTimersC;
	
}
