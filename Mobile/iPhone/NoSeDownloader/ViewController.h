//
//  ViewController.h
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 11/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "Connection.h"
#import "ConnectionDelegate.h"

#define TAG_START   0
#define TAG_STOP   1

#define PROPERTY_PACKETS_DELIVERED      @"packets.delivered"

@interface ViewController : UIViewController <NSNetServiceBrowserDelegate, ConnectionDelegate>
{
    Connection          * connection;
    
    IBOutlet UISwitch   * uiswitch;
    IBOutlet UILabel    * receivedText;
    IBOutlet UILabel    * cachedText;
    IBOutlet UILabel    * sendText;
    IBOutlet UILabel    * statusText;
    IBOutlet UIProgressView * progress;
        
    NSInteger           pktsReceived;
    NSInteger           pktsToDeliver;
    NSInteger           pktsDelivered;
    
	NSNetServiceBrowser	* browser;
	NSMutableArray		* services;
    
    int                 packetsToDownload;
    int                 packetsDownloaded;
        
    float               status;
}

- (IBAction) toggle:(id) sender;

- (void) start;

- (void) stop;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
