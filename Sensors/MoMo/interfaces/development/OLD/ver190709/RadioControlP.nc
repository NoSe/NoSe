#include "MoMoMACconst.h"

module RadioControlP {

    provides {
        interface RadioControl;
    }
    
    uses {
        interface Leds;
        interface SplitControl as SubControl;
        interface LowPowerListening as DutyCycle;
        interface NodeDuty;
		interface RadioCapture;
    }
}

implementation {

    uint16_t my_sleep_duration_;
    uint16_t my_duty_cycle_;

    command error_t RadioControl.startRadio() {
        call SubControl.start();
        return SUCCESS;
    }
    
    command error_t RadioControl.stopRadio() {
        call SubControl.stop();
        return SUCCESS;
    }
    
    event void SubControl.startDone( error_t result ) {
        if ( result != SUCCESS ) {
            call SubControl.start();
            return;
        }
        //MN: radio has been turned ON
        signal RadioControl.startRadioDone( SUCCESS );
    }
    
    command void RadioControl.restartDutyCycle() {
        //MN: this automatically stops the radio before restarting the duty cycle
        call DutyCycle.setLocalDutyCycle( call RadioControl.getNodeDutyCycle() );
    }
    
    event void SubControl.stopDone( error_t result ) {
    
        //call Leds.led0Off(); //MN: to remove
        signal RadioControl.stopRadioDone( SUCCESS );
    }
    
    event void NodeDuty.nodeIsOn() {
#ifdef MM_SIGNAL_DUTY
        call Leds.led0On(); //MN: to remove
#endif
    }
    
    event void NodeDuty.nodeIsOff() {
#ifdef MM_SIGNAL_DUTY
        call Leds.led0Off(); //MN: to remove
#endif
    }
    
    command error_t RadioControl.stopDutyCycle() {
        call DutyCycle.setLocalSleepInterval( MM_ALWAYS_ON );
        if ( call SubControl.start() == EALREADY ) {
            //MN: try again later or leave the contention
            return SUCCESS;   
        }
        return FAIL;
    }
    
    command error_t RadioControl.startContention() {
        if ( call RadioCapture.immediateRadioRequest() == SUCCESS ) {
            return call RadioControl.stopDutyCycle();
        }
        return FAIL;
    }
    
    command error_t RadioControl.enterContention() {
        if ( call RadioCapture.immediateRadioRequest() == SUCCESS ) {
            return call RadioControl.stopDutyCycle();
        }
        return FAIL;
    }
    
    command void RadioControl.stopContention() {
        call RadioControl.restartDutyCycle();
        call RadioCapture.releaseRadio();
    }
    
    command void RadioControl.leaveContention() {
        call RadioControl.restartDutyCycle();
        call RadioCapture.releaseRadio();
    }

    command void RadioControl.setNodeSleepDuration( uint16_t sleep_duration ) {
	   my_sleep_duration_ = sleep_duration;
	   my_duty_cycle_ = call DutyCycle.sleepIntervalToDutyCycle( sleep_duration );
	   call DutyCycle.setLocalSleepInterval( sleep_duration );
	}
	
	command uint16_t RadioControl.getNodeSleepDuration() {
	   return my_sleep_duration_;
	}
	
	command void RadioControl.setNodeDutyCycle( uint16_t duty_cycle ) {
	   my_duty_cycle_ = duty_cycle;
	   my_sleep_duration_ = call DutyCycle.dutyCycleToSleepInterval( duty_cycle );
	   call DutyCycle.setLocalDutyCycle( duty_cycle ); 
	}
	
	command uint16_t RadioControl.getNodeDutyCycle() {
	   return my_duty_cycle_;
	}
	
	command void RadioControl.setRxDutyCycle( message_t *msg, uint16_t duty_cycle ) {
	   call DutyCycle.setRxDutyCycle( msg, duty_cycle );
	}
	
	command void RadioControl.setRxSleepInterval( message_t *msg, uint16_t sleep_duration ) {
	   call DutyCycle.setRxSleepInterval( msg, sleep_duration );
	}
	
	command uint16_t RadioControl.getRxSleepInterval( message_t *msg ) {
	   return call DutyCycle.getRxSleepInterval( msg );
	}
	
	event void RadioCapture.radioRequestDone( error_t result ) {}
}
