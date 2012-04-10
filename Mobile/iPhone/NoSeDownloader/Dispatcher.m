//
//  Dispatcher.m
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Dispatcher.h"
#import "Configuration.h"
#import "Store.h"
#import "NoSeConnector.h"

@interface Dispatcher (Private)

- (void) updateInterfaceWithReachability: (Reachability*) curReach;

@end

/**
 * This class is responsible to deliver packets to internet
 */
@implementation Dispatcher

static Dispatcher * sharedDispatcher = nil;

- (id) init
{
    self = [ super init ];
    if ( self ) {
        
        // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
        // method "reachabilityChanged" will be called. 
        [[ NSNotificationCenter defaultCenter ] addObserver:self 
                                                   selector:@selector(reachabilityChanged:) 
                                                       name:kReachabilityChangedNotification 
                                                     object: nil];
        
        hostReach = [[ Reachability reachabilityWithHostName:NOSE_SERVER ] retain ];
        [ self updateInterfaceWithReachability: hostReach ];
        
    }
    return self;
}

- (void) work
{
    NSAutoreleasePool * pool = [[ NSAutoreleasePool alloc ] init ];
    
    float timeToRetryLater = 5.0;
    
    NoSeConnector * connector = [[ NoSeConnector alloc ] initWithHost:@"http://nodisensori.appspot.com" ];
    
    while ( ! [[ NSThread currentThread ] isCancelled ] ) {
        NSManagedObjectID * objectID = [[ Store sharedStore ] getFirstPacket ];
        if ( objectID == nil ) {
            NSLog(@"No more packets to deliver in internet: retry later...");
            [ NSThread sleepForTimeInterval:timeToRetryLater ];
            continue;
        }
        NSManagedObject * object = [[ Store sharedStore ] objectByID:objectID ];
        
        @try {
            id ret = [ connector unreliableAsyncCallToMethod:@"data" withData:[ object valueForKey:@"data" ]];
            if ( ret != nil ) {
                NSLog(@"Remove packet: %@", [ object valueForKey:@"data" ]);
                [[ Store sharedStore ] removePacket:objectID ];
                [ NSThread sleepForTimeInterval:timeToRetryLater ];
            }
            
        }
        @catch (NSException *exception) {
            NSLog(@"Error sending packet online - %@: retry later...", [ exception description ]);
            [ NSThread sleepForTimeInterval:timeToRetryLater ];
        }
        
    }
    
    [ connector release ];
    
    [ pool release ];
}

- (void) start
{
    [ hostReach startNotifier ];
}

- (void) stop
{
    [ hostReach stopNotifier ];
}

#pragma mark - Reachbility

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    switch ( [ curReach currentReachabilityStatus ] ) {
        case ReachableViaWWAN:
            NSLog(@"Connected via WWAN");
            if ( sendThread == nil ) {
                sendThread = [[ NSThread alloc ] initWithTarget:self selector:@selector(work) object:nil ];
                [ sendThread start ];
            }
            break;
            
        case ReachableViaWiFi:
            NSLog(@"Connected via WiFi");
            if ( sendThread == nil ) {
                sendThread = [[ NSThread alloc ] initWithTarget:self selector:@selector(work) object:nil ];
                [ sendThread start ];
            }
            break;
            
        case NotReachable:
            NSLog(@"Not reachble");
            if ( sendThread != nil ) {
                [ sendThread cancel ];
                [ sendThread release ];
                sendThread = nil;
            }
            break;
            
    }
    
    /*
     [self configureTextField: remoteHostStatusField imageView: remoteHostIcon reachability: curReach];
     NetworkStatus netStatus = [curReach currentReachabilityStatus];
     BOOL connectionRequired= [curReach connectionRequired];
     
     summaryLabel.hidden = (netStatus != ReachableViaWWAN);
     NSString* baseLabel=  @"";
     if(connectionRequired)
     {
     baseLabel=  @"Cellular data network is available.\n  Internet traffic will be routed through it after a connection is established.";
     }
     else
     {
     baseLabel=  @"Cellular data network is active.\n  Internet traffic will be routed through it.";
     }
     summaryLabel.text= baseLabel;
     */
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}

#pragma - Singleton pattern

+ (Dispatcher*) sharedDispatcher
{
    @synchronized(self) {
        if ( sharedDispatcher == nil ) {
            [[ self alloc ] init ]; // assignment not done here
        }
    }
    return sharedDispatcher;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedDispatcher == nil) {
            sharedDispatcher = [ super allocWithZone:zone ];
            return sharedDispatcher;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
