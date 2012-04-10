/*
 * Copyright 2010-2011, Thotpot Inc.
 *
 * Author: Michele Mastrogiovanni
 * Email: mmastrogiovanni@thotpot.com
 *
 */

#import <Foundation/Foundation.h>
// #import "Flags.h"

#define PROXY_ERROR         @"ProxyError"
#define NETWORK_ERROR       @"NetworkError"
#define JSON_PARSING_ERROR  @"JsonParsingError"

/**
 * This class allows to send and get as answer a JSON object (no NSData).
 * The object in input and output can be complex: boolean, string, number, array,
 * dictionary...
 */
@interface NoSeConnector : NSObject {
    
    NSString * host;

}

- (id) initWithHost:(NSString*) host;

- (id) asyncCallToMethod:(NSString*) method withData:(id) object;

- (id) unreliableAsyncCallToMethod:(NSString*) method withData:(id) object;

@end
