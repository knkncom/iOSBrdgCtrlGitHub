//
//  Connect_iOSBridgeTestViewController.m
//  Connect_iOSBridgeTest
//
//  Created by Shun Endo, Kensuke Nishimura.
//  Copyright 2011 University of Aizu Computer Art Lab. All rights reserved.
//


//ver2.1


#import "Connect_iOSBridgeTestViewController.h"
\
#define TIME_TO_WAIT 0.05

void* GetOpenALAudioData(
                         CFURLRef fileURL, ALsizei* dataSize, ALenum* dataFormat, ALsizei *sampleRate)
{
    
    OSStatus    err;
    UInt32      size;
    
    // オーディオファイルを開く
    ExtAudioFileRef audioFile;
    err = ExtAudioFileOpenURL(fileURL, &audioFile);
    if (err) {
        goto Exit;
    }
    
    // オーディオデータフォーマットを取得する
    AudioStreamBasicDescription fileFormat;
    size = sizeof(fileFormat);
    err = ExtAudioFileGetProperty(
                                  audioFile, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat);
    if (err) {
        goto Exit;
    }
    
    // アウトプットフォーマットを設定する
    AudioStreamBasicDescription outputFormat;
    outputFormat.mSampleRate = fileFormat.mSampleRate;
    outputFormat.mChannelsPerFrame = fileFormat.mChannelsPerFrame;
    outputFormat.mFormatID = kAudioFormatLinearPCM;
    outputFormat.mBytesPerPacket = 2 * outputFormat.mChannelsPerFrame;
    outputFormat.mFramesPerPacket = 1;
    outputFormat.mBytesPerFrame = 2 * outputFormat.mChannelsPerFrame;
    outputFormat.mBitsPerChannel = 16;
    outputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    err = ExtAudioFileSetProperty(
                                  audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(outputFormat), &outputFormat);
    if (err) {
        goto Exit;
    }
    
    // フレーム数を取得する
    SInt64  fileLengthFrames = 0;
    size = sizeof(fileLengthFrames);
    err = ExtAudioFileGetProperty(
                                  audioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthFrames);
    if (err) {
        goto Exit;
    }
    
    // バッファを用意する
    UInt32          bufferSize;
    void*           data;
    AudioBufferList dataBuffer;
    bufferSize = fileLengthFrames * outputFormat.mBytesPerFrame;;
    data = malloc(bufferSize);
    dataBuffer.mNumberBuffers = 1;
    dataBuffer.mBuffers[0].mDataByteSize = bufferSize;
    dataBuffer.mBuffers[0].mNumberChannels = outputFormat.mChannelsPerFrame;
    dataBuffer.mBuffers[0].mData = data;
    
    // バッファにデータを読み込む
    err = ExtAudioFileRead(audioFile, (UInt32*)&fileLengthFrames, &dataBuffer);
    if (err) {
        free(data);
        goto Exit;
    }
    
    // 出力値を設定する
    *dataSize = (ALsizei)bufferSize;
    *dataFormat = (outputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
    *sampleRate = (ALsizei)outputFormat.mSampleRate;
    
Exit:
    // オーディオファイルを破棄する
    if (audioFile) {
        ExtAudioFileDispose(audioFile);
    }
    
    return data;
}



@implementation Connect_iOSBridgeTestViewController

@synthesize host, sport;
@synthesize AVSession;


//Initialization of variables(flag, count, label name, timer method, and so on)
-(void)viewDidLoad {
	[super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:@"applicationDidEnterBackground"
                                               object:nil];
    
    // Lockボタンのカスタマイズ
    [[Lock_btn_Title layer] setCornerRadius:8.0f];
    [[Lock_btn_Title layer] setMasksToBounds:YES];
    [[Lock_btn_Title layer] setBorderWidth:1.0f];
    [[Lock_btn_Title layer] setBorderColor:[[UIColor colorWithWhite:0.7 alpha:1.0] CGColor]];
    [Lock_btn_Title setBackgroundColor:[UIColor whiteColor]];
    [[Lock_btn_Title titleLabel] setFont:[UIFont boldSystemFontOfSize:15.0f]];

    
    // OpenAL Start
    
    // OpneALデバイスを開く
    ALCdevice*  device;
    device = alcOpenDevice(NULL);
    
    // OpenALコンテキスを作成して、カレントにする
    ALCcontext* alContext;
    alContext = alcCreateContext(device, NULL);
    alcMakeContextCurrent(alContext);
    
    // バッファとソースを作成する
    alGenBuffers(7, _buffers);
    alGenSources(7, _sources);
    
    int i;
    for (i = 0; i < 13; i++) {
        // サウンドファイルパスを取得する
        NSString*   fileName = nil;
        NSString*   path;
        switch (i) {
            case 0: fileName = @"C4"; break;
            case 1: fileName = @"D"; break;
            case 2: fileName = @"E"; break;
            case 3: fileName = @"F"; break;
            case 4: fileName = @"G"; break;
            case 5: fileName = @"A"; break;
            case 6: fileName = @"B"; break;
        }
        path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"m4a"];
        
        // オーディオデータを取得する
        void*   audioData;
        ALsizei dataSize;
        ALenum  dataFormat;
        ALsizei sampleRate;
        audioData = GetOpenALAudioData(
                                       (CFURLRef)[NSURL fileURLWithPath:path], &dataSize, &dataFormat, &sampleRate);
        
        // データをバッファに設定する
        alBufferData(_buffers[i], dataFormat, audioData, dataSize, sampleRate);
        
        // バッファをソースに設定する
        alSourcei(_sources[i], AL_BUFFER, _buffers[i]);
    }
    
    // ②初期化
    NSMutableArray *mlist = [[NSMutableArray alloc] init];
    NSNumber *num;
    num = [NSNumber numberWithInteger:0];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:0];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:4];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:4];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:5];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:5];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:4];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:3];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:3];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:2];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:2];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:1];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:1];
    [mlist addObject:num];
    num = [NSNumber numberWithInteger:0];
    [mlist addObject:num];
    list = [[NSArray alloc] initWithArray:mlist];
    [mlist release];
    
    
    keyIndex = 0;
    // OpenAL End
    
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


