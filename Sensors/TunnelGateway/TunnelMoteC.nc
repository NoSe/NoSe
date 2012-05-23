
#include "TunnelMote.h"
#include "message.h"

/**
 * Mote perform following actions:
 * - sense data periodically and cache them into volume
 * - answer to HELLO REQUESTs with HELLO RESPONSE (in order to
 * 	publish its existence)
 * - Aswer to DATA REQUEST with DATA RESPONSE 
 *	(in order to download previousely saved data) 
 */
module TunnelMoteC {
	uses {
		interface Boot;
		interface Leds;
		interface Random;
		interface SplitControl as RadioControl;
		interface Timer<TMilli> as HelloTimer;

		interface ActiveMessageAddress;
		interface CC2420PacketBody;
		interface CC2420Config;
		interface Receive as ReceiveHelloRequest;
		interface AMSend as SendHelloResponse;

		// Sense and cache
		interface SenseAndCache;

		// Time synchronization
	        interface GlobalTime<TMilli>;
	        interface TimeSyncInfo;

	}
}
implementation {
	
	state_t  	state;
	uint16_t 	hello_source_id;
	message_t	radio_msg;
	uint16_t	jitter;

	event void Boot.booted() {
		state = STATE_IDLE;
		call RadioControl.start();
	}

	task void sendHelloResponse() {
		call SendHelloResponse.send( hello_source_id, & radio_msg, 0 );
		call Leds.led0Off();
		call Leds.led1Off();
		state  = STATE_IDLE;
	}

	event message_t * ReceiveHelloRequest.receive( message_t * msg, void * payload, uint8_t len ) {
		if ( state == STATE_IDLE ) {
			call Leds.led0On();
			state = STATE_HELLO;
			hello_source_id = ( call CC2420PacketBody.getHeader( msg )) -> src;
			jitter = call Random.rand16() % ( 1024 * HELLO_JITTER_S );
			call HelloTimer.startOneShot(jitter);
		}
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

	// Data pushing

	event void SenseAndCache.eraseDone(error_t err) {
		call Leds.set(7);
	}

	event void SenseAndCache.getDataDone(error_t err, log_entry_t * entry) {}	
	event void SenseAndCache.pushDataDone(error_t err) {}

	event void RadioControl.startDone( error_t result ) {}
	event void RadioControl.stopDone( error_t result ) {}
   	event void CC2420Config.syncDone( error_t error ) {}
    	async event void ActiveMessageAddress.changed() {}

}

