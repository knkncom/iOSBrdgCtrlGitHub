//
//  Connect_iOSBridgeTestAppDelegate.h
//  Connect_iOSBridgeTest
//
//  Created by Shun Endo on 11/08/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Connect_iOSBridgeTestViewController;

@interface Connect_iOSBridgeTestAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    Connect_iOSBridgeTestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet Connect_iOSBridgeTestViewController *viewController;

@end

