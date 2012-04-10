
interface CarrierSense {
    
    async command void setCarrierSenseLength( uint16_t duration );
    
    async command uint16_t getCarrierSenseLength();
    
    async command error_t startCarrierSense();
    
    async event void CarrierSenseResult( error_t result );
    
}
