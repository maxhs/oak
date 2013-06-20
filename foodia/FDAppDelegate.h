//
//  FDAppDelegate.h
//  foodia
//
//  Created by Max Haines-Stiles on 12/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDSlidingViewController.h"
#import "FDLoginViewController.h"
#import "FDAPIClient.h"
#import "Facebook.h"

@interface FDAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, FBSessionDelegate, FBDialogDelegate, FBLoginViewDelegate, FBRequestDelegate> /*{
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}*/
@property BOOL isTakingPhoto;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) Facebook *facebook;
/*@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;*/
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (NSString *)applicationDocumentsDirectory;
- (void)getPublishPermissions;
- (void)showLoadingOverlay;
- (void)hideLoadingOverlay;
- (void)feedDialogWithParams:(NSMutableDictionary *)params;
- (void)showUserProfile:(NSString *)facebookId;
- (void)fbSessionInvalidated;
- (void)fbDidLogout;
@end
