#include "MoMoMsg.h"

configuration ForceAwakeC {

    provides {
        interface ForceAwake;
    }
}

implementation {

    components ForceAwakeP;
    
    ForceAwake                    = ForceAwakeP;
       
}
