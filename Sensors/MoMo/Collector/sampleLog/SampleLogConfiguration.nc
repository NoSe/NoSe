
interface SampleLogConfiguration {

    /* enable the storage in flash of the collected samples */
    command void enableStorage();
    
    /* disable the storage in flash of the collected samples */
    command void disableStorage();

    /* set the interval for acquiring samples from the sensors */
    command void setSamplingPeriod(uint32_t interval);
    
    /* set the sensor from which the collected metric comes */
    command void setSensorSource(uint8_t type);
    
    /* set the threshold value for alarm signaling */
    command void setAlarmThreshold(uint16_t thr);
    
    /* return the sensor from which the collected metric comes */
    command uint8_t getSensorSource();
    
    /* return the threshold value for alarm signaling */
    command uint16_t getAlarmThreshold();
    
    /* return the average of the collected metrics */
    command uint16_t getAverage();

    /* the threshold has been exceeded - send an alarm */
    event void alarm(sensor_sample_t* sample);
}
