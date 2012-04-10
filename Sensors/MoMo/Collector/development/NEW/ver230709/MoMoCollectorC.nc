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
        
        //MN: add interface for using "user" button
        interface Timer<TMilli> as DeferTimer;
        interface Random;
        
        interface Timer<TMilli> as CollectingTimer;
        interface LocalTime<TMilli>;
        //MN: interfaces for getting ADC informations
        interface SampleLogConfiguration;
        //MN: interfaces for storing information in flash
        interface SampleLogRead<sensor_sample_t>;
    }
}

implementation {

    message_t msg_to_send_;
    uint8_t msg_to_send_len_;
    MM_ctrl_msg_t * ctrl_msg_;
    MM_data_msg_t * data_msg_;
      
    uint8_t task_to_post_;
    	
	message_t sample_msg;
	bool sendBusy = FALSE;
	
	//MN: TO MODIFY
	uint16_t lpl_duty_;
	
	//MN: add buffer for these
	sensor_sample_t sample_;

/********** UTILITY FUNCTION ***********/

    
    task void readNextTask();
    task void shutdown();
    
    void readNext() {
        error_t error = call SampleLogRead.readNext();
        if(error == FAIL)
            post readNextTask();
        else if(error == ECANCEL) {
            sendBusy = FALSE;
            //post shutdown();
            //MN: all packets have been sent
            //call Leds.led1Toggle();
        }
    }
    
    inline void preparePktToSend() {
    
        call AMPacket.setDestination( &msg_to_send_, call NodeControl.getMySink() );
        call AMPacket.setType( &msg_to_send_, AM_MM_DATA_MSG );
        data_msg_ -> serial_ = call NodeControl.getUniqueID();
        data_msg_ -> pkt_num_ = sample_.sample_num;
        data_msg_ -> sample_ = sample_.sensor_readings[call SampleLogConfiguration.getSensorSource()];
        data_msg_ -> age_ = call LocalTime.get() - sample_.time_stamp;
    }

/*********** TASK SECTION *************/

    task void readNextTask() { readNext(); }
	
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
        }
        
        atomic {
    		if ( task_to_post_ ) {
        		if ( post sendMsg() == SUCCESS ) {
                    task_to_post_ --;
                }
            }
        }        
    }
    
    task void switchMode() {
        
        if ( lpl_duty_ == PERIODIC ) {
            call DutyCycleControl.stopRTMode();
            call DutyCycleControl.turnNodeOff();
        }   
    }
    
    task void shutdown() {
    
        if ( lpl_duty_ == PERIODIC ) {
            if ( sendBusy == FALSE ) {
                atomic {
                    if ( task_to_post_ == 0 )
                        if ( call DutyCycleControl.turnNodeOff() == SUCCESS )
                            return;
                    post shutdown();
                }
            }
        }
    }
    
/********** BOOTING SECTION **************/
    
    event void Boot.booted() {
        
        task_to_post_ = 0;
                
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
        
        call DeferTimer.startOneShot( call Random.rand16() % MM_MAX_JITTER );
    }
    
    event void SubControl.stopDone(error_t e) {}
    
/*********** SENDING AND RECEIVING SECTION ***************/
    
    event void SubSend.sendDone(message_t* msg, error_t error) {
        
        if ( error != SUCCESS ) {
        } else {
            post shutdown();
        }
    }
    
    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
        
        ctrl_msg_ = (MM_ctrl_msg_t*) call SubSend.getPayload( msg, sizeof( MM_ctrl_msg_t ) );
        //MN: this value should be extracted by the received packet
        //call CollectingTimer.startPeriodic( MM_COLLECTING_TIME );
        call CollectingTimer.startPeriodic( ctrl_msg_ -> collecting_p_ * 1024 );
        call SampleLogConfiguration.setSamplingPeriod( ctrl_msg_ -> sampling_p_ * 1024 );
        
        call SampleLogConfiguration.setSensorSource( ctrl_msg_ -> cmd_type_ );
        
        lpl_duty_ = ctrl_msg_ -> lpl_duty_;
        
        post switchMode();
                
        return msg;
    }
    
/********** OTHER EVENTS SECTION ***********/
	
	async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
    }
        
    event void DutyCycleControl.nodeIsOn() {
    
        if ( lpl_duty_ == PERIODIC ) {
            if(sendBusy == FALSE) {
                sendBusy = TRUE;
                readNext();//
            }
        }
    }
    
    event void DutyCycleControl.nodeIsOff() {
    }
    
/********** TIMER SECTION ************/

    event void DeferTimer.fired() {
        post sendJoin(); //MN: to substitute with user button interface
    }

    event void CollectingTimer.fired() {
    
        if ( lpl_duty_ == PERIODIC ) {
            if ( call DutyCycleControl.turnNodeOn() == SUCCESS )
                return;
        /*
            else {
                if(sendBusy == FALSE) {
                   sendBusy = TRUE;
                   post readNextTask();//
                   return;
                }
            }
        */
        }
        
        if(sendBusy == FALSE) {
            sendBusy = TRUE;
            readNext();//
        }
    }
    
    event void SampleLogRead.readDone(sensor_sample_t* sample, error_t error) {
        if(error == SUCCESS) {
            sample_ = *(sample);
            atomic {
    	       if ( post sendMsg() != SUCCESS ) {
	               task_to_post_ ++;
	           }
	        }
	        if ( sendBusy == TRUE ) post readNextTask();
        } else post readNextTask();
  }
  
    event void SampleLogConfiguration.alarm(sensor_sample_t* sample) {
    //event void SampleLogConfiguration.alarm() {

        //MN: TO CHECK
        sample_ = *(sample);
        atomic {
    	   if ( post sendMsg() != SUCCESS ) {
	           task_to_post_ ++;
	       }
	   }
    }
}
