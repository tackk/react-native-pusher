//
//  RNPusherClient.h
//  RNPusherClient
//
//  Created by Dan Horrigan on 9/14/15.
//  Copyright (c) 2015 Tackk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Pusher/Pusher.h>
#import "RCTBridgeModule.h"

@interface RNPusherClient : NSObject <RCTBridgeModule, PTPusherDelegate>

@end
