module DutyCycleControlP {

    provides {
        interface DutyCycleControl;
    }
    
    uses {
        interface RadioControl;
        interface NodeDuty;
        interface State as RTState;
        interface State as PeriodicState;
        interface State as SendState;
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

    /***************** Functions and tasks ****************/
    
    task void startRadio();
    task void stopRadio();
    
    task void startRadio() {
        if ( call SubControl.start() != SUCCESS ) {
            post startRadio();
            return;
        }
    }
    
    task void stopRadio() {
        //error_t error = 
        call SubControl.stop();
    }
    
    
    command error_t DutyCycleControl.startRTMode() {
        
        call PeriodicState.toIdle();
        call RTState.forceState( S_ON );
        call RadioControl.restartDutyCycle();
        return SUCCESS;
    }
    
    command error_t DutyCycleControl.stopRTMode() {
    
        if ( call RTState.isIdle() || ( call RTState.isState( S_ON ) ) ) {
            if ( call RadioControl.stopDutyCycle() == SUCCESS ) {
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
                    call PeriodicState.forceState( S_STOPPING );    
                    post stopRadio();
                    return SUCCESS;
                }
            }
        }
        return FAIL;    
    }
    
    event void NodeDuty.nodeIsOn() {
        if ( call RTState.isState( S_TURNING_OFF ) ) {
            if ( call RadioControl.stopDutyCycle() == SUCCESS )
                call RTState.forceState( S_OFF );
        }
    }
    
    event void NodeDuty.nodeIsOff() {
    }
        
    event void RadioControl.startRadioDone(error_t error) {
    }
    
    event void RadioControl.stopRadioDone(error_t error) {
    }

    event void SubControl.startDone(error_t error) {
        if ( call PeriodicState.isState( S_STARTING ) ) {
            signal DutyCycleControl.nodeIsOn();
            call PeriodicState.forceState( S_STARTED );
        }
    }

    event void SubControl.stopDone(error_t error) {
        if ( call PeriodicState.isState( S_STOPPING ) ) {
            signal DutyCycleControl.nodeIsOff();
            call PeriodicState.forceState( S_STOPPED );
        }
    }
}
