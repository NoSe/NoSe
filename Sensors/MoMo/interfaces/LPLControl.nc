
interface LPLControl {

    /*
	 * Start/resume the node's duty cycle (LPL)
	 */
	 command void restartLPL();
	 
	 /**
	 * Stop the node's duty cycle (LPL)
	 */
	 command error_t stopLPL();
	 
	 /**
	 * The node starts a contention as sender
	 */
	 command error_t startContention();
	 
	 /**
	 * The node starts a contention as sender
	 */
	 command error_t enterContention();
	 
	 /**
	 * The sender node terminates the current contention
	 */
	 command void stopContention();
	 
	 /**
	 * The receiver node leaves the current contention
	 */
	 command void leaveContention();
	 
	 /**
	 * The node is required to stay awake
	 */
	 command void forceAwake();
	 
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
	
	/**
	 * Same commands implemented by LowPowerListening interface
	 */
	command void setRxDutyCycle( message_t *msg, uint16_t duty_cycle );
	
	command void setRxSleepInterval( message_t *msg, uint16_t sleep_duration );
	
	command uint16_t getRxSleepInterval( message_t *msg );

}
