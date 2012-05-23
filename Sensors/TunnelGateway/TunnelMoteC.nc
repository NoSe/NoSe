
#include "TunnelMote.h"
#include "message.h"

/**
 * Mote perform following actions:
 * - sense data periodically and cache them into volume (20s)
 * - answer to HELLO REQUESTs with HELLO RESPONSE (in order to
 * 	publish its existence)
 * - Aswer to DATA REQUEST with DATA RESPONSE 
 *	(in order to download previousely saved data) 
 * 
 * Led0: toggled when answeres to hello message
 * Led1: toggled when data is sensed and cached
 * Led2: toggled when data is sent to a requestor
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

		// Hello messages
		interface Receive as ReceiveHelloRequest;
		interface AMSend as SendHelloResponse;

		// Data request/response
		interface Receive as ReceiveDataRequest;
		interface AMSend as SendDataResponse;

		// Sense and cache
		interface SenseAndCache;
		interface Timer<TMilli> as SensingTimer;

		// Time synchronization
	        interface GlobalTime<TMilli>;
	        interface TimeSyncInfo;

	}
}
implementation {
	
	state_t  	state;
	uint16_t 	hello_source_id;
	uint16_t	data_requestor;
	message_t	radio_msg;
	uint16_t	jitter;
	message_t	data_response;

	event void Boot.booted() {
		state = STATE_IDLE;
		call Leds.set(0);
		call RadioControl.start();
		call SensingTimer.startPeriodic((uint32_t)( (uint32_t) 1024 * (uint32_t) SENSING_INTERVAL_S ));
	}

	task void sendHelloResponse() {
		call SendHelloResponse.send( hello_source_id, & radio_msg, 0 );
		state  = STATE_IDLE;
	}

	event message_t * ReceiveHelloRequest.receive( message_t * msg, void * payload, uint8_t len ) {
		if ( state == STATE_IDLE ) {
			state = STATE_HELLO;
			hello_source_id = ( call CC2420PacketBody.getHeader( msg )) -> src;
			jitter = call Random.rand16() % ( 1024 * HELLO_JITTER_S );
			call HelloTimer.startOneShot(jitter);
		}
		return msg;
	}

	event void HelloTimer.fired() {
		post sendHelloResponse();
	}

	event void SendHelloResponse.sendDone( message_t * msg, error_t result ) {
		if ( result != SUCCESS ) {
			post sendHelloResponse();
		}
		else {
			call Leds.led0Toggle();
		}
	}

	//---------------------------------------------------------------------
	// Data request/response
	//---------------------------------------------------------------------

	event void SensingTimer.fired() {
		call SenseAndCache.pushData();
	}

	//---------------------------------------------------------------------
	// Data request/response
	//---------------------------------------------------------------------
	
	event message_t * ReceiveDataRequest.receive( message_t * msg, void * payload, uint8_t len ) {
		data_request_msg_t * request_msg = (data_request_msg_t*) payload;
		data_requestor = ( call CC2420PacketBody.getHeader( msg )) -> src;
		if ( request_msg->retry == 0 ) {
			call SenseAndCache.moveNext();
		}
		call SenseAndCache.getData();
		return msg;
	}

	task void sendDataResponse() {
		call SendDataResponse.send( data_requestor, & data_response, sizeof(data_response_msg_t) );
	}

	event void SenseAndCache.getDataDone(error_t err, log_entry_t * entry) {
		if ( err == SUCCESS ) {
			data_response_msg_t * response_msg = (data_response_msg_t*) call CC2420PacketBody.getPayload(& data_response);
			response_msg->source = call ActiveMessageAddress.amAddress();
			response_msg->value = entry->value;
			response_msg->is_valid = entry->is_valid;
			response_msg->time = entry->time;
			post sendDataResponse();
		}
	}

	event void SendDataResponse.sendDone( message_t * msg, error_t result ) {
		if ( result == SUCCESS ) {
			call Leds.led2Toggle();
		}
	}

	// Data pushing

	event void SenseAndCache.eraseDone(error_t err) {}

	event void SenseAndCache.pushDataDone(error_t err) {
		if ( err == SUCCESS ) {
			call Leds.led1Toggle();
		}
	}

	event void RadioControl.startDone( error_t result ) {}
	event void RadioControl.stopDone( error_t result ) {}
   	event void CC2420Config.syncDone( error_t error ) {}
    	async event void ActiveMessageAddress.changed() {}

}

