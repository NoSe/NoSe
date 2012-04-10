
interface RadioCapture {

    /* The node requires to use the radio when available */
    command error_t radioRequest();
    
    /* The node requires to immediately use the radio - if not available the request is dropped */
    command error_t immediateRadioRequest();
    
    /* The radio is granted */
    event void radioGranted( error_t result );

    /* The node releases the radio */
    command error_t releaseRadio();

}
