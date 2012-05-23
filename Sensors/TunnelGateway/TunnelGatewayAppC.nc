
#include "TunnelMote.h"

configuration TunnelGatewayAppC {
}
implementation {

	components MainC;
	components TunnelGatewayC;
	TunnelGatewayC.Boot -> MainC;

	components LedsC;
	TunnelGatewayC.Leds -> LedsC;

	components RandomC;
	TunnelGatewayC.Random -> RandomC;

	components CC2420PacketC;
	TunnelGatewayC.CC2420PacketBody -> CC2420PacketC;

	components CC2420ControlC;
	TunnelGatewayC.CC2420Config -> CC2420ControlC;

	components ActiveMessageC;
	TunnelGatewayC.RadioControl -> ActiveMessageC;

	components new AMReceiverC( AM_DISCOVERY_REQUEST ) as ReceiveHelloRequest;
	TunnelGatewayC.ReceiveHelloRequest -> ReceiveHelloRequest;

	components new AMSenderC( AM_DISCOVERY_RESPONSE ) as SendHelloResponse;
	TunnelGatewayC.SendHelloResponse -> SendHelloResponse;

	components new AMSenderC( AM_DISCOVERY_REQUEST ) as SendHelloRequest;
	TunnelGatewayC.SendHelloRequest -> SendHelloRequest;

	components new AMReceiverC( AM_DISCOVERY_RESPONSE ) as ReceiveHelloResponse;
	TunnelGatewayC.ReceiveHelloResponse -> ReceiveHelloResponse;

	components ActiveMessageAddressC as Address;
	TunnelGatewayC.ActiveMessageAddress -> Address;

	// Serial connection
	components SerialActiveMessageC;
	TunnelGatewayC.SerialControl -> SerialActiveMessageC;
	TunnelGatewayC.SerialAMPacket -> SerialActiveMessageC;

	components new SerialAMReceiverC( AM_COMMAND_MSG ) as ReceiveSerial;
	TunnelGatewayC.ReceiveSerial -> ReceiveSerial;

	components new SerialAMSenderC( AM_NEIGHBORS_MSG ) as SendNeighborsSerial;
	TunnelGatewayC.SendNeighborsSerial -> SendNeighborsSerial;

	components new TimerMilliC() as HelloTimer;
	TunnelGatewayC.HelloTimer -> HelloTimer;

	components new TimerMilliC() as NeighborsDiscoveryTimer;
	TunnelGatewayC.NeighborsDiscoveryTimer -> HelloTimer;

	components new TimerMilliC() as NeighborsCleanupTimer;
	TunnelGatewayC.NeighborsCleanupTimer -> HelloTimer;

	components new TimerMilliC() as DownloadDataPauseTimer;
	TunnelGatewayC.DownloadDataPauseTimer -> DownloadDataPauseTimer;

	// User button interface
	// 1 push - send hello request
	components UserButtonC;
	TunnelGatewayC.Get -> UserButtonC;
	TunnelGatewayC.Notify -> UserButtonC;

	components new SenseAndCacheC(uint16_t, sizeof(uint16_t));
	TunnelGatewayC.SenseAndCache -> SenseAndCacheC;

	components new ConstantSensorC(uint16_t, 0xbeef) as Sensor;
	SenseAndCacheC.Read -> Sensor.Read;

	// Time Synchronization
	components TimeSyncC;
	MainC.SoftwareInit -> TimeSyncC;
	TimeSyncC.Boot -> MainC;
	TunnelGatewayC.GlobalTime -> TimeSyncC;
  	TunnelGatewayC.TimeSyncInfo -> TimeSyncC;

}
