
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
    components CC2420ActiveMessageC as RadioManager;
    components DefaultLplC as LplC;
    RadioControlP.SendState             -> LplC;
    RadioControlP.LPL                   -> RadioManager;
    RadioControlP.SubControl            -> RadioManager;
#else
    components DummyLplC as LplC;
    RadioControlP.SendState             -> LplC;
    RadioControlP.LPL                   -> LplC;
    RadioControlP.SubControl            -> LplC;
#endif

    components new MoMoRadioArbitrationC() as RTCapture;
    components new MoMoRadioArbitrationC() as PeriodicCapture;
	RadioControlP.RTCapture             -> RTCapture;
	RadioControlP.PeriodicCapture       -> PeriodicCapture;
}
