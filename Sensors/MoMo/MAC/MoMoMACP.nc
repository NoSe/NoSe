/**
 *
 * This module provides the MAC layer implementation.
 * MAC layer provides channel sensing to avoid collision, sends the packet
 * and collects the ack from the packet destination for a reliable transmission.
 * 
 */

#include "MoMoMsg.h"

module MoMoMACP {
    provides {
        interface SplitControl;
        interface Send;
        interface Receive;
        interface Packet;
    }

    uses {
        interface Boot;
        interface Leds;

        interface AMPacket;
        interface Packet as SubPacket;
      
        //MN: TO REMOVE
        interface MoMoQueue<momo_queue_info_t> as Queue;
        
        interface AMSend as SendAck;
        interface Receive as ReceiveAck;
        
        interface AMSend as SendSync;
        interface Receive as ReceiveSync;
        
        interface AMSend as SubSend;    
        interface Receive as SubReceive;
        
        interface LocalTime<T32khz> as LocalTime;
        interface CC2420PacketBody;
                
        interface RadioBackoff as CCAControlData;
        interface RadioBackoff as CCAControlAck;
        interface RadioBackoff as CCAControlSync;

        interface Alarm<T32khz,uint32_t> as SlotTimer;
        
        interface SplitControl as SubControl;
        interface LPLControl;
        
        //Required to send commands in periodic mode functioning
        interface ForceAwake;
        interface NodeControl;
    }
}

