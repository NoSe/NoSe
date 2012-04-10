
configuration DutyCycleControlC {

    provides {
        interface DutyCycleControl;
    }
}

implementation {

    components RadioControlC, LedsC, DutyCycleControlP;
    
    DutyCycleControl                     = DutyCycleControlP;
    
    DutyCycleControlP.RadioControl       -> RadioControlC;
    DutyCycleControlP.Leds               -> LedsC;
    
    components PowerCycleC;
    DutyCycleControlP.NodeDuty           -> PowerCycleC.NodeDuty;
    
    components CC2420CsmaC;
    DutyCycleControlP.SubControl         -> CC2420CsmaC;
     
    components new StateC() as RTState;
    DutyCycleControlP.RTState            -> RTState;
    
    components new StateC() as PeriodicState;
    DutyCycleControlP.PeriodicState      -> PeriodicState;
    
#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    components DefaultLplC as LplC;
    DutyCycleControlP.SendState          -> LplC;
#else
    components DummyLplC as LplC;
    DutyCycleControlP.SendState          -> LplC;
#endif

    components new MoMoRadioArbitrationC();
	DutyCycleControlP.RadioCapture		 -> MoMoRadioArbitrationC;
       
}
