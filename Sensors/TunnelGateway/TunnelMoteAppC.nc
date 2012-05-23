
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

	// Discovery
	
	components new AMReceiverC( AM_DISCOVERY_REQUEST ) as ReceiveHelloRequest;
	TunnelMoteC.ReceiveHelloRequest -> ReceiveHelloRequest;

	components new AMSenderC( AM_DISCOVERY_RESPONSE ) as SendHelloResponse;
	TunnelMoteC.SendHelloResponse -> SendHelloResponse;

	// Data request/response

	components new AMReceiverC( AM_DATA_REQUEST ) as ReceiveDataRequest;
	TunnelMoteC.ReceiveDataRequest -> ReceiveDataRequest;

	components new AMSenderC( AM_DATA_RESPONSE ) as SendDataResponse;
	TunnelMoteC.SendDataResponse -> SendDataResponse;

	components ActiveMessageAddressC as Address;
	TunnelMoteC.ActiveMessageAddress -> Address;

	components new TimerMilliC() as HelloTimer;
	TunnelMoteC.HelloTimer -> HelloTimer;

	components SenseAndCacheC;
	TunnelMoteC.SenseAndCache -> SenseAndCacheC;

	components new TimerMilliC() as SensingTimer;
	TunnelMoteC.SensingTimer -> SensingTimer;

	components new ConstantSensorC(uint16_t, 0xbeef) as Sensor;
	SenseAndCacheC.Read -> Sensor.Read;

	// Time Synchronization
	components TimeSyncC;
	MainC.SoftwareInit -> TimeSyncC;
	TimeSyncC.Boot -> MainC;
	TunnelMoteC.GlobalTime -> TimeSyncC;
  	TunnelMoteC.TimeSyncInfo -> TimeSyncC;

	SenseAndCacheC.GlobalTime -> TimeSyncC;

}
