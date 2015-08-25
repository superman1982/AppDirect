//
//  ViewController.m
//  AppDirect
//
//  Created by sangfor on 13-10-28.
//  Copyright (c) 2013年 sangfor. All rights reserved.
//

#import <sys/socket.h>
#import <sys/time.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <time.h>
#import <pthread.h>

#import "ViewController.h"
#import "AuthHelper.h"

// 以下是认证可能会用到的认证信息
short port = 443;                        //vpn设备端口号，一般为443
NSString *vpnIp =    @"www.gznftz.cn";  //vpn设备IP地址  116.254.202.135 120.31.67.68
NSString *userName = @"estar";             //用户名认证的用户名
NSString *userPassword = @"ysd8689sh";                //用户名认证的密码
NSString *certName = @"sangfor.p12";     //导入证书名字，如果服务端没有设置证书认证可以不设置
NSString *certPwd =  @"123456";          //证书密码，如果服务端没有设置证书

NSString *kurl =  @"http://88.128.0.170:8082/x5/mobileUI/portal/mLogin.w";
NSString *kname= @"";
NSString *kpassword = @"";


@interface ViewController (PrivateMethod)

@end

@implementation ViewController

@synthesize helper;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    activityIndicator = [[UIActivityIndicatorView  alloc]initWithFrame:CGRectMake(100, 100, 80, 80)];
    
    activityIndicator.center = self.view.center;
    
    //设置 风格;
    activityIndicator.activityIndicatorViewStyle=UIActivityIndicatorViewStyleGray;
    //设置活动指示器的颜色
    activityIndicator.color=[UIColor grayColor];
    //hidesWhenStopped默认为YES，会隐藏活动指示器。要改为NO
    activityIndicator.hidesWhenStopped=YES;
    //启动
    [activityIndicator startAnimating];
    
    [self.view addSubview:activityIndicator];
    
    webview.delegate =self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    vpnIp =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kvpnIPKey]];
    userName =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kuserNameKey]];
    userPassword =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kuserPasswordKey]];
    vpnIp = [self getIPWithHostName:vpnIp];
    self.helper = [[AuthHelper alloc] initWithHostAndPort:vpnIp port:443 delegate:self];
    //关闭自动登陆的选项，建议设置为关闭的状态，自动登陆的选项开启的情况下，每次有网络请求的时候
    //都会探测用户是不是处于在线的状态，网络速度有所下降，支持IOS7的新版本的SDK对此做了优化，建议
    //显示的关闭该选项，用户可以调用vpn_query_status来查询状态，如果发现用户掉线可以调用vpn_relogin
    //来完成自动登陆
    // [helper setAuthParam:@AUTO_LOGIN_OFF_KEY param:@"true"];

 
    //设置认证参数 用户名和密码以数值map的形式传入
    [helper setAuthParam:@PORPERTY_NamePasswordAuth_NAME param:userName];
    [helper setAuthParam:@PORPERTY_NamePasswordAuth_PASSWORD param:userPassword];
    //开始用户名密码认证
    [helper loginVpn:SSL_AUTH_TYPE_PASSWORD];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*) getIPWithHostName:(const NSString*)hostName
{
    const char *hostN= [hostName UTF8String];
    struct hostent* phot;
    
    @try {
        phot = gethostbyname(hostN);
        
    }
    @catch (NSException *exception) {
        return nil;
    }
    
    struct in_addr ip_addr;
    memcpy(&ip_addr, phot->h_addr_list[0], 4);
    char ip[20] = {0};
    inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
    
    NSString* strIPAddress = [NSString stringWithUTF8String:ip];
    NSLog(@"strIPAddress==%@",strIPAddress);
    return strIPAddress;
}

- (IBAction)btnReturn:(id)sender {
    //[webview goBack];//
    [webview stringByEvaluatingJavaScriptFromString:@"window.location.href='/x5/mobileUI/portal/mIndex.w?language=zh_CN&isIOS=undefined'"];
}