// Update Host IP and Re-connect
-(void)Host_Input {
    [self getUserDefaults]; // 設定画面の値をアプリ側で読み込む
    if([host length] != 0) { // Do nothing if host IP is empty
        port_hostLabel.text = [NSString stringWithFormat:@" Host: %@",host];
        testip = [host UTF8String];
        // Init OSC sending port
        port = [[OSCPort oscPortToAddress:testip portNumber:sport] retain];
    } else {
        port_hostLabel.text = [NSString stringWithFormat:@" Host: None"];
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
        
        // Sound, Vibration, Camera flash
        if((int)yaw % 360 < 180) {
            if(!triggered)
            {
                // LEDライト
                if(toggleLED)
                    [self flashON];
                [self flashOFF];
                // サウンド
                if(toggleSound)
                    // AudioServicesPlaySystemSound(1013);
                     [self playSound];
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
	}
}

-(IBAction)one_shot_btn{
	if (yaw > 0) {
		[port sendTo:"angle" types:"i",(int)(yaw*1000+Ch+KindOfValue_Flag*10)];
	}else {
		[port sendTo:"angle" types:"i",(int)(yaw*1000-Ch-KindOfValue_Flag*10)];
	}
}


-(IBAction)switchChanged {
	if (Run_switch.on == YES) {
		Run_Flag = 1;
        [self Host_Input]; // ホストに再接続
	} else {
		Run_Flag = 0;
        latLabel.text = [NSString stringWithFormat:@" No Connection"];
	}
}



//Channel name setting
-(IBAction)Channel_Set_btn {
	UIActionSheet *ChannelSheet = [[UIActionSheet alloc]
								   initWithTitle:@"Channel Setting"
								   delegate:self
								   cancelButtonTitle:@"Cancel"
								   destructiveButtonTitle:nil
								   otherButtonTitles:@"CH0",@"CH1",@"CH2",@"CH3",@"CH4",@"CH5",nil];
	ChannelSheet.tag = 1;
	[ChannelSheet showInView:self.view];
	[ChannelSheet release];
}

//Wrapped and Unwrapped mode setting
-(IBAction)Wrapped_Unwrapped_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:nil
								 otherButtonTitles:@"Wrapped",@"Unwrapped",nil];
	ValueSheet.tag = 2;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}
//Positive and Negative mode setting
-(IBAction)Positive_Negative_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:nil
								 otherButtonTitles:@"Positive",@"Negative",nil];
	ValueSheet.tag = 3;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}
//Circumferential and Azimuthal mode setting
-(IBAction)Circumferential_Azimuthal_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:nil
								 otherButtonTitles:@"Both",@"Circumferential",@"Azimuthal",nil];
	ValueSheet.tag = 4;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

//Continuous and One-Shot mode setting
-(IBAction)Mode_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:nil
								 otherButtonTitles:@"Continuous",@"One-Shot",nil];
	ValueSheet.tag = 5;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

//Upright and Inverted mode setting
-(IBAction)Upright_Inverted_btn{
	UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:nil
								 otherButtonTitles:@"Upright",@"Inverted",nil];
	ValueSheet.tag = 6;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

