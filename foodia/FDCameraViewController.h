//
//  FDCameraViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/30/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "AVCamCaptureManager.h"
#import "GPUImage.h"

@interface FDCameraViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    
    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter/*, *secondFilter, *terminalFilter*/;
}
//@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic, strong) IBOutlet UIImageView *photoPreviewImageView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UIButton *takePhotoButton;
@property (nonatomic,retain) IBOutlet UIButton *cancelButton;
@property (nonatomic,retain) IBOutlet UIButton *useButton;

- (IBAction)captureStillImage:(id)sender;
- (IBAction)cancel;

@end

