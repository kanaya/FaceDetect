//
//  ViewController.m
//  FaceDetect
//
//  Created by Ichi Kanaya on 2018/03/01.
//  Copyright © 2018 Ichi Kanaya. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#import "ViewController.h"

@implementation ViewController

- (void)refreshDevices {
    self.videoDevices = [[AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]
                         arrayByAddingObjectsFromArray: [AVCaptureDevice devicesWithMediaType: AVMediaTypeMuxed]];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice: device
                                                                              error: NULL];
    NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt: kCVPixelFormatType_32BGRA]};
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    dataOutput.videoSettings = settings;
    [dataOutput setSampleBufferDelegate: self
                                  queue: dispatch_get_main_queue()];
    
    self.session = [[AVCaptureSession alloc] init];
    [self.session addInput: deviceInput];
    [self.session addOutput: dataOutput];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    AVCaptureConnection *videoConnection = NULL;
    
    [self.session beginConfiguration];
    for (AVCaptureConnection *connection in [dataOutput connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual: AVMediaTypeVideo]) {
                videoConnection = connection;
            }
        }
    }
    if ([videoConnection isVideoOrientationSupported]) { // **Here it is, its always false**
        [videoConnection setVideoOrientation: AVCaptureVideoOrientationPortrait];
    }
    
    [self.session commitConfiguration];
    [self.session startRunning];
}

- (NSImage *)imageFromSampleBufferRef: (CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(cgContext);
    
    CIImage *input = [CIImage imageWithCGImage: cgImage];
    CIFilter *filter = [CIFilter filterWithName: @"CISepiaTone"];
    [filter setValue: input forKey: kCIInputImageKey];
    [filter setValue: @0.5 forKey: kCIInputIntensityKey];
    CIImage *output = filter.outputImage;
    CIContext *ciContext = [CIContext context];
    CGImageRef filtered = [ciContext createCGImage: output
                                          fromRect: input.extent];
    NSImage *image = [[NSImage alloc] initWithCGImage: filtered // cgImage
                                                 size: NSMakeSize(width, height)];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
}

- (void)captureOutput: (AVCaptureOutput *)captureOutput
didOutputSampleBuffer: (CMSampleBufferRef)sampleBuffer
       fromConnection: (AVCaptureConnection *)connection {
    self.imageView.image = [self imageFromSampleBufferRef: sampleBuffer];
}

- (void)setRepresentedObject: (id)representedObject {
    [super setRepresentedObject: representedObject];

    // Update the view, if already loaded.
}

@end
