
#include "TunnelMote.h"

configuration TunnelMoteAppC {
}
implementation {

	components MainC;
	components TunnelMoteC;
	TunnelMoteC.Boot -> MainC;

	components LedsC;
	TunnelMoteC.Leds -> LedsC;

	components RandomC;
	TunnelMoteC.Random -> RandomC;

	components CC2420PacketC;
	TunnelMoteC.CC2420PacketBody -> CC2420PacketC;

	components CC2420ControlC;
	TunnelMoteC.CC2420Config -> CC2420ControlC;

	components ActiveMessageC;
	TunnelMoteC.RadioControl -> ActiveMessageC;

	components new AMReceiverC( AM_DISCOVERY_REQUEST ) as ReceiveHelloRequest;
	TunnelMoteC.ReceiveHelloRequest -> ReceiveHelloRequest;

	components new AMSenderC( AM_DISCOVERY_RESPONSE ) as SendHelloResponse;
	TunnelMoteC.SendHelloResponse -> SendHelloResponse;

	components new AMSenderC( AM_DISCOVERY_REQUEST ) as SendHelloRequest;
	TunnelMoteC.SendHelloRequest -> SendHelloRequest;

	components new AMReceiverC( AM_DISCOVERY_RESPONSE ) as ReceiveHelloResponse;
	TunnelMoteC.ReceiveHelloResponse -> ReceiveHelloResponse;

	components ActiveMessageAddressC as Address;
	TunnelMoteC.ActiveMessageAddress -> Address;

	// Serial connection
	components SerialActiveMessageC;
	TunnelMoteC.SerialControl -> SerialActiveMessageC;
	TunnelMoteC.SerialAMPacket -> SerialActiveMessageC;

	components new SerialAMReceiverC( AM_COMMAND_MSG ) as ReceiveSerial;
	TunnelMoteC.ReceiveSerial -> ReceiveSerial;

	components new SerialAMSenderC( AM_NEIGHBORS_MSG ) as SendNeighborsSerial;
	TunnelMoteC.SendNeighborsSerial -> SendNeighborsSerial;

	components new TimerMilliC() as HelloTimer;
	TunnelMoteC.HelloTimer -> HelloTimer;

	// User button interface
	// 1 push - send hello request
	components UserButtonC;
	TunnelMoteC.Get -> UserButtonC;
	TunnelMoteC.Notify -> UserButtonC;

	components new SenseAndCacheC(uint16_t, sizeof(uint16_t));
	TunnelMoteC.SenseAndCache -> SenseAndCacheC;

	components new ConstantSensorC(uint16_t, 0xbeef) as Sensor;
	SenseAndCacheC.Read -> Sensor.Read;


}
