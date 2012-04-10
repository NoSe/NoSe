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

        interface AMPacket;
        interface Packet;
        interface PacketAcknowledgements as Acks;

        interface RadioControl;
        interface NodeControl;
        interface MoMoQueue<momo_queue_info_t> as Queue;
        
        interface AMSend as SendData;
        interface Receive as ReceiveData;
        
        interface AMSend as SendAck;
        interface Receive as ReceiveAck;
        
        //MN: try to improve precision
        interface TimeSyncAMSend<TMilli, uint32_t> as SendDataSync;
        interface TimeSyncPacket<TMilli, uint32_t> as CheckDataSync;
        interface Receive as ReceiveDataSync;
        interface LocalTime<TMilli>;
                
        interface RadioBackoff as CCAControl;

        interface Timer<TMilli> as WaitAckTimer;
        interface Timer<TMilli> as SendingAckTimer;
    }
}

implementation {

    message_t * msg_recv_data_; //point to the message to send
    uint8_t len_recv_data_;
    message_t free_msg_;        //local message buffer
    message_t msg_ack_;
    
    message_t * msg_data_;
	uint8_t msg_data_len_;
	
	uint16_t neigh_duty_;
	uint16_t neigh_list_[MM_MAX_NUM_NEIGH];
	
	uint16_t new_nodes_list_[MM_MAX_NUM_NEIGH];
	uint16_t joining_node_;
	
	norace uint8_t num_neigh_ = 0;
	uint8_t num_reached_neigh_ = 0;
	
	uint32_t sync_time_;

	norace uint8_t mac_state_; //MN: current MAC layer state
	
	norace error_t error_;
	
	
	task void endContentionSenderSuccess();
	task void endContentionSenderRetry();
	task void sendData();
	
	void endContentionSenderRetry_( uint8_t v );
	
    //MN: this should be removed (it is only for testing purposes)
    event void Boot.booted() {
        num_neigh_ = 0;
        num_reached_neigh_ = 0;
    }
	
    //MN: this module should be started by upper layer    
    command error_t SplitControl.start() {
        //PUT here more initializations
        msg_recv_data_ = & free_msg_;
        mac_state_ = MT_MM_IDLE;
        sync_time_ = 0;
        
        if ( call NodeControl.isSink() == TRUE ) {
            neigh_duty_ = MM_DUTY;
            call RadioControl.setNodeSleepDuration( MM_ALWAYS_ON );
        } else { 
            neigh_duty_ = MM_ALWAYS_ON;
            call RadioControl.setNodeDutyCycle( MM_DUTY );
        }
        
        call RadioControl.startRadio();
        
		return SUCCESS;
    }
    
    command error_t SplitControl.stop() {
		signal SplitControl.stopDone( SUCCESS );
		return SUCCESS;
	}
	
	//MN: this module is in charge to start the radio
    event void RadioControl.startRadioDone(error_t error) {
        if( error != SUCCESS ) {
            call RadioControl.startRadio();
            return;
        }
        
        signal SplitControl.startDone( SUCCESS );
    }
    
    event void RadioControl.stopRadioDone(error_t error) {
    }
    

/**************************************************/
/************ UTILITY FUNCTION SECTION ************/
/**************************************************/    
    
    inline bool allNodesReached( uint16_t node ) {
    
        if ( neigh_list_[ node ] == 0 ) {
            num_reached_neigh_ ++;
        }
        
        neigh_list_[ node ] = 1;
        
        return ( num_reached_neigh_ == num_neigh_ );
    }
    
    inline bool isNodeInList( uint16_t node ) {
    
        uint8_t i;
        for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
            if ( new_nodes_list_[ i ] == node )
                return TRUE;
        }
        
        new_nodes_list_[ num_neigh_ + 1 ] = node;
        return FALSE;
    }
    
    inline uint16_t getNodeID( uint16_t node ) {
        uint8_t i;
        for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
            if ( new_nodes_list_[ i ] == node )
                return i;
        }
    }
    
    inline void resetNeighList() {
    
        uint8_t i;
        for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
            neigh_list_[ i ] = 0;
        }
        
        num_reached_neigh_ = 0;
    }
    
    void _error_( uint8_t v ) {
		call Leds.set( v );
		for (;;) {}
	}
        
    void endContentionSenderRetry_( uint8_t v ) {
		error_ = v;
		post endContentionSenderRetry();
	}
       
    inline void makePktData() {
        //MN: maybe it is not necessary
        call AMPacket.setType( msg_data_, IEEE154_TYPE_DATA );
        call Packet.setPayloadLength( msg_data_, msg_data_len_ );
        
        //MN: Nodes follow duty-cycle - using conversion function it is possible to reduce the number of instructions
        if ( call NodeControl.isSink() == TRUE ) {
            call RadioControl.setRxDutyCycle( msg_data_, neigh_duty_ );
        } else {
            call RadioControl.setRxSleepInterval( msg_data_, neigh_duty_ );
        }
        
        sync_time_ = call RadioControl.getRxSleepInterval( msg_data_ ); //MN: this should be the time at which the packet has been sent // + call LocalTime.get()
        if ( sync_time_ == 0 )
            sync_time_ = MM_GUARD_TIME;
    }

    inline void makePktAck() {
        MM_mac_ack_msg_t* ptr_ack = (MM_mac_ack_msg_t*) call Packet.getPayload( &msg_ack_, sizeof( MM_mac_ack_msg_t ) );
        if ( call NodeControl.isSink() == TRUE ) {
            //MN: aggiungere una lista (basata su ID del nodo) er evitare di aggiungere lo stesso nodo
            if ( isNodeInList( joining_node_ ) == FALSE ) { 
                ptr_ack -> node_id = num_neigh_ + 1;
                ptr_ack -> unique_id = joining_node_;
                call NodeControl.addNeigh();
            } else {
                ptr_ack -> node_id = getNodeID( joining_node_ );
            }
            call AMPacket.setDestination( &msg_ack_, AM_BROADCAST_ADDR );
        } else {
            call AMPacket.setDestination( &msg_ack_, call NodeControl.getMySink() );
        }
        
        call RadioControl.setRxSleepInterval( &msg_ack_, neigh_duty_ );
    }
    
