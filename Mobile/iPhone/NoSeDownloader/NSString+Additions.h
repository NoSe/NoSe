/*
 * Copyright 2010-2011, Thotpot Inc.
 *
 * Author: Michele Mastrogiovanni
 * Email: mmastrogiovanni@thotpot.com
 *
 */

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (Additions)

- (NSString*) firstChar;

- (void) limitedLog;

- (NSString*) limit:(int) length;

- (NSString*) resolveString;

- (UIColor*) colorWithWebString;

- (NSString*) encodeSHA1;

@end
