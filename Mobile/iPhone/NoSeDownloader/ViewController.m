//
//  ViewController.m
//  NoSeDownloader
//
//  Created by Michele Mastrogiovanni on 11/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 

#import "AppDelegate.h"
#import "Store.h"

@interface ViewController (Private)

- (void) updateLabels;

- (void) log:(NSString*) string;

@end

@implementation ViewController

@synthesize managedObjectContext = __managedObjectContext;

- (void) start
{
    NSLog(@"Discovery started");
    [ services removeAllObjects ];
    [ browser searchForServicesOfType:@"_NoSeService._tcp." inDomain:@"" ];
}

- (void) stop
{
    if ( connection != nil ) {
        [ connection close ];
        connection = nil;
    }
    [ browser stop ];
    [ services removeAllObjects ];
    NSLog(@"Discovery stopped");
}

- (IBAction) toggle:(id) sender
{
    if ( [ sender isOn ] ) {
        [ AppDelegate setDiscoveryEnabled:YES ];
        [ self start ];
    }
    else {
        [ AppDelegate setDiscoveryEnabled:NO ];
        [ self stop ];
    }

}

- (void) foundService:(NSNetService *) service
{
    [ self log:[ NSString stringWithFormat:@"Connected to service: host:%@, port: %d", service.hostName, service.port ]];

    // Send hello!
    [ connection sendNetworkPacket:[ @"Hello!" dataUsingEncoding:NSASCIIStringEncoding ]];
}

#pragma mark ConnectionDelegate delegates

- (void) connectionEstablished:(Connection*)connection forNetService:(NSNetService*) aNetService
{
    [ self foundService:aNetService ];
}

- (void) connectionAttemptFailed:(Connection*)aConnection
{
    NSLog(@"Errore di connessione al servizio");
    
    [ connection release ];
    connection = nil;
}

- (void) connectionTerminated:(Connection*)aConnection
{
    NSLog(@"connection terminated");
    
    [ connection release ];
    connection = nil;
}

- (void) receivedNetworkPacket:(NSData*)message viaConnection:(Connection*)aConnection
{
    uint8_t buffer[1024];
    
    [ message getBytes:buffer length:1024 ];
    
    if ( buffer[ 0 ] == 0 ) {
        int multiplier = 1;
        packetsToDownload = 0;
        for ( int i = 1; ; i ++ ) {
            int num = buffer[ i ];
            if ( num == 0 )
                break;
            packetsToDownload += multiplier * num;
            multiplier = multiplier * 256;
        }
        NSLog(@"Received hello: %d packets", packetsToDownload);
        [ progress setProgress:0.0 ];
    }
    else {
        NSString * msg = [[[ NSString alloc ] initWithData:message encoding:NSASCIIStringEncoding ] autorelease ];
        
        // Cannot serialize packet
        if ( ! [[ Store sharedStore ] addMessage:msg ] ) {
            abort();
        }
        
        // Send ACK and update GUI
        [ aConnection sendNetworkPacket:[ NSData data ]];
        packetsDownloaded ++;
        pktsReceived ++;
        [ progress setProgress:((float) packetsDownloaded / (float) packetsToDownload) animated:YES ];
        
        [ self updateLabels ];
        
    }
}

#pragma mark NSNetServiceBrowser delegates

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService * ) aNetService moreComing:(BOOL)moreComing {
    NSLog(@"Service discovered");
    
    connection = [[ Connection alloc ] initWithNetService:aNetService ];
    connection.delegate = self;
    
    if ( [ connection connect ] ) {
        NSLog(@"Device connected!");
        [ services addObject:aNetService ];
    }
    else {
        NSLog(@"Impossible to contact this service");
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"Service removed by browser");
    [ services removeObject:aNetService ];
}

#pragma mark - View lifecycle

- (void) packetRemoved:(NSNotification*) aNotification
{
    NSLog(@"Received packet removed")
    pktsToDeliver = [[ Store sharedStore ] packetsStored ];
    [ self updateLabels ];
}

- (void)viewDidLoad
{
    [ super viewDidLoad ];

    AppDelegate * delegate = (AppDelegate*)[[ UIApplication sharedApplication ] delegate ];
    self.managedObjectContext = [ delegate managedObjectContext ];

    browser = [[ NSNetServiceBrowser alloc ] init ];
    services = [[ NSMutableArray alloc ] init ];
    [ browser setDelegate:self ];
    connection = nil;
    status = 0;
    
    pktsToDeliver = [[ Store sharedStore ] packetsStored ];
    [ self updateLabels ];

    if ( [ AppDelegate isDiscoveryEnabled ] ) {
        [ self start ];
    }

    // Update switch
    [ uiswitch setOn:[ AppDelegate isDiscoveryEnabled ]];
    
    [[ NSNotificationCenter defaultCenter ] addObserver:self 
                                               selector:@selector(packetRemoved:) 
                                                   name:NOTIFICATION_PACKET_REMOVE 
                                                 object:nil];
    
}

- (void)viewDidUnload
{
    [ self stop ];
    [ super viewDidUnload ];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"Did appear");
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    NSLog(@"Did disappear");
}

/*
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [ super didReceiveMemoryWarning ];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void) dealloc
{
    [ services release ];
    
    [ browser stop ];
    [ browser release ];
    
    // [ connection close ];
    [ connection release ];
    
    [ super dealloc ];
}

#pragma mark - Private Methods

- (void) updateLabels
{
    receivedText.text = [ NSString stringWithFormat:@"%d", pktsReceived ];
    cachedText.text = [ NSString stringWithFormat:@"%d", pktsToDeliver ];
    sendText.text = [ NSString stringWithFormat:@"%d", pktsDelivered ];
}

- (void) log:(NSString*) string
{
    NSLog(@"%@", string);
    statusText.text = string;
}


@end
