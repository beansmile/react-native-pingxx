//
//  RNPingPayManager.m
//  RNPingPayManager
//
//  Created by LvBingru on 10/13/15.
//  Copyright © 2015 erica. All rights reserved.
//

#import "RCTPingxx.h"
#import "Pingpp.h"
#import "RCTEventDispatcher.h"
#import "RCTBridge.h"

static NSString *gScheme = @"";

@interface RCTPingxx()

@end

@implementation RCTPingxx

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _autoGetScheme];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:@"RCTOpenURLNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleOpenURL:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    NSString *url = userInfo[@"url"];
    
    [Pingpp handleOpenURL:[NSURL URLWithString:url] withCompletion:^(NSString *result, PingppError *error) {
        [self onResult:result erorr:error];
    }];
}

RCT_EXPORT_METHOD(pay:(NSString *)charge)
{
#ifdef DEBUG
    [Pingpp setDebugMode:YES];
#endif
    UIViewController *controller = [[UIApplication sharedApplication].delegate window].rootViewController;
    
    [Pingpp createPayment:charge
           viewController:controller
             appURLScheme:gScheme
           withCompletion:^(NSString *result, PingppError *error) {
               [self onResult:result erorr:error];
    }];
}

- (void)onResult:(NSString *)result erorr:(PingppError *)error
{
    NSMutableDictionary *body = @{}.mutableCopy;
    body[@"result"] = result;
    if (![result isEqualToString:@"success"]) {
        body[@"errCode"] = @(error.code);
        body[@"errMsg"] = [error getMsg];
    }
    [self.bridge.eventDispatcher sendAppEventWithName:@"Pingxx_Resp" body:body];
}

- (void)_autoGetScheme
{
    if (gScheme.length > 0) {
        return;
    }
    
    NSArray *list = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
    for (NSDictionary *item in list) {
        NSString *name = item[@"CFBundleURLName"];
        if ([name isEqualToString:@"alipay"]) {
            NSArray *schemes = item[@"CFBundleURLSchemes"];
            if (schemes.count > 0)
            {
                gScheme = schemes[0];
                break;
            }
        }
    }
}

@end
