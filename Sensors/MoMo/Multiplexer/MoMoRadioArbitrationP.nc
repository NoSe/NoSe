
configuration MoMoRadioArbitrationP {
	provides {
		interface Resource[ uint8_t ];
	}
}
implementation {

	components new MoMoFcfsArbiterC( MOMO_RADIO_RESOURCE ) as Arbiter;
	Resource = Arbiter.Resource;
	
}