/**************************************************/
/***************** TASK SECTION *******************/
/**************************************************/

    task void endContentionReceiverSuccess() {
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        call RadioControl.restartDutyCycle();
    }
    
    task void endContentionReceiverFail() {
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        call RadioControl.restartDutyCycle();
    }

    task void endContentionSenderSuccess() {
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        call RadioControl.restartDutyCycle();
        signal Send.sendDone( msg_data_, SUCCESS );
    }
    
    task void endContentionSenderRetry() {
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        call RadioControl.restartDutyCycle();
        signal Send.sendDone( msg_data_, error_ );
    }
    
    task void requiredBackoff() {
        switch ( mac_state_ ) {
	       case MT_MM_TX_UNI:
	           if ( call SendData.cancel( msg_data_ ) == SUCCESS ) {
	               endContentionSenderRetry_( E_BUSY_CHANNEL );
	               return;
	           }
	           break;
	       case MT_MM_TX_BR:
	           if ( call SendDataSync.cancel( msg_data_ ) == SUCCESS ) {
	               endContentionSenderRetry_( E_BUSY_CHANNEL );
	               return;
	           }
	           break;
	       default:
	           break;
	       }
	       post requiredBackoff();
    }

	task void sendData() {
	
	   makePktData();
	   
	   switch ( mac_state_ ) {
	       case MT_MM_TX_UNI:
	           if ( call Acks.requestAck( msg_data_ ) == SUCCESS ) {
	               if ( call SendData.send( call AMPacket.destination( msg_data_ ), msg_data_, msg_data_len_ ) == SUCCESS ) {
    	               return;
	               }
	           }
	           endContentionSenderRetry_( E_TX_PROBLEM );
	           break;
	       case MT_MM_TX_BR:
	           if ( call SendDataSync.send( call AMPacket.destination( msg_data_ ), msg_data_, msg_data_len_,  sync_time_ ) == SUCCESS ) {
	               call Leds.led0On();
    	           return;
    	       }
    	       endContentionSenderRetry_( E_TX_PROBLEM );
    	       break;
	       default:
	           break;
	   }
	}
    
/**************************************************/
/**************** COMMAND SECTION *****************/
/**************************************************/
    
    command error_t Send.send(message_t* msg, uint8_t len) {
        //MN: initilazing the packet to send based on the type ADDR (UNICAST or BROADCAST)
        if ( mac_state_ != MT_MM_IDLE )
            return FAIL;

        msg_data_ = msg;
        msg_data_len_ = len;
        
        switch ( call AMPacket.destination( msg_data_ ) ) {
            case AM_BROADCAST_ADDR:
                if( call RadioControl.stopDutyCycle() != SUCCESS )
                    return FAIL;
                mac_state_ = MT_MM_TX_BR;
                if ( call NodeControl.isSink() == FALSE ) {
                    MM_mac_join_msg_t* ptr_join = (MM_mac_join_msg_t*) call Packet.getPayload( msg, sizeof( MM_mac_join_msg_t ) );
                    ptr_join -> unique_id = call NodeControl.getUniqueID();
                    msg_data_len_ += sizeof( MM_mac_join_msg_t );
                }
                break;
            default:
                mac_state_ = MT_MM_TX_UNI;
                break;
        }

        post sendData();
        return SUCCESS;
    }
    
