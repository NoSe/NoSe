#include "MoMoMsg.h"

module MoMoCollectorC {
    uses {
        interface Boot;
        interface SplitControl as SubControl;
        
        interface AMPacket;
        interface NodeControl;
        interface DutyCycleControl;

        interface Send as SubSend;
        interface Receive as SubReceive;
        
        interface Leds;
        interface Timer<TMilli> as CollectingTimer;
        //MN: add interface for using "user" button
        
        //MN: interfaces for getting ADC informations
        interface Read<uint16_t> as TempRead;
        interface Timer<TMilli> as SamplingTimer;
        
    }
}

implementation {

    message_t msg_to_send_;
    uint8_t msg_to_send_len_;
    MM_ctrl_msg_t * ctrl_msg_;
    MM_data_msg_t * data_msg_;
      
    uint8_t task_to_post_;
    uint16_t cont_;
    
	uint32_t num_samples_;
	uint32_t sample_value_;

/********** UTILITY FUNCTION ***********/

    inline void preparePktToSend() {
    
        call AMPacket.setDestination( &msg_to_send_, call NodeControl.getMySink() );
        call AMPacket.setType( &msg_to_send_, AM_MM_DATA_MSG );
        data_msg_ -> serial_ = call NodeControl.getUniqueID();
        data_msg_ -> pkt_num_ = cont_;
        atomic {
            data_msg_ -> sample_ = ( sample_value_ ) ? (uint16_t)( sample_value_ / num_samples_ ) : 0;
            sample_value_ = 0;
            num_samples_ = 0;
        }
    }

/*********** TASK SECTION *************/
	
	task void sendJoin() {

        call AMPacket.setDestination( &msg_to_send_, AM_BROADCAST_ADDR );
        call AMPacket.setType( &msg_to_send_, AM_MM_JOIN_MSG );
        
        if( call SubSend.send( &msg_to_send_, sizeof( MM_join_msg_t ) ) != SUCCESS ) {
            return;
        }
	}
    
    task void sendMsg() {
            
        preparePktToSend();
        
        if( call SubSend.send( &msg_to_send_, msg_to_send_len_ ) != SUCCESS ) {
            return;
        } else {
            cont_ ++;
        }
        
        atomic {
    		if ( task_to_post_ ) {
        		if ( post sendMsg() == SUCCESS ) {
                    task_to_post_ --;
                }
            }
        }
            
    }
    
/********** BOOTING SECTION **************/
    
    event void Boot.booted() {
        
        task_to_post_ = 0;
        cont_ = 0;
        
        num_samples_ = 0;
        sample_value_ = 0;
        
        call NodeControl.setUniqueID( call NodeControl.getNodeAddress() );
        
        call NodeControl.setNumNeigh( 1 );
        data_msg_ = (MM_data_msg_t*) call SubSend.getPayload( & msg_to_send_, sizeof( MM_data_msg_t ) );
        data_msg_ -> cmd_type_ = 0; //MN: define some command constants
        msg_to_send_len_ = sizeof( MM_data_msg_t );
        
        call SubControl.start();
    }
    
    event void SubControl.startDone(error_t error) {
        if( error != SUCCESS ) {
            call SubControl.start();
            return;
        }
        
        //MN: use a default SENSING_TIME
        call SamplingTimer.startPeriodic( MM_SENSING_TIME );
        post sendJoin(); //MN: to substitute with user button interface
    }
    
    event void SubControl.stopDone(error_t e) {}
    
/*********** SENDING AND RECEIVING SECTION ***************/
    
    event void SubSend.sendDone(message_t* msg, error_t error) {
        
        if ( error != SUCCESS ) {
        } else {
        }
        
    }
    
    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
        uint16_t value;
        
        ctrl_msg_ = (MM_ctrl_msg_t*) call SubSend.getPayload( msg, sizeof( MM_ctrl_msg_t ) );
        value = ctrl_msg_ -> threshold_;
        //MN: this value should be extracted by the received packet
        call CollectingTimer.startPeriodic( MM_COLLECTING_TIME );
        
        //call Leds.set( value );
        
        return msg;
    }
    
/********** OTHER EVENTS SECTION ***********/

    event void TempRead.readDone(error_t result, uint16_t data) {
    	atomic {
	   	   if ( result == SUCCESS ) {
    			num_samples_ ++;
                sample_value_ += (uint32_t) data;
           }
		}
	}
	
	async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
    }
        
    event void DutyCycleControl.nodeIsOn() {
    }
    
    event void DutyCycleControl.nodeIsOff() {
    }
    
/********** TIMER SECTION ************/

    event void SamplingTimer.fired() {
        call TempRead.read();
    }

    event void CollectingTimer.fired() {
        atomic {
    	   if ( post sendMsg() != SUCCESS ) {
	           task_to_post_ ++;
	       }
	   }
    }
}
