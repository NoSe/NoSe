/**
 *
 * This module provides the Collector application implementation.
 * This application resides on top of the link layer. 
 * Packets are sent to and received from the link layer.
 * The collector sends collected metrics to sink and receives
 * programming commands. This module may switch over different
 * operating modes (RT - PER). The collected metrics can be stored in flash.
 * 
 */



#include "MoMoMsg.h"

module MoMoCollectorC {
    uses {
        interface Boot;
        interface SplitControl as SubControl;
        
        interface AMPacket;
        interface NodeControl;
        
        //radio control
        interface DutyCycleControl;
        interface LPLControl;

        //link layer interfaces
        interface Send as SubSend;
        interface Receive as SubReceive;
        
        interface Leds;
        
        //MN: add interface for using "user" button
        //timer for desync
        interface Timer<TMilli> as DeferTimer;
        interface Random;
        
        interface Timer<TMilli> as CollectingTimer;
        interface LocalTime<TMilli>;
        //interfaces for getting ADC informations
        interface SampleLogConfiguration;
        //interfaces for storing information in flash
        interface SampleLogRead<sensor_sample_t>;
        
        //packets extracted from flash are stored in queue before sending them
        interface Queue<sensor_sample_t> as SampleQueue;
    }
}

implementation {

    bool joined;                    //node already joined a given sink

    message_t msg_to_send_;         //buffer for the message to send
    uint8_t msg_to_send_len_;       //length of the message to send
    MM_ctrl_msg_t * ctrl_msg_;      //pointer to the control header
    MM_data_msg_t * data_msg_;      //pointer to the data header
      
    uint8_t task_to_post_;          //counter of pending tasks
    	
	message_t sample_msg;          //buffer for the sample message
	bool sendBusy = FALSE;         //if true the node is already sending a previous packet
	
	//MN: TO MODIFY
	uint16_t lpl_duty_;            //low power listening duty cycle value
	uint8_t metric_type_;          //send all packet or just an average
	
	//added buffer for these
	sensor_sample_t sample_;       //cointains infos about the acquired sample

/********** UTILITY FUNCTION ***********/
    
    task void readNextTask();
    
    void readNext() {
        error_t error = call SampleLogRead.readNext();
        if(error == FAIL)
            post readNextTask();
        else if(error == ECANCEL) {
            sendBusy = FALSE;
            //all packets have been taken from flash and sent over the network
            //call Leds.led1Toggle();
        }
    }
    
    inline void preparePktToSend() {
    
        //get a packet from queue
        sample_ = call SampleQueue.dequeue();
        //collector sends packets always to its sink
        call AMPacket.setDestination( &msg_to_send_, call NodeControl.getMySink() );
        call AMPacket.setType( &msg_to_send_, AM_MM_DATA_MSG );
        data_msg_ -> serial_ = call NodeControl.getUniqueID();
        data_msg_ -> pkt_num_ = sample_.sample_num;
        //if ( 1 ) {
        if ( metric_type_ == GET_ALL_SAMPLES ) {
            //send all the collected metrics
            data_msg_ -> sample_ = sample_.sensor_readings[call SampleLogConfiguration.getSensorSource()];
            data_msg_ -> age_ = call LocalTime.get() - sample_.time_stamp;
        } else {
            //MN: added this command - check
            //send just an average value of the collected metrics
            data_msg_ -> sample_ = call SampleLogConfiguration.getAverage();
            data_msg_ -> age_ = 0; 
        }
    }

/*********** TASK SECTION *************/

    task void readNextTask() { readNext(); }
	
	task void sendJoin() {

        //the node does not know the sinks address - the join message is sent in broadcast
        call AMPacket.setDestination( &msg_to_send_, AM_BROADCAST_ADDR );
        call AMPacket.setType( &msg_to_send_, AM_MM_JOIN_MSG );
        
        if( call SubSend.send( &msg_to_send_, sizeof( MM_join_msg_t ) ) != SUCCESS ) {
            post sendJoin();
            return;
        }
	}
    
    task void sendMsg() {
            
        preparePktToSend();
        
        if( call SubSend.send( &msg_to_send_, msg_to_send_len_ ) != SUCCESS ) {
            return;
        }
        
        //check if the are more similar tasks that need to be post
        atomic {
    		if ( task_to_post_ ) {
        		if ( post sendMsg() == SUCCESS ) {
                    task_to_post_ --;
                }
            }
        }        
    }
    
    //switch over different operating modes (RT or PER)
    task void switchMode() {
        
        if ( lpl_duty_ == PERIODIC ) {
            //try to trun off the node and turn on when a packet to send is ready
            call DutyCycleControl.stopRTMode();
            if ( call DutyCycleControl.turnNodeOff() == FAIL )
                post switchMode();
        } else {
            //change the value of low power listening duty cycle
            call LPLControl.setNodeDutyCycle( lpl_duty_ );
            //restart the low power listening with the new duty cycle value
            if ( call DutyCycleControl.startRTMode() == FAIL )
                post switchMode();
        }
    }
    
    task void getValues() {
    
        if ( metric_type_ == GET_ALL_SAMPLES ) {
            if(sendBusy == FALSE) {
                sendBusy = TRUE;
                readNext();//
            }
        } else {
            atomic {
                if ( post sendMsg() != SUCCESS ) {
                    task_to_post_ ++;
	           }
	       }
        }
    }
    
/********** BOOTING SECTION **************/
    
    event void Boot.booted() {
        
        joined = FALSE;
        metric_type_ = GET_ALL_SAMPLES;
        lpl_duty_ = MM_DUTY; //node is initially in RT mode with duty cycle MM_DUTY
        task_to_post_ = 0;
                
        //unique ID is the programming address
        call NodeControl.setUniqueID( call NodeControl.getNodeAddress() );
        
        //collector nodes have just the sink as neighbor
        call NodeControl.setNumNeigh( 1 );
        data_msg_ = (MM_data_msg_t*) call SubSend.getPayload( & msg_to_send_, sizeof( MM_data_msg_t ) );
        data_msg_ -> cmd_type_ = 0; //MN: define some command constants
        msg_to_send_len_ = sizeof( MM_data_msg_t );
        
        //start lower layers (link layer)
        call SubControl.start();
    }
    
    //Lower layers have been started
    event void SubControl.startDone(error_t error) {
        if( error != SUCCESS ) {
            call SubControl.start();
            return;
        }
        
        //send the join message after a random jitter
        call DeferTimer.startOneShot( call Random.rand16() % MM_MAX_JITTER );
    }
    
    event void SubControl.stopDone(error_t e) {}
    
/*********** SENDING AND RECEIVING SECTION ***************/
    
    event void SubSend.sendDone(message_t* msg, error_t error) {
        
        if ( error != SUCCESS ) {
        } else {
            //node successfully joined a new network
            if ( call AMPacket.type( msg ) == AM_MM_JOIN_MSG )
                joined = TRUE;
        }
    }
    
    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
        
        //still not joined nodes can not receive packets
        if ( joined == FALSE ) return msg;    
        ctrl_msg_ = (MM_ctrl_msg_t*) call SubSend.getPayload( msg, sizeof( MM_ctrl_msg_t ) );
        //MN: this value should be extracted by the received packet
        //call CollectingTimer.startPeriodic( MM_COLLECTING_TIME );
        if ( call CollectingTimer.isRunning() == TRUE ) 
                call CollectingTimer.stop();
        
        call CollectingTimer.startPeriodic( ctrl_msg_ -> collecting_p_ * 1024 );
        call SampleLogConfiguration.setSamplingPeriod( ctrl_msg_ -> sampling_p_ * 1024 );
        
        call SampleLogConfiguration.setSensorSource( ctrl_msg_ -> cmd_type_ );
        call SampleLogConfiguration.setAlarmThreshold( ctrl_msg_ -> threshold_ );
        
        metric_type_ = ctrl_msg_ -> version_;
        
        //if the node is required to send an average of the collected metrics
        //the storage may be disabled
        if ( metric_type_ == GET_AVERAGE )
            call SampleLogConfiguration.disableStorage();
        else call SampleLogConfiguration.enableStorage();    
            
        
        if ( lpl_duty_ != ctrl_msg_ -> lpl_duty_ ) {
            //if the node is already in the required mode
            //there is nothing to switch
            lpl_duty_ = ctrl_msg_ -> lpl_duty_;
            post switchMode();
        }
                
        return msg;
    }
    
/********** OTHER EVENTS SECTION ***********/
	
	async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
    }
        
    event void DutyCycleControl.nodeIsOn() {
        
        if ( lpl_duty_ == PERIODIC ) {
            //node is on then get the values and send them to the sink
            post getValues();
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
            if ( call DutyCycleControl.turnNodeOn() == FAIL ) {
                return;
            }
            return;
        } 
        
        //collecting timer fired then send the collected metrics
        post getValues();
        
    }
    
    event void SampleLogRead.readDone(sensor_sample_t* sample, error_t error) {
        if(error == SUCCESS) {
            call SampleQueue.enqueue(*(sample));
            //sample_ = *(sample);
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