/**************************************************/
/****************** EVENT SECTION *****************/
/**************************************************/
    
    event void WaitAckTimer.fired() {
        call Leds.led1Off();
        endContentionSenderRetry_( E_ACK_LOST );
    }
    
    event void SendingAckTimer.fired() {
        //MN: to decide if HW-ACK should be required -> add endContentionReceiver
        makePktAck();
        if ( call SendAck.send( call AMPacket.destination( &msg_ack_ ), &msg_ack_, sizeof( MM_mac_ack_msg_t ) ) == SUCCESS ) {
            call Leds.led0Off();
            return;
        }
        //MN: to specify the error type
        post endContentionReceiverFail();
    }
        
    event void SendData.sendDone( message_t* msg, error_t error ) {     
        if ( error == SUCCESS ) {
            if ( call Acks.wasAcked( msg ) ) {
                post endContentionSenderSuccess();
                return;
            }
        }
        endContentionSenderRetry_( E_ACK_LOST );
    }
    
    event void SendAck.sendDone( message_t* msg, error_t error ) {
        if ( error == SUCCESS ) {
            post endContentionReceiverSuccess();
            return;
        }
        post endContentionReceiverFail();
    }
    
    event void SendDataSync.sendDone(message_t* msg, error_t error) {
        if ( error == SUCCESS ) {
            call Leds.led0Off();
            call Leds.led1On();
            mac_state_ = MT_MM_WAIT_ACK;
            call WaitAckTimer.startOneShot( num_neigh_ * MM_SLOT_LENGTH + call RadioControl.getRxSleepInterval( msg_data_ ) );
            return;
        }
        endContentionSenderRetry_( E_SYNC_LOST );
    }
        
    event message_t* ReceiveData.receive(message_t* msg, void* payload, uint8_t len) {
        message_t * tmp;
        tmp = msg_recv_data_;
        msg_recv_data_ = msg;
        
        if ( mac_state_ != MT_MM_IDLE )
			return msg;
        
        msg_recv_data_ = signal Receive.receive( msg_recv_data_, payload, len );
        return tmp;
    }
    
    
    event message_t* ReceiveDataSync.receive(message_t* msg, void* payload, uint8_t len) {
        uint32_t my_slot;
        message_t * tmp;
        MM_mac_join_msg_t* ptr_join = (MM_mac_join_msg_t*) call Packet.getPayload( msg, sizeof( MM_mac_join_msg_t ) );
        tmp = msg_recv_data_;
        msg_recv_data_ = msg;
        
        if ( mac_state_ != MT_MM_IDLE )
			return msg;

        if ( call SendingAckTimer.isRunning() == FALSE ) {
            if ( call CheckDataSync.isValid( msg_recv_data_ ) == TRUE ) {
                if ( call RadioControl.stopDutyCycle() == SUCCESS ) {
                    mac_state_ = MT_MM_SENDING_ACK;
                    sync_time_ = call CheckDataSync.eventTime( msg_recv_data_ ) - call LocalTime.get();
                    my_slot = ( call NodeControl.isSink() == TRUE ) ? 0 : ( call NodeControl.getNodeAddress() - 1 );
                    if ( sync_time_ > 0 ) {
                        joining_node_ = ptr_join -> unique_id;
                        msg_recv_data_ = signal Receive.receive( msg_recv_data_, payload, len );
                        call SendingAckTimer.startOneShot( sync_time_ + my_slot * MM_SLOT_LENGTH );
                        call Leds.led0On();
                        return tmp;
                    }
                }
            }
        }        
        
        return msg;
    }
    
    event message_t* ReceiveAck.receive(message_t* msg, void* payload, uint8_t len) {
    
        MM_mac_ack_msg_t* ptr_ack = (MM_mac_ack_msg_t*) call Packet.getPayload( msg, sizeof( MM_mac_ack_msg_t ) );
                        
        if ( mac_state_ != MT_MM_WAIT_ACK )
			return msg;
			
        if ( call NodeControl.isSink() == FALSE ) {
            if ( call NodeControl.getUniqueID() != ptr_ack -> unique_id )
                return msg;
            call Leds.led1Off();
            call Leds.led2On();
            call WaitAckTimer.stop();
            call NodeControl.setMySink( call AMPacket.source( msg ) );
            call NodeControl.setNodeAddress( TOS_AM_GROUP, ptr_ack -> node_id );
            post endContentionSenderSuccess();
            return msg;
        }
        
        if ( call AMPacket.destination( msg ) != call NodeControl.getNodeAddress() )
            return msg;

        
        if ( allNodesReached( call AMPacket.source( msg ) ) == TRUE ) {
            call Leds.led1Off();
            call Leds.led2On();
            call WaitAckTimer.stop();
            resetNeighList();
            post endContentionSenderSuccess();
        }
                   
        return msg;
    }

/***************************************************/
/************ VOID EVENTS AND COMMAND **************/
/***************************************************/

    async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
        num_neigh_ = neigh;
    }

    command error_t Send.cancel(message_t* msg) {}
    
    command uint8_t Send.maxPayloadLength() {}
    
    command void* Send.getPayload(message_t* msg, uint8_t len) {}
        
    async event void CCAControl.requestInitialBackoff(message_t * ONE msg) {
        //MN: set here the right backoff value
    }
    async event void CCAControl.requestCongestionBackoff(message_t * ONE msg) {
        //MN: set here the right backoff value
        post requiredBackoff();
    }
    async event void CCAControl.requestCca(message_t * ONE msg) {
        //Regular CCA is substitute by my own Carrier Sense (CS)
        //call CCAControl.setCca( FALSE );
        //Sending with default CCA
        if ( mac_state_ == MT_MM_SENDING_ACK ) 
            call CCAControl.setCca( FALSE );
        else call CCAControl.setCca( TRUE );    
    }
}
