//
//  ViewController.h
//  AppDirect
//
//  Created by sangfor on 13-10-28.
//  Copyright (c) 2013年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthHelper.h"
#import "sdkheader.h"
#import "sslvpnnb.h"


#define say_log(str) printf("[log]:%s,%s,%d:%s\n",__FILE__,__FUNCTION__,__LINE__,str)
#define say_err(err) printf("[log]:%s,%s,%d:%s,%s\n",__FILE__,__FUNCTION__,__LINE__,err,get_err())
#define get_err() ssl_vpn_get_err()


#define kvpnIPKey                    @"vpnIP"
#define kuserNameKey                 @"userName"
#define kuserPasswordKey             @"userPassword"
#define kurlKey                      @"url"
#define knameKey                     @"name"
#define kpasswordKey                 @"password"

@interface ViewController : UIViewController<SangforSDKDelegate,UIWebViewDelegate,UIAlertViewDelegate>
{
    AuthHelper *helper;
    IBOutlet UIWebView *webview;
    UIActivityIndicatorView *activityIndicator;
    IBOutlet UIButton *btnRet;
}
@property (nonatomic, retain) AuthHelper *helper;
- (NSString *)getIPWithHostName:(NSString *)hostName;
- (IBAction)btnReturn:(id)sender;


@end
