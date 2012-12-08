//
//  Connect_iOSBridgeTestViewController.m
//  Connect_iOSBridgeTest
//
//  Created by Shun Endo on 11/08/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


//ver1


#import "Connect_iOSBridgeTestViewController.h"


#define TIME_TO_WAIT 0.05

@implementation Connect_iOSBridgeTestViewController

@synthesize host, sport;
@synthesize AVSession;

-(void)getUserDefaults
{
    [NSUserDefaults resetStandardUserDefaults];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    toggleSound = [defaults boolForKey: @"toggle_sound"];
    toggleVibration = [defaults boolForKey: @"toggle_vibration"];
}


//////////////////////////////////////////////////////////////////////
//                                                                  //
//   カメラのフラッシュをONにする                                   //
//                                                                  //
//////////////////////////////////////////////////////////////////////

-(void)flashON
{
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn])
    {
        BOOL success = [flashLight lockForConfiguration:nil];
        if(success)
        {
            [flashLight setTorchMode:AVCaptureTorchModeOn];
            [flashLight unlockForConfiguration];
        }
    }
}

//////////////////////////////////////////////////////////////////////
//                                                                  //
//   カメラのフラッシュをOFFにする                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////

-(void)flashOFF
{
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn])
    {
        BOOL success = [flashLight lockForConfiguration:nil];
        if(success)
        {
            [flashLight setTorchMode:AVCaptureTorchModeOff];
            [flashLight unlockForConfiguration];
        }
    }
}

