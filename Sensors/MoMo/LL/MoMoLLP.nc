/**
 *
 * This module provides the link layer implementation.
 * Link layer receive packets from the application and send them
 * to the MAC layer for forwarding them to the next hop.
 * Otherwise it sends to the application the packets receive by
 * the MAC layer coming from other nodes. A queue for storing packets
 * is implemented.
 * 
 */

#include "MoMoLLconst.h"


module MoMoLLP {
    provides {
        interface SplitControl; //MN: this should be in charge to start lower layer
        interface Send;
        interface Receive; 
    }
    
    uses {
        interface Boot;
        interface Leds;
        
        interface MoMoQueue<momo_queue_info_t> as Queue;
        interface Pool<message_t> as MessageCache;
        
        interface NodeControl;
        interface Random;
        interface AMPacket;
        
        interface Send as SubSend;
        interface Receive as SubReceive;
        interface SplitControl as SubControl;
        interface Timer<TMilli> as Backoff;
    }
}

implementation {

    uint8_t state_;                      // Link Layer State.
    momo_queue_info_t current_packet_;   // Current queue item
    
    task void queueNotEmpty();						// Notify that queue is not empty
	task void sendNextPacket();						// Send next packet in queue
	task void terminateSend();						// Terminate to send a packet
	task void terminateSendBackoff();				// Terminate to send a packet with a backoff
    
    //Initialize this module
    event void Boot.booted() {
		state_ = LL_STOPPED;
    }

    //Start this module and lower layers
    command error_t SplitControl.start() {
        if ( state_ != LL_STOPPED )
			return FAIL;        
        return call SubControl.start();
    }

    //Stop this module and lower layers
    command error_t SplitControl.stop() {
        if ( state_ != LL_IDLE )
			return FAIL;
		state_ = LL_STOPPING;
        call SubControl.stop();
        return SUCCESS;
    }

    //Lower layers has been started
    event void SubControl.startDone( error_t result ) {
       state_ = LL_IDLE;
	   signal SplitControl.startDone( result );
    }

    //Lower layers has been stopped
    event void SubControl.stopDone( error_t result ) {
        signal SplitControl.stopDone( result );
    }

/***** UTILITY FUNCTIONS AND TASKS ******/

	task void queueNotEmpty();  //get the next packet to send from queue
    task void sendNextPacket(); //tries to send the packet to lover (MAC) layer
    task void terminateSend();  //previous transmission ended - check next packet to send immediately
    task void terminateSendBackoff(); //previous transmission ended - check next packet to send after backoff period
	
	void _error_( uint8_t v ) {
		call Leds.set( v );
		for (;;) {}
	}

    //Upper layer (Application) sending result notification
    void sendDone( message_t * msg, error_t error ) {
        //return the message to the cache
        call MessageCache.put( msg );
        signal Send.sendDone( msg, error );
    }
    
    task void queueNotEmpty() {
		if ( state_ != LL_IDLE ) {			
			return;
		}
		post sendNextPacket();
    }
    
    task void sendNextPacket() {
	
		// If node is stopping: stop and notify it
		if ( state_ == LL_STOPPING ) {
			state_ = LL_STOPPED;
			call SubControl.stop();
			return;
		}

		// If queue is empty, return
		if ( call Queue.empty() == TRUE )
			return;

		// Node must be IDLE
		if ( state_ != LL_IDLE )
			return;

		// Put node in sending state.
		state_ = LL_SENDING;

		// Get packet from queue
		current_packet_ = call Queue.popBottom();
		
		// Send the packet
		if ( call SubSend.send( current_packet_.msg, current_packet_.len ) == SUCCESS )
			return;
		
		// Problem with transmission: insert message in queue again.
		if ( call Queue.pushTop( current_packet_ ) != SUCCESS ) {
			sendDone( current_packet_.msg, E_QUEUE_FULL );
			post terminateSend();
			return;
		}
		
		//Schedule a later transmission attempt after the backoff period
		post terminateSendBackoff();
		
	}
	
	task void terminateSend() {
		if ( state_ != LL_SENDING )
			return;
		state_ = LL_IDLE;
		post sendNextPacket();
	}
	
	task void terminateSendBackoff() {
	    uint16_t backoff_time;
		if ( state_ != LL_SENDING )
			return;
		state_ = LL_BACKOFF;
		//call Backoff.startOneShot( call Random.rand16() % 1024 );
        if( call NodeControl.isSink() == TRUE ) {
    		backoff_time = call Random.rand16() % BACKOFF_LL_SINK;
        } else {
            backoff_time = call Random.rand16() % BACKOFF_LL_NODE;
        }
        call Backoff.startOneShot( backoff_time );
	}
        
    event void Backoff.fired() {
        if ( state_ != LL_BACKOFF )
			return;
		state_ = LL_IDLE;
		post sendNextPacket();
    }


/***** UPPER LAYER SENDING FUNCTIONS ******/

    command error_t Send.send(message_t* msg, uint8_t len) {
    
        error_t result;
        momo_queue_info_t info;             // Queue entry used to push packet in the queue
        message_t *	new_msg;		        // Message allocated from Cache.
        
        /*
        switch ( type ) {
            case AM_MM_DATA_MSG :
                //MN: set the carrier sense length for implementing priority sending
                break;
        
            case AM_MM_CTRL_MSG :
                //MN: set a different carrier sense length         
                break;
            default :
                return FAIL;
                break;
        }
        */
        
        // Allocate a free packet for upper layer.
        new_msg = call MessageCache.get();
        
        // Packet cannot be accepted.
        if ( new_msg == NULL )
            return FAIL;
        
        // Copy packet.
        memcpy( new_msg, msg, sizeof( message_t ) );
        
        // Load queue item
        info.len = len;
        info.num_fail = 0;
        info.msg = new_msg;
        
        // Enqueue the packet
        result = call Queue.pushTop( info ); 
    
        if( result == SUCCESS ) {
            post queueNotEmpty();
        } else {
            call MessageCache.put( new_msg );
        }
        
        return result;
    
    }
    
    command error_t Send.cancel(message_t* msg) {
        return call SubSend.cancel( msg );
    }
    
    command error_t Send.maxPayloadLength() {
        return call SubSend.maxPayloadLength();
    }
    
    command void* Send.getPayload(message_t* msg, uint8_t len) {
        return call SubSend.getPayload( msg, len );
    }
        
    default event void Send.sendDone( message_t* msg, error_t error ) {} 
    
/****** LOWER LAYER SENDING FUNCTIONS ******/

    //MAC layer sending result notification
    event void SubSend.sendDone(message_t* msg, error_t error) {
        
        //Previous packet was sent successfully - next packet required immediately
        if ( error == E_SENDING_BURST ) {
			sendDone( msg, SUCCESS );
			return;
		}
        
        //Previous packet was sent successfully - if available next packet will be sent after a backoff period
        if( error == SUCCESS ) {
            sendDone( msg, SUCCESS );
            //post terminateSend(); //MN: original
            post terminateSendBackoff();
            return;
        }
        
        //Transmission attempt failed
        current_packet_.num_fail = current_packet_.num_fail + 1;
        
#ifdef USE_MM_MAX_RETRY
        //Drop the packet if the max number of attempts exceeded
        if (current_packet_.num_fail >= MM_MAX_RETRY ) {
            //Notify to upper layer
            sendDone( msg, E_MAX_RETRY_DATA );
            //Check next packet to send
            post terminateSend();
            return;
        }
#endif
          
        // Enqueue packet again.
		if ( call Queue.pushBottom( current_packet_ ) == SUCCESS ) {
		    //Next transmission attempt after a backoff period
			post terminateSendBackoff();
			return;
		}
        
        sendDone( msg, E_QUEUE_FULL );
        //Packet has been dropped (queue is full) - check for the next packet to send
		post terminateSend();
		//post terminateSendBackoff();
		
    
    }
        
    //Packet received from lower (MAC) layer
    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
        momo_queue_info_t info;     // Queue entry used to push packet in the queue
        message_t *	new_msg;		// Message allocated from Cache.
       
        //MN: TO CHECK HERE
        //Return to the lower layer the buffer provided from upper layer
        //Upper layer should have a buffer to store the information before storing in the flash (no message cache)
        if( call NodeControl.isSink() == TRUE ) {
            return signal Receive.receive( msg, payload, len );
        } else {
            if ( call AMPacket.isForMe( msg ) )
                return signal Receive.receive( msg, payload, len );

            //This packet must be enqueued before forwarding
            // Allocate a packet to forward the message.
            new_msg = call MessageCache.get();
            
            //Cache is full - packet drop
            if ( new_msg == NULL ) {
                return msg;
            }
        
            // Copy packet.
            memcpy( new_msg, msg, sizeof( message_t ) );
            
            // Enqueue the packet.
            info.len = len;
            info.num_fail = 0;
            info.msg = new_msg;
            
            if ( call Queue.pushTop( info ) == SUCCESS ) {
				post queueNotEmpty();
            } else {					
				call MessageCache.put( new_msg );
            }
            
            return msg;
        
        }   
    }
    
    /*
    default event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len ) {
		return msg;
	}
	*/
	
	async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
    }
}
