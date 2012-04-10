/*
 * Copyright (c) 2007 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date July 24, 2007
 */

generic module PeriodicSampleLoggerP(uint8_t num_sensors, 
                                     typedef sensor_type_t) {
  provides interface SampleLogConfiguration;
  
  uses {
    interface Boot;
    interface Read<sensor_type_t> as Sensor[uint8_t];
    interface Timer<TMilli> as Timer;
    interface LocalTime<TMilli>;
    interface LogWrite;
    interface Leds;
  }
}
implementation {
  #include "GenericSensorSample.h"

  generic_sensor_sample_t sample[2];
  generic_sensor_sample_t* current_sample;
  uint8_t current_sample_id;
  uint32_t period_ms;
  uint32_t sample_num;
  
  uint8_t sensor_type;
  uint16_t threshold;
  
  uint32_t num_samples;
  uint32_t sample_value;
  
  bool storage_on;

  task void eraseTask();
  task void appendTask();

  void readSensors() {
    int i;
    sample[current_sample_id].sample_num = sample_num;
    sample_num ++;
    sample[current_sample_id].time_stamp = call LocalTime.get();
    for(i=0; i<num_sensors; i++)
      call Sensor.read[i]();
  }

  void appendSample(generic_sensor_sample_t* s) {
    //printf("WRITE LOC: %d\n", call LogWrite.currentOffset());
    if(call LogWrite.append(s, sizeof(generic_sensor_sample_t)) != SUCCESS)
      post appendTask();
  }

  task void eraseTask() {
    if(call LogWrite.erase() != SUCCESS)
      post eraseTask();
  }

  task void appendTask() {
    appendSample(&(sample[!current_sample_id]));
  }

  event void Boot.booted() {
    sample_num = 0;
    threshold = 0;
    sensor_type = 0;
    num_samples = 0;
    sample_value = 0;
    storage_on = TRUE;
    if(call LogWrite.erase() != SUCCESS)
      post eraseTask();
  }

  event void LogWrite.eraseDone(error_t error) {
    sample[0].sample_num = 0;
    sample[1].sample_num = 1;
    current_sample_id = 0;
    current_sample = &(sample[current_sample_id]);
    //readSensors();
    //call Timer.startPeriodic(period_ms);
  }

  event void Timer.fired() {
    call Leds.led0Toggle();
    if ( storage_on == TRUE ) appendSample(current_sample);
    current_sample_id = !current_sample_id;
    current_sample = &(sample[current_sample_id]);
    readSensors();
  }

  event void Sensor.readDone[uint8_t i](error_t result, sensor_type_t val) {
    uint16_t value = 0;
    if(result == SUCCESS) {
      current_sample->values[i] = val;
      value = ((sensor_sample_t*)current_sample)->sensor_readings[sensor_type];
      if ( i == sensor_type ) {
          atomic {
            num_samples ++;
            sample_value += (uint32_t) value;
          }
          if ( value < threshold )
            signal SampleLogConfiguration.alarm( (sensor_sample_t*)current_sample );
      }
      call Leds.led1Toggle();
    }
    else {
      current_sample->values[i] = ((generic_sensor_sample_type_union_t)(0xFFFFFFFF)).st;
      call Leds.led2Toggle();
    }
  }

  event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t error){
    if(error != SUCCESS)
      post appendTask();
    else {
      call LogWrite.sync();
      ((generic_sensor_sample_t*)buf)->sample_num+=2;
    }
  }
  event void LogWrite.syncDone(error_t error) {}
  default command error_t Sensor.read[uint8_t i]() {return SUCCESS;}
  
  command void SampleLogConfiguration.enableStorage() {
    storage_on = TRUE;
  }
  
  command void SampleLogConfiguration.disableStorage() {
    storage_on = FALSE;
  }

  command void SampleLogConfiguration.setSamplingPeriod(uint32_t interval) {
    sample_num = 0;
    num_samples = 0;
    sample_value = 0;
    period_ms = interval;
    readSensors();
    //after the given timeout another reading should be performed
    if ( call Timer.isRunning() )
        call Timer.stop();
    call Timer.startPeriodic( period_ms );
  }
  
  command void SampleLogConfiguration.setSensorSource(uint8_t type) {
    sensor_type = type;
  }
  
  command void SampleLogConfiguration.setAlarmThreshold(uint16_t thr) {
    threshold = thr;
  }
  
  command uint8_t SampleLogConfiguration.getSensorSource() {
    return sensor_type;
  }
    
  command uint16_t SampleLogConfiguration.getAlarmThreshold() {
    return threshold;
  }
  
  command uint16_t SampleLogConfiguration.getAverage() {
    uint16_t avg;
    atomic {
        avg = ( sample_value ) ? (uint16_t)( sample_value / num_samples ) : 0;
        sample_value = 0;
        num_samples = 0;
    }
    return avg;
  }
}
