
interface DutyCycleControl {

    /*
    command error_t setAwakeDuration( uint32_t awake_duration );
    
    command uint32_t getAwakeDuration();
    
    command error_t setSleepDuration( uint32_t sleep_duration );
    
    command uint32_t getSleepDuration();
    */
    
    command error_t startRTMode();
    
    command error_t stopRTMode();
    
    command error_t turnNodeOn();
    
    event void nodeIsOn();
    
    command error_t turnNodeOff();
    
    event void nodeIsOff();
    
}
