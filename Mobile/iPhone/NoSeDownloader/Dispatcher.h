//
//  Dispatcher.h
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface Dispatcher : NSObject
{
    Reachability        * hostReach;
    NSThread            * sendThread;
}

- (void) start;

- (void) stop;

+ (Dispatcher*) sharedDispatcher;

@end
