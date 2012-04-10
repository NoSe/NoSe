#include "MoMoMsg.h"
//MN: ripulire dalle interfacce che non uso
//MN: aggiungere il back-to-back per inviare una serie di pacchetti senza CS

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

        interface NodeControl;
        interface MoMoQueue<momo_queue_info_t> as Queue;
        
        interface AMSend as SendData;
        interface Receive as ReceiveData;
        
        interface RadioBackoff as CCAControl;
        interface CarrierSense;

        interface LowPowerListening as DutyCycle;
        interface Timer<TMilli> as WaitingTimer;
    }
}

implementation {

    message_t * msg_recv_data_; //point to the message to send
    uint8_t len_recv_data_;
    message_t free_msg_;        //local message buffer
    
    message_t * msg_data_;
	uint8_t msg_data_len_;
	
	uint16_t neigh_duty_;
	
	bool started_;
	
	norace uint8_t mac_state_; //MN: current MAC layer state
	
	norace error_t error_;
	
	
	task void endContentionSenderSuccess();
	task void endContentionSenderRetry();
	task void sendData();
	task void haltLPL();
	
    //MN: this should be removed (it is only for testing purposes)
    event void Boot.booted() {
    }
	
    //MN: this module should be started by upper layer    
    command error_t SplitControl.start() {
        //PUT here more initializations
        started_ = FALSE;
        msg_recv_data_ = & free_msg_;
        mac_state_ = MT_MM_IDLE;
        
        if ( call NodeControl.isSink() == TRUE ) {
            neigh_duty_ = MM_DUTY;
        } else { 
            neigh_duty_ = MM_ALWAYS_ON;
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
        
        if ( started_ == FALSE ) {
            started_ = TRUE;
            if ( call NodeControl.isSink() == FALSE ) {
                call DutyCycle.setLocalDutyCycle( call NodeControl.getNodeDutyCycle() );
            } else {
                //MN: sink node is ALWAYS ON
                call DutyCycle.setLocalSleepInterval( call NodeControl.getNodeSleepDuration() );
            }
        }
        
        signal SplitControl.startDone( SUCCESS );
    }
    
    event void RadioControl.stopDone(error_t e) {}
    
/**************************************************/
/************ UTILITY FUNCTION SECTION ************/
/**************************************************/    
    
    void _error_( uint8_t v ) {
		call Leds.set( v );
		for (;;) {}
	}
    
    void endContentionSenderRetry_( uint8_t v ) {
		error_ = v;
		post endContentionSenderRetry();
	}
    
    inline error_t startContention() {
        call Leds.led2Off();
        call DutyCycle.setLocalSleepInterval( MM_ALWAYS_ON );
        call CarrierSense.setCarrierSenseLength( CS_LENGTH );
        if ( call CarrierSense.startCarrierSense() == SUCCESS ) {
            call Leds.led0On();
            return SUCCESS;
        }
        return FAIL;
    }
    
    void preparePacketToSend() {
        //MN: this information should be provided at higher layer
        //call AMPacket.setDestination( msg_data_, MM_SOURCE );
        //MN: maybe it is not necessary
        call AMPacket.setType( msg_data_, IEEE154_TYPE_DATA );
        
        //MN: Nodes follow duty-cycle - MN: TO CHECK HERE se funziona il duty (indirizzo non BROADCAST)
        if ( call NodeControl.isSink() == TRUE ) {
            call DutyCycle.setRxDutyCycle( msg_data_, neigh_duty_ );
        } else {
            call DutyCycle.setRxSleepInterval( msg_data_, neigh_duty_ );
        }
    }

    
/**************************************************/
/***************** TASK SECTION *******************/
/**************************************************/

    //MN: aggiungere le endContentionReceiver per rimettere il ricevitore in sleep

    task void endContentionSenderSuccess() {
        mac_state_ = MT_MM_IDLE;
        call Leds.led1Off();
        call DutyCycle.setLocalDutyCycle( call NodeControl.getNodeDutyCycle() );
        signal Send.sendDone( msg_data_, SUCCESS );
    }
    
    task void endContentionSenderRetry() {
        mac_state_ = MT_MM_IDLE;
        call Leds.led1Off();
        call Leds.led2On();
        call DutyCycle.setLocalDutyCycle( call NodeControl.getNodeDutyCycle() );
        signal Send.sendDone( msg_data_, error_ );
    }

	task void sendData() {
	   
	   preparePacketToSend();
	   
	   if ( call Acks.requestAck( msg_data_ ) == SUCCESS ) {
	       if ( call SendData.send( call AMPacket.destination( msg_data_ ), msg_data_, msg_data_len_ ) == SUCCESS ) {
	           call Leds.led1On();
	           return;
	       }
	   }
	   post sendData();
	}
	
	task void haltLPL() {
	   call DutyCycle.setLocalSleepInterval( MM_ALWAYS_ON );
	   call WaitingTimer.startOneShot( WAITING_TIME );
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
    
    event void WaitingTimer.fired() {
        call DutyCycle.setLocalDutyCycle( call NodeControl.getNodeDutyCycle() );
    }
    
    async event void CarrierSense.CarrierSenseResult( error_t result ) {
    
        call Leds.led0Off();
        /*
        if( result == EBUSY ) {
            endContentionSenderRetry_( E_CHANNEL_BUSY );
        }
        
    
        if( result == SUCCESS ) {
            post sendData();
        }
        */
        post sendData();
        return;
    }
    
    event void SendData.sendDone( message_t* msg, error_t error ) {     
        if (error == SUCCESS ) {
            if ( call Acks.wasAcked( msg ) ) {
                post endContentionSenderSuccess();
                return;
            }
        }
        endContentionSenderRetry_( E_ACK_LOST );
    }
        
    event message_t* ReceiveData.receive(message_t* msg, void* payload, uint8_t len) {
        message_t * tmp;
        tmp = msg_recv_data_;
        msg_recv_data_ = msg;
        //post haltLPL();
        msg_recv_data_ = signal Receive.receive( msg_recv_data_, payload, len );
        return tmp;
    }


/***************************************************/
/************ VOID EVENTS AND COMMAND **************/
/***************************************************/

    command error_t Send.cancel(message_t* msg) {}
    
    command uint8_t Send.maxPayloadLength() {}
    
    command void* Send.getPayload(message_t* msg, uint8_t len) {}
        
    async event void CCAControl.requestInitialBackoff(message_t * ONE msg) {}
    async event void CCAControl.requestCongestionBackoff(message_t * ONE msg) {}
    async event void CCAControl.requestCca(message_t * ONE msg) {
        //Regular CCA is substitute by my own Carrier Sense (CS)
        //Sending with no default CCA
        call CCAControl.setCca( FALSE );
    }
}
