//
//  CIImage+Extras.m
//  WS4 CoreGraphics Only Test
//
//  Created by Anthony Myatt on 24/04/13.
//  Copyright (c) 2013 Anthony Myatt. All rights reserved.
//

#import "CIImage+Extras.h"
#import <Accelerate/Accelerate.h>

@implementation CIImage (Extras)

- (NSImage*) NSImage
{
    CGContextRef cg = [[NSGraphicsContext currentContext] graphicsPort];
    CIContext *context = [CIContext contextWithCGContext:cg options:nil];
    CGImageRef cgImage = [context createCGImage:self fromRect:self.extent];
    
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize];
    CGImageRelease(cgImage);
    
    return image;
}

- (CIImage*) imageRotated90DegreesClockwise:(BOOL)clockwise
{
    CIImage *im = self;
    CIFilter *f = [CIFilter filterWithName:@"CIAffineTransform"];
    NSAffineTransform *t = [NSAffineTransform transform];
    [t rotateByDegrees:clockwise ? -90 : 90];
    [f setValue:t forKey:@"inputTransform"];
    [f setValue:im forKey:@"inputImage"];
    im = [f valueForKey:@"outputImage"];
    
    CGRect extent = [im extent];
    f = [CIFilter filterWithName:@"CIAffineTransform"];
    t = [NSAffineTransform transform];
    [t translateXBy:-extent.origin.x
                yBy:-extent.origin.y];
    [f setValue:t forKey:@"inputTransform"];
    [f setValue:im forKey:@"inputImage"];
    im = [f valueForKey:@"outputImage"];
    
    return im;
}

- (CIImage*) imageWithChromaColor:(NSColor*)chromaColor BackgroundColor:(NSColor*)backColor
{
    CIImage *im = self;
    
    CIColor *backCIColor = [[CIColor alloc] initWithColor:backColor];
    CIImage *backImage = [CIImage imageWithColor:backCIColor];
    backImage = [backImage imageByCroppingToRect:self.extent];
    float chroma[3];
    
    chroma[0] = chromaColor.redComponent;
    chroma[1] = chromaColor.greenComponent;
    chroma[2] = chromaColor.blueComponent;
    
    // Allocate memory
    const unsigned int size = 64;
    const unsigned int cubeDataSize = size * size * size * sizeof (float) * 4;
    float *cubeData = (float *)malloc (cubeDataSize);
    float rgb[3];//, *c = cubeData;
    
    // Populate cube with a simple gradient going from 0 to 1
    size_t offset = 0;
    for (int z = 0; z < size; z++){
        rgb[2] = ((double)z)/(size-1); // Blue value
        for (int y = 0; y < size; y++){
            rgb[1] = ((double)y)/(size-1); // Green value
            for (int x = 0; x < size; x ++){
                rgb[0] = ((double)x)/(size-1); // Red value
                float alpha = ((rgb[0] == chroma[0]) && (rgb[1] == chroma[1]) && (rgb[2] == chroma[2])) ? 0.0 : 1.0;
                
                cubeData[offset]   = rgb[0] * alpha;
                cubeData[offset+1] = rgb[1] * alpha;
                cubeData[offset+2] = rgb[2] * alpha;
                cubeData[offset+3] = alpha;
                
                offset += 4;
            }
        }
    }
    
    // Create memory with the cube data
    NSData *data = [NSData dataWithBytesNoCopy:cubeData
                                        length:cubeDataSize
                                  freeWhenDone:YES];
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    [colorCube setValue:[NSNumber numberWithInt:size] forKey:@"inputCubeDimension"];
    // Set data for cube
    [colorCube setValue:data forKey:@"inputCubeData"];
    
    [colorCube setValue:im forKey:@"inputImage"];
    im = [colorCube valueForKey:@"outputImage"];
    
    CIFilter *sourceOver = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [sourceOver setValue:im forKey:@"inputImage"];
    [sourceOver setValue:backImage forKey:@"inputBackgroundImage"];
    
    im = [sourceOver valueForKey:@"outputImage"];
    
    return im;
}

- (NSColor*)colorAtX:(NSUInteger)x y:(NSUInteger)y
{
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithCIImage:self];
    NSColor *color = [bitmap colorAtX:x y:y];
    return color;
}

- (NSData*)RGB565Data
{
    NSUInteger w = self.extent.size.width;
    NSUInteger h = self.extent.size.height;
    
    NSUInteger inBytesPerPixel = 4;
    NSUInteger inBytesPerRow = (inBytesPerPixel * w);
    
    void* argb888Data = malloc((w * inBytesPerPixel) * h);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef cg = CGBitmapContextCreate(NULL, w, h, 8, inBytesPerRow, colorSpace,kCGImageAlphaNoneSkipLast);
    CIContext *context = [CIContext contextWithCGContext:cg options:nil];
    CGContextRelease(cg);
    [context render:self toBitmap:argb888Data rowBytes:(inBytesPerPixel * w) bounds:NSMakeRect(0, 0, w, h) format:kCIFormatARGB8 colorSpace:colorSpace];
    
    CGColorSpaceRelease(colorSpace);
    
    vImage_Buffer src;
    src.data = argb888Data;
    src.width = w;
    src.height = h;
    src.rowBytes = (w * inBytesPerPixel);
    
    NSUInteger outBytesPerPixel = 2;
    
    void* rgb565Data = malloc((w * outBytesPerPixel) * h);
    
    vImage_Buffer dst;
    dst.data = rgb565Data;
    dst.width = w;
    dst.height = h;
    dst.rowBytes = (w * outBytesPerPixel);
    
    vImageConvert_ARGB8888toRGB565(&src, &dst, 0);
    
    free(argb888Data);
    
    size_t dataSize = outBytesPerPixel * w * h; // RGB565 = 2 5-bit components and 1 6-bit (16 bits/2 bytes)
    NSData *RGB565DataOut = [NSData dataWithBytes:dst.data length:dataSize];
    
    free(rgb565Data);
    
    return RGB565DataOut;
}

@end
