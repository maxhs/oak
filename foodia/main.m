//
//  main.m
//  foodia
//
//  Created by Max Haines-Stiles on 10/21/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        int retVal = -1;
        @try {
            retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([FDAppDelegate class]));
        }
        @catch (NSException* exception) {
            NSLog(@"Uncaught exception: %@", exception.description);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
        }
        return retVal;
    }
}
