//
//  FDProfileMapViewController.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/11/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FDProfileMapViewController : UIViewController
@property (strong, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) NSString *uid;
@property (nonatomic) IBOutlet MKMapView *mapView;

@end
