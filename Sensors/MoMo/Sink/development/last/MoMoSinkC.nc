#include "MoMoMsg.h"

module MoMoSinkC {
    uses {
        interface Boot;
        interface SplitControl as SubControl;

        interface Queue<message_t> as MsgQueue;
        interface Leds;
        
        interface AMPacket;
        interface NodeControl;

        interface Send as SubSend;
        interface Receive as SubReceive;
     
        interface Timer<TMilli> as PollingTimer;

        //MN: UART interfaces
        interface SplitControl as UartControl;
        interface AMSend as SendUart;
        interface Receive as ReceiveUart;
    }
}

implementation {

    bool serialSending;
    norace bool RTMode;
    
    message_t msg_to_send_;
    uint8_t msg_to_send_len_;
    
    MM_ctrl_msg_t * ctrl_msg_;
    message_t * recv_msg_;
    
    message_t uart_send_msg_;
    uart_send_msg_t * uart_send_;
    
    uint8_t task_to_post_;

/********** UTILITY FUNCTION ***********/

    inline void preparePktToSend( am_addr_t dest_addr ) {
    
        call AMPacket.setDestination( &msg_to_send_, dest_addr );
        call AMPacket.setType( &msg_to_send_, AM_MM_CTRL_MSG );
        ctrl_msg_ -> threshold_ = 0;
    }

/*********** TASK SECTION *************/

    task void startPolling() {
	   call PollingTimer.startOneShot( MM_POLLING_TIME ); 
    }

    task void sendUart() {
        MM_data_msg_t * data_msg_;
        data_msg_ = (MM_data_msg_t*) call SubSend.getPayload( recv_msg_, sizeof( MM_data_msg_t ) );
        uart_send_ -> source = call AMPacket.source( recv_msg_ );
        uart_send_ -> serial = data_msg_ -> serial_;
        uart_send_ -> sample = data_msg_ -> sample_;
        uart_send_ -> cmd_type = data_msg_ -> cmd_type_;
        uart_send_ -> pkt_num = data_msg_ -> pkt_num_;
    
		call SendUart.send( AM_BROADCAST_ADDR, & uart_send_msg_, sizeof( uart_send_msg_t ) );
	}
    
    task void sendMsg() {
            
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
    
/********** BOOTING SECTION **************/
    
    event void Boot.booted() {
        
        serialSending = FALSE;
        RTMode = TRUE;
        task_to_post_ = 0;

        call NodeControl.setUniqueID( call NodeControl.getNodeAddress() );
        
        call NodeControl.setSink();
        ctrl_msg_ = (MM_ctrl_msg_t*) call SubSend.getPayload( & msg_to_send_, sizeof( MM_ctrl_msg_t ) );
        msg_to_send_len_ = sizeof( MM_ctrl_msg_t );
        uart_send_ = (uart_send_msg_t*) call SendUart.getPayload( & uart_send_msg_, sizeof( uart_send_msg_t ) );
        
        preparePktToSend( AM_BROADCAST_ADDR );
        
        call SubControl.start();
        call UartControl.start();
    }
    
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
        
        if ( error != SUCCESS ) {
        } else {
        }    
    }
    
    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    
        if(call MsgQueue.empty() == FALSE || serialSending == TRUE)
            call MsgQueue.enqueue(*msg);
        else {
            recv_msg_ = msg;
            serialSending = TRUE;
            post sendUart();
        }
        
        return msg;
    }
    
/********** OTHER EVENTS SECTION ***********/

	async event void NodeControl.changedNumNeigh( uint8_t neigh ) {
	   if ( RTMode == TRUE )
	       post startPolling();
    }
    
/********** TIMER SECTION ************/

    event void PollingTimer.fired() {
        atomic {
    	   if ( post sendMsg() != SUCCESS ) {
	           task_to_post_ ++;
	       }
	   }
    }

/********** SERIAL SECTION ***********/

    event void SendUart.sendDone( message_t * msg, error_t error ) {
        if ( error != SUCCESS ) {
            post sendUart();
            return;
        }
        if(call MsgQueue.empty() == FALSE) {
            *recv_msg_ = call MsgQueue.dequeue();
            post sendUart();
        } else
            serialSending = FALSE;
    }
    
     event message_t* ReceiveUart.receive(message_t* msg, void* payload, uint8_t len) {
        //preparePktToSend( AM_BROADCAST_ADDR ); //MN: ricevuto con il pacchetto
        return msg;
     }
}
