
generic module MoMoMultiplexerP() {
	provides {
		interface RadioCapture;
	}
	uses {
		interface Resource;
	}
}
implementation {

	//------------------------------------------------------------------------------------
	// Release Tasks
	//------------------------------------------------------------------------------------

	task void release() {
		call Resource.release();
	}

	//------------------------------------------------------------------------------------
	// Radio Capture Management
	//------------------------------------------------------------------------------------
	
	command error_t RadioCapture.radioRequest() {
		if ( call Resource.request() != SUCCESS )
			return EBUSY;
		return SUCCESS;
	}
	
	command error_t RadioCapture.immediateRadioRequest() {
		if ( call Resource.immediateRequest() != SUCCESS )
			return FAIL;
		return SUCCESS;
	}

	command error_t RadioCapture.releaseRadio() {
		if ( call Resource.isOwner() == FALSE )
			return FAIL;
		post release();
		return SUCCESS;
	}
	
	event void Resource.granted() {
		signal RadioCapture.radioGranted( SUCCESS );
	}

}
