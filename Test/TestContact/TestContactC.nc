#include "TestContact.h"
#include "CC2420.h"
#include "message.h"

#include <UserButton.h>

module TestContactC {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl;
		interface Timer<TMilli> as ProbeTimer;
		interface Leds;
		interface ActiveMessageAddress;
		interface CC2420PacketBody;
		interface AMSend as SendRadio;
		interface Receive as ReceiveRadio;
		interface AMSend as SendStats;
		interface Receive as ReceiveSerial;
		interface AMPacket as SerialAMPacket;
		
		interface Random;
		//interface LocalTime<TMilli>;
		interface Counter<TMilli,uint32_t> as LocalTime;
		
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
    bool        lastPower;
    uint8_t     to_test_power;
    uint32_t	num_pkts;
	
	uint8_t		rx_lqi;
	uint8_t		rx_rssi;
	uint8_t     rx_channel_ID;
	uint8_t		rx_pot;
	uint8_t		rx_len;
	uint8_t		rx_pkt_ID;
	uint16_t	rx_source;
	int64_t		rx_time_stamp;
		
	message_t	radio_msg;
	message_t	uart_msg;
	cmd_msg_t*	cmd_msg_p;
	
	bool 		m_busy;
  	log_entry_t m_entry;
  	
  	storage_cookie_t startRead;
  	
  	int64_t	reference_time;
  	uint32_t local_ref_time;
  	
  	void assignTimestamp(int64_t * dest, int32_t ms, int32_t ls) {
  		local_ref_time = call LocalTime.get();
  		(*dest) = ((int64_t)ms & 0x00000000FFFFFFFF);
		(*dest) = (*dest) << 32;
		(*dest) += ((int64_t)ls & 0x00000000FFFFFFFF);
  		
  	}
  	
  	void splitTimestamp(nx_int32_t * ptr_m, nx_int32_t * ptr_l, int64_t ref) {
  		(*ptr_m) = (int32_t)(ref >> 32);
  		(*ptr_l) = (int32_t)(ref & 0x00000000FFFFFFFF);  	
  	}
  	
  	task void flushFlashMemory() {
  		if (call LogRead.read(&m_entry, sizeof(log_entry_t)) != SUCCESS) {
			post flushFlashMemory();
      }
  	}
	
	
	task void bcastMessage() {
		cc2420_metadata_t * metadata = (cc2420_metadata_t*) call CC2420PacketBody.getMetadata( & radio_msg );
		radio_msg_t * ptr_radio = (radio_msg_t*) ( radio_msg.data );

		metadata -> tx_power = to_test_power;
		
		ptr_radio -> channel_ID = CC2420_DEF_CHANNEL;
		ptr_radio -> pot = to_test_power;
		ptr_radio -> pkt_ID = num_pkts;
		
#ifdef CT_INFRASTRUCTURE_NODE
		if (reference_time != 0) splitTimestamp(&(ptr_radio -> time_stamp_m), &(ptr_radio -> time_stamp_l), reference_time);
#endif
		
		if ( to_test_power > CT_LAST_POWER ) {
			to_test_power = CT_FIRST_POWER;
			return;
		} else {
			to_test_power += CT_POWER_STEP;
			call Leds.led2Toggle();
		}
		
		num_pkts ++;
		call SendRadio.send( AM_BROADCAST_ADDR, & radio_msg, sizeof(radio_msg_t) );
		
	}
	
