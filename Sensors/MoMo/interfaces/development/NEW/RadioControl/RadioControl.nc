
interface RadioControl {

    /**
	 * Start the radio for the first time
	 */
    command error_t startRadio();
    
    /**
	 * Stop the radio
	 */
    command error_t stopRadio();
    
    event void startRadioDone( error_t error );
    
    event void stopRadioDone( error_t error );
    /**
	 * Start/resume the node's duty cycle
	 */
    command void restartDutyCycle();
    
    /**
	 * Stop the node's duty cycle
	 */
    command error_t stopDutyCycle();
    
    command error_t startContention();
    
    command error_t enterContention();
    
    command void stopContention();
    
    command void leaveContention();
    
    /**
	 * Set node's sleep duration (in [ms])
	 */
	command void setNodeSleepDuration( uint16_t sleep_duration );

	/**
	 * Return node's sleep duration
	 */
	command uint16_t getNodeSleepDuration();

	/**
	 * Set node's duty cycle (in units of [percentage*100])
	 */
	command void setNodeDutyCycle( uint16_t duty_cycle );

	/**
	 * Return node's duty cycle
	 */
	command uint16_t getNodeDutyCycle();
	
	command void setRxDutyCycle( message_t *msg, uint16_t duty_cycle );
	
	command void setRxSleepInterval( message_t *msg, uint16_t sleep_duration );
	
	command uint16_t getRxSleepInterval( message_t *msg );

}
