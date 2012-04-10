#include "TestContact.h"
#include "LogEntry.h"
#include "StorageVolumes.h"


configuration TestContactAppC {

}
implementation {

	components LedsC;
	components MainC;
	components TestContactC;

	components SerialActiveMessageC;
	components new SerialAMSenderC( AM_CONTACT_MSG ) as SendStats;
	components new SerialAMReceiverC( AM_CMD_MSG ) as ReceiveSerial;
	
	components ActiveMessageC;
	components new AMSenderC( AM_RADIO_MSG ) as SendRadio;
	components new AMReceiverC( AM_RADIO_MSG ) as ReceiveRadio;
	
	components CC2420PacketC;
	components ActiveMessageAddressC as Address;
	components new TimerMilliC() as ProbeTimer;
	
	components RandomC;
	//components LocalTimeMilliC;
	components CounterMilli32C;
	
	TestContactC.Boot					-> MainC;
	TestContactC.RadioControl			-> ActiveMessageC;
	TestContactC.SerialControl			-> SerialActiveMessageC;
	TestContactC.ProbeTimer            	-> ProbeTimer;
	
	TestContactC.CC2420PacketBody		-> CC2420PacketC;
	TestContactC.Leds					-> LedsC;

	TestContactC.SendRadio				-> SendRadio;
	TestContactC.ReceiveRadio			-> ReceiveRadio;
	TestContactC.SendStats				-> SendStats;
	TestContactC.ReceiveSerial			-> ReceiveSerial;
	TestContactC.SerialAMPacket        	-> SerialActiveMessageC;

	TestContactC.ActiveMessageAddress	-> Address;
	
	TestContactC.Random                 -> RandomC;
	//TestContactC.LocalTime				-> LocalTimeMilliC;
	TestContactC.LocalTime				-> CounterMilli32C;
	
	
	
	/**
	* User button interface
	* 1 push   - star the source node generating packets
	* 2 pushes - stopt the source node generating packets
	* hold for 2 seconds - erase the flash memory
	**/
	
	components UserButtonC;
	TestContactC.Get                   -> UserButtonC;
	TestContactC.Notify                -> UserButtonC;
	components new TimerMilliC() as FlashTimer;
	TestContactC.FlashTimer            -> FlashTimer;
	
	/**
	* Flash storage
	**/
	components new LogStorageC(VOLUME_LOGCONTACTS, TRUE);	
	
	TestContactC.LogRead				-> LogStorageC;
	TestContactC.LogWrite				-> LogStorageC;
		
}