	task void sendStats() {
		contact_msg_t * stats = (contact_msg_t*)( uart_msg.data );
		stats -> neigh_ID = call ActiveMessageAddress.amAddress();
		stats -> source = rx_source;
		stats -> rssi = rx_rssi;
		stats -> lqi = rx_lqi;
		stats -> pot = rx_pot;
		stats -> len = rx_len;
		stats -> channel_ID = rx_channel_ID;
		stats -> pkt_ID = rx_pkt_ID;
		splitTimestamp(&(stats -> time_stamp_m), &(stats -> time_stamp_l), rx_time_stamp);
		call Leds.led1On();
		call SerialAMPacket.setSource(&uart_msg, call ActiveMessageAddress.amAddress());
#ifndef CT_INFRASTRUCTURE_NODE
		if (!m_busy) {
      		m_busy = TRUE;
      		m_entry.len = rx_len + 12;
		    m_entry.msg = uart_msg;
      		if (call LogWrite.append(&m_entry, sizeof(log_entry_t)) != SUCCESS) {
				m_busy = FALSE;
      		}
    	}
#else
		call SendStats.send( AM_BROADCAST_ADDR, & uart_msg, sizeof( contact_msg_t ) );
#endif	
		
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
		rx_len = len - 12;
		if (( reference_time == 0 ) && ( ptr_radio -> time_stamp_l != 0 )) assignTimestamp(&reference_time, ptr_radio -> time_stamp_m, ptr_radio -> time_stamp_l);
		rx_time_stamp = reference_time + (call LocalTime.get() - local_ref_time);
        call Leds.led0Toggle();
		post sendStats();
		return msg;
	}
	
	event message_t * ReceiveSerial.receive( message_t * msg, void * payload, uint8_t len ) {
		cmd_msg_p = (cmd_msg_t*)msg->data;
		//call Leds.set( 7 );
		if ( cmd_msg_p->cmd_type == CT_FLUSH_LOG_CMD ) {
#ifndef CT_INFRASTRUCTURE_NODE
			startRead = call LogRead.currentOffset();
			post flushFlashMemory();
#endif
		} else if ( cmd_msg_p->cmd_type == CT_SYNC_NODE_CMD) {
			assignTimestamp(&reference_time, cmd_msg_p->ref_time_m, cmd_msg_p->ref_time_l);
		}
		return msg;
	}
	
	event void Boot.booted() {
	    call Leds.set( 0 );
	    call Notify.enable();
	    
        startProbing = FALSE;
        lastPower = FALSE;
        //m_busy = TRUE;
        m_busy = FALSE; //MN: modified for fixing missing reset
        to_test_power = CT_FIRST_POWER;
        
        num_pkts = 0;
        reference_time = 0;
        
		call RadioControl.start();
		call SerialControl.start();
	}
	
	event void RadioControl.startDone( error_t result ) {
#ifdef CT_INFRASTRUCTURE_NODE
	   call ProbeTimer.startOneShot( CT_START_DELAY + call Random.rand16() % CT_MAX_JITTER );
#endif
	}
	event void RadioControl.stopDone( error_t result ) {}
	
	event void SerialControl.startDone( error_t result ) {}
	event void SerialControl.stopDone( error_t result ) {}
	
	event void SendRadio.sendDone( message_t * msg, error_t result ) {
		//MN: eventually I have to use a timer
		post bcastMessage();
	}
	event void SendStats.sendDone( message_t * msg, error_t result ) {
	   if ( result == SUCCESS ) {
	       call Leds.led1Off();
	       call Leds.led2Off();
#ifndef CT_INFRASTRUCTURE_NODE
	       if ( startRead != call LogRead.currentOffset() )
	       	  post flushFlashMemory();
	       else startRead == call LogRead.currentOffset();
#endif
	   } else {
	   	   call Leds.led2On();
	   	   call SendStats.send( AM_BROADCAST_ADDR, & m_entry.msg, m_entry.len );
	   }
	}
	
	event void ProbeTimer.fired() {
	   if ( startProbing  == FALSE ) {
	       startProbing = TRUE;
	       call ProbeTimer.startPeriodic( CT_PROBE_DELAY );
	   }
	   post bcastMessage();
	}
	
	event void FlashTimer.fired() {
	}

    
    async event void ActiveMessageAddress.changed() {}
    
    event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
    	if ( (len == sizeof(log_entry_t)) && (buf == &m_entry) ) {
    		call Leds.set( 7 );
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
    
    async event void LocalTime.overflow() {
    	//MN: we need to resynch now - to implement
    }
    
    event void Notify.notify( button_state_t state ) {
        if ( state == BUTTON_PRESSED ) {
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
            	if ( startProbing == FALSE ) {
                	call ProbeTimer.startOneShot( CT_START_DELAY + call Random.rand16() % CT_MAX_JITTER );
            	} else {
                	startProbing = FALSE;
                	call ProbeTimer.stop();
            	}
            }
        }
    }
}

