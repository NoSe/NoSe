#include "MoMoMsg.h"
//MN: ripulire dalle interfacce che non uso

module MoMoMACP {
    provides {
        interface SplitControl;
        interface Send;
        interface Receive;
    }

    uses {
        interface Boot;
        interface Leds;
        interface SplitControl as RadioControl;

        interface AMPacket;
        interface Packet;
        interface PacketAcknowledgements as Acks;

        interface NodeControl as LocalAddress;
        
        interface AMSend as SendData;
        interface Receive as ReceiveData;
        
        interface RadioBackoff as CCAControl;
        interface CarrierSense;

        interface LowPowerListening as DutyCycle;
        interface Timer<TMilli> as TimerSend;
    }
}

implementation {

    message_t * msg_recv_data_; //point to the message to send
    uint8_t len_recv_data_;
    message_t free_msg_;        //local message buffer
    
    message_t * msg_data_;
	uint8_t msg_data_len_;
	
	norace uint8_t mac_state_; //MN: current MAC layer state
	
    //MN: this should be removed (it is only for testing purposes)
    event void Boot.booted() {
    }
	
    //MN: this module should be started by upper layer    
    command error_t SplitControl.start() {
        //PUT here more initializations
        msg_recv_data_ = & free_msg_;
        mac_state_ = MT_MM_IDLE;
        
        if ( call LocalAddress.getNodeAddress() == MM_SINK ) {
            call LocalAddress.setSink();
        }
        call RadioControl.start();
        
		return SUCCESS;
    }
    
    command error_t SplitControl.stop() {
		signal SplitControl.stopDone( SUCCESS );
		return SUCCESS;
	}
	
	//MN: this module is in charge to start the radio
    event void RadioControl.startDone(error_t error) {
        if( error != SUCCESS ) {
            call RadioControl.start();
            return;
        }
        
        if ( call LocalAddress.isSink() == FALSE ) {
            //MN: sink node is ALWAYS ON
            call DutyCycle.setLocalDutyCycle( MM_DUTY );
        }
        
        signal SplitControl.startDone( SUCCESS );
    }
    
    event void RadioControl.stopDone(error_t e) {}
    
/**************************************************/
/***************** TASK SECTION *******************/
/**************************************************/

	task void sendData() {
	
	   call AMPacket.setDestination( msg_data_, MM_SOURCE );
	   //MN: may it is not necessary
	   call AMPacket.setType( msg_data_, IEEE154_TYPE_DATA );
	   
	   //MN: Nodes follow duty-cycle - MN: TO CHECK HERE se funziona il duty (indirizzo non BROADCAST)
	   call DutyCycle.setRxDutyCycle( msg_data_, MM_DUTY );
	   //Sending with no default CCA
	   if ( call Acks.requestAck( msg_data_ ) == SUCCESS ) {
	       if ( call SendData.send( MM_SOURCE, msg_data_, msg_data_len_ ) == SUCCESS ) {
	           call Leds.led1On();
	           return;
	       }
	   }
	   post sendData();
	}
	
	task void doBackoff() {
	   //MN: to substitute - BACKOFF should be provided by upper layer
	   call Leds.led2On();
	   call TimerSend.startOneShot( BACKOFF_TIME );
    }
    
/**************************************************/
/************ UTILITY FUNCTION SECTION ************/
/**************************************************/    
    
    inline error_t startContention() {
        call CarrierSense.setCarrierSenseLength( CS_LENGTH );
        if ( call CarrierSense.startCarrierSense() == SUCCESS ) {
            call Leds.led0On();
            return SUCCESS;
        }
        return FAIL;
    }

/**************************************************/
/**************** COMMAND SECTION *****************/
/**************************************************/
    
    command error_t Send.send(message_t* msg, uint8_t len) {
        //MN: initilazing the packet to send based on the type (CTRL or DATA)
        if ( mac_state_ != MT_MM_IDLE )
            return FAIL;

        mac_state_ = MT_MM_TX;
        msg_data_ = msg;
        msg_data_len_ = len;
        call Packet.setPayloadLength( msg_data_, msg_data_len_ );
        return startContention();
    }
    
/**************************************************/
/****************** EVENT SECTION *****************/
/**************************************************/
    
    event void TimerSend.fired() {
        //MN: restart contention (retransmission and backoff should be provided by upper layer
        call Leds.led2Off();
        startContention();
    }
    
    async event void CarrierSense.CarrierSenseResult( error_t result ) {
    
        call Leds.led0Off();
        
        if( result == EBUSY ) {
            post doBackoff();
        }
    
        if( result == SUCCESS ) {
            post sendData();
        }
        return;
    }
    
    event void SendData.sendDone( message_t* msg, error_t error ) {     
        if (error == SUCCESS ) {
            if ( call Acks.wasAcked( msg ) ) {
                mac_state_ = MT_MM_IDLE;
                call Leds.led1Off();
                signal Send.sendDone( msg_data_, SUCCESS );
                return;
            }
        }
        post doBackoff();
    }
        
    event message_t* ReceiveData.receive(message_t* msg, void* payload, uint8_t len) {
        message_t * tmp;
        tmp = msg_recv_data_;
        msg_recv_data_ = msg;
        msg_recv_data_ = signal Receive.receive( msg_recv_data_, payload, len );
        return tmp;
    }


/**************************************************/
/************ VOID EVENT AND COMMAND **************/
/**************************************************/

    command error_t Send.cancel(message_t* msg) {}
    
    command uint8_t Send.maxPayloadLength() {}
    
    command void* Send.getPayload(message_t* msg, uint8_t len) {}
        
    async event void CCAControl.requestInitialBackoff(message_t * ONE msg) {}
    async event void CCAControl.requestCongestionBackoff(message_t * ONE msg) {}
    async event void CCAControl.requestCca(message_t * ONE msg) {
        //MN: regular CCA is substitute by my own Carrier Sense (CS)
        call CCAControl.setCca( FALSE );
    }
}