//Initialization of variables(flag, count, label name, timer method, and so on)
-(void)viewDidLoad {
	[super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(getUserDefaults)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    
    NSUserDefaults *Default_Host = [NSUserDefaults standardUserDefaults];
    host = [Default_Host stringForKey:@"HOST"];
    Host_TextField.text = host;
    
    
	Continuous_Flag = 0;
	Value_correction = 0;
	
	New_heading = 0;
	Old_heading = 0;
    
    New_yaw = 0;
	Old_yaw = 0;
    
	Rotation_count = 0;
	Rotation_Flag = 0;
	Polarity = 1;
	
	KindOfValue_Flag = 1;
	KindOfValue = [NSString stringWithFormat:@"Both"];
	
	Threshold_Value = 0;
    Transmission_Value = 1;
    
    Reverse_state = 1;
    
    [NSTimer
     scheduledTimerWithTimeInterval:1.0
     target:self selector:@selector(Spin_Timer:)
     userInfo:nil repeats:YES];
    Timer_V = 0;
    Timer_Flag = 0;
    
	Ch = 0;
	yaw = 0.0;
	x = 0.0;
	y = 0.0;
    sport = 50000;
    
    triggered = NO;
    
    
	lm = [[CLLocationManager alloc] init];
	lm.delegate = self;
	lm.desiredAccuracy = kCLLocationAccuracyHundredMeters;
	lm.distanceFilter = kCLDistanceFilterNone;
	[lm startUpdatingLocation];
	[lm startUpdatingHeading];
}


//////////////////////////////////////////////////////////////////////
//                                                                  //
//   ホストIPの更新・再接続                                         //
//                                                                  //
//////////////////////////////////////////////////////////////////////

-(void)Host_Input {
    if([Host_TextField.text length] != 0) { // IPアドレスが空欄の場合は何もしない
        host = Host_TextField.text;
        port_hostLabel.text = [NSString stringWithFormat:@"%@",host];
        testip = [host UTF8String];
        //OSC送信ポートの初期化
        port = [[OSCPort oscPortToAddress:testip portNumber:sport] retain];
        
        NSUserDefaults *Default_Host = [NSUserDefaults standardUserDefaults];
        [Default_Host setObject:Host_TextField.text forKey:@"HOST"];
        [Default_Host synchronize];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading{
	if (Run_Flag == 1) {
        compassImg.transform = CGAffineTransformMakeRotation(((-heading.magneticHeading - Value_correction)* M_PI/180)*Reverse_state);
		New_heading = (int)heading.magneticHeading;
        
		if (300 < (New_heading - Old_heading)) {
			Rotation_count--;
		}
		else if (-300 > (New_heading - Old_heading)) {
			Rotation_count++;
		}
		yaw = ((int)(New_heading + (360*Rotation_count)) * Polarity) + Value_correction;
        
        yaw *= Transmission_Value;
        New_yaw = yaw;
        
        
        // サウンド バイブレーション カメラフラッシュ
        if((int)yaw % 360 < 180)
        {
            if(!triggered)
            {
                // LEDライト
                if(toggleLED)
                    [self flashON];
                [self flashOFF];
                // サウンド
                if(toggleSound)
                    AudioServicesPlaySystemSound(1013);
                // バイブレーション
                if(toggleVibration)
                    AudioServicesPlaySystemSound(1011);
                triggered = YES;
            }
        }
        else
            triggered = NO;
        
        
        if (Rotation_Flag == 0) {
            yaw = ((int)(New_heading + (360*0)) * Polarity) + Value_correction;
            if (yaw > 360 && Rotation_Flag == 0) {
                yaw -= 360;
            }
            if (yaw < 0 && Rotation_Flag == 0){
                yaw += 360;
            }
        }
        
 		if (Continuous_Flag == 1) {
			if(abs((int)(New_yaw - Old_yaw)) > Threshold_Value){
				if (yaw > 0) {
					[port sendTo:"angle" types:"i",(int)(yaw*1000+Ch+KindOfValue_Flag*10)];
				}else {
					[port sendTo:"angle" types:"i",(int)(yaw*1000-Ch-KindOfValue_Flag*10)];
				}
				Old_yaw = New_yaw;
                if (Rotation_Flag == 0) {
                    if (Rotation_count < -1 || Rotation_count > 1) {
                        Rotation_count = 0;
                    }
                }
			}
            Old_heading = New_heading;
		}
        
        if (Continuous_Flag != 1) {
            Old_yaw = New_yaw;
            Old_heading = New_heading;
        }
        
        x = 64 * cos(M_PI * (yaw) / 180.0);
		y = 64 * sin(M_PI * (-1*yaw) / 180.0);
		latLabel.text = [NSString stringWithFormat:@" Yaw: %.0f X: %.0f Y: %.0f", yaw, x, y];
	}
	else {
		compassImg.transform = CGAffineTransformMakeRotation(-heading.magneticHeading * 0);
		yaw = 0;
		x = 0;
		y = 0;
		latLabel.text = [NSString stringWithFormat:@" Yaw: %.0f X: %.0f Y: %.0f", yaw, x, y];
	}
}

-(IBAction)one_shot_btn{
	if (yaw > 0) {
		[port sendTo:"angle" types:"i",(int)(yaw*1000+Ch+KindOfValue_Flag*10)];
	}else {
		[port sendTo:"angle" types:"i",(int)(yaw*1000-Ch-KindOfValue_Flag*10)];
	}
}


-(IBAction)Run_switch;{
	if (Run_switch.on == YES) {
		Run_Flag = 1;
        [self Host_Input]; // ホストに再接続
	} else {
		Run_Flag = 0;
	}
}
//Channel name setting
-(IBAction)Channel_Set_btn {
	UIActionSheet *ChannelSheet = [[UIActionSheet alloc]
								   initWithTitle:@"Channel Setting"
								   delegate:self
								   cancelButtonTitle:@"Cancel"
								   destructiveButtonTitle:@"Select"
								   otherButtonTitles:@"CH0",@"CH1",@"CH2",@"CH3",@"CH4",@"CH5",nil];
	ChannelSheet.tag = 1;
	[ChannelSheet showInView:self.view];
    [self Host_Input]; // チャンネルを変更したらホストに再接続する
	[ChannelSheet release];
}

//Wrapped and Unwrapped mode setting
-(IBAction)Wrapped_Unwrapped_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:@"Value Setting"
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:@"Select"
								 otherButtonTitles:@"Wrapped",@"Unwrapped",nil];
	ValueSheet.tag = 2;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}
//Positive and Negative mode setting
-(IBAction)Positive_Negative_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:@"Value Setting"
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:@"Select"
								 otherButtonTitles:@"Positive",@"Negative",nil];
	ValueSheet.tag = 3;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}
//Circumferential and Azimuthal mode setting
-(IBAction)Circumferential_Azimuthal_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:@"Value Setting"
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:@"Select"
								 otherButtonTitles:@"Both",@"Circumferential",@"Azimuthal",nil];
	ValueSheet.tag = 4;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

//Continuous and One-Shot mode setting
-(IBAction)Mode_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:@"Value Setting"
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:@"Select"
								 otherButtonTitles:@"Continuous",@"One-Shot",nil];
	ValueSheet.tag = 5;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

