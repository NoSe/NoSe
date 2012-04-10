
interface DutyCycleControl {

    // MN: commands currently not implemented
    /*
    command error_t setAwakeDuration( uint32_t awake_duration );
    
    command uint32_t getAwakeDuration();
    
    command error_t setSleepDuration( uint32_t sleep_duration );
    
    command uint32_t getSleepDuration();
    */
    
    /* the node starts to operate in real-time mode (LPL) */
    command error_t startRTMode();
    
    /* the node stops to operate in real-time mode (LPL) */
    command error_t stopRTMode();
    
    command error_t turnNodeOn();
    
    event void nodeIsOn();
    
    command error_t turnNodeOff();
    
    event void nodeIsOff();
    
}
