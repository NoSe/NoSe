/**
 *
 * This module provides the LPLControl and DutyCycleControl interfaces.
 * It provides the commands that application and MAC layers use to
 * start and stop the radio (when the node is operating in periodic mode) 
 * or start and stop the low power listening 
 * (when the node is operating in real-time mode).
 * The radio is a shared resource managed by the RadioCapture interface.
 * This way prevents the application to stop the radio when the MAC layer is using it.
 * 
 */




module RadioControlP {

    provides {
        interface SplitControl;
        interface LPLControl;
        interface DutyCycleControl;
    }
    
    uses {
        interface RadioCapture as MACCapture;
        interface RadioCapture as AppCapture;
        interface MoMoQueue<momo_queue_info_t> as LLQueue;
        interface LowPowerListening as LPL;
        interface State as RadioState;
        interface SplitControl as DynamicControl; //control for turning on and off the radio when node is in Periodic mode
        interface SplitControl as SubControl; //control for starting the lower layer (MAC) and for managing low-power listening
        
        interface Timer<TMilli> as WaitingTimer;
        interface Leds;
    }
}

implementation {

    //Radio state 
    enum {
        S_TURNING_OFF,
        S_OFF, //radio is off by default
        S_TURNING_ON,
        S_ON,
    };
    
    //Node operation mode - Real-time or Periodic
    enum {
        M_IDLE,
        M_RT,
        M_PERIODIC,
    };
       
    bool force_awake_; //if true the node remains awake for awhile after the end of a contention
    uint8_t  radio_mode_;
    uint16_t my_sleep_duration_;
    uint16_t my_duty_cycle_;

    /***************** Functions and tasks ****************/
    
    /**** Radio Control ****/
    
    task void startRadio(); //turn on the radio
    task void stopRadio();  //turn off the radio
    
    task void startRadio() {
        if ( call DynamicControl.start() != SUCCESS ) {
            post startRadio();
            return;
        }
    }
    
    task void stopRadio() {
        //error_t error = 
        call DynamicControl.stop();
    }
    
    event void DynamicControl.startDone(error_t result) {
        if ( result != SUCCESS ) {
            post startRadio();
            return;
        }
        call RadioState.forceState( S_ON );
        signal DutyCycleControl.nodeIsOn();
#ifdef MM_SIGNAL_DUTY
        call Leds.led0On(); //MN: to remove
#endif
    }

    event void DynamicControl.stopDone(error_t result) {
        call RadioState.forceState( S_OFF );
        signal DutyCycleControl.nodeIsOff();
#ifdef MM_SIGNAL_DUTY
        call Leds.led0Off(); //MN: to remove
#endif 
    }
    
    /**** Lower-layers Control ****/
    
    command error_t SplitControl.start() {
        force_awake_ = FALSE;
        if ( call RadioState.isIdle() ) {
            radio_mode_ = M_RT; //the node starts to operate in Real-time mode
            call RadioState.forceState( S_TURNING_ON );
            call SubControl.start();
            return SUCCESS;
        }
        return FAIL;
    }
    
    command error_t SplitControl.stop() {
        if ( radio_mode_ == M_RT ) {
            if ( call RadioState.isState( S_ON ) ) {
                radio_mode_ = M_IDLE;
                call RadioState.forceState( S_TURNING_OFF );        
                call SubControl.stop();
                return SUCCESS;
            }
        }
        return FAIL;
    }
    
    event void SubControl.startDone(error_t result) {
        if ( result != SUCCESS ) {
            call SubControl.start();
            return;
        }
        call RadioState.forceState( S_ON );
        signal SplitControl.startDone(result);
    }
    
    event void SubControl.stopDone(error_t result) {
        call RadioState.forceState( S_OFF );
        signal SplitControl.stopDone(result);
     }
     
    /**** Low-power listening control ****/

    command void LPLControl.restartLPL() {
        //this automatically stops the radio before restarting the duty cycle
        call LPL.setLocalDutyCycle( call LPLControl.getNodeDutyCycle() );
    }
        
    command error_t LPLControl.stopLPL() {
        call LPL.setLocalSleepInterval( MM_ALWAYS_ON );
        if ( call SubControl.start() == EALREADY ) {
            //try again later or leave the contention
            return SUCCESS;   
        }
        return FAIL;
    }
    
    command void LPLControl.setNodeSleepDuration( uint16_t sleep_duration ) {
	   my_sleep_duration_ = sleep_duration;
	   my_duty_cycle_ = call LPL.sleepIntervalToDutyCycle( sleep_duration );
	   call LPL.setLocalSleepInterval( sleep_duration );
	}
	
	command uint16_t LPLControl.getNodeSleepDuration() {
	   return my_sleep_duration_;
	}
	
	command void LPLControl.setNodeDutyCycle( uint16_t duty_cycle ) {
	   my_duty_cycle_ = duty_cycle;
	   my_sleep_duration_ = call LPL.dutyCycleToSleepInterval( duty_cycle );
	   call LPL.setLocalDutyCycle( duty_cycle ); 
	}
	
	command uint16_t LPLControl.getNodeDutyCycle() {
	   return my_duty_cycle_;
	}
	
	command void LPLControl.setRxDutyCycle( message_t *msg, uint16_t duty_cycle ) {
	   call LPL.setRxDutyCycle( msg, duty_cycle );
	}
	
	command void LPLControl.setRxSleepInterval( message_t *msg, uint16_t sleep_duration ) {
	   call LPL.setRxSleepInterval( msg, sleep_duration );
	}
	
	command uint16_t LPLControl.getRxSleepInterval( message_t *msg ) {
	   return call LPL.getRxSleepInterval( msg );
	}
	
	//Lower-layer (MAC) requires the node to remain awake after this contention ends
	command void LPLControl.forceAwake() {
	   force_awake_ = TRUE;
    }
    
    //The node try to acquire immediately the radio resource -> contention starts (the node is acting as sender)
    command error_t LPLControl.startContention() {
        if ( call MACCapture.immediateRadioRequest() == SUCCESS ) {
            return call LPLControl.stopLPL();
        }
        return FAIL;
    }
    
    //The node try to acquire immediately the radio resource -> contention starts (the node is acting as receiver)
    command error_t LPLControl.enterContention() {
        if ( call MACCapture.immediateRadioRequest() == SUCCESS ) {
            //The node is not following the lpl duty cycle
            if ( call WaitingTimer.isRunning() == TRUE ) {
                call WaitingTimer.stop();
                return SUCCESS;
            } else return call LPLControl.stopLPL();
        }
        return FAIL;
    }
    
    command void LPLControl.stopContention() {
        if ( radio_mode_ == M_RT ) 
            call LPLControl.restartLPL();
        else {
            //PERIODIC MODE
            if ( call LLQueue.empty() == TRUE ) {
                //When required the node remains awake only if its queue is empty - otherwise it first finishes to manage its packets
                if ( force_awake_ == TRUE ) {
                    force_awake_ = FALSE;
                    call WaitingTimer.startOneShot( WAITING_TIME ); 
                } else { 
                    call RadioState.forceState( S_TURNING_OFF );
                    call DutyCycleControl.turnNodeOff();
                }
            }
        }
        call MACCapture.releaseRadio();
    }
    
    command void LPLControl.leaveContention() {
        if ( radio_mode_ == M_RT ) 
            call LPLControl.restartLPL();
        else {
            //PERIODIC MODE
            //If the code is not empty the radio is not turned off
            if ( call LLQueue.empty() == TRUE ) {
                call RadioState.forceState( S_TURNING_OFF );
                call DutyCycleControl.turnNodeOff();
            }   
        }
        call MACCapture.releaseRadio();
    }
    
    command error_t DutyCycleControl.startRTMode() {
        
        if ( radio_mode_ == M_RT ) return SUCCESS;
        
        //Application tries to acquire the radio
        if ( call AppCapture.radioRequest() == SUCCESS ) {
            radio_mode_ = M_RT;
            if ( call RadioState.isState( S_OFF ) )
                call RadioState.forceState( S_TURNING_ON );
            return SUCCESS;
        }
        return FAIL;
    }
    
    command error_t DutyCycleControl.stopRTMode() {
    
        if ( radio_mode_ == M_PERIODIC ) return SUCCESS;
    
        if ( call LPLControl.stopLPL() == SUCCESS ) {
            radio_mode_ = M_PERIODIC;            
            return SUCCESS;
        }
        return FAIL;
    }
    
    command error_t DutyCycleControl.turnNodeOn() {
        
        if ( radio_mode_ == M_RT ) return FAIL;
        
        if ( call RadioState.isState( S_OFF ) ) {
            call RadioState.forceState( S_TURNING_ON );
            post startRadio();
            return SUCCESS;
        } else if ( call RadioState.isState( S_ON ) )
            return EALREADY;

        return FAIL;
    }
    
    command error_t DutyCycleControl.turnNodeOff() {
    
        if ( radio_mode_ == M_RT ) return FAIL;
    
        //Application should acquire the radio before turning it off
        if ( call AppCapture.radioRequest() == SUCCESS ) {
            if ( call RadioState.isState( S_ON ) ) {
                call RadioState.forceState( S_TURNING_OFF );
                return SUCCESS;   
            } else if ( call RadioState.isState( S_ON ) )
                return EALREADY; 
        }
        
        return FAIL;
    }
    
    event void MACCapture.radioGranted( error_t result ) {
        if ( result != SUCCESS )
            return;
    }
    
    event void AppCapture.radioGranted( error_t result ) {
            if ( result != SUCCESS )
                return;
            
            if ( call RadioState.isState( S_TURNING_ON ) )
                call SubControl.start();
                
            if ( call RadioState.isState( S_TURNING_OFF ) )
                post stopRadio();
            
            call AppCapture.releaseRadio();
    }
    
    event void WaitingTimer.fired() {
        call RadioState.forceState( S_TURNING_OFF );
        call DutyCycleControl.turnNodeOff();
    }
    
    default event void DutyCycleControl.nodeIsOff() {}
    default event void DutyCycleControl.nodeIsOn() {}
}
