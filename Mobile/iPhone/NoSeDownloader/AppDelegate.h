//
//  AppDelegate.h
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 11/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#define DISCOVERY_ENABLED       @"nose.discovery.enabled"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;

- (NSURL *)applicationDocumentsDirectory;

+ (BOOL) isDiscoveryEnabled;

+ (void) setDiscoveryEnabled:(BOOL) flag;

@end