- (void)refreshFields {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    vpnIp =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kvpnIPKey]];
    userName =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kuserNameKey]];
    userPassword =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kuserPasswordKey]];
    
    kurl =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kurlKey]];
    kname =  [NSString stringWithFormat:@"%@",[defaults objectForKey:knameKey]];
    kpassword =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kpasswordKey]];
    NSLog(@"vpnIp=%@",vpnIp);
    NSLog(@"userName=%@",userName);
    NSLog(@"userPassword=%@",userPassword);
    //NSLog(@"url=%@",url);
    NSLog(@"name=%@",kname);
    NSLog(@"password=%@",kpassword);
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:app];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)applicationWillEnterForeground:(NSNotification *)notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    [self refreshFields];
}

- (void) onCallBack:(const VPN_RESULT_NO)vpnErrno authType:(const int)authType
{
    switch (vpnErrno)
    {
        case RESULT_VPN_INIT_FAIL:
            say_err("Vpn Init failed!");
            
            break;
            
        case RESULT_VPN_AUTH_FAIL:
            [helper clearAuthParam:@SET_RND_CODE_STR];
            say_err("Vpn auth failed!");
            break;
            
        case RESULT_VPN_INIT_SUCCESS:
            say_log("Vpn init success!");
            break;
        case RESULT_VPN_AUTH_SUCCESS:
            [self startOtherAuth:authType];
            break;
        case RESULT_VPN_AUTH_LOGOUT:
            say_log("Vpn logout success!");
            break;
		case RESULT_VPN_OTHER:
			if (VPN_OTHER_RELOGIN_FAIL == (VPN_RESULT_OTHER_NO)authType) {
				say_log("Vpn relogin failed, maybe network error");
			}
			break;
            
        case RESULT_VPN_NONE:
            break;
            
        default:
            break;
    }
}

- (void) onReloginCallback:(const int)status result:(const int)result
{
    switch (status) {
        case START_RECONNECT:
            NSLog(@"vpn relogin start reconnect ...");
            break;
        case END_RECONNECT:
            NSLog(@"vpn relogin end ...");
            if (result == SUCCESS) {
                NSLog(@"Vpn relogin success!");
            } else {
                NSLog(@"Vpn relogin failed");
            }
            break;
        default:
            break;
    }
}

- (void) startOtherAuth:(const int)authType
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    kurl =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kurlKey]];
    
    NSArray *paths = nil;
    switch (authType)
    {
        case SSL_AUTH_TYPE_CERTIFICATE:
            paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                        NSUserDomainMask, YES);
            
            if (nil != paths && [paths count] > 0)
            {
                NSString *dirPaths = [paths objectAtIndex:0];
                NSString *authPaths = [dirPaths stringByAppendingPathComponent:certName];
                NSLog(@"PATH = %@",authPaths);
                [helper setAuthParam:@CERT_P12_FILE_NAME param:authPaths];
                [helper setAuthParam:@CERT_PASSWORD param:certPwd];
            }
            say_log("Start Cert Auth!!!");
            break;
            
        case SSL_AUTH_TYPE_PASSWORD:
            say_log("Start Password Name Auth!!!");
            [helper setAuthParam:@PORPERTY_NamePasswordAuth_NAME param:userName];
            [helper setAuthParam:@PORPERTY_NamePasswordAuth_PASSWORD param:userPassword];
            
            break;
        case SSL_AUTH_TYPE_NONE:
            say_log("Auth success!!!");
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            kurl =  [NSString stringWithFormat:@"%@",[defaults objectForKey:kurlKey]];
            CGRect frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.width;
            frame.size.height = [UIScreen mainScreen].bounds.size.height;
            frame.origin.x = 0.0;
            frame.origin.y = 20.0;
            [webview setFrame:frame];
            
            NSURL* url = [NSURL URLWithString:kurl];
            NSURLRequest*request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [webview loadRequest:request];
            webview.scrollView.bounces = NO;
            [activityIndicator stopAnimating];
//            NSURLResponse *respnose = nil;
//            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&respnose error:NULL];
//            NSString *result = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
//            NSLog(@"%@", respnose.MIMEType);
//            NSLog(@"%@",result);
            
