//
//  FDCameraViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/30/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer, AVCamViewController;

@interface FDCameraViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    BOOL selectingImageFromLibrary;
}


@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet UIView *videoPreviewView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *cameraToggleButton;
@property (nonatomic,retain) IBOutlet UIButton *recordButton;
@property (nonatomic,retain) IBOutlet UIButton *stillButton;
@property (nonatomic,retain) IBOutlet UILabel *focusModeLabel;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,retain) IBOutlet UIImageView *capturedImageView;
@property (nonatomic,retain) IBOutlet UIView *captureButtons;
@property (nonatomic,retain) IBOutlet UIView *reviewButtons;
@property (nonatomic,retain) IBOutlet UIButton *libraryButton;
@property (nonatomic,retain) UIImage *capturedImage;

#pragma mark Toolbar Actions
- (IBAction)toggleRecording:(id)sender;
- (IBAction)captureStillImage:(id)sender;
- (IBAction)toggleCamera:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)selectImage:(id)sender;

@end
