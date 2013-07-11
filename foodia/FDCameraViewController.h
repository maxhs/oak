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
@property (nonatomic,strong) AVCamCaptureManager *captureManager;
@property (nonatomic, strong) IBOutlet UIImageView *photoPreviewImageView;
@property (strong, nonatomic) UIImage *originalImage;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,weak) IBOutlet UIButton *takePhotoButton;
@property (nonatomic,weak) IBOutlet UIButton *cancelButton;
@property (nonatomic,weak) IBOutlet UIButton *useButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;
@property (weak, nonatomic) IBOutlet UIScrollView *filterScrollView;
@property BOOL isPreview;
@property BOOL shouldBeEditing;

- (IBAction)captureStillImage:(id)sender;
- (IBAction)cancel;

@end

