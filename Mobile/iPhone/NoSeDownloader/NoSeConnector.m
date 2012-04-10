/*
 * Copyright 2010-2011, Thotpot Inc.
 *
 * Author: Michele Mastrogiovanni
 * Email: mmastrogiovanni@thotpot.com
 *
 */

#define DEBUG_JSON      YES

#import "NoSeConnector.h"

// #import "ErrorCodes.h"
#import "JSON/JSON.h"
#import "NSString+Additions.h"

#ifdef USE_ASI_PROXY
#import "ASIHTTPRequest.h"
#endif

#define PAUSE_BETWEEN_RETRY			1.5
#define RETRY_OPERATIONS			0

@implementation NoSeConnector

- (id) initWithHost:(NSString*) aHost
{
    self = [ super init ];
    if ( self ) {
        host = [ aHost retain ];
    }
    return self;
}

- (void) dealloc
{
    [ host release ];
    [ super dealloc ];
}

- (id) asyncCallToMethod:(NSString*) method withData:(id) object
{
	int count = RETRY_OPERATIONS;
	
	while ( count > 1 ) {
		
		@try {
			id ret = [ self unreliableAsyncCallToMethod:method withData:object ];
			return ret;
		}
		@catch (NSException * e) {
			NSLog(@"Exception in method %@: RETRY", method);
			// NSLog(@"Exception: %@", e);
		}
		
		count --;
		
		[ NSThread sleepForTimeInterval:PAUSE_BETWEEN_RETRY ];
		
	}
	
	return [ self unreliableAsyncCallToMethod:method withData:object ];
}

/**
 * Call an async method with a data passed as parameter.
 * The parameter is transformed as a JSON fragment and delivered
 * to the host.
 * The result is parsed as a JSON fragment.
 * Result can be either a number less or equal than 0 (error result)
 * or a JSON object (number >= 0, string, dictionary, array...).
 */
- (id) unreliableAsyncCallToMethod:(NSString*) method withData:(id) object
{
	NSNumber * bytesSent = [[ NSUserDefaults standardUserDefaults ] objectForKey:@"application.bytes.sent" ];
	NSNumber * bytesReceived = [[ NSUserDefaults standardUserDefaults ] objectForKey:@"application.bytes.received" ];
	
	if ( bytesSent == nil )
		bytesSent = [ NSNumber numberWithLongLong:0 ];
	if ( bytesReceived == nil )
		bytesReceived = [ NSNumber numberWithLongLong:0 ];
	
	// Get content for call as a JSON fragment
	NSString * content = [ object JSONFragment ];
	
#ifdef DEBUG_JSON
	[[ NSString stringWithFormat:@"invoke: %@ (%@)", method, content ] limitedLog ];
#endif
	
	// Setup request content
	NSString * post = [ NSString stringWithFormat:@"%@\r\n", content ];
	
	// Transform post string in data
	NSData *postData = [ post dataUsingEncoding:NSASCIIStringEncoding ];
	
	// Calculate body length
	NSString *postLength = [ NSString stringWithFormat:@"%d", [ postData length ]];

	// URL: host/serviceMethod
	NSURL * urlRequest = [ NSURL URLWithString:[ NSString stringWithFormat:@"%@/%@", host, method ]];
	
	NSUInteger encoding = NSASCIIStringEncoding;
	
	// encoding = NSUTF8StringEncoding;
	// encoding = NSUnicodeStringEncoding;
	// encoding = NSUTF16StringEncoding;
	// encoding = NSMacOSRomanStringEncoding;
	// encoding = NSISOLatin1StringEncoding;
	// encoding = NSISOLatin2StringEncoding;
	// encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin9);

#ifndef USE_ASI_PROXY

	// Make a request
	NSMutableURLRequest *request = [[[ NSMutableURLRequest alloc ] init ] autorelease ];
		
	[ request setURL:urlRequest ];
	
	[ request setHTTPMethod:@"POST" ];
	[ request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[ request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type" ];
	[ request setHTTPBody:postData ];
		
	// Get response and errors
	NSError *error = nil;
	// NSURLResponse *response;
	NSHTTPURLResponse * response;
	NSData * urlData = [ NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
	
	if ( [ response statusCode ] != 200 ) {
		NSLog(@"Error: returned status code %d", [ response statusCode ]);
		if ( [ response statusCode ] == 407 )
			[ NSException raise:PROXY_ERROR format:@"Client is behind a proxy: authentication required" ];
		else
			[ NSException raise:NETWORK_ERROR format:@"Problems in connection with network. Please try again." ];
	}
	
	if ( error != nil ) {
		// Connection error
		NSLog(@"Error: %@", [ error description ]);
		[ NSException raise:NETWORK_ERROR format:@"Problems in connection with network. Please try again." ];
	}
	
	NSString * data = [[[ NSString alloc] initWithData:urlData encoding:encoding ] autorelease ];
			
#else
	
	ASIHTTPRequest * request = [ ASIHTTPRequest  requestWithURL:urlRequest ];
	
	// [ request setShouldCompressRequestBody:NO ];
	
	[ request setRequestMethod:@"POST" ];
	[ request addRequestHeader:@"Content-Length" value:postLength ];
	[ request addRequestHeader:@"Content-Type" value:@"text/plain" ];
	[ request setPostBody:[ NSMutableData dataWithData:postData ]];
	
	[ request setUseSessionPersistence:YES ];
	
	[ request startSynchronous ];
	
	if ( [ request responseStatusCode ] != 200 )
		NSLog(@"Response: %d", [ request responseStatusCode ]);
	
	if ( [ request responseStatusCode ] == 500 ) {
		NSLog(@"Error: returned status code %d", [ request responseStatusCode ]);
		[ NSException raise:NETWORK_ERROR format:@"Problems in connection with network. Please try again." ];
	}
		
	NSError *error = [ request error ];
	if ( error != nil ) {
		NSLog(@"Error: %@", [ error description ]);
		[ NSException raise:NETWORK_ERROR format:@"Problems in connection with network. Please try again." ];
	}	
	
	NSString * data = [[[ NSString alloc] initWithData:[ request responseData ] encoding:encoding ] autorelease ];

#endif
	
	// Save bytes sent
	bytesSent = [ NSNumber numberWithLongLong:([ bytesSent longLongValue ] + [ postData length ]) ];

	// Save bytes received
	bytesReceived = [ NSNumber numberWithLongLong:([ bytesReceived longLongValue ] + [ data length ]) ];

	// Save network status
	[[ NSUserDefaults standardUserDefaults ] setObject:bytesSent forKey:@"application.bytes.sent" ];
	[[ NSUserDefaults standardUserDefaults ] setObject:bytesReceived forKey:@"application.bytes.received" ];
	[[ NSUserDefaults standardUserDefaults ] synchronize ];
	
	@try {
		id ret = [ data JSONFragmentValue ];
		
#ifdef DEBUG_JSON
		[[ NSString stringWithFormat:@"Response JSON: (class: %@) %@", [[ ret class ] description ], [ ret description ]] limitedLog ];
#endif
		
		return ret;
	}
	@catch (NSException * e) {
		[ NSException raise:JSON_PARSING_ERROR format:@"Problems in reading the data coming from the service." ];
	}
	
	return nil;
}

@end
