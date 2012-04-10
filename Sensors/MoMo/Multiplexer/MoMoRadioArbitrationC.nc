
#include "MoMoDefaults.h"

generic configuration MoMoRadioArbitrationC() {
	provides {
		interface RadioCapture;
	}
}
implementation {

	components MoMoRadioArbitrationP;

	components new MoMoMultiplexerP();
	
	RadioCapture						= MoMoMultiplexerP;
	
	MoMoMultiplexerP.Resource			-> MoMoRadioArbitrationP.Resource[ unique( MOMO_RADIO_RESOURCE ) ];

}