implementation {

    message_t * msg_recv_data_;                     //message received pointer
    void * payload_recv_data_;                      //payload of received message pointer
    uint8_t len_recv_data_;                         //received message length
    message_t free_msg_;                            //local message buffer
    message_t msg_ack_;                             //ack message
    message_t msg_sync_;                            //sync message
    uint16_t sender_addr_;                          //sender addr of the received packet
    
    norace message_t * msg_data_;                   //message to send pointer
	uint8_t msg_data_len_;                          //message to send length
	
	uint16_t neigh_duty_;                           //neighbors duty cycle
	uint16_t neigh_list_[MM_MAX_NUM_NEIGH];         //list of reached neighbors
	
	uint16_t new_nodes_list_[MM_MAX_NUM_NEIGH];    //mapping between neighbor unique ID and the given address
	uint16_t joining_node_;                        //address of the node requiring to join this sink
	
	norace uint8_t num_neigh_;                     //current number of neighbors in the cluster of this sink
	uint8_t num_reached_neigh_;                    //current number of neighbors reached from the sent packet
	                                               //(number of the nodes that acknowledged the given packet)
	
	norace uint8_t mac_state_;                      //current MAC layer state
	
	norace error_t error_;
	
	bool joined_;                                   //node has joined a given sink
	
	
	task void endContentionSenderSuccess();         //sender successfully sent the packet
	task void endContentionSenderRetry();           //transmission attempt failed - try again after a given backoff
	task void endContentionReceiverSuccess();       //receiver successfully received the packet
	task void endContentionReceiverFail();          //packet has been lost - contention ended
	task void sendData();                           
	task void sendAck();
	task void sendSync();
	
	//radio detect busy channel - required backoff
	task void requiredBackoffData();
	task void requiredBackoffAck();
	task void requiredBackoffSync();
	
	
	void endContentionSenderRetry_( uint8_t v );
	
    //this should be removed (it is only for testing purposes)
    event void Boot.booted() {
        //num_neigh_ = 0;
        num_reached_neigh_ = 0;
    }
	
    //this module should be started by upper layer (LL)
    command error_t SplitControl.start() {
        //PUT here more initializations
        msg_recv_data_ = & free_msg_;
        mac_state_ = MT_MM_IDLE;
        sender_addr_ = 0xFFFF;
        
        if ( call NodeControl.isSink() == TRUE ) {
            joined_ = TRUE;
            neigh_duty_ = MM_DUTY;
            call LPLControl.setNodeSleepDuration( MM_ALWAYS_ON ); //set the sink duty cycle - it is always on
            call ForceAwake.setNeighborsDuty( neigh_duty_ );
        } else {
            //neighbor of regular nodes is always the sink - it is always on
            joined_ = FALSE;
            neigh_duty_ = MM_ALWAYS_ON;
            call LPLControl.setNodeDutyCycle( MM_DUTY ); //set the node duty cycle in low-power listening (RT operating mode)
        }
        
        //start the radio module
        call SubControl.start();
        
		return SUCCESS;
    }
    
    command error_t SplitControl.stop() {
		signal SplitControl.stopDone( SUCCESS );
		return SUCCESS;
	}
	
	//this module is in charge to start the radio
    event void SubControl.startDone(error_t error) {
        if( error != SUCCESS ) {
            call SubControl.start();
            return;
        }
        
        signal SplitControl.startDone( SUCCESS );
    }
    
    event void SubControl.stopDone(error_t error) {
    }
    

/**************************************************/
/************ UTILITY FUNCTION SECTION ************/
/**************************************************/

    //return the node slot for ack reply - for broadcast packets the node reply based on its address - for unicast packets it replies immediately
    inline uint8_t getMySlot( uint16_t dest_addr ) {
        uint8_t my_slot;
        if ( dest_addr == AM_BROADCAST_ADDR )
            my_slot = ( call NodeControl.isSink() == TRUE ) ? 0 : ( call NodeControl.getNodeAddress() - 1 );
        else
            my_slot = 0;
        
        return my_slot;
    } 
    
    //check if all the nodes of the cluster have been reached - if they sent back their ack
    inline bool allNodesReached( uint16_t node ) {
    
        if ( neigh_list_[ node ] == 0 ) {
            //node not still reached
            num_reached_neigh_ ++;
        }
        
        neigh_list_[ node ] = 1;
        
        return ( num_reached_neigh_ == num_neigh_ );
    }
    
    //check if the node has been already added as neighbor
    inline bool isNodeInList( uint16_t node ) {
    
        uint8_t i;
        //for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
        for ( i = 0; i <= num_neigh_; i++) {
            if ( new_nodes_list_[ i ] == node )
                return TRUE;
        }
        
        //new node - the number of neighbors should be incremented by calling NodeControl.addNeigh()
        new_nodes_list_[ num_neigh_ + 1 ] = node;
        return FALSE;
    }
    
    //return the uniqueID of the node corresponding to the given address in the network
    inline uint16_t getNodeID( uint16_t node ) {
        uint8_t i;
        //for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
        for ( i = 0; i <= num_neigh_; i++) {
            if ( new_nodes_list_[ i ] == node )
                return i;
        }
    }
    
    //reset the list of the neighbors reached from the current packet
    //when the node is in RT mode
    //(an ack message has been received from the given neighbor)
    inline void resetNeighList() {
    
        uint8_t i;
        uint8_t periodic_neigh = 0;
        
        //for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
        for ( i = 0; i <= num_neigh_; i++) {
            //neigh_list_[ i ] = 0;
            if ( call ForceAwake.checkNeighborsMode( i ) == RT_MODE )
                neigh_list_[ i ] = 0;
            else {
                //if ( neigh_list_[ i ] == 1 ) //MN: TO CHECK
                periodic_neigh ++;
            }
        }
        
        //num_reached_neigh_ = 0;
        num_reached_neigh_ = periodic_neigh;
    }
    
    void _error_( uint8_t v ) {
		call Leds.set( v );
		for (;;) {}
	}
        
    void endContentionSenderRetry_( uint8_t v ) {
		error_ = v;
		post endContentionSenderRetry();
	}
       
    //prepare the packet data to send - set the duty cycle of the destination node
    //operating in low-power listening (RT mode)
    inline void makePktData() {
        
        //MN: Nodes follow duty-cycle - using conversion function it is possible to reduce the number of instructions
        if ( call NodeControl.isSink() == TRUE ) {
            if ( ( mac_state_ == MT_MM_TX_DATA_BR ) || ( call ForceAwake.checkNeighborsMode( call AMPacket.destination( msg_data_ )  ) == RT_MODE ) )
                call LPLControl.setRxDutyCycle( msg_data_, call ForceAwake.getNeighborsDuty() );
            else call LPLControl.setRxSleepInterval( msg_data_, MM_ALWAYS_ON ); //Node should be in periodic mode and required to remain awake
        } else {
            call LPLControl.setRxSleepInterval( msg_data_, neigh_duty_ );
        }
    }

    //prepare the ack packet to send
    inline void makePktAck() {
        MM_mac_ack_msg_t* ptr_ack = (MM_mac_ack_msg_t*) call SubPacket.getPayload( &msg_ack_, sizeof( MM_mac_ack_msg_t ) );
        
        ptr_ack -> node_id = sender_addr_;
        //check if the destination node is required to remain awake
        ptr_ack -> force_awake = call ForceAwake.checkNeighbors( sender_addr_ );
        
        if ( joining_node_ == sender_addr_ ) {
            if ( call NodeControl.isSink() == TRUE ) {
                //if this neighbor is joining this sink - the ack will provide the address
                if ( isNodeInList( joining_node_ ) == FALSE ) { 
                    ptr_ack -> node_id = num_neigh_ + 1;
                    if ( ptr_ack -> node_id > MM_MAX_NUM_NEIGH ) ptr_ack -> node_id = MM_MAX_NUM_NEIGH + 1;
                    call NodeControl.addNeigh(); //MN: it is possible to move it whitin the isNodeInList() function
                } else {
                    ptr_ack -> node_id = getNodeID( joining_node_ );
                }
            }
        }
        
        call AMPacket.setDestination( &msg_ack_, sender_addr_ );
        
        call LPLControl.setRxSleepInterval( &msg_ack_, MM_ALWAYS_ON );
    }
    
    //prepare the sync packet to send
    inline void makePktSync() {
        call AMPacket.setDestination( &msg_sync_, AM_BROADCAST_ADDR );
        //the nodes waiting for the sync message are always on
        call LPLControl.setRxSleepInterval( &msg_sync_, MM_ALWAYS_ON );
    }
    
/**************************************************/
/***************** TASK SECTION *******************/
/**************************************************/

    task void endContentionReceiverSuccess() {
        //MN: add the following lines - TO CHECK
        MM_mac_header_msg_t* ptr_header = (MM_mac_header_msg_t*) call SubSend.getPayload( msg_recv_data_,  call SubSend.maxPayloadLength() );
        sender_addr_ = 0xFFFF;
        call AMPacket.setType( msg_recv_data_, ptr_header -> type );
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        //the low power listening may be restarted
        call LPLControl.leaveContention();
        msg_recv_data_ = signal Receive.receive( msg_recv_data_, payload_recv_data_, len_recv_data_ );
    }
    
    task void endContentionReceiverFail() {
        call Leds.set( 0 );
        sender_addr_ = 0xFFFF;
        mac_state_ = MT_MM_IDLE;
        //the low power listening may be restarted
        call LPLControl.leaveContention();
    }

    task void endContentionSenderSuccess() {
        //MN: add the following lines - TO CHECK
        MM_mac_header_msg_t* ptr_header = (MM_mac_header_msg_t*) call SubSend.getPayload( msg_data_,  call SubSend.maxPayloadLength() );
        call AMPacket.setType( msg_data_, ptr_header -> type );
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        //node stops to follow the low power listening duty cycle
        call LPLControl.stopContention();
        signal Send.sendDone( msg_data_, SUCCESS );
    }
    
    task void endContentionSenderRetry() {
        MM_mac_header_msg_t* ptr_header = (MM_mac_header_msg_t*) call SubSend.getPayload( msg_data_,  call SubSend.maxPayloadLength() );
        call AMPacket.setType( msg_data_, ptr_header -> type );
        call Leds.set( 0 );
        mac_state_ = MT_MM_IDLE;
        //node stops to follow the low power listening duty cycle
        call LPLControl.stopContention();
        signal Send.sendDone( msg_data_, error_ );
    }
    
    task void requiredBackoffData() {
        //call SubSend.cancel( msg_data_ );
        uint16_t backoff_time;
        if( call NodeControl.isSink() == TRUE ) {
            //the sink node should have priority for sending packets
    		backoff_time = BACKOFF_LL_SINK;
        } else {
            backoff_time = BACKOFF_LL_NODE;
        }
        //call CCAControlData.setCongestionBackoff( backoff_time );
        if ( call SubSend.cancel( msg_data_ ) == SUCCESS )
            endContentionSenderRetry_( E_TX_PROBLEM );
        else call CCAControlData.setCongestionBackoff( backoff_time );
    }
    
    task void requiredBackoffAck() {
        if ( call SendAck.cancel( &msg_ack_ ) == SUCCESS )
            post endContentionReceiverFail();
        else call CCAControlAck.setCongestionBackoff( 1 );
    }
    
    task void requiredBackoffSync() {
        if ( call SendSync.cancel( &msg_sync_ ) == SUCCESS )
            endContentionSenderRetry_( E_TX_PROBLEM );
        else call CCAControlSync.setCongestionBackoff( 1 );
    }

	task void sendData() {
	    makePktData();
   
	    if ( call SubSend.send( call AMPacket.destination( msg_data_ ), msg_data_, msg_data_len_ ) == SUCCESS ) {
	       call Leds.led0On();
    	   return;
        }
        endContentionSenderRetry_( E_TX_PROBLEM );
    }
    
    task void sendAck() {
        makePktAck();
        if ( call SendAck.send( call AMPacket.destination( &msg_ack_ ), &msg_ack_, sizeof( MM_mac_ack_msg_t ) ) == SUCCESS ) {
            //call Leds.led0Off();
            return;
        }
        //MN: to specify the error type
        post endContentionReceiverFail();
    }
    
    task void sendSync() {
        makePktSync();
        
        if ( call SendSync.send( call AMPacket.destination( &msg_sync_ ), &msg_sync_, sizeof( MM_mac_sync_msg_t ) ) == SUCCESS ) {
	       //call Leds.led0On();
    	   return;
        }
        endContentionSenderRetry_( E_TX_PROBLEM );
    }
    
/**************************************************/
/**************** COMMAND SECTION *****************/
/**************************************************/
    
    command error_t Send.send(message_t* msg, uint8_t len) {
        //MN: initilazing the packet to send based on the type ADDR (UNICAST or BROADCAST)
        MM_mac_header_msg_t* ptr_header = (MM_mac_header_msg_t*) call SubSend.getPayload( msg,  call SubSend.maxPayloadLength() );
        
        //if the node is already managing a packet - try again after backoff
        if ( mac_state_ != MT_MM_IDLE )
            return FAIL;
            
        if( call LPLControl.startContention() != SUCCESS )
            return FAIL;

        msg_data_ = msg;
        msg_data_len_ = len + sizeof( MM_mac_header_msg_t );
        
        ptr_header -> unique_id = call NodeControl.getUniqueID();
        ptr_header -> type = call AMPacket.type( msg_data_ );
                
        switch ( call AMPacket.destination( msg_data_ ) ) {
            case AM_BROADCAST_ADDR:
                mac_state_ = MT_MM_TX_DATA_BR;
                break;
            default:
                mac_state_ = MT_MM_TX_DATA_UNI;
                break;
        }
        
        post sendData();
        return SUCCESS;
    }
    
/**************************************************/
/****************** EVENT SECTION *****************/
/**************************************************/
    
    async event void SlotTimer.fired() {
    
        switch ( mac_state_ ) {
            case MT_MM_WAIT_SYNC:
                call Leds.led0Off();
                post endContentionReceiverFail();
                break;
                
            case MT_MM_WAIT_ACK_UNI:
            case MT_MM_WAIT_ACK_BR:
                call Leds.led1Off();
                endContentionSenderRetry_( E_ACK_LOST );
                break;
                
            case MT_MM_TX_ACK:
                call Leds.led1Off();
                post sendAck();        
                break;

            default:
                break;    
        }
    
    }
        
    event void SendAck.sendDone( message_t* msg, error_t error ) {
        if ( error == SUCCESS ) {
            post endContentionReceiverSuccess();
            return;
        }
        post endContentionReceiverFail();
    }
    
    //sync packet is only for broadcast transmission
    event void SendSync.sendDone( message_t* msg, error_t error ) {
        if ( error == SUCCESS ) {
            mac_state_ = MT_MM_WAIT_ACK_BR;
            call Leds.led1On();
            //node waits ack from any of its neighbors
            call SlotTimer.start( MM_GUARD_TIME + num_neigh_ * MM_SLOT_LENGTH );
            return;
        }
        endContentionSenderRetry_( E_TX_PROBLEM );
    }
    
    
    event void SubSend.sendDone(message_t* msg, error_t error) {

        if ( error == SUCCESS ) {
            call Leds.led0Off();
            //call Leds.led1On();
            mac_state_ = ( mac_state_ == MT_MM_TX_DATA_BR ) ? MT_MM_TX_SYNC : MT_MM_WAIT_ACK_UNI;
            //with unicast transmission node waits ack only from the destination
            if ( mac_state_ == MT_MM_WAIT_ACK_UNI ) {
                call SlotTimer.start( MM_SLOT_LENGTH );
                return;
            }
            call Leds.led1On();
            post sendSync();
            return;
        }
        endContentionSenderRetry_( E_TX_PROBLEM );
    }

    event message_t* ReceiveSync.receive(message_t* msg, void* payload, uint8_t len) {
        uint8_t my_slot;
        uint32_t slot_time;
        
        //nodes can participate in a contention at a time
        if ( call AMPacket.source( msg ) != sender_addr_ )
            return msg;
        
        if ( mac_state_ != MT_MM_WAIT_SYNC )
			return msg;
			
        mac_state_ = MT_MM_TX_ACK;
        //node gets the slot for its reply
        my_slot = getMySlot( call AMPacket.destination( msg ) );			
        slot_time = MM_GUARD_TIME + my_slot * MM_SLOT_LENGTH;
        call Leds.led0Off();
        call Leds.led1On();
        call SlotTimer.start( slot_time );
        
        return msg;
    }

    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
        uint32_t slot_time = 0;
        message_t * tmp;
        MM_mac_header_msg_t* ptr_header = (MM_mac_header_msg_t*) payload;
        
        //nodes still not joined to the network cannot participate 
        if ( ( mac_state_ != MT_MM_IDLE ) || ( joined_ == FALSE ) )
			return msg;
			
        //join packets are only for sink node
        if ( ptr_header -> type == AM_MM_JOIN_MSG ) {
            if ( call NodeControl.isSink() == FALSE )
                return msg;
        }
            
        if ( call LPLControl.enterContention() == SUCCESS ) {
            tmp = msg_recv_data_;
            msg_recv_data_ = msg;
            len_recv_data_ = len - sizeof( MM_mac_header_msg_t );
            payload_recv_data_ = payload + sizeof( MM_mac_header_msg_t );
        
            joining_node_ = ptr_header -> unique_id;
            sender_addr_ = call AMPacket.source( msg_recv_data_ );
            if ( call AMPacket.destination( msg_recv_data_ ) == AM_BROADCAST_ADDR ) {
                mac_state_ = MT_MM_WAIT_SYNC;
                slot_time = ((int32_t)( call LPLControl.getNodeSleepDuration() ) << 5);
                call Leds.led0On();
            } else {
                //for unicast packets the node immediately sends its ack
                mac_state_ = MT_MM_TX_ACK;
            }
            slot_time += MM_GUARD_TIME;
            call SlotTimer.start( slot_time );
            return tmp;
        }
        
        return msg;
    }
    
    event message_t* ReceiveAck.receive(message_t* msg, void* payload, uint8_t len) {
    
        MM_mac_ack_msg_t* ptr_ack = (MM_mac_ack_msg_t*) call SubPacket.getPayload( msg, sizeof( MM_mac_ack_msg_t ) );
                
        if ( call AMPacket.destination( msg ) != call NodeControl.getNodeAddress() )
            return msg;
                        
        switch ( mac_state_ ) {
            case MT_MM_WAIT_ACK_UNI:
                call Leds.led1Off();
                call Leds.led2On();
                call SlotTimer.stop();
                //check if the sender is requiring the node to remain awake
                if ( ptr_ack -> force_awake == 1 ) call LPLControl.forceAwake();
                post endContentionSenderSuccess();
                break;
                
            case MT_MM_WAIT_ACK_BR:
                //for broadcast packets the node should receive ack from any neighbors
                if ( allNodesReached( call AMPacket.source( msg ) ) == TRUE ) {
                    call Leds.led1Off();
                    call Leds.led2On();
                    call SlotTimer.stop();
                    resetNeighList();
                    //if the node is a joining node it must set its new address 
                    if ( ptr_ack -> node_id != call NodeControl.getNodeAddress() ) {
                        //MN: to check
                        if ( ptr_ack -> node_id == ( MM_MAX_NUM_NEIGH + 1) )  {
                            post endContentionSenderRetry();        
                            break;
                        }
                        call NodeControl.setMySink( call AMPacket.source( msg ) );
                        call NodeControl.setNodeAddress( TOS_AM_GROUP, ptr_ack -> node_id );
                        joined_ = TRUE;
                    }
                    post endContentionSenderSuccess();
                }    
                break;

            default:
                return msg;
                break;
        }

        return msg;
    }