//            UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@""
//                                                           message:@"VPN不成功，是否重新连接"
//                                                          delegate:self
//                                                 cancelButtonTitle:@"取消"
//                                                 otherButtonTitles:@"确定",@"设置VPN",nil ];
//            [alert show];
            
            return;
        default:
            say_err("Other failed!!!");
            return;
    }
    [helper loginVpn:authType];
}

- (IBAction)login:(id)sender
{
    //设置认证参数 用户名和密码以数值map的形式传入
    [helper setAuthParam:@PORPERTY_NamePasswordAuth_NAME param:userName];
    [helper setAuthParam:@PORPERTY_NamePasswordAuth_PASSWORD param:userPassword];
    //开始用户名密码认证
    [helper loginVpn:SSL_AUTH_TYPE_PASSWORD];
}

- (IBAction)logout:(id)sender
{
    //注销用户登陆
    [helper logoutVpn];
}

-(IBAction)autoLogin:(id)sender
{
    //如果svpn已经注销了，就重新登陆
    if ([helper queryVpnStatus] == VPN_STATUS_LOGOUT)
    {
        NSLog(@"Svpn is logout!");
        [helper relogin];
    }
}

-(IBAction)requestRc:(id)sender
{
    
//    CGRect frame;
//    frame.size.width = [UIScreen mainScreen].bounds.size.width;
//    frame.size.height = [UIScreen mainScreen].bounds.size.height;
//    frame.origin.x = 0.0;
//    frame.origin.y = 20.0;
//    [webview setFrame:frame];
    
    //http://88.128.170.3:8082/x5
    //http://88.128.170.3:8082/x5/mobileUI/portal/mLogin.w
    //http://88.128.0.30
    NSURL* url = [NSURL URLWithString:@"http://88.128.0.30"];
    NSURLRequest*request = [NSURLRequest requestWithURL:url];
    [webview loadRequest:request];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSLog(@"Button %d pressed",buttonIndex);
    //[alertView release];
}

//-(void) webViewDidStartLoad:(UIWebView *)webView{
//    NSURL *nsurl = [[webView request] URL];
//    NSString *url = [nsurl absoluteString];
//    NSLog(@"URL==%@",url);
//    
//    
//    NSRange range = [url rangeOfString:@"uploadDoc"];
//    if (range.location != NSNotFound) {
//        
//        [webView stringByEvaluatingJavaScriptFromString:@"document.body.append('<a>dddddd</a>');"];
//        return;
//        
//    }else{
//        NSLog(@"sorry!");
//    }
//}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
        NSURL *nsurl = [[webView request] URL];
        NSString *url = [nsurl absoluteString];
        //NSLog(@"URL==%@",url);
    
    
//    NSString *jsToGetHTMLSource = @"document.getElementsByTagName('html')[0].innerHTML";
//    
//    NSString *HTMLSource = [webView stringByEvaluatingJavaScriptFromString:jsToGetHTMLSource];
//    
//    NSLog(@"%@",HTMLSource);
    
    
    
        NSRange range = [url rangeOfString:@"uploadDoc"];
        if (range.location != NSNotFound) {
            //self.backItem.enabled = self.webView.canGoBack;
            btnRet.hidden=NO;
        }else{
            btnRet.hidden=YES;
            //NSLog(@"sorry!");
        }
    
    [activityIndicator stopAnimating];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    kname =  [NSString stringWithFormat:@"document.getElementById('username_input').value='%@';",[defaults objectForKey:knameKey]];
    kpassword =  [NSString stringWithFormat:@"document.getElementById('password_input').value='%@';",[defaults objectForKey:kpasswordKey]];
    [webView stringByEvaluatingJavaScriptFromString:kname];
    [webView stringByEvaluatingJavaScriptFromString:kpassword];
    [webView stringByEvaluatingJavaScriptFromString:@"Login.doLogin();"];//checkRememberMe();
}

- (void)dealloc {
    [webview release];
    [btnRet release];
    [btnRet release];
    [super dealloc];
}
@end

