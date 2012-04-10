
module RadioControlP {

    provides {
        interface SplitControl;
        interface LPLControl;
        interface DutyCycleControl;
    }
    
    uses {
        interface RadioCapture as RTCapture;
        interface RadioCapture as PeriodicCapture;
        interface NodeDuty;
        interface LowPowerListening as LPL;
        interface State as RTState;
        interface State as PeriodicState;
        interface State as SendState;
        interface SplitControl as PeriodicControl;
        interface SplitControl as SubControl;
        interface Leds;
    }
}

implementation {

    enum {
        S_OFF, // off by default
        S_TURNING_ON,
        S_ON,
        S_TURNING_OFF,
        S_STOPPED,
        S_STARTED,
        S_STARTING,
        S_STOPPING,
    };
    
    enum {
        M_LPL,
        M_PERIODIC,
    };
    
    uint8_t radio_mode_;
    
    uint16_t my_sleep_duration_;
    uint16_t my_duty_cycle_;

    /***************** Functions and tasks ****************/
    
    task void startRadio();
    task void stopRadio();
    
    task void startRadio() {
        if ( call PeriodicControl.start() != SUCCESS ) {
            post startRadio();
            return;
        }
    }
    
    task void stopRadio() {
        //error_t error = 
        call PeriodicControl.stop();
    }
    
    command error_t SplitControl.start() {
        radio_mode_ = M_LPL;
        call RTState.forceState( S_ON );
        call PeriodicState.forceState( S_STOPPED );
        call SubControl.start();
        return SUCCESS;
    }
    
    command error_t SplitControl.stop() {
        call SubControl.stop();
        return SUCCESS;
    }

    command void LPLControl.restartLPL() {
        //MN: this automatically stops the radio before restarting the duty cycle
        call LPL.setLocalDutyCycle( call LPLControl.getNodeDutyCycle() );
    }
        
    command error_t LPLControl.stopLPL() {
        call LPL.setLocalSleepInterval( MM_ALWAYS_ON );
        if ( call SubControl.start() == EALREADY ) {
            //MN: try again later or leave the contention
            return SUCCESS;   
        }
        return FAIL;
    }
    
    command error_t LPLControl.startContention() {
        if ( call RTCapture.immediateRadioRequest() == SUCCESS ) {
            return call LPLControl.stopLPL();
        }
        return FAIL;
    }
    
    command error_t LPLControl.enterContention() {
        if ( call RTCapture.immediateRadioRequest() == SUCCESS ) {
            return call LPLControl.stopLPL();
        }
        return FAIL;
    }
    
    command void LPLControl.stopContention() {
        if ( radio_mode_ == M_LPL ) call LPLControl.restartLPL();
        call RTCapture.releaseRadio();
    }
    
    command void LPLControl.leaveContention() {
        if ( radio_mode_ == M_LPL ) call LPLControl.restartLPL();
        call RTCapture.releaseRadio();
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
	   /*
	   if ( radio_mode_ == M_PERIODIC )
	       call LPL.setRxSleepInterval( msg, MM_ALWAYS_ON );
	   else 
	   */
	   call LPL.setRxDutyCycle( msg, duty_cycle );
	}
	
	command void LPLControl.setRxSleepInterval( message_t *msg, uint16_t sleep_duration ) {
	   /*
	   if ( radio_mode_ == M_PERIODIC )
	       call LPL.setRxSleepInterval( msg, MM_ALWAYS_ON );
	   else 
	   */
	   call LPL.setRxSleepInterval( msg, sleep_duration );
	}
	
	command uint16_t LPLControl.getRxSleepInterval( message_t *msg ) {
	   return call LPL.getRxSleepInterval( msg );
	}
    
    command error_t DutyCycleControl.startRTMode() {
        
        if ( call PeriodicCapture.radioRequest() == SUCCESS ) {
            call PeriodicState.toIdle();
            call RTState.forceState( S_TURNING_ON );
            return SUCCESS;
        }
        return FAIL;
    }
    
    command error_t DutyCycleControl.stopRTMode() {
    
        if ( call RTState.isIdle() || ( call RTState.isState( S_ON ) ) ) {
            if ( call LPLControl.stopLPL() == SUCCESS ) {
                call RTState.forceState( S_OFF );
                return SUCCESS;
            }
            call RTState.forceState( S_TURNING_OFF );
        }
        return FAIL;
    }
    
    command error_t DutyCycleControl.turnNodeOn() {
        
        
        if ( call RTState.isState( S_OFF ) ) {
            if ( call PeriodicState.isIdle() || call PeriodicState.isState( S_STOPPED ) ) { 
                call PeriodicState.forceState( S_STARTING );
                post startRadio();
                return SUCCESS;
            }
        }
        return FAIL;
    }
    
    command error_t DutyCycleControl.turnNodeOff() {
    
        if ( call RTState.isState( S_OFF ) ) {
            if ( call PeriodicState.isIdle() || call PeriodicState.isState( S_STARTED ) ) {
                if ( call SendState.isIdle() ) {
                    call Leds.led1Toggle();      
                    if ( call PeriodicCapture.radioRequest() == SUCCESS ) {
                        call PeriodicState.forceState( S_STOPPING );
                        call Leds.led2On();
                        return SUCCESS;
                    }
                }
            }
        }
        return FAIL;    
    }
    
    event void NodeDuty.nodeIsOn() {
#ifdef MM_SIGNAL_DUTY
        call Leds.led0On(); //MN: to remove
#endif
        if ( call RTState.isState( S_TURNING_OFF ) ) {
            if ( call LPLControl.stopLPL() == SUCCESS )
                call RTState.forceState( S_OFF );
        }
    }
    
    event void NodeDuty.nodeIsOff() {
#ifdef MM_SIGNAL_DUTY
        call Leds.led0Off(); //MN: to remove
#endif
    }

    event void PeriodicControl.startDone(error_t result) {
        if ( result != SUCCESS ) {
            post startRadio();
            return;
        }
        if ( call PeriodicState.isState( S_STARTING ) ) {
            radio_mode_ = M_PERIODIC;
            call PeriodicState.forceState( S_STARTED );
            signal DutyCycleControl.nodeIsOn();
        } 
    }

    event void PeriodicControl.stopDone(error_t result) {
        if ( call PeriodicState.isState( S_STOPPING ) ) {
            radio_mode_ = M_PERIODIC;
            call PeriodicState.forceState( S_STOPPED );
            call PeriodicCapture.releaseRadio();
            signal DutyCycleControl.nodeIsOff();
        } 
    }
    
    event void SubControl.startDone(error_t result) {
        if ( result != SUCCESS ) {
            call SubControl.start();
            return;
        }
        if ( radio_mode_ == M_LPL ) {
           signal SplitControl.startDone(result);
           return;
        }
    }
    
    event void SubControl.stopDone(error_t result) {
        if ( radio_mode_ == M_LPL ) {
            signal SplitControl.stopDone(result);
            return;
        }
     }
    
    event void PeriodicCapture.radioGranted( error_t result ) {
        if ( result != SUCCESS )
            return;
    
        if ( call RTState.isState( S_TURNING_ON ) ) {
            radio_mode_ = M_LPL;
            call RTState.forceState( S_ON );
            call LPLControl.restartLPL();
            call PeriodicCapture.releaseRadio();
        }
        
        if ( call PeriodicState.isState( S_STOPPING ) ) {
            call Leds.led2Off();
            post stopRadio();
        }
    }
    
    event void RTCapture.radioGranted( error_t result ) {
            if ( result != SUCCESS )
            return;
            
            call RTCapture.releaseRadio();
    }
    
    default event void DutyCycleControl.nodeIsOff() {}
    default event void DutyCycleControl.nodeIsOn() {}
}
