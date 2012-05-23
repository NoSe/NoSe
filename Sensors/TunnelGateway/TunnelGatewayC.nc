
#include "TunnelMote.h"

#include "CC2420.h"
#include "message.h"
#include <UserButton.h>

module TunnelGatewayC {
	uses {
		interface Boot;
		interface Leds;
		interface Random;
		interface SplitControl as RadioControl;
		interface Timer<TMilli> as HelloTimer;
		interface Timer<TMilli> as NeighborsDiscoveryTimer;
		interface Timer<TMilli> as NeighborsCleanupTimer;
		interface Timer<TMilli> as DownloadDataPauseTimer;

		interface ActiveMessageAddress;
		interface CC2420PacketBody;
		interface CC2420Config;
		interface Receive as ReceiveHelloRequest;
		interface AMSend as SendHelloResponse;
		interface AMSend as SendHelloRequest;
		interface Receive as ReceiveHelloResponse;

		// Serial connection
		interface SplitControl as SerialControl;
		interface AMPacket as SerialAMPacket;
		interface Receive as ReceiveSerial;
		interface AMSend as SendNeighborsSerial;

		/* Button interface */
		interface Get<button_state_t>;
		interface Notify<button_state_t>;

		// Sense and cache
		interface SenseAndCache<uint16_t>;

		// Time synchronization
	        interface GlobalTime<TMilli>;
	        interface TimeSyncInfo;

	}
}
implementation {
	
	uint16_t	neighbors[MAX_NEIGHBORS_NUM];
	state_t  	state;
	uint16_t 	hello_source_id;
	message_t	radio_msg;
	uint16_t	jitter;
	command_msg_t*	command_message;
	message_t	uart_msg;

	//------------------------
	// Neihgbors
	//------------------------
	void clearNeighbors() {
		uint8_t i;
		for ( i = 0; i < MAX_NEIGHBORS_NUM; i ++ )
			neighbors[i] = 0xFFFF;
	}

	bool addNeighbor(uint16_t node) {
		uint8_t i;
		uint8_t free_index = 0xFF;
		for ( i = 0; i < MAX_NEIGHBORS_NUM; i ++ ) {
			if ( neighbors[i] == node )
				return TRUE;
			if ( neighbors[i] == 0xFFFF )
				free_index = i;
		}
		if ( free_index != 0xFF ) {
			neighbors[free_index] = node;
			return TRUE;
		}
		return FALSE;
	}

	uint8_t getNeighborsCount() {
		uint8_t i;
		uint8_t count = 0;
		for ( i = 0; i < MAX_NEIGHBORS_NUM; i ++ ) {
			if ( neighbors[i] != 0xFFFF )
				count ++;
		}
		return count;
	}

	task void sendHelloRequest() {
		call SendHelloRequest.send( AM_BROADCAST_ADDR, & radio_msg, 0 );
	}

	event void Boot.booted() {
		state = STATE_IDLE;
	    	call Notify.enable();
		call RadioControl.start();
		call SerialControl.start();
#ifdef IS_GATEWAY
		clearNeighbors();
		call NeighborsDiscoveryTimer.startPeriodic((uint32_t)( 1024 * NEIGHBORS_DISCOVERY_TIME_S ));
		call NeighborsCleanupTimer.startPeriodic((uint32_t)( (uint32_t) 1024 * (uint32_t) NEIGHBORS_DISCOVERY_CLENUP_S ));
#endif
	}

	task void sendHelloResponse() {
		call SendHelloResponse.send( hello_source_id, & radio_msg, 0 );
		call Leds.led0Off();
		call Leds.led1Off();
		state  = STATE_IDLE;
	}

	task void sendNeighborsSerial() {
		uint8_t i;
		uint8_t c;
		neighbors_msg_t * payload;
		payload = (neighbors_msg_t*) uart_msg.data;
		c = 0;
		for ( i = 0; i < MAX_NEIGHBORS_NUM; i ++ ) {
			if ( neighbors[i] != 0xFFFF )
				(payload->node)[c ++] = neighbors[i];
		}
		payload->length = c;
		call SendNeighborsSerial.send( AM_BROADCAST_ADDR, & uart_msg, sizeof(neighbors_msg_t) );
	}

	event message_t * ReceiveHelloRequest.receive( message_t * msg, void * payload, uint8_t len ) {
#ifndef IS_GATEWAY
		if ( state == STATE_IDLE ) {
			call Leds.led0On();
			state = STATE_HELLO;
			hello_source_id = ( call CC2420PacketBody.getHeader( msg )) -> src;
			jitter = call Random.rand16() % ( 1024 * HELLO_JITTER_S );
			call HelloTimer.startOneShot(jitter);
		}
#endif
		return msg;
	}

	event message_t * ReceiveHelloResponse.receive( message_t * msg, void * payload, uint8_t len ) {
#ifdef IS_GATEWAY
		addNeighbor(( call CC2420PacketBody.getHeader( msg )) -> src);
		call Leds.set(getNeighborsCount());
		post sendNeighborsSerial();
#endif
		return msg;
	}
    
	event void HelloTimer.fired() {
		call Leds.led1On();
		post sendHelloResponse();
	}

	event void SendHelloResponse.sendDone( message_t * msg, error_t result ) {
		if ( result != SUCCESS ) {
			post sendHelloResponse();
		}
	}

    	event void Notify.notify( button_state_t button_state ) {
        	if ( button_state == BUTTON_PRESSED ) {
			call SenseAndCache.erase();
        	} else if ( button_state == BUTTON_RELEASED ) {

            	}
        }

	event message_t * ReceiveSerial.receive( message_t * msg, void * payload, uint8_t len ) {
		/*
		command_message = payload;
		call Leds.set( 7 );
		if ( command_message->type == 10 ) {
			post sendHelloRequest();
		}
		*/
		return msg;
	}

	// Clean the neighbors list
	event void NeighborsCleanupTimer.fired() {
		clearNeighbors();
	}
	
	event void NeighborsDiscoveryTimer.fired() {
		post sendHelloRequest();
	}	

	event void DownloadDataPauseTimer.fired() {
	}

	// Data pushing

	event void SenseAndCache.eraseDone(error_t err) {
		call Leds.set(7);
	}

	event void RadioControl.startDone( error_t result ) {
		if ( result == SUCCESS ) {
			post sendHelloRequest();
		}
	}

	event void SenseAndCache.pushDataDone(error_t err) {}
	event void SenseAndCache.flushTerminated() {}
	event void SenseAndCache.dataArrived(uint16_t data) {}

	event void SendNeighborsSerial.sendDone( message_t * msg, error_t result ) {}
	event void SendHelloRequest.sendDone( message_t * msg, error_t result ) {}
	event void SerialControl.startDone( error_t result ) {}
	event void SerialControl.stopDone( error_t result ) {}

	event void RadioControl.stopDone( error_t result ) {}
   	event void CC2420Config.syncDone( error_t error ) {}
    	async event void ActiveMessageAddress.changed() {}

}

