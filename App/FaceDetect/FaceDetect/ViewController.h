//
//  ViewController.h
//  FaceDetect
//
//  Created by Ichi Kanaya on 2018/03/01.
//  Copyright © 2018 Ichi Kanaya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController: NSViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) NSArray *videoDevices;
@property (nonatomic, strong) IBOutlet NSImageView *imageView;

@end

