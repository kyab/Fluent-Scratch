//
//  AudioEngine.h
//  Circle Edit
//
//  Created by kyab on 2017/04/27.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol AudioEngineDelegate <NSObject>
@optional
- (OSStatus) renderOutput:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData;
@end




@interface AudioEngine : NSObject{
    AUGraph _graph;
    AudioUnit _outUnit;
    AudioUnit _converterUnit;
    BOOL _bIsPlaying;
    id<AudioEngineDelegate> _delegate;
    
}

-(void)setRenderDelegate:(id<AudioEngineDelegate>)delegate;
-(BOOL)initialize;
-(BOOL)start;
-(BOOL)stop;
-(BOOL)isPlaying;

@end