//Display lock flag setting
-(IBAction)Lock_btn {
    UIActionSheet *ValueSheet = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:@"Lock Screen for 30 sec"
								 otherButtonTitles:nil];
	ValueSheet.tag = 7;
	[ValueSheet showInView:self.view];
	[ValueSheet release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case 1: // Channel setting
            if (0 <= buttonIndex && buttonIndex < 6) {
                Ch = buttonIndex;
            }
            [Channel_Set_btn_Title setTitle:[NSString stringWithFormat:@"CH%d",Ch] forState:UIControlStateNormal];
            break;
        case 2: // Wrapped and Unwrapped flag setting
            switch (buttonIndex) {
                case 0:
                    Rotation_Flag = 0;
                    [Wrapped_Unwrapped_btn_Title setTitle: @"Wrapped" forState:UIControlStateNormal];
                    break;
                case 1:
                    Rotation_Flag = 1;
                    [Wrapped_Unwrapped_btn_Title setTitle: @"Unwrapped" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
            break;
        case 3: // Positive and Negative flag setting
            switch (buttonIndex) {
                case 0:
                    Polarity = 1;
                    [Positive_Negative_btn_Title setTitle: @"Positive" forState:UIControlStateNormal];
                    break;
                case 1:
                    Polarity = -1;
                    [Positive_Negative_btn_Title setTitle: @"Negative" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
            break;
        case 4: // Circumferential and Azimuthal flag setting
            switch (buttonIndex) {
                case 0:
                    KindOfValue_Flag = 1;
                    [Circumferential_Azimuthal_btn_Title setTitle: @"Both" forState:UIControlStateNormal];
                    break;
                case 1:
                    KindOfValue_Flag = 2;
                    [Circumferential_Azimuthal_btn_Title setTitle: @"Circumferential" forState:UIControlStateNormal];
                    break;
                case 2:
                    KindOfValue_Flag = 3;
                    [Circumferential_Azimuthal_btn_Title setTitle: @"Azimuthal" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
            break;
        case 5: // Continuous and One-Shot flag setting
            switch (buttonIndex) {
                case 0:
                    Continuous_Flag = 1;
                    [Mode_btn_Title setTitle: @"Continuous" forState:UIControlStateNormal];
                    break;
                case 1:
                    Continuous_Flag = 0;
                    [Mode_btn_Title setTitle: @"One-Shot" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
            break;
        case 6: // Upright and Inverted flag setting
            switch (buttonIndex) {
                case 0:
                    Reverse_state = 1;
                    [Upright_Inverted_btn_Title setTitle: @"Upright" forState:UIControlStateNormal];
                    break;
                case 1:
                    Reverse_state = -1;
                    [Upright_Inverted_btn_Title setTitle: @"Inverted" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
            break;
        case 7: // Lock Setting
            switch (buttonIndex) {
                case 0:
                    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                    Timer_Flag = 1;
                    break;
                default:
                    break;
            }
        default:
            break;
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


//Timer function
-(void)Spin_Timer:(NSTimer *)timer {
    if (Timer_Flag == 1) {
        
        // change button color
        [Lock_btn_Title setBackgroundColor:[UIColor orangeColor]];
        [[Lock_btn_Title titleLabel] setFont:[UIFont boldSystemFontOfSize:17.0f]];

        Timer_V += 1;
        [Lock_btn_Title setTitle: [NSString stringWithFormat:@"T: %d",30-Timer_V] forState:UIControlStateNormal];
        
        if (Timer_V == 30) {
            Timer_Flag = 0;
            Timer_V = 0;
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            [Lock_btn_Title setTitle: @"Lock" forState:UIControlStateNormal];

            // change button color
            [Lock_btn_Title setBackgroundColor:[UIColor whiteColor]];
            [[Lock_btn_Title titleLabel] setFont:[UIFont boldSystemFontOfSize:15.0f]];
        }
    }
    else {
        Timer_V = 0;
    }
}


-(void)getUserDefaults
{
    [NSUserDefaults resetStandardUserDefaults];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    toggleSound = [userDefaults boolForKey: @"toggle_sound"];
    toggleVibration = [userDefaults boolForKey: @"toggle_vibration"];
    host = [userDefaults stringForKey: @"host_str"];
    
    NSLog(@"host: %@\n",host);    
}

// Camera flash ON Function
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

// Camera flash OFF Function
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

- (void)playSound {
    // ドラムインデックスを取得する
    //    int index;
    //    index = [sender tag] - 100;
    if (keyIndex >= [list count])
        keyIndex = 0;
    else {
        id e = [list objectAtIndex: keyIndex];
        NSLog(@"%@", e);
        NSString *str = (NSString*)e;
        int suuji = [str intValue];
        alSourcePlay(_sources[suuji]);
        keyIndex++;
    }
    // オーディオを再生する
   // alSourcePlay(_sources[(int)aIndex]);
}

- (void)applicationDidEnterBackground {
    NSLog(@"applicationDidEnterBackground callled.");
//    [self getUserDefaults]; // 設定画面の値をアプリ側で読み込む
    Run_Flag = 0;
    Run_switch.on = NO;
    port_hostLabel.text = [NSString stringWithFormat:@" Host: None"];
    latLabel.text = [NSString stringWithFormat:@" No Connection"];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    [lm release];
    lm = nil;
//    [list release];
//    list = nil;
}
- (void)dealloc {
    if (AVSession != nil)
        [AVSession release];
    [super dealloc];
}
@end
