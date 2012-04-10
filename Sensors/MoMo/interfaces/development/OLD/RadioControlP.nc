#include "MoMoMACconst.h"

module RadioControlP {

    provides {
        interface RadioControl;
    }
    
    uses {
        interface Leds;
        interface SplitControl as SubControl;
        interface LowPowerListening as DutyCycle;
    }
}

implementation {

    enum {
        S_STARTING_RADIO,
        S_STOPPING_DUTY,
    };
    
    uint8_t state_;
    uint16_t my_sleep_duration_;
    uint16_t my_duty_cycle_;

    command error_t RadioControl.startRadio() {
        state_ = S_STARTING_RADIO;
        call SubControl.start();
        return SUCCESS;
    }
    
    event void SubControl.startDone( error_t result ) {
        if ( state_ == S_STARTING_RADIO ) {
            if ( result != SUCCESS ) {
                call SubControl.start();
                return;
            }
            //MN: radio has been turned ON
            signal RadioControl.startRadioDone( SUCCESS );
        } else if ( state_ == S_STOPPING_DUTY ) {
            signal RadioControl.stopDutyCycleDone( result );            
        }
    }
    
    command void RadioControl.restartDutyCycle() {
        //MN: this automatically stops the radio before starting the duty cycle
        call DutyCycle.setLocalDutyCycle( call RadioControl.getNodeDutyCycle() );
    }
    
    event void SubControl.stopDone( error_t result ) {
        if ( result != SUCCESS ) {
            call DutyCycle.setLocalDutyCycle( call RadioControl.getNodeDutyCycle() );
            return;
        }
        //MN: the duty cycle has been started
        signal RadioControl.restartDutyCycleDone( SUCCESS );
    }
    
    command error_t RadioControl.stopDutyCycle() {
        state_ = S_STOPPING_DUTY;
        call DutyCycle.setLocalSleepInterval( MM_ALWAYS_ON );
        if ( call SubControl.start() == EALREADY ) {
            //MN: try again later or leave the contention
            return SUCCESS;   
        }
        return FAIL;
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

}
