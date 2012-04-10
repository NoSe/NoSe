#include "MoMoLLconst.h"


configuration MoMoLLC {

    provides {
        interface SplitControl; 
        interface Send;
        interface Receive;        
    }
}

implementation {

#ifdef MM_DEBUG
    components LedsC;
#else
    components NoLedsC as LedsC;
#endif

    components MainC, MoMoLLP as LL, MoMoMACC, NodeControlC, RandomC, ActiveMessageC;
    
    SplitControl                 = LL;
    Send                         = LL.Send;
    Receive                      = LL.Receive;
    
    LL.Boot                     -> MainC;
    LL.Leds                     -> LedsC;
    LL.NodeControl              -> NodeControlC;
    LL.Random                   -> RandomC;
    LL.AMPacket                 -> ActiveMessageC;
    
    components new MoMoQueueC( momo_queue_info_t, MM_QUEUE ) as LLQueue;
    components new PoolC( message_t, MM_QUEUE ) as MessageCache;
    components RadioControlC;

    LL.Queue                    -> LLQueue;
    LL.MessageCache             -> MessageCache;
    RadioControlC.LLQueue       -> LLQueue;
       
    LL.SubSend                  -> MoMoMACC.Send;
    LL.SubReceive               -> MoMoMACC.Receive; 
    LL.SubControl               -> MoMoMACC.SplitControl;
    
    components new TimerMilliC() as Backoff;
    LL.Backoff                  -> Backoff;
    
}
