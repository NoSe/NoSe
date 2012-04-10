//
//  Store.h
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define NOTIFICATION_PACKET_REMOVE          @"PacketRemoved"

@interface Store : NSObject
{
    NSUInteger packetsStored;
}

@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;

- (BOOL) addMessage:(NSString*) message;

- (NSManagedObject*) objectByID:(NSManagedObjectID*) objectID;

- (NSManagedObjectID*) getFirstPacket;

- (BOOL) removePacket:(NSManagedObjectID*) objectID;

- (NSUInteger) packetsStored;

+ (Store*) sharedStore;

@end
