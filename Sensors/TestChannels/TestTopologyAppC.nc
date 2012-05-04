#include "TestTopology.h"
#include "LogEntry.h"
#include "StorageVolumes.h"


configuration TestTopologyAppC {

}
implementation {

	components LedsC;
	components MainC;
	components TestTopologyC;

	components SerialActiveMessageC;
	components new SerialAMSenderC( AM_CHANNEL_MSG ) as SendStats;
	components new SerialAMSenderC( AM_TEST_MSG ) as SendTest;
	components new SerialAMReceiverC( AM_CMD_MSG ) as ReceiveSerial;
	
	components ActiveMessageC;
	components new AMSenderC( AM_RADIO_MSG ) as SendRadio;
	components new AMReceiverC( AM_RADIO_MSG ) as ReceiveRadio;
	
	components CC2420PacketC;
	components CC2420ControlC;
	components ActiveMessageAddressC as Address;
	components new TimerMilliC() as ProbeTimer;
	
	TestTopologyC.Boot					-> MainC;
	TestTopologyC.RadioControl			-> ActiveMessageC;
	TestTopologyC.SerialControl			-> SerialActiveMessageC;
	TestTopologyC.ProbeTimer            -> ProbeTimer;
	
	TestTopologyC.CC2420PacketBody		-> CC2420PacketC;
	TestTopologyC.CC2420Config			-> CC2420ControlC;
	TestTopologyC.Leds					-> LedsC;

	TestTopologyC.SendRadio				-> SendRadio;
	TestTopologyC.ReceiveRadio			-> ReceiveRadio;
	TestTopologyC.SendStats				-> SendStats;
	TestTopologyC.SendTest				-> SendTest;
	TestTopologyC.ReceiveSerial			-> ReceiveSerial;
	TestTopologyC.SerialAMPacket        -> SerialActiveMessageC;

	TestTopologyC.ActiveMessageAddress	-> Address;
	
	/*
	* User button interface
	* 1 push   - star the source node generating packets
	* 2 pushes - stopt the source node generating packets
	* hold for 2 seconds - erase the flash memory
	*/
	components UserButtonC;
	TestTopologyC.Get                   -> UserButtonC;
	TestTopologyC.Notify                -> UserButtonC;
	components new TimerMilliC() as FlashTimer;
	TestTopologyC.FlashTimer            -> FlashTimer;
	
	/*
	* Flash storage
	*/
	components new LogStorageC(VOLUME_LOGCHANNELS, TRUE);	
	
	TestTopologyC.LogRead				-> LogStorageC;
	TestTopologyC.LogWrite				-> LogStorageC;
		
}
