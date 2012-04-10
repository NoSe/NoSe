#include "MoMoMsg.h"

configuration NodeControlC {

    provides {
        interface NodeControl;
    }
}

implementation {

    components MainC, NodeControlP;
    
    NodeControlP.Boot              -> MainC;
    
    components ActiveMessageAddressC;
    NodeControlP.LocalAddress      -> ActiveMessageAddressC;
    
    NodeControl                    = NodeControlP;
       
}
