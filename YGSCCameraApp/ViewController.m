//
//  ViewController.m
//  YGSCCameraApp
//
//  Created by Takaaki Abe on 2015/05/31.
//  Copyright (c) 2015年 Takaaki Abe. All rights reserved.
//
// https://github.com/piemonte/PBJVision/blob/master/README.md

#import "ViewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController () <PBJVisionDelegate>
{
    UIView* _previewView;
    AVCaptureVideoPreviewLayer* _previewLayer;
    UILongPressGestureRecognizer* _longPressGestureRecognizer;
    BOOL _recording;
    NSDictionary* _currentVideo;
    ALAssetsLibrary* _assetLibrary;
    IBOutlet UIButton* saveButton;
    IBOutlet UILabel* statusLabel;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _assetLibrary = [[ALAssetsLibrary alloc] init];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPressGestureRecognizer:)];
    [self.view addGestureRecognizer:_longPressGestureRecognizer];
    
    _recording = NO;
    // Do any additional setup after loading the view, typically from a nib.
    _previewView = [[UIView alloc] initWithFrame:CGRectZero];
    _previewView.backgroundColor = [UIColor blackColor];
    CGRect previewFrame = CGRectMake(0, 60.0f, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame));
    _previewView.frame = previewFrame;
    _previewLayer = [[PBJVision sharedInstance] previewLayer];
    _previewLayer.frame = _previewView.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewView.layer addSublayer:_previewLayer];
    [self.view addSubview:_previewView];
    
    [self _setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_setup
{
    _longPressGestureRecognizer.enabled = YES;
    
    PBJVision *vision = [PBJVision sharedInstance];
    vision.delegate = self;
    vision.cameraMode = PBJCameraModeVideo;
    vision.cameraOrientation = PBJCameraOrientationPortrait;
    vision.focusMode = PBJFocusModeContinuousAutoFocus;
    vision.outputFormat = PBJOutputFormatSquare;
    
    [vision startPreview];
}

- (void)_handleLongPressGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (!_recording){
                [[PBJVision sharedInstance] startVideoCapture];
                _recording = YES;
            }else{
                [[PBJVision sharedInstance] resumeVideoCapture];
            }
            statusLabel.text = @"Recording now!";
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [[PBJVision sharedInstance] pauseVideoCapture];
            statusLabel.text = @"Pause";
            break;
        }
        default:
            break;
    }
}

- (void)vision:(PBJVision *)vision capturedVideo:(NSDictionary *)videoDict error:(NSError *)error
{
    if (error && [error.domain isEqual:PBJVisionErrorDomain] && error.code == PBJVisionErrorCancelled) {
        NSLog(@"recording session cancelled");
        return;
    } else if (error) {
        NSLog(@"encounted an error in video capture (%@)", error);
        return;
    }
    
    _currentVideo = videoDict;
    
    NSString *videoPath = [_currentVideo  objectForKey:PBJVisionVideoPathKey];
    [_assetLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:videoPath] completionBlock:^(NSURL *assetURL, NSError *error1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Video Saved!" message: @"Saved to the camera roll."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        _recording = NO;
    }];
}

- (IBAction)saveVideoCapture:(id)sender
{
    [[PBJVision sharedInstance] endVideoCapture];
}

@end
