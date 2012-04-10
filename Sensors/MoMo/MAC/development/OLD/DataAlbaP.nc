//MN: controllare il calcolo di T_CTS nel caso in cui la regione sia la 0  (aggiunto 1 se non sink e un call T_ALBA_TX_CTS)**
//MN: completare con il burst - chiedere a Mastro
//MN: al limite mettere sempre collision a FALSE tanto dovrei cavarmela con i JITTER (non sembra funzionare)

#include "AlbaMsg.h"
#include "AlbaState.h"

module DataAlbaP {
	provides {
		interface SplitControl;
		interface IrisSend;
		interface IrisReceive;
		interface Packet;
		interface IrisNotification;
	}
	uses {
		interface Leds;

		interface IrisSlot;
		interface IrisBackoff;
		
		interface Packet as SubPacket;
		
		interface ActiveMessageAddress;
		interface IrisPhy;
		interface IrisDutyCycleControl;
		interface IrisPhyPacket;
		interface CC2420PacketBody;
		interface Random;
		
		interface Alarm<T32khz,uint16_t> as SlotTimer;
		interface Counter<T32khz,uint16_t> as ClockLocalTime;
				
		interface IrisQueue<iris_queue_info_t> as Queue; //MN: bisogna collegarla nel file di configurazione
		interface AlbaPosition;
#ifdef USE_ALBA_REMOTE
		interface AlbaDebug;
#endif

		interface Send as SendRts;
		interface Send as SendColl;
		interface Send as SendCts;
		interface Send as SendData;
		interface Send as SendAck;

		interface Receive as ReceiveRts;
		interface Receive as ReceiveColl;
		interface Receive as ReceiveCts;
		interface Receive as ReceiveData;
		interface Receive as ReceiveAck;
		
		interface IrisTimers;
		
	}
}
implementation {

	norace error_t error_;

	norace uint8_t state_ = MT_ALBA_IDLE;

	message_t * msg_data_;
	uint8_t msg_data_len_;

	message_t msg_rts_;
	message_t msg_cts_;
	message_t msg_ack_;

	message_t * msg_recv_data_;
	void * payload_recv_data_;
	uint8_t len_recv_data_;
	
	message_t free_msg_;	

	norace bool busy_;
	norace bool received_;
	norace bool received_cts_;
	norace bool collision_;			/* heard collision */
	
	//_________________________________________
	// Contention Variables.
	//_________________________________________
	
	bool	 sink_;
	uint8_t  myPos[2];			/* to simulate a localization protocol */
	uint16_t dist_sink_;		/* node distance from the sink */
	uint16_t radius_;			/* Tx Radius */
	uint16_t sqr_radius_;
	
	norace uint8_t cont_p_;			/* p value in RTS pkt */
	norace uint8_t coll_p_;			/* p value in RTS pkt for collision resolution algorithm */
	norace uint8_t coll_type_;		/* current collision resolution algotihm used */
	
	norace uint8_t collRetryCount_;  /* number of attempt to resolve collision alredy done */
	
	/* actually these variables are constants */
	norace uint16_t n_p_;		 /* Relay regions */
	norace uint16_t n_p_coll_;   /* Relay regions for collision resolution algorithm */
	uint16_t cont_type_;		/* contention type: 0=geographic-based contention; 1=queue-based contention (like-ALBA) */
	uint8_t coll_ra_type_;		/* collisione resolution algorithm type: 0=splitting three beetwen all nodes; 1=splitting three beetwen the nodes in the same region */
	
	//-----------------------------------------
	// Information About Current Contention.
	//-----------------------------------------

	uint16_t recv_ctrl_addr_;   /* for CTS/ACK validation (to participate to just one contention at time)  */
	uint16_t relay_address_;	/* for DATA validation (to receive the DATA for which the relay won the contention */
	
	//-----------------------------------------
	// BACK-2-BACK Variables.
	//-----------------------------------------

	uint8_t relay_accepted_data_;		/* to avoid queue overflow at the receiver */
	uint8_t num_data_of_burst_to_send_;
	uint8_t real_max_burst_length_;		/* maximum number (exponential average) of burst packet successfully delivered */

	//-----------------------------------------
	// ALBA_R Variables.
	//-----------------------------------------

	bool    not_relaying_;				/* current relay don't want any packet */
	uint8_t nodeColor_;					/* node's current color (initialise to 0) */
	norace uint8_t num_empties_cycles_; /* number of cycles without any reply from relay */
	
	norace uint16_t		T_REMAIN_SLOT;
	norace uint16_t		T_CTS;
	
	norace uint8_t		my_error;
	
	task void errorTask() {
		signal IrisNotification.error( my_error );
	}
		
	void _error_( uint8_t v ) {
		my_error = v;
		post errorTask();
		/*
		call Leds.set( v );
		for (;;) {}
		*/
	}
					
	task void startContention();

	task void endContentionSenderSuccess();
	task void endContentionSenderRetry();

	task void endContentionReceiverFail();
	task void endContentionReceiverSuccess();
	
	task void send_Data();
	task void send_Rts();
	task void send_Coll();
	task void send_Cts();
	task void send_Ack();
	
	//-----------------------------------------
	// Utility Functions.
	//-----------------------------------------
	
	inline error_t startTimer( uint16_t duration, message_t * msg ) {
		uint16_t delta = ( call ClockLocalTime.get() - (call CC2420PacketBody.getMetadata( msg )) -> time );
		if ( duration > delta ) {
			if ( duration - delta >= MINIMUM_TIME ) {
				call SlotTimer.start( duration - delta );
				return SUCCESS;
			}
		}
		return FAIL;
	}

	inline void reload_positions() {
		radius_ = call AlbaPosition.getRadius();
		//MN: aggiungere gli altri calcoli
		sqr_radius_ = SQR( radius_ );
		myPos[0] = call AlbaPosition.getPosX();
		myPos[1] = call AlbaPosition.getPosY();
		dist_sink_ = call AlbaPosition.getSinkDistance();
	}
	
	inline uint16_t my_abs_of_diff( uint16_t a, uint16_t b ) {
		return a > b ? a - b : b - a;
	}

	bool relay_region(message_t* msg) {
	
		alba_rts_msg_t* ptr_rts = (alba_rts_msg_t*) call SubPacket.getPayload( msg, 0 );
		uint16_t dist_ta, dist_self;
		uint16_t sender_id = (call CC2420PacketBody.getHeader( msg )) -> src;

		//MN: to implement ALBA_R
		if((nodeColor_ == ptr_rts -> sender_color) || (nodeColor_ == (ptr_rts -> sender_color - 1))) {
			dist_ta    = (ptr_rts -> interest).sqr_dist;
			//dist_self  = SQR(myPos[0] - (ptr_rts -> interest).x);
			//dist_self += SQR(myPos[1] - (ptr_rts -> interest).y);
			dist_self  = dist_sink_;
		} else return FALSE;

		//MN: it is not always true in presence of localization error
		//if(sqrtf(dist_ta) <= radius_)
		//	return FALSE;

		if((ptr_rts -> sender_color % 2) == 0) {
			//MN: F region
			return ((dist_ta > dist_self) || ((dist_ta == dist_self) && (call ActiveMessageAddress.amAddress() > sender_id)));
		}
		else {
			//MN: Fc region
			return ((dist_ta < dist_self) || ((dist_ta == dist_self) && (call ActiveMessageAddress.amAddress() < sender_id)));
		}
	}
	
	//MN: add this function for new collision avoidance procedure
	uint8_t getGPIIndex(void * payload, uint8_t np) {
		
		alba_rts_msg_t* ptr_rts = (alba_rts_msg_t*) payload;
		uint16_t PARTIAL = sqr_radius_ / np;
		uint16_t TOT = PARTIAL * np;
		uint16_t dist_ta, dist_self;
		uint16_t diff = 0;
		uint16_t  r = 0;

		//MN: controllare se il tipo di variabili va bene
		dist_ta    = (ptr_rts -> interest).sqr_dist;
		dist_self  = dist_sink_;
		
		diff = my_abs_of_diff(dist_ta, dist_self);

		if( diff > TOT )
			r = 0;
		else
			r = np - diff / PARTIAL;

		return (uint8_t)r;
	}

	uint8_t getQPIIndex( void * payload ) {

		alba_rts_msg_t* ptr_rts = (alba_rts_msg_t*) payload;
		uint8_t r = 0;
		uint8_t accepted_burst = ptr_rts -> proposed_burst;
		
		//MN: to check
		if ( ( call Queue.size() + accepted_burst ) > call Queue.maxSize() )
			accepted_burst = ( call Queue.maxSize() - call Queue.size() );
		
		r = (call Queue.size() + accepted_burst) / real_max_burst_length_;

		return r;
	}

	int8_t my_region(void * payload, uint8_t type, uint8_t np, uint8_t coll_ra) {
	
		alba_rts_msg_t* ptr_rts = (alba_rts_msg_t*) payload;
		float dist_ta, dist_self;
		uint8_t r = 0, r_color = 0;
		
		if(ptr_rts -> sender_color > 0) {
			type = COLOR_CONT;
			//to use ALBA-mechanisms also for backtracking packets
			if( (coll_ra == 1) )
				type = QUEUE_CONT;
		} //MN: aggiungere SCAN_C_CONT

		switch(type) {
			case GEO_CONT:

				r = getGPIIndex( payload, np );
				
				T_CTS = ( getQPIIndex( payload ) + 1 ) * NP_SLOT * ( call Random.rand16() % call IrisTimers.T_ALBA_TX_CTS() );
				//r = 3; //MN: TO REMOVE
				//T_CTS = ( 3 + 1 ) * NP_SLOT * rand( 32, call IrisTimers.T_ALBA_TX_CTS() ); //MN: TO REMOVE
				
				break;

			case QUEUE_CONT:

				r = getQPIIndex( payload );
                
				if( ( r >= np ) || ( (call Queue.maxSize() ) == (call Queue.size() ) ) ){
					not_relaying_ = TRUE;
					r = ( np - 1 );
				}
				
				T_CTS = ( getGPIIndex( payload, np ) + 1 ) * NP_SLOT * ( call Random.rand16() % call IrisTimers.T_ALBA_TX_CTS() );
				//r = 3; //MN: TO REMOVE
				//T_CTS = ( 3 + 1 ) * NP_SLOT * rand( 32, call IrisTimers.T_ALBA_TX_CTS() ); //MN: TO REMOVE

				break;

			case COLOR_CONT:
			
				dist_ta    = (ptr_rts -> interest).sqr_dist;
				//dist_self  = SQR(myPos[0] - (ptr_rts -> interest).x);
				//dist_self += SQR(myPos[1] - (ptr_rts -> interest).y);
				dist_self  = dist_sink_;

				//dist_ta    = sqrtf(dist_ta);
				//dist_self  = sqrtf(dist_self);

				//MN: to remove in new implementation
				/*
				if ( fabsf(dist_ta - dist_self) > radius_ )
					r_color = 0;
				else r_color = (np/2) - (uint8_t)ceil( fabsf(dist_ta - dist_self)/(radius_ / (np/2)) );
				*/

				if(nodeColor_ == (ptr_rts -> sender_color - 1)) {
					r = r_color;
				} else if(nodeColor_ == ptr_rts -> sender_color) {
					r = 2 + r_color;
				}
				else r = np;

				T_CTS = ( getQPIIndex( payload ) + 1 ) * NP_SLOT * ( call Random.rand16() % call IrisTimers.T_ALBA_TX_CTS() );

				break;

			default:
				break;
		}
		
		//MN: to check if it is necessary                                                                                                                                  
		if(r >= np)
			return -1;

		if(coll_ra == 0xFF) {
			if(r <= ptr_rts -> p)
				return 0;
		} 
		else {
			if(r == ptr_rts -> p)
				return 0;
			if(r < ptr_rts -> p)
				return -1;
		}
		
		return 1;
	}

	int8_t my_region_coll(void * payload, uint8_t type, uint8_t np) {

		alba_rts_msg_t* ptr_rts = (alba_rts_msg_t*) payload;
		uint8_t r_cont, r_coll;
		r_cont = r_coll = 0;

		if ( (call Queue.maxSize()) == (call Queue.size()) )
			return -1;

		if(ptr_rts -> sender_color != 0)
			return -1;

		switch(type) {
			case GEO_CONT:

				r_cont = getGPIIndex( payload, np );

				break;

			case QUEUE_CONT:

				r_cont = getQPIIndex( payload );

				break;
				
			default:
				break;
		}

		if(r_cont >= np)
			return -1;

		r_coll = my_region(payload, !cont_type_, n_p_coll_, 1);
        
		if(r_cont == ptr_rts -> best_p) {
			return r_coll;
		}

		return -1;
	}

	void updateMsg(message_t* msg) {
		
		alba_data_msg_t* ptr_data = (alba_data_msg_t*) call SubPacket.getPayload( msg, 0 );
		//uint16_t dist_self;
		
		ptr_data -> hops = ptr_data -> hops + 1;
		ptr_data -> retry = 0;

		if(( ptr_data -> interest).sink != call ActiveMessageAddress.amAddress()) {

			//dist_self  = SQR(myPos[0] - (ptr_data -> interest).x);
			//dist_self += SQR(myPos[1] - (ptr_data -> interest).y);

			//(ptr_data -> interest).sqr_dist = dist_self;
			(ptr_data -> interest).sqr_dist = dist_sink_;
		}
	}

	bool haveToChangeColor() {
	
		float duty_cycle_ = call IrisDutyCycleControl.getDutyCycle() / 255.0;
		float prob_to_find_relay = (1.0 - powf((1.0 - (ALBA_REL_FACTOR * duty_cycle_)), num_empties_cycles_));
		
		return ( prob_to_find_relay >= ALBA_FIND_THR );
	}

	void checkBurstLength() {

		if((MAX_BURST_LENGTH == 1) || (num_data_of_burst_to_send_ > 0))
			return;

		if(call Queue.size() >= MAX_BURST_LENGTH)
			num_data_of_burst_to_send_ = MAX_BURST_LENGTH;
		else num_data_of_burst_to_send_ = call Queue.size();
	}
	
	void setBurstLength() {
	
		if((MAX_BURST_LENGTH == 1) || (relay_accepted_data_ == 0))
			return;
			
		if(num_data_of_burst_to_send_ > relay_accepted_data_)
			num_data_of_burst_to_send_ = relay_accepted_data_;

		relay_accepted_data_ = 0;
	}
	
	inline void makePktRts(bool coll) {
	
		alba_data_msg_t* ptr_data = (alba_data_msg_t*) call SubPacket.getPayload( msg_data_, 0 );
		alba_rts_msg_t* ptr_rts = (alba_rts_msg_t*) call SubPacket.getPayload( & msg_rts_, 0 );
			
		ptr_rts -> p = cont_p_;
		ptr_rts -> coll_ra = 0xFF;
		
		ptr_rts -> best_p = 0xFF;

		if(coll_ra_type_ == NEW_COLL_RA) {
			if(coll || (state_ == MT_ALBA_WAIT_CTS_COLL)) {
				ptr_rts -> p = coll_p_;
				ptr_rts -> coll_ra = 1;
				ptr_rts -> best_p = cont_p_;
			}
		}
		
		(ptr_rts -> interest).x = (ptr_data -> interest).x;
		(ptr_rts -> interest).y = (ptr_data -> interest).y;

		(ptr_rts -> interest).sink = (ptr_data -> interest).sink;
		(ptr_rts -> interest).sqr_dist = (ptr_data -> interest).sqr_dist;

		if(num_data_of_burst_to_send_ == 0)
			ptr_rts -> proposed_burst = 1;
		else ptr_rts -> proposed_burst = num_data_of_burst_to_send_;
		
		ptr_rts -> sender_color = nodeColor_;
		
		//MN: aggiungere inizializzazione per le variante con scanning
		ptr_rts -> min_color = 0;
		ptr_rts -> max_color = 0;

  }
  
	inline void makePktCts() {
	
		alba_cts_msg_t* ptr_cts = (alba_cts_msg_t*) call SubPacket.getPayload( & msg_cts_, 0 );

		if(((call Queue.maxSize()) == (call Queue.size())) || not_relaying_)  {
			not_relaying_ = TRUE;
			ptr_cts -> accepted_burst = 0;
		} else ptr_cts -> accepted_burst = ((call Queue.maxSize()) - (call Queue.size()));
		
		//MN: inizializzare gli altri campi utili per gestire dinamicita' sender_color e il flags FINAL_COLOR
		
		(call CC2420PacketBody.getHeader( & msg_cts_ )) -> dest = recv_ctrl_addr_;
	}

	inline void makePktAck() {
	
		alba_ack_msg_t* ptr_ack = (alba_ack_msg_t*) call SubPacket.getPayload( & msg_ack_, 0 );
		
		ptr_ack -> msg_to_recv = num_data_of_burst_to_send_;
		//MN: inizializzare gli altri campi utili per gestire dinamicita' sender_color e il flags DUTY_UP

		(call CC2420PacketBody.getHeader( & msg_ack_ )) -> dest = recv_ctrl_addr_;
	}
	

	void transmitDATA() {

		alba_data_msg_t* ptr_data = (alba_data_msg_t*) call SubPacket.getPayload( msg_data_, 0 );

		if(num_data_of_burst_to_send_ > 0) {
			num_data_of_burst_to_send_ --;
			ptr_data -> msg_to_send = num_data_of_burst_to_send_;
		}
		else {
			ptr_data -> msg_to_send = 0;
		}

		(call CC2420PacketBody.getHeader( msg_data_ )) -> dest = relay_address_;
		ptr_data -> sender_color = nodeColor_;
		//MN: inizializzare i flags DUMMY e DUTY_UP
	}
	
	void endContentionSenderRetry_( uint8_t v ) {
		error_ = v;
		post endContentionSenderRetry();
	}

	task void endContentionSenderRetry() {
		state_ = MT_ALBA_IDLE;
		if ( call IrisPhy.stopSender( SUCCESS ) != SUCCESS ) {
			//_error_( 3 );
			return;
		}
		
		// if ( call IrisPhy.stopSender( ERETRY ) == SUCCESS )
		//	return;

		if ( haveToChangeColor() ) {
			nodeColor_ += 1;
			num_empties_cycles_ = 0;
#ifdef USE_ALBA_REMOTE
			call AlbaDebug.setColor( nodeColor_ );
			call AlbaDebug.changed();
#endif
			/*
			if ( ( ((alba_data_msg_t*) call SubPacket.getPayload( msg_data_, 0 )) -> hops > 0 ) && (( nodeColor_ - ((alba_data_msg_t*) call SubPacket.getPayload( msg_data_, 0 )) -> sender_color ) > 0) ) {
				//MN: questo pacchetto deve comunque essere scartato
				error_ = E_LOOP_CONDITION;
			}
			*/
		}

		signal IrisSend.sendDone( msg_data_, error_ );
	}
	
	task void endContentionSenderSuccess() {
		state_ = MT_ALBA_IDLE;
		if ( call IrisPhy.stopSender( SUCCESS ) != SUCCESS ) {
			//_error_( 4 );
			return;
		}
		signal IrisSend.sendDone( msg_data_, SUCCESS );
	}
		
	/**
	 * In this method is assuming that a caller will not call two times this method 
	 * before the reception of the event "sendDone".
	 */
	 /*MN: viene chiamata una sola volta per ogni nuovo pacchetto da inviare fino a quando non si finisice di gestire il pacchetto
	 quindi si possono mettere qui le varie inizializzazioni*/
	command error_t IrisSend.send( message_t* msg, uint16_t interest_id, uint8_t len ) {

		//MN: condizione di scarto per loop -> manca la gestione del TTL
		/*
		if ( ( ((alba_data_msg_t*) call SubPacket.getPayload( msg, 0 )) -> hops > 0 ) && (( nodeColor_ - ((alba_data_msg_t*) call SubPacket.getPayload( msg, 0 )) -> sender_color ) > 0) ) {
			error_ = E_LOOP_CONDITION;
			//((alba_data_msg_t*) call SubPacket.getPayload( msg, 0 )) -> hops = 0xFF; //MN: gestito tramite il tipo di errore
			return FAIL;
		}
		*/

		// Save info about the message to send.
		msg_data_ = msg;
		msg_data_len_ = len + sizeof( alba_data_msg_t );

		// Prepare the packet.
		call IrisPhyPacket.prepareWithType( msg_data_, AM_BROADCAST_ADDR, MT_ALBA_DATA );
		
		return call IrisPhy.startSender();
		
	}
			
	/**
	 * If result is SUCCESS, the node gained access to the medium,
	 * the power is on and the contention can start.
	 * If result is FAIL, the node lost access to the medium after
	 * the maximum number of retries.
	 */
	event void IrisPhy.startSenderDone( error_t result ) {
	
		alba_data_msg_t* ptr_data = (alba_data_msg_t*) call SendData.getPayload( msg_data_, call SendData.maxPayloadLength() );
		ptr_data -> retry = ptr_data -> retry + 1;

		if ( result == SUCCESS ) {
			post startContention(); 
			return;
		}
		/*
		// Return in idle state.
		state_ = MT_ALBA_IDLE;

		if ( call IrisPhy.stopSender( SUCCESS ) != SUCCESS ) {
			//_error_( 3 );
			return;
		}
			
		// Notify that node was not successfull in sending the packet.
		// if ( call IrisPhy.stopSender( ERETRY ) == SUCCESS )
		// 	return;

		signal IrisSend.sendDone( msg_data_, E_CHANNEL_BUSY );
		*/
		endContentionSenderRetry_( E_CHANNEL_BUSY );
	}
	
	/**
	 * Start contention procedure.
	 */
	task void startContention() {
	
		// Initialize contention variables
		cont_p_ = 0;
		coll_p_ = 0;
		collRetryCount_ = 0;
		num_data_of_burst_to_send_ = 0;
		coll_type_ = coll_ra_type_;

		busy_ = FALSE;
		received_ = FALSE;
		received_cts_ = FALSE;
		collision_ = FALSE;
		
		// call Leds.led2On();
		
		checkBurstLength();

		makePktRts(busy_);

		state_ = MT_ALBA_PREPARE_SEND;

		call SlotTimer.start( call IrisTimers.T_ALBA_TX_RTS() );

		if ( call SendRts.send( & msg_rts_, sizeof( alba_rts_msg_t ) ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}
		
	task void endContentionReceiverFail() {
	
		num_data_of_burst_to_send_ = 0;
		recv_ctrl_addr_ = 0xFFFF;
		not_relaying_ = FALSE;
		coll_type_ = coll_ra_type_;
		
		state_ = MT_ALBA_IDLE;
		// call Leds.led2Off();
		call IrisPhy.stopReceiver();
	}
	
	task void endContentionReceiverSuccess() {
	
		num_data_of_burst_to_send_ = 0;
		recv_ctrl_addr_ = 0xFFFF;
		not_relaying_ = FALSE;
		coll_type_ = coll_ra_type_;
		
		state_ = MT_ALBA_IDLE;
		// call Leds.led2Off();
		call IrisPhy.stopReceiver();
		msg_recv_data_ = signal IrisReceive.receive( msg_recv_data_, payload_recv_data_, 0, len_recv_data_ );
		
#ifdef USE_ALBA_REMOTE
        call AlbaDebug.end();
#endif
	}
	
	//-----------------------------------------------------------------------
	// Protocol
	//-----------------------------------------------------------------------

	event void SendRts.sendDone( message_t* msg, error_t error ) {
		if ( state_ != MT_ALBA_PREPARE_SEND )
			return;
			
		if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			endContentionSenderRetry_( E_TX_PROBLEM );
			return;
		}
			
		state_ = MT_ALBA_RTS;
		
		if ( error != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}
	
	event void SendColl.sendDone( message_t* msg, error_t error ) {
	
		if ( state_ != MT_ALBA_PREPARE_SEND )
			return;
			
		if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			endContentionSenderRetry_( E_TX_PROBLEM );
			return;
		}
			
		state_ = MT_ALBA_COLL;
		
		if ( error != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}

	event void SendData.sendDone( message_t* msg, error_t error ) {
	
		if ( state_ != MT_ALBA_PREPARE_SEND )
			return;
			
		if ( startTimer( call IrisTimers.T_ALBA_DATA(), msg ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			endContentionSenderRetry_( E_TX_PROBLEM );
			return;
		}

		state_ = MT_ALBA_DATA;
		
		if ( error != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}
	
	event void SendCts.sendDone( message_t* msg, error_t error ) {
		if ( error != SUCCESS ) {
			state_ = MT_ALBA_RECV_ERROR;
			call SlotTimer.stop();
			post endContentionReceiverFail();
		}
	}

	event void SendAck.sendDone( message_t* msg, error_t error ) {
		//MN: qui va modificato nel caso in cui mi aspetto un burst controllando se devo ricevere ancora
		if ( error != SUCCESS ) {
			state_ = MT_ALBA_RECV_ERROR;
			call SlotTimer.stop();
			post endContentionReceiverFail();
		}
		else {
			state_ = MT_ALBA_RECEIVED;
			post endContentionReceiverSuccess();
		}
	}
	
	//MN: controllare se fare la return msg ogni volta che fallisco
	event message_t * ReceiveRts.receive( message_t * msg, void * payload, uint8_t len ) {

		alba_rts_msg_t * ptr_rts = (alba_rts_msg_t*) payload;
		int8_t my_region_;
		received_ = TRUE;
		
		//MN: serve per fermare il duty_cycle del nodo - TO CHECK
		if ( recv_ctrl_addr_ == 0xFFFF ) {
			if ( call IrisPhy.startReceiver() != SUCCESS )
				return msg;
		}

		if ( ( recv_ctrl_addr_ != 0xFFFF ) && ( recv_ctrl_addr_ != (call CC2420PacketBody.getHeader( msg )) -> src ) )
			return msg;
			
		switch ( state_ ) {

			case MT_ALBA_IDLE:

				/* don't care zones if we are the target */
				if( (ptr_rts -> interest).sink == call ActiveMessageAddress.amAddress() ) {
					recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
					//MN: il sink non deve collidere con nessuno quindi manda subito
					
					if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
						state_ = MT_ALBA_RECV_ERROR;
						call SlotTimer.stop(); //MN: last add
						post endContentionReceiverFail();
						return msg;
					}
										
					T_CTS = 0;
					state_ = MT_ALBA_CTS;
					break;
				}

				/* if we are sink don't care about pkts for other sinks */
				if( sink_ && (ptr_rts -> interest).sink != call ActiveMessageAddress.amAddress() ) {
					return msg;
				}
				
				if( !relay_region(msg) ) {
					state_ = MT_ALBA_RECV_ERROR;
					call SlotTimer.stop();
					post endContentionReceiverFail();
					return msg;
				}

				/* fall through */
			
			case MT_ALBA_WAIT_CONT:
				
				my_region_ = -1;
				if ( ptr_rts -> coll_ra == 1 ) {
					my_region_ = my_region_coll( payload, cont_type_, n_p_ );
					coll_type_ = STD_COLL_RA;
				}
				else
					my_region_ = my_region( payload, cont_type_, n_p_, ptr_rts-> coll_ra );
						
				switch ( my_region_ ) {
					case -1:
						state_ = MT_ALBA_RECV_ERROR;
						call SlotTimer.stop();
						post endContentionReceiverFail();
						break;
					case 0:
						recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
						//MN: per evitare collisioni in due fasi -> mettere un jitter al tempo
						
						if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
							state_ = MT_ALBA_RECV_ERROR;
							call SlotTimer.stop(); //MN: last add
							post endContentionReceiverFail();
							return msg;
						}
						
						state_ = MT_ALBA_CTS;
						break;
					case 1:
						recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
						T_REMAIN_SLOT = call IrisTimers.T_ALBA_RES_SLOT() + call IrisTimers.T_ALBA_TX_DATA();
						call SlotTimer.start( T_REMAIN_SLOT );
						state_ = MT_ALBA_WAIT_CONT;
						break;
					default:
						break;
				}
				break;
				
			case MT_ALBA_COLL_IDLE:
		      
			  switch(coll_type_) {
				case STD_COLL_RA:
					if ( ( ( call Random.rand16() % 10 ) < 5) && (relay_region(msg))) {
						recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
						
						if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
							state_ = MT_ALBA_RECV_ERROR;
							call SlotTimer.stop(); //MN: last add
							post endContentionReceiverFail();
							return msg;
						}
						
						state_ = MT_ALBA_CTS;
					}
					else {
						//MN: impostare il timer per lo stato MT_ALBA_COLL_IDLE
						T_REMAIN_SLOT = call IrisTimers.T_ALBA_RES_SLOT() + call IrisTimers.T_ALBA_TX_DATA();
						call SlotTimer.start( T_REMAIN_SLOT );
						state_ = MT_ALBA_COLL_IDLE;
					}
					break;
					
				case NEW_COLL_RA: {
					switch(my_region(payload, !cont_type_, n_p_coll_, ptr_rts -> coll_ra)) {
					case -1:
						state_ = MT_ALBA_RECV_ERROR;
						call SlotTimer.stop();
						post endContentionReceiverFail();
						break;
					case 0:
						recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
						coll_type_ = STD_COLL_RA;
						
						if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
							state_ = MT_ALBA_RECV_ERROR;
							call SlotTimer.stop(); //MN: last add
							post endContentionReceiverFail();
							return msg;
						}

						state_ = MT_ALBA_CTS;
						break;
					case 1:
						recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
						T_REMAIN_SLOT = call IrisTimers.T_ALBA_RES_SLOT() + call IrisTimers.T_ALBA_TX_DATA();
						call SlotTimer.start( T_REMAIN_SLOT );
						state_ = MT_ALBA_COLL_IDLE;
						break;
					default:
						break;
					}
				}
				
				default:
					break;
			}
			
			case MT_ALBA_WAIT_DATA:
				/* I'm a sink... */
				if( (ptr_rts -> interest).sink == call ActiveMessageAddress.amAddress() ) {
				
					if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
						state_ = MT_ALBA_RECV_ERROR;
						call SlotTimer.stop(); //MN: last add
						post endContentionReceiverFail();
						return msg;
					}
				
					T_CTS = 0;
					state_ = MT_ALBA_CTS;
					break;
				}
			default:
				break;
		}

		return msg;
		
	}
	
	event message_t * ReceiveColl.receive( message_t * msg, void * payload, uint8_t len ) {
		
		alba_rts_msg_t * ptr_rts = (alba_rts_msg_t*) payload;
		received_ = TRUE;
		
		if ( state_ != MT_ALBA_WAIT_DATA )
			return msg;
		
		if ( ( recv_ctrl_addr_ != 0xFFFF ) && ( recv_ctrl_addr_ != (call CC2420PacketBody.getHeader( msg )) -> src ) )
			return msg;
			
		/* I'm a sink... */
		if( (ptr_rts -> interest).sink == call ActiveMessageAddress.amAddress() ) {
		
			if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
				state_ = MT_ALBA_RECV_ERROR;
				call SlotTimer.stop(); //MN: last add
				post endContentionReceiverFail();
				return msg;
			}
		
			T_CTS = 0;
			state_ = MT_ALBA_CTS;
			return msg;
		}

		switch(coll_type_) {
			case STD_COLL_RA:
				if( ( ( call Random.rand16() % 10 ) < 5) && (relay_region(msg))) {
					recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
					
					if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
						state_ = MT_ALBA_RECV_ERROR;
						call SlotTimer.stop(); //MN: last add
						post endContentionReceiverFail();
						return msg;
					}
					
					state_ = MT_ALBA_CTS;
				}
				else {
					//MN: impostare il timer per lo stato MT_ALBA_COLL_IDLE
					T_REMAIN_SLOT = call IrisTimers.T_ALBA_RES_SLOT() + call IrisTimers.T_ALBA_TX_DATA();
					call SlotTimer.start( T_REMAIN_SLOT );
					state_ = MT_ALBA_COLL_IDLE;
				}
				break;
					
			case NEW_COLL_RA: {
				switch(my_region(payload, !cont_type_, n_p_coll_, ptr_rts -> coll_ra)) {
				case -1:
					state_ = MT_ALBA_RECV_ERROR;
					call SlotTimer.stop();
					post endContentionReceiverFail();
					break;
				case 0:
					recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
					coll_type_ = STD_COLL_RA;
					
					if ( startTimer( call IrisTimers.T_ALBA_RTS(), msg ) != SUCCESS ) {
						state_ = MT_ALBA_RECV_ERROR;
						call SlotTimer.stop(); //MN: last add
						post endContentionReceiverFail();
						return msg;
					}
					
					state_ = MT_ALBA_CTS;
					break;
				case 1:
					recv_ctrl_addr_ = (call CC2420PacketBody.getHeader( msg )) -> src;
					T_REMAIN_SLOT = call IrisTimers.T_ALBA_RES_SLOT() + call IrisTimers.T_ALBA_TX_DATA();
					call SlotTimer.start( T_REMAIN_SLOT );
					state_ = MT_ALBA_COLL_IDLE;
					break;
				default:
					break;
				}
			}
				
			default:
				break;
			}

		return msg;
	}

	event message_t * ReceiveCts.receive( message_t * msg, void * payload, uint8_t len ) {
	
		alba_cts_msg_t * ptr_cts = (alba_cts_msg_t*) payload;
		received_ = TRUE;
		
		// Discard CTS messages not destined to me.                                                                                                                        
		if ( (call CC2420PacketBody.getHeader( msg )) -> dest != call ActiveMessageAddress.amAddress() )
			return msg;
		
		if (( state_ != MT_ALBA_WAIT_CTS ) && ( state_ != MT_ALBA_WAIT_CTS_COLL ))
			return msg;
			
		if ( received_cts_ == TRUE )
			return msg;
			
		collRetryCount_ = 0;
		num_empties_cycles_ = 0;
				
		if( ptr_cts -> accepted_burst > 0 ) {
			received_cts_ = TRUE;
			real_max_burst_length_ = 1;
			relay_address_ = (call CC2420PacketBody.getHeader( msg )) -> src;
			relay_accepted_data_ = ptr_cts -> accepted_burst;
		} else {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			//MN: controllare se il tipo di errore va bene
			endContentionSenderRetry_( E_NOBODY_AROUND );
		}
		
		return msg;
	}
	
	event message_t * ReceiveData.receive( message_t * msg, void * payload, uint8_t len ) {
	
		message_t * tmp;
		alba_data_msg_t * ptr_data = (alba_data_msg_t*) payload;
		received_ = TRUE;
		
		if ( state_ != MT_ALBA_WAIT_DATA )
			return msg;
		
		// Discard DATA messages not destined to me.
		if ( (call CC2420PacketBody.getHeader( msg )) -> dest != call ActiveMessageAddress.amAddress() )
			return msg;

		//MN: controllare se va bene messa qui
		updateMsg( msg );
		
		num_data_of_burst_to_send_ = ptr_data-> msg_to_send;
		
		//MN: controllare -> questo era il caso del burst ma qui ancora non lo uso
		state_ = MT_ALBA_ACK;
		//MN: devo mettere il tempo dopo il quale mi aspetto un altro dato
		
		if ( startTimer( call IrisTimers.T_ALBA_DATA(), msg ) != SUCCESS ) {
			state_ = MT_ALBA_RECV_ERROR;
			call SlotTimer.stop(); //MN: last add
			post endContentionReceiverFail();
			return msg;
		}
				
		tmp = msg_recv_data_;
				
		msg_recv_data_ = msg;
		len_recv_data_ = len - sizeof( alba_data_msg_t );
		payload_recv_data_ = payload + sizeof( alba_data_msg_t );
		
		return tmp;
	}

	event message_t * ReceiveAck.receive( message_t * msg, void * payload, uint8_t len ) {
	
		received_ = TRUE;
		
		if ( state_ != MT_ALBA_WAIT_ACK )
			return msg;
			
		if ( (call CC2420PacketBody.getHeader( msg )) -> dest != call ActiveMessageAddress.amAddress() )
			return msg;
		
		call SlotTimer.stop();
		
		//MN: per ora non viene mai chiamato - burst
		if(num_data_of_burst_to_send_ > 0) {
			real_max_burst_length_ ++;
			//MN: ottenre un nuovo dato da inviare
			post send_Data();
		}
		else {
			real_max_burst_length_ = MAX_BURST_LENGTH;
			state_ = MT_ALBA_SENT;
			post endContentionSenderSuccess();
		}
			
		return msg;
	}

	task void send_Rts() {
	
		makePktRts(collision_);

		state_ = MT_ALBA_PREPARE_SEND;

		call SlotTimer.start( call IrisTimers.T_ALBA_TX_RTS() );

		if ( call SendRts.send( & msg_rts_, sizeof( alba_rts_msg_t ) ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}
	
	task void send_Coll() {
	
		makePktRts(collision_);

		state_ = MT_ALBA_PREPARE_SEND;

		call SlotTimer.start( call IrisTimers.T_ALBA_TX_RTS() );

		if ( call SendColl.send( & msg_rts_, sizeof( alba_rts_msg_t ) ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}

	task void send_Data() {
	
		setBurstLength();
		transmitDATA();
		state_ = MT_ALBA_PREPARE_SEND;
		call SlotTimer.start( call IrisTimers.T_ALBA_TX_DATA() );
		
		if ( call SendData.send( msg_data_, msg_data_len_ ) != SUCCESS ) {
			state_ = MT_ALBA_SEND_ERROR;
			call SlotTimer.stop();
			endContentionSenderRetry_( E_TX_PROBLEM );
		}
	}

	task void send_Cts() {

		makePktCts();

		// call Leds.led1Toggle();
		if ( call SendCts.send( & msg_cts_, sizeof( alba_cts_msg_t ) ) != SUCCESS ) {
			state_ = MT_ALBA_RECV_ERROR;
			call SlotTimer.stop();
			post endContentionReceiverFail();
		}
	}
		
	task void send_Ack() {
	
		makePktAck();

		if ( call SendAck.send( & msg_ack_, sizeof( alba_ack_msg_t ) ) != SUCCESS ) {
			state_ = MT_ALBA_RECV_ERROR;
			call SlotTimer.stop();
			post endContentionReceiverFail();
		}
	}
				
	async event void SlotTimer.fired() {
		switch ( state_ ) {
			
			case MT_ALBA_RTS :
			
				busy_ = FALSE;
				received_ = FALSE;
				received_cts_ = FALSE;
				collision_ = FALSE;
				call SlotTimer.start( call IrisTimers.T_ALBA_RES_SLOT() );
				call IrisSlot.start( & busy_ );
				state_ = MT_ALBA_WAIT_CTS;
				break;

			case MT_ALBA_COLL :
				
				busy_ = FALSE;
				received_ = FALSE;
				received_cts_ = FALSE;
				collision_ = FALSE;
				call SlotTimer.start( call IrisTimers.T_ALBA_RES_SLOT() );
				call IrisSlot.start( & busy_ );
				state_ = MT_ALBA_WAIT_CTS_COLL;
				break;
				
			case MT_ALBA_CTS :
				
				//MN: calcolare il tempo random di invio
				T_REMAIN_SLOT = call IrisTimers.T_ALBA_RES_SLOT() + call IrisTimers.T_ALBA_TX_DATA() - T_CTS;
				if( T_CTS == 0 ) {
					call SlotTimer.start( T_REMAIN_SLOT );
					state_ = MT_ALBA_WAIT_DATA;
					post send_Cts();
				} else {
					call SlotTimer.start( T_CTS );
					state_ = MT_ALBA_WAIT_SEND_CTS;
				}
				break;
			
			case MT_ALBA_WAIT_SEND_CTS :
				call SlotTimer.start( T_REMAIN_SLOT );
				state_ = MT_ALBA_WAIT_DATA;
				post send_Cts();
				break;
				
			case MT_ALBA_WAIT_CTS :
				call IrisSlot.stop();
				
				//collision_ = (busy_ && !received_);
				
				if( received_cts_ == TRUE ) {
					post send_Data();
					break;
				}

				if( collision_ == TRUE ) {
					post send_Coll();
				}
				else {
					cont_p_ ++;
					if(cont_p_ >= n_p_) {
						//MN: chiedere se corretto come ricomincio la TX
						state_ = MT_ALBA_SEND_ERROR;
						num_empties_cycles_ ++;
						endContentionSenderRetry_( E_NOBODY_AROUND );
					}
					else {
						post send_Rts();
					}
				}
				break;
				
			case MT_ALBA_WAIT_CTS_COLL :
				call IrisSlot.stop();
				
				if( received_cts_ == TRUE ) {
					post send_Data();
					break;
				}
				
				switch(coll_type_) {
				case STD_COLL_RA:
					//MN: standard collision resolution algorithm
					collRetryCount_ ++;
					if (collRetryCount_ <= MAX_RETRY_COLLISION) {
						collision_ = (busy_ && !received_);
						post send_Coll();
					}
					else {
						collRetryCount_ = 0;
						state_ = MT_ALBA_SEND_ERROR;
						call SlotTimer.stop();
						endContentionSenderRetry_( E_NOBODY_AROUND );
					}
					break;

				case NEW_COLL_RA:
					//MN: new collision resolution algorithm
					
					collision_ = (busy_ && !received_);
																
					if( collision_ == TRUE ) {
						coll_type_ = STD_COLL_RA;
						post send_Coll();
					}
					else {
						coll_p_ ++;
						//MN: to check - important
						if(coll_p_ >= n_p_coll_) {
							state_ = MT_ALBA_SEND_ERROR;
							call SlotTimer.stop();
							endContentionSenderRetry_( E_NOBODY_AROUND );
						}
						else {
							post send_Coll();
						}
					}
					break;
				default:
					break;
				}
				
				break;
			
			case MT_ALBA_DATA :
				call SlotTimer.start( call IrisTimers.T_ALBA_TX_ACK() );
				state_ = MT_ALBA_WAIT_ACK;
				break;
			
			case MT_ALBA_WAIT_CONT :
			case MT_ALBA_COLL_IDLE :
			case MT_ALBA_WAIT_DATA :
				state_ = MT_ALBA_RECV_ERROR;
				post endContentionReceiverFail();
				break;

			case MT_ALBA_WAIT_ACK :
				state_ = MT_ALBA_SEND_ERROR;
				endContentionSenderRetry_( E_ACK_LOST );
				break;
				
			case MT_ALBA_ACK :
				post send_Ack();
				break;
								
			case MT_ALBA_RECEIVED	: // Node correctly received message: the "recv" method notifies it.
			case MT_ALBA_SENT		: // Node correctly sent message: the "sendDone" method notifies it.
			case MT_ALBA_RECV_ERROR	: // Node was not able to receive.
			case MT_ALBA_SEND_ERROR	: // Node was not able to send.
				break;
			case MT_ALBA_PREPARE_SEND :
				endContentionSenderRetry_( E_TX_PROBLEM );
				break;
				
			default :
				_error_( state_ );
				break;
				
		}
	}

	async event void ClockLocalTime.overflow() {}
		
	command error_t SplitControl.start() {
	
		state_ = MT_ALBA_IDLE;
			
		msg_recv_data_ = & free_msg_;
		
		//MN: devo mettere qui i miei timer
		
		busy_ = FALSE;
		received_ = FALSE;
		received_cts_ = FALSE;
		collision_ = FALSE;
		
		//variables inizialization
		sink_ = call IrisDutyCycleControl.isSink(); //MN: to check
		recv_ctrl_addr_ = 0xFFFF;

		reload_positions();

		n_p_ = NP;
		n_p_coll_ = NP_COLL;
		cont_type_ = QUEUE_CONT;
		coll_ra_type_ = STD_COLL_RA; //MN: to change in case of original collision resolution mechanism
		coll_type_ = coll_ra_type_;
		
		collRetryCount_ = 0;

		/* BACK-2-BACK Variables */
		num_data_of_burst_to_send_ = 0;
		relay_accepted_data_ = 0;
		real_max_burst_length_ = MAX_BURST_LENGTH;

		/* ALBA-R Variables */
		not_relaying_ = FALSE;
		num_empties_cycles_ = 0;
		nodeColor_ = 0;

		call IrisPhyPacket.prepare( & msg_rts_, AM_BROADCAST_ADDR );
		call IrisPhyPacket.prepare( & msg_cts_, AM_BROADCAST_ADDR );
		call IrisPhyPacket.prepare( & msg_ack_, AM_BROADCAST_ADDR );

		signal SplitControl.startDone( SUCCESS );
		return SUCCESS;
	}
	
	command error_t SplitControl.stop() {
		signal SplitControl.stopDone( SUCCESS );
		return SUCCESS;
	}

	command uint8_t IrisSend.maxPayloadLength() {
		return call Packet.maxPayloadLength();
	}

	command void* IrisSend.getPayload( message_t* msg, uint8_t len ) {
		return call Packet.getPayload( msg, len );
	}

	command error_t IrisSend.cancel( message_t * msg ) {
		call Packet.clear( msg );
		return SUCCESS;
	}

	event void IrisBackoff.backoff() {
		alba_data_msg_t* ptr_data = (alba_data_msg_t*) call SendData.getPayload( msg_data_, call SendData.maxPayloadLength() );
		ptr_data -> retry = ptr_data -> retry + 1;
		// call Leds.led2Toggle();
	}
	
	event void IrisBackoff.configure( backoff_config_t * conf ) {
		//MN: dove metto i miei valori di backoff?
		conf -> Wmin = 1;
		conf -> Wmax = 1;
		conf -> max_retry = 2;
		conf -> time_slot = call IrisDutyCycleControl.getDutyDuration();
	}
	
	event void AlbaPosition.positionChanged( bool sink ) {
		reload_positions();
	}
	
#ifdef USE_ALBA_REMOTE
	event void AlbaDebug.colorChanged() {
	}
	
	event void AlbaDebug.contentionEnd() {
	}
#endif

	//----------------------------------------------------------------------
	// Packet interface
	//----------------------------------------------------------------------
	
	command void Packet.clear( message_t * msg ) {
		alba_data_msg_t* ptr_msg = (alba_data_msg_t*) call SubPacket.getPayload( msg, 0 );
		
		(ptr_msg -> interest).x = call AlbaPosition.getSinkX();
		(ptr_msg -> interest).y = call AlbaPosition.getSinkY();
		(ptr_msg -> interest).sink = call AlbaPosition.getSinkID();
		
		updateMsg( msg );
		
		ptr_msg -> hops = 0;
		ptr_msg -> msg_to_send = 0;
		ptr_msg -> sender_color = 0;
#ifdef RECORD_TTL
		ptr_msg -> ttl = 0;
#endif
		ptr_msg -> dummy = 0;
		ptr_msg -> duty_up = 0;

		call IrisPhyPacket.prepareWithType( msg, AM_BROADCAST_ADDR, MT_ALBA_DATA );
	}

	command uint8_t Packet.payloadLength( message_t * msg ) {
		return call SubPacket.payloadLength( msg ) - sizeof( alba_data_msg_t );
    }

	command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
		call SubPacket.setPayloadLength( msg, len + sizeof( alba_data_msg_t ) );
	}
		
	command uint8_t Packet.maxPayloadLength() {
		return call SubPacket.maxPayloadLength() - sizeof( alba_data_msg_t );
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len) {
		if ( len > call Packet.maxPayloadLength() )
			return NULL;
		return call SubPacket.getPayload( msg, len + sizeof( alba_data_msg_t ) ) + sizeof( alba_data_msg_t );
	}

	async event void ActiveMessageAddress.changed() {}

}
