/**
 *
 * This module provides the Sink application implementation.
 * This application resides on top of the link layer. 
 * Packets are sent to and received from the link layer.
 * The sink sends programming packets to its neighbors and receives
 * back the collected metrics. The packets the sink receives
 * from its neighbors are sent to the UART.
 * 
 */


#include "MoMoMsg.h"

module MoMoSinkC {
    uses {
        interface Boot;
        interface SplitControl as SubControl;

        interface Leds;
        
        interface AMPacket;
        interface NodeControl;

        //Link Layer communications
        interface Send as SubSend;
        interface Receive as SubReceive;
     
        //Timer for neighbors programming
        interface Timer<TMilli> as PollingTimer;

        //UART interfaces
        interface SplitControl as UartControl;
        interface AMSend as SendUart;
        interface Receive as ReceiveUart;
        
        interface ForceAwake;
        
        //Queue for UART messages
        interface Queue<message_t> as MsgQueue;
        
    }
}

implementation {

    bool serialSending;                 //node is already sending messages over the UART
    norace bool RTMode;                 //sink neighbors operating mode
                                        //true if the neighbors are using low power listening
    
    message_t msg_to_send_;             //buffer for the message to send
    uint8_t msg_to_send_len_;           //length of the message to send
    
    MM_ctrl_msg_t * ctrl_msg_;          //pointer to the control header of the message
    message_t * recv_msg_;              //pointer to the received message
    
    message_t uart_send_msg_;           //buffer for the message sent over the UART
    uart_send_msg_t * uart_send_;       //point to the uart header of the message
    
    bool uart_recv;                     //a packet has been received from the UART
    MM_ctrl_msg_t * uart_recv_;         //pointer to the control header of the message received from the UART
    
    uint8_t task_to_post_;              //counter of pending tasks
    
    norace uint8_t num_neigh_;                 //current sink number of the neighbors 
    
/********** UTILITY FUNCTION ***********/

    //prepare the header of the control message
    inline void preparePktToSend( am_addr_t dest_addr ) {
    
        //in PERIODIC mode packets are sent to a given destionation - otherwise they are sent in broadcast
        call AMPacket.setDestination( &msg_to_send_, dest_addr );
        call AMPacket.setType( &msg_to_send_, AM_MM_CTRL_MSG );
        if ( uart_recv == FALSE ) {
            //use the default control parameters
            ctrl_msg_ -> version_ = GET_ALL_SAMPLES;
            ctrl_msg_ -> threshold_ = MM_DEF_THR;
            //ctrl_msg_ -> lpl_duty_ = PERIODIC;
            ctrl_msg_ -> lpl_duty_ = MM_DUTY;
            ctrl_msg_ -> cmd_type_ = MM_GET_FROM_SENSOR;
            ctrl_msg_ -> sampling_p_ = MM_SAMPLING_TIME;
            ctrl_msg_ -> collecting_p_ = MM_COLLECTING_TIME;
        } else {
            //use the control parameters received from the UART
            ctrl_msg_ -> version_ = uart_recv_ -> version_;
            ctrl_msg_ -> threshold_ = uart_recv_ -> threshold_ ;
            ctrl_msg_ -> lpl_duty_ = uart_recv_ -> lpl_duty_;
            ctrl_msg_ -> cmd_type_ = uart_recv_ -> cmd_type_;
            ctrl_msg_ -> sampling_p_ = uart_recv_ -> sampling_p_;
            ctrl_msg_ -> collecting_p_ = uart_recv_ -> collecting_p_;
        }
    }

/*********** TASK SECTION *************/

    //send control message to the neighbors
    task void startPolling() {
        if ( call PollingTimer.isRunning() == FALSE )
            call PollingTimer.startOneShot( MM_POLLING_TIME * 1024 ); 
    }

    //prepare the UART message using the received message
    task void sendUart() {
        MM_data_msg_t * data_msg_;
        data_msg_ = (MM_data_msg_t*) call SubSend.getPayload( recv_msg_, sizeof( MM_data_msg_t ) );
        uart_send_ -> source = call AMPacket.source( recv_msg_ );
        uart_send_ -> serial = data_msg_ -> serial_;
        uart_send_ -> sample = data_msg_ -> sample_;
        uart_send_ -> cmd_type = data_msg_ -> cmd_type_;
        uart_send_ -> pkt_num = data_msg_ -> pkt_num_;
        uart_send_ -> age = data_msg_ -> age_;
    
		call SendUart.send( AM_BROADCAST_ADDR, & uart_send_msg_, sizeof( uart_send_msg_t ) );
	}
    
    //send the message to the network
    task void sendMsg() {
            
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
    
/********** BOOTING SECTION **************/
    
    event void Boot.booted() {
        
        //default initializations
        serialSending = FALSE;
        RTMode = TRUE;
        uart_recv = FALSE;
        task_to_post_ = 0;

        //unique ID is the programming address
        call NodeControl.setUniqueID( call NodeControl.getNodeAddress() );
        
        //this node is the sink
        call NodeControl.setSink();
        ctrl_msg_ = (MM_ctrl_msg_t*) call SubSend.getPayload( & msg_to_send_, sizeof( MM_ctrl_msg_t ) );
        msg_to_send_len_ = sizeof( MM_ctrl_msg_t );
        uart_send_ = (uart_send_msg_t*) call SendUart.getPayload( & uart_send_msg_, sizeof( uart_send_msg_t ) );
        
        preparePktToSend( AM_BROADCAST_ADDR );
        
        //start lower layers (link layer)
        call SubControl.start();
        //start the UART module
        call UartControl.start();
    }
    
    //Lower layers have been started
    event void SubControl.startDone(error_t error) {
        if( error != SUCCESS ) {
            call SubControl.start();
            return;
        }
    }
    
    event void SubControl.stopDone(error_t e) {}
    
    event void UartControl.startDone( error_t result ) {}
    event void UartControl.stopDone( error_t result ) {}
    
/*********** SENDING AND RECEIVING SECTION ***************/
    
    event void SubSend.sendDone(message_t* msg, error_t error) {
    
        MM_ctrl_msg_t * recv_ctrl = (MM_ctrl_msg_t*) call SubSend.getPayload( msg, sizeof( MM_ctrl_msg_t ) );
        
        if ( error != SUCCESS ) {
        } else {
            //check if the node that needs to remain awake has been successfully advised
            if ( recv_ctrl -> lpl_duty_ != PERIODIC ) {
                //update the neighbors duty cycle (maybe it can be move down)
                call ForceAwake.setNeighborsDuty( recv_ctrl -> lpl_duty_ );
                if ( RTMode == TRUE ) return;
                //if the given node is back in RT mode, it does not need to remain awake  
                if ( call ForceAwake.checkNeighbors( call AMPacket.destination( msg ) ) == 1 ) {
                    call ForceAwake.resetNeighbors( call AMPacket.destination( msg ) );
                    call ForceAwake.setNeighborsMode( RT_MODE, call AMPacket.destination( msg ) );
                    //check if all the nodes are back in RT mode
                    //if it is the case the network working mode may be switched to RT
                    if ( call ForceAwake.checkAllNeighbors( num_neigh_ ) == FALSE )
                        RTMode = TRUE;
                }
            }   
        }
    }
    
    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {

        //enque the received message if the sink node is sending a previous packet over the UART 
        //otherwise send it immediately
        if(call MsgQueue.empty() == FALSE || serialSending == TRUE)
            call MsgQueue.enqueue(*msg);
        else {
            recv_msg_ = msg;
            serialSending = TRUE;
            post sendUart();
        }
        
        //in PERIODIC mode the program messages must be sent at the end of each contention
        if ( RTMode == FALSE ) {
            if ( uart_recv == TRUE ) {
                //check if the given node is waiting awake for a transmission from the sink
                if ( call ForceAwake.checkNeighbors( call AMPacket.source( msg ) ) == 1 ) {
                    preparePktToSend( call AMPacket.source( msg ) );
                    atomic {                    
                        if ( post sendMsg() != SUCCESS ) {
                            task_to_post_ ++;
                        }
                    }
                }
            }
        }
        
        return msg;
    }
    
/********** OTHER EVENTS SECTION ***********/

    //a new neighbor joined the network - it needs to be programmed
	async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
	   num_neigh_ = neigh;
	   if ( RTMode == TRUE )
	       post startPolling();
    }
    
/********** TIMER SECTION ************/

    event void PollingTimer.fired() {
        if ( ctrl_msg_ -> lpl_duty_ == PERIODIC ) {
            RTMode = FALSE;
            //set the neighbors mode to PERIODIC
            call ForceAwake.setAllNeighborsMode( PER_MODE );
        }
        atomic {
    	   if ( post sendMsg() != SUCCESS ) {
	           task_to_post_ ++;
	       }
	   }
    }

/********** UART SECTION ***********/

    event void SendUart.sendDone( message_t * msg, error_t error ) {
        if ( error != SUCCESS ) {
            post sendUart();
            return;
        }
        //the previous packet has been sent correctly - the node continues to send the others
        if(call MsgQueue.empty() == FALSE) {
            *recv_msg_ = call MsgQueue.dequeue();
            post sendUart();
        } else
            serialSending = FALSE;
    }
    
    event message_t* ReceiveUart.receive(message_t* msg, void* payload, uint8_t len) {
        uart_recv_ = payload;
        if ( uart_recv_ -> cmd_type_ == MM_FORCE_AWAKE ) {
            //this packet is not a network programming packet
            uart_recv = FALSE;
            //require to a given node to remain awake
            if ( uart_recv_ -> version_ == 0 ) { 
                //require all the nodes to stay awake at the end of each transmission
                call ForceAwake.setAllNeighbors( num_neigh_ );
            } else call ForceAwake.setNeighbors( uart_recv_ -> version_ );
        } else {
            //control message has been received from the UART - use it to program the neighbors
            uart_recv = TRUE;
            if ( RTMode == TRUE ) {
                //polling is required only if the nodes are working in RT mode
                preparePktToSend( AM_BROADCAST_ADDR );
                post startPolling();
            }
        }
        return msg;
     }
}
