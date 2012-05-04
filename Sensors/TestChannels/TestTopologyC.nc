#include "TestTopology.h"
#include "CC2420.h"
#include "message.h"

#include <UserButton.h>

module TestTopologyC {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl;
		interface Timer<TMilli> as ProbeTimer;
		interface Leds;
		interface ActiveMessageAddress;
		interface CC2420PacketBody;
		interface CC2420Config;
		interface AMSend as SendRadio;
		interface Receive as ReceiveRadio;
		interface AMSend as SendStats;
		interface AMSend as SendTest;
		interface Receive as ReceiveSerial;
		interface AMPacket as SerialAMPacket;
		
		/* Button interface */
		interface Get<button_state_t>;
		interface Notify<button_state_t>;
		interface Timer<TMilli> as FlashTimer;
		
		/* Flash storage */
		interface LogRead;
    	interface LogWrite;
		
	}
}
implementation {

    bool        startProbing;
    bool        lastChannel;
    bool        lastPower;
    bool        epochEnd;
    bool        startSender;
    uint8_t     to_test_channel;
    uint8_t     to_test_power;
    uint16_t    num_pkts;
	
	uint8_t		rx_lqi;
	uint8_t		rx_rssi;
	uint16_t	rx_source;
	uint8_t     rx_channel_ID;
	uint8_t		rx_pot;
	uint8_t		rx_len;
	uint8_t		rx_pkt_ID;
	uint8_t     rx_num_pkts;
	
	message_t	radio_msg;
	message_t	uart_msg;
	cmd_msg_t*	cmd_msg;
	
	bool 		m_busy;
  	log_entry_t m_entry;
  	
  	storage_cookie_t startRead;
  	
  	task void flushFlashMemory() {
  		if (call LogRead.read(&m_entry, sizeof(log_entry_t)) != SUCCESS) {
			post flushFlashMemory();
      }
  	}
	
	task void sendTest() {
	   test_msg_t * test = (test_msg_t*)( uart_msg.data );
	   test -> source = call ActiveMessageAddress.amAddress();
	   test -> num_pkts = CT_NUM_PKTS;
	   epochEnd = FALSE;
	   call SerialAMPacket.setSource(&uart_msg, call ActiveMessageAddress.amAddress());
	   call SendTest.send( AM_BROADCAST_ADDR, & uart_msg, sizeof( test_msg_t ) );
	}
	
	task void bcastMessage() {
		cc2420_metadata_t * metadata = (cc2420_metadata_t*) call CC2420PacketBody.getMetadata( & radio_msg );
		radio_msg_t * ptr_radio = (radio_msg_t*) ( radio_msg.data );
		
		if ( num_pkts == CT_NUM_PKTS ) {
		  num_pkts = 0;
		  if ( to_test_channel == CT_LAST_CHANNEL ) {
		      to_test_channel = CT_FIRST_CHANNEL;
		      if ( to_test_power == CT_LAST_POWER ) {
		          to_test_power = CT_FIRST_POWER;
		          call ProbeTimer.stop();
		          epochEnd = TRUE;
		          call ProbeTimer.startOneShot( CT_START_DELAY );
		          return;
		      } else {
		          to_test_power += CT_POWER_STEP;
		          call Leds.led2Toggle();
		      }
		  } else {
		      to_test_channel += CT_CHANNEL_STEP;
		      call CC2420Config.setChannel( to_test_channel );
		      call Leds.led1Toggle();
		  }
        } else {
            call Leds.led0Toggle();
        }
		
		metadata -> tx_power = to_test_power;
		ptr_radio -> channel_ID = to_test_channel;
		ptr_radio -> pot = to_test_power;
		ptr_radio -> pkt_ID = num_pkts;
		ptr_radio -> num_pkts = CT_NUM_PKTS;
		num_pkts ++;
		call SendRadio.send( AM_BROADCAST_ADDR, & radio_msg, sizeof(radio_msg_t) );
	}
	
	task void sendStats() {
		channel_msg_t * stats = (channel_msg_t*)( uart_msg.data );
		stats -> neigh_ID = call ActiveMessageAddress.amAddress();
		stats -> source = rx_source;
		stats -> rssi = rx_rssi;
		stats -> lqi = rx_lqi;
		stats -> pot = rx_pot;
		stats -> len = rx_len;
		stats -> num_pkts = rx_num_pkts;
		stats -> channel_ID = rx_channel_ID;
		stats-> pkt_ID = rx_pkt_ID;
		call Leds.led1On();
		call SerialAMPacket.setSource(&uart_msg, call ActiveMessageAddress.amAddress());
		if (!m_busy) {
      		m_busy = TRUE;
      		m_entry.len = rx_len + 5;
		    m_entry.msg = uart_msg;
      		if (call LogWrite.append(&m_entry, sizeof(log_entry_t)) != SUCCESS) {
				m_busy = FALSE;
      		}
    	}
		//call SendStats.send( AM_BROADCAST_ADDR, & uart_msg, sizeof( channel_msg_t ) );	
		
	}
	
	event message_t * ReceiveRadio.receive( message_t * msg, void * payload, uint8_t len ) {
		cc2420_metadata_t * metadata = (cc2420_metadata_t*) call CC2420PacketBody.getMetadata( msg );
		radio_msg_t * ptr_radio = (radio_msg_t*)( msg -> data );
		rx_source = ( call CC2420PacketBody.getHeader( msg )) -> src; 
		rx_lqi = metadata -> lqi;
		rx_rssi = metadata -> rssi;
		rx_pot = ptr_radio -> pot;
		rx_pkt_ID = ptr_radio -> pkt_ID;
		rx_channel_ID = ptr_radio -> channel_ID;
		rx_num_pkts = ptr_radio -> num_pkts;
		rx_len = len - 5;
        call Leds.led0Toggle();
		post sendStats();
		return msg;
	}
	
	event message_t * ReceiveSerial.receive( message_t * msg, void * payload, uint8_t len ) {
		cmd_msg = payload;
		call Leds.set( 7 );
		if ( cmd_msg->cmd_type == 10 ) {
			startRead = call LogRead.currentOffset();
			post flushFlashMemory();
		}
		return msg;
	}
	
	event void Boot.booted() {
	    call Leds.set( 0 );
	    call Notify.enable();
	    
        startProbing = FALSE;
        lastChannel = FALSE;
        lastPower = FALSE;
        epochEnd = FALSE;
        startSender = FALSE;
        //m_busy = TRUE;
        m_busy = FALSE; //MN: modified for fixing missing reset
        num_pkts = 0;
        to_test_channel = CT_FIRST_CHANNEL;
        to_test_power = CT_FIRST_POWER;
        
		call RadioControl.start();
		call SerialControl.start();
	}
	
	event void RadioControl.startDone( error_t result ) {
#ifdef CT_SENDER_NODE
	   //call ProbeTimer.startOneShot( CT_START_DELAY );
#endif
	}
	event void RadioControl.stopDone( error_t result ) {}
	
	event void SerialControl.startDone( error_t result ) {}
	event void SerialControl.stopDone( error_t result ) {}
	
	event void SendRadio.sendDone( message_t * msg, error_t result ) {}
	event void SendStats.sendDone( message_t * msg, error_t result ) {
	   if ( result == SUCCESS ) {
	       call Leds.led1Off();
	       call Leds.led2Off();
	       if ( startRead != call LogRead.currentOffset() )
	       	  post flushFlashMemory();
	       else startRead == call LogRead.currentOffset();
	   } else {
	   	   call Leds.led2On();
	   	   call SendStats.send( AM_BROADCAST_ADDR, & m_entry.msg, m_entry.len );
	   }
	}
	
	event void ProbeTimer.fired() {
	   if ( epochEnd == TRUE ) {
	       post sendTest();
	       return;
	   }
	   if ( startProbing  == FALSE ) {
	       startProbing = TRUE;
	       call ProbeTimer.startPeriodic( CT_PROBE_DELAY );
	   }
	   post bcastMessage();
	}
	
	event void FlashTimer.fired() {
	}

    event void SendTest.sendDone( message_t * msg, error_t result ) {}
    
   	event void CC2420Config.syncDone( error_t error ) {}
    async event void ActiveMessageAddress.changed() {}
    
    event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
    	if ( (len == sizeof(log_entry_t)) && (buf == &m_entry) ) {
      		call SendStats.send( AM_BROADCAST_ADDR, & m_entry.msg, m_entry.len );
    	}
    }
    event void LogRead.seekDone(error_t err) {}
    
    event void LogWrite.eraseDone(error_t err) {
    	call Leds.set( 0 );
    	if (err == SUCCESS) {
      		m_busy = FALSE;
    	}
    	else {
    		call Leds.led2On();
    	}
    }
    
    event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t err) {
    	m_busy = FALSE;
    	call Leds.led1Off();
  	}
  	
    event void LogWrite.syncDone(error_t err) {}
    
    event void Notify.notify( button_state_t state ) {
        if ( state == BUTTON_PRESSED ) {
            // Nothing to do
            call FlashTimer.stop();
            call FlashTimer.startOneShot( CT_FLASH_TIMER );
        } else if ( state == BUTTON_RELEASED ) {
            if ( call FlashTimer.isRunning() == FALSE ) {
            	call Leds.set( 7 );
                // reset flash memory
                if (call LogWrite.erase() != SUCCESS) {
					call Leds.led2On();
      			}
                return;
            } else {
            	if ( startSender == FALSE ) {
                	startSender = TRUE;
                	call ProbeTimer.startOneShot( CT_START_DELAY );
            	} else {
                	startSender = FALSE;
                	call ProbeTimer.stop();
            	}
            }
        }
    }
    
}

