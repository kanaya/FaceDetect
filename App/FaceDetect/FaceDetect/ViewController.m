//
//  ViewController.m
//  FaceDetect
//
//  Created by Ichi Kanaya on 2018/03/01.
//  Copyright © 2018 Ichi Kanaya. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)refreshDevices {
    self.videoDevices = [[AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]
                         arrayByAddingObjectsFromArray: [AVCaptureDevice devicesWithMediaType: AVMediaTypeMuxed]];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];  // Failes.
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
    
    CGImageRef cgImage;
    NSImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [[NSImage alloc] initWithCGImage: cgImage
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
