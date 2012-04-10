//
//  Store.m
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Store.h"
#import "AppDelegate.h"

@interface Store (Private)

- (NSArray*) allPackets;

@end

@implementation Store

@synthesize managedObjectContext = __managedObjectContext;

- (NSArray*) allPackets
{
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest * fetchRequest = [[ NSFetchRequest alloc ] init ];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [ NSEntityDescription entityForName:@"Packet" inManagedObjectContext:self.managedObjectContext];

    NSSortDescriptor *sortDescriptor = [[ NSSortDescriptor alloc ] initWithKey:@"time" ascending:YES ];
    [ fetchRequest setSortDescriptors:[ NSArray arrayWithObject:sortDescriptor ]];
    [ sortDescriptor release ];

    [ fetchRequest setEntity:entity ];
    
    // Set the batch size to a suitable number.
    [ fetchRequest setFetchBatchSize:20 ];
    
    NSError *error = nil;
    NSArray * list = [ self.managedObjectContext executeFetchRequest:fetchRequest error:& error ];
    if ( error != nil ) {
        NSLog(@"Cannot get list of items");
        abort();
    }
    
    return list;
}

- (NSManagedObject*) objectByID:(NSManagedObjectID*) objectID
{
    return [ self.managedObjectContext objectWithID:objectID ];
}

- (BOOL) removePacket:(NSManagedObjectID*) objectID
{
    @try {        
        
        NSError *error = nil;
        
        NSManagedObject * object = [ self.managedObjectContext objectWithID:objectID ];
        [ self.managedObjectContext deleteObject:object ];
        
        // Save the context.
        if ( ! [ self.managedObjectContext save:&error ] ) {
            NSLog(@"Unresolved error %@, %@", error, [ error userInfo ]);
            return NO;
        }

    }
    @catch (NSException *exception) {
        NSLog(@"Exception: cannot remove packet: %@", [ exception description ]);
        return NO;
    }

    packetsStored --;
    [[ NSNotificationCenter defaultCenter ] postNotificationName:NOTIFICATION_PACKET_REMOVE object:self ];
     
    return YES;
}

- (NSManagedObjectID*) getFirstPacket
{
    @try {
        // Set up the fetched results controller.
        // Create the fetch request for the entity.
        NSFetchRequest * fetchRequest = [[ NSFetchRequest alloc ] init ];
        
        // Get only one object
        [ fetchRequest setFetchLimit:1 ];
        
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [ NSEntityDescription entityForName:@"Packet" inManagedObjectContext:self.managedObjectContext];
        
        [ fetchRequest setEntity:entity ];
        
        NSSortDescriptor *sortDescriptor = [[ NSSortDescriptor alloc ] initWithKey:@"time" ascending:YES ];
        [ fetchRequest setSortDescriptors:[ NSArray arrayWithObject:sortDescriptor ]];
        [ sortDescriptor release ];
        
        // Set the batch size to a suitable number.
        [ fetchRequest setFetchBatchSize:20 ];
        
        NSError *error = nil;
        NSArray * list = [ self.managedObjectContext executeFetchRequest:fetchRequest error:& error ];
        if ( error != nil ) {
            NSLog(@"Cannot get list of items: %@", [ error description ]);
            return nil;
        }
        
        if ( [ list count ] == 0 )
            return nil;
                
        return [[ list objectAtIndex:0 ] objectID ];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception in getting first packet: %@", [ exception description ]);
    }
    
    return nil;
}

- (NSUInteger) packetsStored
{
    if ( packetsStored > 0 )
        return packetsStored;
    
    packetsStored = 0;
    
    @try {
        // Set up the fetched results controller.
        // Create the fetch request for the entity.
        NSFetchRequest * fetchRequest = [[ NSFetchRequest alloc ] init ];
        
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [ NSEntityDescription entityForName:@"Packet" inManagedObjectContext:self.managedObjectContext];
        
        NSSortDescriptor *sortDescriptor = [[ NSSortDescriptor alloc ] initWithKey:@"time" ascending:YES ];
        [ fetchRequest setSortDescriptors:[ NSArray arrayWithObject:sortDescriptor ]];
        [ sortDescriptor release ];
        
        [ fetchRequest setEntity:entity ];
        
        // Set the batch size to a suitable number.
        [ fetchRequest setFetchBatchSize:20 ];
        
        NSError *error = nil;
        packetsStored = [ self.managedObjectContext countForFetchRequest:fetchRequest error:& error ];
        if ( error != nil ) {
            NSLog(@"Cannot count packets: %@", [ error description ]);
            packetsStored = 0;
        }
        
    }
    @catch (NSException * exception) {
        NSLog(@"Excetion in counting packets: %@", [ exception description ]);
    }

    return packetsStored;
}

- (void)mergeChanges:(NSNotification *)notification
{
	// Merge changes into the main context on the main thread
	[ self.managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)	
                                                 withObject:notification
                                              waitUntilDone:YES];	
}

- (BOOL) addMessage:(NSString*) message
{

    NSManagedObjectContext * context = [[ NSManagedObjectContext alloc ] init ];

    @try {
        
        [ context setUndoManager:nil ];
        [ context setPersistentStoreCoordinator:self.managedObjectContext.persistentStoreCoordinator ];
        
        // Register context with the notification center
        NSNotificationCenter *nc = [ NSNotificationCenter defaultCenter ];
        [ nc addObserver:self 
                selector:@selector(mergeChanges:) 
				   name:NSManagedObjectContextDidSaveNotification
				 object:context ];
        
        NSManagedObject *newManagedObject = [ NSEntityDescription insertNewObjectForEntityForName:@"Packet" inManagedObjectContext:context ];
        
        [ newManagedObject setValue:message forKey:@"data" ];
        [ newManagedObject setValue:[ NSDate date ] forKey:@"time" ];
        
        // Save the context.
        NSError *error = nil;
        if ( ! [ context save:&error ] ) {
            NSLog(@"Unresolved error %@, %@", error, [ error userInfo ]);
            [ context reset ];
            [ context release ];
            return NO;
        }
        [ context release ];

    }
    @catch (NSException *exception) {
        NSLog(@"Exception during adding of packet: %@", [ exception description ]);
        [ context reset ];
        [ context release ];
        return NO;
    }
    
    packetsStored ++;
    return YES;
}

#pragma - Singleton Pattern

static Store * sharedStore = nil;

+ (Store*) sharedStore
{
    @synchronized(self) {
        if (sharedStore == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    
    AppDelegate * delegate = (AppDelegate*)[[ UIApplication sharedApplication ] delegate ];
    sharedStore.managedObjectContext = [ delegate managedObjectContext ];
    
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedStore == nil) {
            sharedStore = [super allocWithZone:zone];
            return sharedStore;  // assignment and return on first allocation
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