/***************************************************/
/************ VOID EVENTS AND COMMAND **************/
/***************************************************/

    async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
        //node discovers a new neighbor
        num_neigh_ = neigh;
    }
    
    command error_t Send.cancel(message_t* msg) {
        call Packet.clear( msg );
		return SUCCESS;
    }
    
    command uint8_t Send.maxPayloadLength() {
        return call Packet.maxPayloadLength();
    }
    
    command void* Send.getPayload(message_t* msg, uint8_t len) {
        return call Packet.getPayload( msg, len );
    }
        
    async event void CCAControlData.requestInitialBackoff(message_t * ONE msg) {
        //MN: use the default value
        call CCAControlData.setInitialBackoff( 0 );
    }
    async event void CCAControlData.requestCongestionBackoff(message_t * ONE msg) {
        //MN: backoff is correctly managed by upper layer -> this way the node may continue to accept data
        //call CCAControlData.setCongestionBackoff( 31 );
        if ( msg == msg_data_ )
            post requiredBackoffData();
        
    }
    async event void CCAControlData.requestCca(message_t * ONE msg) {
        //Sending with default CCA
        call CCAControlData.setCca( TRUE );    
    }
    
    async event void CCAControlAck.requestInitialBackoff(message_t * ONE msg) {
        //MN: use the default value because the CCA has been disabled
        call CCAControlAck.setInitialBackoff( 0 );
    }
    
    async event void CCAControlAck.requestCongestionBackoff(message_t * ONE msg) {
        //MN: use the default value because the CCA has been disabled
        if ( msg == &msg_ack_ )
            post requiredBackoffAck();
    }
    
    async event void CCAControlAck.requestCca(message_t * ONE msg) {
        //Sending without CCA
        call CCAControlAck.setCca( FALSE );
    }
    
    async event void CCAControlSync.requestInitialBackoff(message_t * ONE msg) {
        //MN: use the default value because the CCA has been disabled
        call CCAControlSync.setInitialBackoff( 0 );
    }
    
    async event void CCAControlSync.requestCongestionBackoff(message_t * ONE msg) {
        //MN: use the default value because the CCA has been disabled
        if ( msg == &msg_sync_ )
           post requiredBackoffSync();
    }
    
    async event void CCAControlSync.requestCca(message_t * ONE msg) {
        //Sending without CCA
        call CCAControlSync.setCca( FALSE );
    }
    
    command void Packet.clear( message_t * msg ) {
        call SubPacket.clear( msg );
    }
    
    command uint8_t Packet.payloadLength( message_t * msg ) {
		return call SubPacket.payloadLength( msg ) - sizeof( MM_mac_header_msg_t );
    }

	command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
		call SubPacket.setPayloadLength( msg, len + sizeof( MM_mac_header_msg_t ) );
	}
		
	command uint8_t Packet.maxPayloadLength() {
		return call SubPacket.maxPayloadLength() - sizeof( MM_mac_header_msg_t );
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len) {
		if ( len > call Packet.maxPayloadLength() )
			return NULL;
		return call SubPacket.getPayload( msg, len + sizeof( MM_mac_header_msg_t ) ) + sizeof( MM_mac_header_msg_t );
	}
}
