//
//  CIImage+Extras.h
//  WS4 CoreGraphics Only Test
//
//  Created by Anthony Myatt on 24/04/13.
//  Copyright (c) 2013 Anthony Myatt. All rights reserved.
//

#import <QuartzCore/CoreImage.h>

@interface CIImage (Extras)

- (NSImage*) NSImage;
- (CIImage*) imageRotated90DegreesClockwise:(BOOL)clockwise;
- (CIImage*) imageWithChromaColor:(NSColor*)chromaColor BackgroundColor:(NSColor*)backColor;
- (NSColor*) colorAtX:(NSUInteger)x y:(NSUInteger)y;
- (NSData*) RGB565Data;

@end
