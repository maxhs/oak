//
//  Post.h
//  foodia
//
//  Created by Max Haines-Stiles on 1/30/13.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Post : NSManagedObject

@property (nonatomic, retain) NSNumber * postId;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSString * detailImageURL;
@property (nonatomic, retain) NSString * featuredImageURL;
@property (nonatomic, retain) NSNumber * epochTime;
@property (nonatomic, retain) NSNumber * featured;
@property (nonatomic, retain) NSNumber * featuredEpochTime;
@property (nonatomic, retain) NSString * feedImageURL;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * latitude;
@property (nonatomic, retain) NSString * recCount;
@property (nonatomic, retain) NSString * likeCount;
@property (nonatomic, retain) NSString * likers;
@property (nonatomic, retain) NSString * viewers;
@property (nonatomic, retain) NSNumber * foursquareid;
@property (nonatomic, retain) NSString * locationName;
@property (nonatomic, retain) NSString * longitude;
@property (nonatomic, retain) NSString * photoImage;
@property (nonatomic, retain) NSString * recommendedTo;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * withFriends;

@end