//Upright and Inverted mode setting
-(IBAction)Upright_Inverted_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:@"Value Setting"
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:@"Select"
								 otherButtonTitles:@"Upright",@"Inverted",nil];
	ValueSheet.tag = 6;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == 1) {
		if (1 <= buttonIndex && buttonIndex <= 6) {
			Ch = buttonIndex - 1;
		}
        [Channel_Set_btn_Title setTitle:[NSString stringWithFormat:@"CH%d",Ch] forState:UIControlStateNormal];
    }
    //Wrapped and Unwrapped flag setting
    else if (actionSheet.tag == 2){
        if (buttonIndex == 1) {
            Rotation_Flag = 0;
            [Wrapped_Unwrapped_btn_Title setTitle: @"Wrapped" forState:UIControlStateNormal];
        }
        else if (buttonIndex == 2){
            Rotation_Flag = 1;
            [Wrapped_Unwrapped_btn_Title setTitle: @"Unwrapped" forState:UIControlStateNormal];
        }
    }
    //Positive and Negative flag setting
    else if (actionSheet.tag == 3) {
        if (buttonIndex == 1) {
            Polarity = 1;
            [Positive_Negative_btn_Title setTitle: @"Positive" forState:UIControlStateNormal];
        }
        else if (buttonIndex == 2){
            Polarity = -1;
            [Positive_Negative_btn_Title setTitle: @"Negative" forState:UIControlStateNormal];
        }
    }
    //Circumferential and Azimuthal flag setting
    else if (actionSheet.tag == 4) {
        if (buttonIndex == 1){
            KindOfValue_Flag = 1;
            [Circumferential_Azimuthal_btn_Title setTitle: @"Both" forState:UIControlStateNormal];
        }
        else if (buttonIndex == 2){
            KindOfValue_Flag = 2;
            [Circumferential_Azimuthal_btn_Title setTitle: @"Circumferential" forState:UIControlStateNormal];
        }
        else if (buttonIndex == 3){
            KindOfValue_Flag = 3;
            [Circumferential_Azimuthal_btn_Title setTitle: @"Azimuthal" forState:UIControlStateNormal];
        }
    }
    //Continuous and One-Shot flag setting
    else if (actionSheet.tag == 5) {
        if (buttonIndex == 1) {
            Continuous_Flag = 1;
            [Mode_btn_Title setTitle: @"Continuous" forState:UIControlStateNormal];
        }
        else if (buttonIndex == 2){
            Continuous_Flag = 0;
            [Mode_btn_Title setTitle: @"One-Shot" forState:UIControlStateNormal];
        }
    }
    //Upright and Inverted flag setting
    else if (actionSheet.tag == 6) {
        if (buttonIndex == 1){
            Reverse_state = 1;
            [Upright_Inverted_btn_Title setTitle: @"Upright" forState:UIControlStateNormal];
        }
        else if (buttonIndex == 2){
            Reverse_state = -1;
            [Upright_Inverted_btn_Title setTitle: @"Inverted" forState:UIControlStateNormal];
        }
    }
}
-(IBAction)Threshold_Slider_Change{
	Threshold_Value = (int)Threshold_Slider.value;
	Threshold_Label.text = [NSString stringWithFormat:@"Th%d : Tr%0.1f",Threshold_Value, Transmission_Value];
}
//Transmission
-(IBAction)Transmission_Slider_Change{
	Transmission_Value = (int)Transmission_Slider.value;
    if (Transmission_Value >= 10) {
        Transmission_Value -= 9;
    }
    else {
        Transmission_Value /= 10;
    }
	Threshold_Label.text = [NSString stringWithFormat:@"Th%d : Tr%0.1f",Threshold_Value, Transmission_Value];
}

//Calibration functions
-(IBAction)Plus_btn{
	Value_correction += 5;
	Correction_Label.text = [NSString stringWithFormat:@"%d", Value_correction];
}
-(IBAction)Minus_btn{
	Value_correction -= 5;
	Correction_Label.text = [NSString stringWithFormat:@"%d", Value_correction];
}

//Display lock flag setting
-(IBAction)Rock_btn{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    Timer_Flag = 1;
}

//Timer function
-(void)Spin_Timer:(NSTimer *)timer{
    if (Timer_Flag == 1) {
        Timer_V += 1;
        Threshold_Label.text = [NSString stringWithFormat:@"T: %d",30-Timer_V];
        [Rock_btn_Title setTitle: [NSString stringWithFormat:@"T: %d",30-Timer_V] forState:UIControlStateNormal];
        
        if (Timer_V == 30) {
            Timer_Flag = 0;
            Timer_V = 0;
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            [Rock_btn_Title setTitle: @"Lock" forState:UIControlStateNormal];
        }
    }
    else {
        Timer_V = 0;
    }
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}
- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}
- (void)dealloc {
    if (AVSession != nil)
        [AVSession release];
    [super dealloc];
}
@end
