/*
 * Copyright 2010-2011, Thotpot Inc.
 *
 * Author: Michele Mastrogiovanni
 * Email: mmastrogiovanni@thotpot.com
 *
 */

#import "NSString+Additions.h"

@interface NSString (Private)

NSInteger hexDigit(unichar c);

CGFloat colorFromString(NSString* string);

@end

@implementation NSString (Additions)

- (NSString*) encodeHEX:(unsigned char) c
{
	if ( c <= 9 ) {
		return [ NSString stringWithFormat:@"%c", ('0' + c) ];
	}
	else {
		return [ NSString stringWithFormat:@"%c", ('a' + c - 10) ];
	}
	
}

- (NSString*) encodeChar:(unsigned char) c
{
	char first = ( c & 0xF0 ) >> 4;
	char second = c & 0x0F;
	return [ NSString stringWithFormat:@"%@%@", [ self encodeHEX:first ], [ self encodeHEX:second ]];
}

- (NSString*) encodeSHA1
{
	unsigned char hashedChars[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1([ self UTF8String ],
			[ self lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
			hashedChars);
	NSData * hashedData = [ NSData dataWithBytes:hashedChars length:CC_SHA1_DIGEST_LENGTH ];
	
//	return [ hashedData base64EncodedString ];
	
	unsigned char * bytes = (unsigned char*)[ hashedData bytes ];
	
	NSMutableString * string = [ NSMutableString string ];
	for ( int i = 0; i < [ hashedData length ]; i ++ ) {
		[ string appendString:[ self encodeChar:bytes[ i ]]];
	}
	
	return string;
}

- (NSString*) firstChar
{
	if ( self == nil )
		return @"#";
	
	if ( [ self length ] == 0 )
		return @"#";
	
	NSString * character = [[ self substringToIndex:1 ] uppercaseString ];
	
	unichar c = [ character characterAtIndex:0 ];
	
	if ( c < 'A' || c > 'Z' )
		return @"#";
	
	return character;
}

- (void) limitedLog
{
	NSLog(@"%@", self); // [ self limit:500 ]);
}

- (NSString*) limit:(int) length
{
	return [ self substringToIndex:( length < [self length ] ? length : [ self length ] )];
}

- (NSString*) resolveString
{
	NSString * ret = self;
	ret = [ ret stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n" ];
	ret = [ ret stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\" ];
	return ret;
}

NSInteger hexDigit(unichar c)
{
	if ( c <= '9' && c >= '0' )
		return c - '0';
	return 10 + c - 'a';
}

CGFloat colorFromString(NSString* string) 
{
	unichar first = [ string characterAtIndex:0 ];
	unichar second = [ string characterAtIndex:1 ];
	NSInteger firstValue = hexDigit( first );
	NSInteger secondValue = hexDigit( second );
	NSInteger value = firstValue * 16 + secondValue;
	CGFloat ret = (CGFloat) value / (CGFloat) 256.0;
	// NSLog(@"Value for %@ (%d,%d,%d), %.3f", string, firstValue, secondValue, value, ret);
	return ret;
}

- (UIColor*) colorWithWebString
{
	NSString * string = self;
	
	if ( [ string length ] != 7 )
		return [ UIColor clearColor ];
	
	if ( [ string characterAtIndex:0 ] != '#' )
		return [ UIColor clearColor ];
	
	string = [ string lowercaseString ];
	
	NSString * red = [ self substringWithRange:NSMakeRange(1, 2) ];
	NSString * green = [ self substringWithRange:NSMakeRange(3, 2) ];
	NSString * blue = [ self substringWithRange:NSMakeRange(5, 2) ];
	
	return [ UIColor colorWithRed:colorFromString(red) 
							green:colorFromString(green) 
							 blue:colorFromString(blue) 
							alpha:1.0 ];
}

@end
