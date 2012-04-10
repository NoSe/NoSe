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

        interface ActiveMessageAddress as LocalAddress;
        
        interface Send as SendData;
        interface Receive as ReceiveData;
        //interface CC2420Receive as ReceiveData;
        
        interface RadioBackoff as CCAControl;
        interface CarrierSense;

#ifndef TOSSIM
        interface LowPowerListening as LPL;
#endif
        interface Timer<TMilli> as TimerSend;
    }
}

implementation {

    message_t * msg_recv_data_; //point to the message to send
    uint8_t len_recv_data_;
    message_t free_msg_;        //local message buffer
    
    message_t * msg_data_;
	uint8_t msg_data_len_;
	
    
    command error_t SplitControl.start() {
        //PUT here more initializations
        msg_recv_data_ = & free_msg_;
        
        call RadioControl.start();
        
        //signal SplitControl.startDone( SUCCESS );
		return SUCCESS;
    }
    
    command error_t SplitControl.stop() {
		signal SplitControl.stopDone( SUCCESS );
		return SUCCESS;
	}
	
	default event void SplitControl.startDone(error_t error) {}
	
    event void Boot.booted() {
        //MN: to remove
        //atomic msg_recv_data_ = & free_msg_;
        //call RadioControl.start();
    }

	task void sendData() {
	
	   call AMPacket.setDestination( msg_data_, MM_SOURCE );
	   call AMPacket.setType( msg_data_, IEEE154_TYPE_DATA );
	   
	   //if(( call Packet.payloadLength( msg_data_) - sizeof( MM_ctrl_msg_t ) ) == 0 )
	       //call Leds.set( 7 );
	
	   //Nodes follow duty-cycle - MN: TO CHECK HERE se funziona il duty (indirizzo non BROADCAST)
	   //call LPL.setRxDutyCycle( msg_data_, LPL_DUTY );
	   //Sending with no default CCA
	   if ( call SendData.send( msg_data_, msg_data_len_ ) != SUCCESS ) {
	       post sendData();
	       return;
	   }
	   call Leds.led0On();
	}
	
	task void doBackoff() {
	   call TimerSend.startOneShot( BACKOFF_TIME );
    }
    
    event void RadioControl.startDone(error_t error) {
        if( error != SUCCESS ) {
            call RadioControl.start();
            return;
        }
        
        if ( call LocalAddress.amAddress() != MM_SINK ) {
            //call Leds.led0On();
            //call LPL.setLocalDutyCycle( LPL_DUTY );
        }
        
        signal SplitControl.startDone( SUCCESS );
    }
    
    event void RadioControl.stopDone(error_t e) {}
    
    event void TimerSend.fired() {
        //post sendData();
                
        call CarrierSense.setCarrierSenseLength( CS_LENGTH );
        if ( call CarrierSense.startCarrierSense() == SUCCESS ) {
            ////call Leds.led0On();
             return;
        }
        call TimerSend.startOneShot( BACKOFF_TIME );
    }

    event void SendData.sendDone( message_t* msg, error_t error ) {     
        if (error == SUCCESS ) {
            ////call Leds.led1Off();
            call Leds.led0Off();
            signal Send.sendDone( msg_data_, SUCCESS );
        } else {
            post doBackoff();
        }
    }
    
    async event void CarrierSense.CarrierSenseResult( error_t result ) {
    
        ////call Leds.led0Off();
        if( result == EBUSY ) {
            ////call Leds.led2Toggle();
            post doBackoff();
        }
    
        if( result == SUCCESS ) {
            ////call Leds.led1On();
            post sendData();
        }
        return;
    }
    
    command error_t Send.send(message_t* msg, uint8_t len) {        
        msg_data_ = msg;
        msg_data_len_ = len;
        call Packet.setPayloadLength( msg_data_, msg_data_len_ );
        call TimerSend.startOneShot( 10 );
        return SUCCESS;   
    }
    
    command error_t Send.cancel(message_t* msg) {}
    
    command uint8_t Send.maxPayloadLength() {}
    
    command void* Send.getPayload(message_t* msg, uint8_t len) {}
    
    //default event void Send.sendDone(message_t* msg, error_t error) {}
    
    event message_t* ReceiveData.receive(message_t* msg, void* payload, uint8_t len) {
        message_t * tmp;
        ////call Leds.set( 6 );
        //call Leds.led2Toggle();
        tmp = msg_recv_data_;
        msg_recv_data_ = msg;
        msg_recv_data_ = signal Receive.receive( msg_recv_data_, payload, len );
        return tmp;
    }

    /*
    async event void ReceiveData.receive( uint8_t type, message_t* ONE_NOK message ) {
        msg_recv_data_ = message;
        len_recv_data_ = call Packet.payloadLength( msg_recv_data_ );
        msg_recv_data_ = signal Receive.receive( msg_recv_data_, call Packet.getPayload( msg_recv_data_, len_recv_data_ ),  len_recv_data_ );
    }
    */
    
    async event void LocalAddress.changed() {}
    
    async event void CCAControl.requestInitialBackoff(message_t * ONE msg) {}
    async event void CCAControl.requestCongestionBackoff(message_t * ONE msg) {}
    async event void CCAControl.requestCca(message_t * ONE msg) {
        call CCAControl.setCca( FALSE );
    }
}
