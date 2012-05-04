
#include "TunnelMote.h"

configuration TunnelMoteAppC {
}
implementation {

	components LedsC;
	components MainC;
	components TunnelMoteC;
	components new RandomC

	components ActiveMessageC;
	components new AMSenderC( AM_DISCOVERY_HELLO ) 		as SendHello;
	components new AMReceiverC( AM_DISCOVERY_HELLO ) 	as ReceiveHello;
	
	components CC2420PacketC;
	components CC2420ControlC;
	components ActiveMessageAddressC as Address;
	components new TimerMilliC() 				as HelloTimer;
	
	TunnelMoteC.Boot					-> MainC;
	TunnelMoteC.RadioControl				-> ActiveMessageC;
	TunnelMoteC.HelloTimer            			-> HelloTimer;
	
	TunnelMoteC.CC2420PacketBody				-> CC2420PacketC;
	TunnelMoteC.CC2420Config				-> CC2420ControlC;
	TunnelMoteC.Leds					-> LedsC;

	TunnelMoteC.SendHello					-> SendHello;
	TunnelMoteC.ReceiveHello				-> ReceiveHello;
	TunnelMoteC.SerialAMPacket        			-> SerialActiveMessageC;

	TunnelMoteC.ActiveMessageAddress			-> Address;
	TunnelMoteC.Random					-> Random;
		
}
