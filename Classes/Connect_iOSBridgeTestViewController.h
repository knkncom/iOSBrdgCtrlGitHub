//
//  Connect_iOSBridgeTestViewController.h
//  Connect_iOSBridgeTest
//
//  Created by Shun Endo, Kensuke Nishimura.
//  Copyright 2011 University of Aizu Computer Art Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSCPort.h"
#import<CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

@interface Connect_iOSBridgeTestViewController : UIViewController <CLLocationManagerDelegate,UIActionSheetDelegate>{
	
	int Ch;
	float x, y, yaw;
	OSCPort *port;
	int sport;
	const char* testip;

	int New_heading;
	int Old_heading;
	int Rotation_count;
    int New_yaw;
	int Old_yaw;
	
	int Polarity;
	int Run_Flag;
	int Continuous_Flag;
	
	int Rotation_Flag;
	int KindOfValue_Flag;
	NSString *KindOfValue;
    
	int Rock_Flag;
    
	CLLocationManager *lm;
	IBOutlet UILabel *latLabel;
    
	int Threshold_Value;
	IBOutlet UISlider *Threshold_Slider;
	IBOutlet UILabel *Threshold_Label;
    
    float Transmission_Value;
    IBOutlet UISlider *Transmission_Slider;
	
	IBOutlet UIImageView *compassImg;
	IBOutlet UILabel *port_hostLabel;
	
    NSString *host;   
    int eport;  
	
	IBOutlet UISwitch *Run_switch;

	int Value_correction;
	IBOutlet UILabel *Correction_Label;
    
    
    int Timer_V;
    int Timer_Flag;
    
    int Reverse_state;
    
    IBOutlet UITextField *Host_TextField;
    
    IBOutlet UIButton *Channel_Set_btn_Title;
    IBOutlet UIButton *Lock_btn_Title;
    IBOutlet UIButton *Mode_btn_Title;
    
    IBOutlet UIButton *Wrapped_Unwrapped_btn_Title;
    IBOutlet UIButton *Upright_Inverted_btn_Title;
    IBOutlet UIButton *Positive_Negative_btn_Title;
    IBOutlet UIButton *Circumferential_Azimuthal_btn_Title;
    
	AVCaptureSession *AVSession;    
    BOOL triggered;
    BOOL toggleLED;
    BOOL toggleSound;
    BOOL toggleVibration;
}

@property (nonatomic, retain) NSString *host;
@property (nonatomic, readwrite) int sport;

@property (nonatomic, retain) AVCaptureSession *AVSession;


-(IBAction)Mode_btn;


-(IBAction)Upright_Inverted_btn;

-(IBAction)Wrapped_Unwrapped_btn;
-(IBAction)Positive_Negative_btn;
-(IBAction)Circumferential_Azimuthal_btn;


-(IBAction)Run_switch;

-(IBAction)Channel_Set_btn;
-(IBAction)one_shot_btn;

-(IBAction)Plus_btn;
-(IBAction)Minus_btn;

-(IBAction)Threshold_Slider_Change;
-(IBAction)Transmission_Slider_Change;

-(IBAction)Lock_btn;

-(void)Spin_Timer:(NSTimer *)timer;

-(IBAction)Host_Input;

-(void)updateSettings;




@end

