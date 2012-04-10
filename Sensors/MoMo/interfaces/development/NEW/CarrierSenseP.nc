#include "CarrierSense.h"

module CarrierSenseP {
    provides {
        //interface SplitControl;
        interface CarrierSense;
    }
    uses {
        interface Boot;
		interface Leds;
		
        interface ReceiveIndicator as EnergyIndicator;
        interface ReceiveIndicator as PacketIndicator;
        interface Alarm<T32khz,uint16_t> as CCATimer;
    }
}

implementation {
    
    enum {
        GET_NONE                = 0,
        GET_CARRIER_SENSE       = 1,
    };

    norace bool stop_cca_;
    norace uint8_t startup_carrier_sense_;
    norace uint16_t cca_duration_;		                // Duration of next CCA
   
   void _error_( uint8_t v ) {
		call Leds.set( v );
		for (;;) {}
	}
   	
	event void Boot.booted() {
        stop_cca_ = TRUE;
        startup_carrier_sense_ = GET_NONE;
        cca_duration_ = 0;
    }
    
    task void startCarrierSense();
    
    async command void CarrierSense.setCarrierSenseLength( uint16_t duration ) {
        cca_duration_ = duration;
    }
    
    async command uint16_t CarrierSense.getCarrierSenseLength() {
        return cca_duration_;
    }
    
    async command error_t CarrierSense.startCarrierSense() {
        //If node already receiving this attempt will fail
        //MN: modify
        /*
        if ( call PacketIndicator.isReceiving() )
            return FAIL;
        */
        //Add here more fail conditions
        if( cca_duration_ > 0 ) {
            post startCarrierSense();
        } else {
            signal CarrierSense.CarrierSenseResult( SUCCESS );
        }
        return SUCCESS;
    }
    
    task void startCarrierSense() {
		if ( stop_cca_ == FALSE )
			return;
		stop_cca_ = FALSE;
		startup_carrier_sense_ = GET_CARRIER_SENSE;
		
		call CCATimer.start( STARTUP_CCA );
	}
	
    task void getChannelSense() {
        while ( stop_cca_ == FALSE ) {
	       if ( call PacketIndicator.isReceiving() ) {
	           call CCATimer.stop();
               stop_cca_ = TRUE;
			   signal CarrierSense.CarrierSenseResult( EBUSY );
               return;
            }
            if ( call EnergyIndicator.isReceiving() ) {
                call CCATimer.stop();
	            stop_cca_ = TRUE;
			    signal CarrierSense.CarrierSenseResult( EBUSY );
				return;
            }
	    }
        signal CarrierSense.CarrierSenseResult( SUCCESS );
	}
	
	async event void CCATimer.fired() {
		if ( stop_cca_ == TRUE )
			return;
		switch ( startup_carrier_sense_ ) {
		
			case GET_CARRIER_SENSE :
				startup_carrier_sense_ = GET_NONE;
				call CCATimer.start( cca_duration_ );
				post getChannelSense();
				return;
            default:
				stop_cca_ = TRUE;
				return;
		}
	}
}
