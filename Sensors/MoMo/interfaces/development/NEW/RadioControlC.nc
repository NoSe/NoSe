
configuration RadioControlC {

    provides {
        interface SplitControl;
        interface LPLControl;
        interface DutyCycleControl;
    }
}

implementation {

    components RadioControlC, LedsC, RadioControlP;
    
    SplitControl                         = RadioControlP;
    LPLControl                           = RadioControlP;
    DutyCycleControl                     = RadioControlP;
    
    RadioControlP.Leds                  -> LedsC;
    
    components PowerCycleC;
    RadioControlP.NodeDuty              -> PowerCycleC.NodeDuty;
    
    components CC2420CsmaC;
    RadioControlP.PeriodicControl       -> CC2420CsmaC;
     
    components new StateC() as RTState;
    RadioControlP.RTState               -> RTState;
    
    components new StateC() as PeriodicState;
    RadioControlP.PeriodicState         -> PeriodicState;
    
#if defined(PLATFORM_TELOSB) && defined(LOW_POWER_LISTENING)
    components DefaultLplC as LplC;
    components CC2420ActiveMessageC as RadioManager;
    RadioControlP.SendState             -> LplC;
    RadioControlP.LPL                   -> RadioManager;
    RadioControlP.SubControl            -> RadioManager;
#else
    components DummyLplC as LplC;
    RadioControlP.SendState             -> LplC;
    RadioControlP.LPL                   -> LplC;
    RadioControlP.SubControl            -> LplC;
#endif

    components new MoMoRadioArbitrationC();
	RadioControlP.RadioCapture		    -> MoMoRadioArbitrationC;
       
}
