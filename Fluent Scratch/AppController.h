//
//  AppController.h
//  Fluent Scratch
//
//  Created by kyab on 2017/05/08.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainView.h"
#import "AudioEngine.h"

#include <vector>

#define BUFFER_SIZE_SAMPLE 44100*10*60

@interface AppController : NSObject{

    __weak IBOutlet MainView *_mainView;
    __weak IBOutlet NSTextField *_lblSpeedRate;
    __weak IBOutlet NSTextField *_lblPlayTime;
    __weak IBOutlet NSSlider *_sliderPlayTime;
    
    
    NSTimer *_timer;
    NSTimer *_timerPlayTime;
    
    float _leftBuf[BUFFER_SIZE_SAMPLE];
    float _rightBuf[BUFFER_SIZE_SAMPLE];
    
    UInt32 _buffer_len;
    UInt32 _currentFrame;
    
    std::vector<float> _conv_left;
    std::vector<float> _conv_right;
    
    BOOL _changeSpeed;
    BOOL _reverse;
    double _speedRate;
    
    double _slowDownAccel;  //遅くなる加速度？　1秒にどれだけ遅くなるか
    
    AudioEngine *ae;
    

}

@end
