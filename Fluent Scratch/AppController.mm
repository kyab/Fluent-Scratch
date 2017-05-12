//
//  AppController.m
//  Fluent Scratch
//
//  Created by kyab on 2017/05/08.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AppController.h"

static double linearInterporation(int x0, double y0, int x1, double y1, double x){
    if (x0 == x1){
        return y0;
    }
    double rate = (x - x0) / (x1 - x0);
    double y = (1.0 - rate)*y0 + rate*y1;
    return y;
}


@implementation AppController

-(void)awakeFromNib{
    NSLog(@"AppController awake from nib");
    
    [_mainView setDelegate:(id<MainViewDragDropDelegate>)self];
    
    
    ae = [[AudioEngine alloc] init];
    if ([ae initialize]){
        NSLog(@"AudioEngine initialized");
    }
    
    [ae setRenderDelegate:(id<AudioEngineDelegate>)self];
    
    
    _conv_left.clear();
    _conv_right.clear();
    
    //play time update routine
    _timerPlayTime = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onPlayTimeUpdate:) userInfo:nil repeats:YES];
    
}



- (OSStatus) renderOutput:(AudioUnitRenderActionFlags *)ioActionFlags inTimeStamp:(const AudioTimeStamp *) inTimeStamp inBusNumber:(UInt32) inBusNumber inNumberFrames:(UInt32)inNumberFrames ioData:(AudioBufferList *)ioData{
    
    
    {
        static UInt32 count = 0;
        if ((count % 100) == 0){
            //            NSLog(@"AppController outCallback inNumberFrames = %u", inNumberFrames);
        }
        count++;
    }

    if (_buffer_len == 0){
        //zero output
        float *pLeft = (float *)ioData->mBuffers[0].mData;
        float *pRight = (float *)ioData->mBuffers[1].mData;
        bzero(pLeft,sizeof(float)*inNumberFrames );
        bzero(pRight,sizeof(float)*inNumberFrames );
        return noErr;
    }
    
    if (_reverse && _speedRate == -1.0f){
        _conv_left.clear();
        _conv_right.clear();
        _conv_left.reserve(inNumberFrames);
        _conv_right.reserve(inNumberFrames);
        
        [self reverse:inNumberFrames];
        
        memcpy(ioData->mBuffers[0].mData,
               &(_conv_left[0]), sizeof(float) * inNumberFrames);
        memcpy(ioData->mBuffers[1].mData,
               &(_conv_right[0]), sizeof(float) * inNumberFrames);
        
    }else if (_reverse){    //Rx X
        _conv_left.clear();
        _conv_right.clear();
        _conv_left.reserve(inNumberFrames);
        _conv_right.reserve(inNumberFrames);
        
        
        [self convertAtRate:_speedRate numberSamples:inNumberFrames];
        
        memcpy(ioData->mBuffers[0].mData,
               &(_conv_left[0]), sizeof(float) * inNumberFrames);
        memcpy(ioData->mBuffers[1].mData,
               &(_conv_right[0]), sizeof(float) * inNumberFrames);
        
    }else if (_changeSpeed){
        _conv_left.clear();
        _conv_right.clear();
        _conv_left.reserve(inNumberFrames);
        _conv_right.reserve(inNumberFrames);
        
        
        [self convertAtRate:_speedRate numberSamples:inNumberFrames];
        
        memcpy(ioData->mBuffers[0].mData,
               &(_conv_left[0]), sizeof(float) * inNumberFrames);
        memcpy(ioData->mBuffers[1].mData,
               &(_conv_right[0]), sizeof(float) * inNumberFrames);
        
    }else{
        //x1
        if (_currentFrame + inNumberFrames > _buffer_len){
            //skipe last samples for simplize
            _currentFrame = 0;
            [ae stop];
        }
        memcpy(ioData->mBuffers[0].mData,
               &(_leftBuf[_currentFrame]), sizeof(float) * inNumberFrames);
        memcpy(ioData->mBuffers[1].mData,
               &(_rightBuf[_currentFrame]), sizeof(float) * inNumberFrames);
        
        _currentFrame += inNumberFrames;
    }
    
    
    
    return noErr;
}



-(void)convertAtRate:(double)rate numberSamples:(UInt32)numberSamples{
    if (rate >= 0){
        [self convertAtRatePlus:rate numberSamples:numberSamples];
    }else{
        [self convertAtRateMinus:rate numberSamples:numberSamples];
    }
}

-(void)convertAtRatePlus:(double)rate numberSamples:(UInt32)numberSamples{
    
    if (_currentFrame + numberSamples*rate > _buffer_len){
        _currentFrame = 0;
        [ae stop];
    }
    
    for (int targetSample = 0; targetSample < numberSamples; targetSample++){
        int x0 = floor(targetSample*rate);
        int x1 = ceil(targetSample*rate);

        float y0_l = _leftBuf[_currentFrame + x0];
        float y1_l = _leftBuf[_currentFrame + x1];
        float y_l = linearInterporation(x0, y0_l, x1, y1_l, targetSample*rate);
 
        float y0_r = _rightBuf[_currentFrame + x0];
        float y1_r = _rightBuf[_currentFrame + x1];
        float y_r = linearInterporation(x0, y0_r, x1, y1_r, targetSample*rate);
        
        _conv_left.push_back(y_l);
        _conv_right.push_back(y_r);
        
        if (_currentFrame + x1 > _buffer_len){
            [ae stop];
        }
    }
    _currentFrame += numberSamples*rate;
}

-(void)convertAtRateMinus:(double)rate numberSamples:(UInt32)numberSamples{
    
    if ((SInt32)_currentFrame + numberSamples*rate < 0){
        _currentFrame = _buffer_len;
        [ae stop];
    }
    
    for (int targetSample = 0; targetSample < numberSamples; targetSample++){
        int x0 = ceil(targetSample*rate);
        int x1 = floor(targetSample*rate);
        
        float y0_l = _leftBuf[_currentFrame + x0];
        float y1_l = _leftBuf[_currentFrame + x1];
        float y_l = linearInterporation(x0, y0_l, x1, y1_l, targetSample*rate);
        
        float y0_r = _rightBuf[_currentFrame + x0];
        float y1_r = _rightBuf[_currentFrame + x1];
        float y_r = linearInterporation(x0, y0_r, x1, y1_r, targetSample*rate);
        
        _conv_left.push_back(y_l);
        _conv_right.push_back(y_r);
        
        if (_currentFrame + x1 > _buffer_len){
            [ae stop];
        }
    }
    _currentFrame += numberSamples*rate;
}


-(void)reverse:(UInt32)numberSamples{
    if ((SInt32)_currentFrame -(SInt32)numberSamples < 0){
        _currentFrame = _buffer_len;
        [ae stop];
    }
    
    for (int targetSample = 0; targetSample < numberSamples;targetSample++){
        _conv_left.push_back(_leftBuf[_currentFrame-targetSample]);
        _conv_right.push_back(_leftBuf[_currentFrame - targetSample]);
    }
    
    _currentFrame -= numberSamples;
    
}


-(BOOL)mainViewDragDropTryAction:(NSString *)filePath{
    OSStatus ret = noErr;
    ExtAudioFileRef extAudioFile;
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    CFURLRef urlRef =(__bridge CFURLRef )fileURL;
    ret = ExtAudioFileOpenURL(urlRef,&extAudioFile);
    if (ret < 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed ExtAudioFileOpenURL err=%d(%@)", ret, [err description]);
        return NO;
    }
    if (extAudioFile == 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to open file err=%d(%@)", ret, [err description]);
        return NO;
    }
    
    ret = ExtAudioFileSeek(extAudioFile, 0);
    if (ret < 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get format err=%d(%@)", ret, [err description]);
        return NO;
    }
    return YES;
}


-(BOOL)mainViewDragDropAction:(NSString *)filePath{
    return [self loadFile:filePath];
}

-(BOOL)loadFile:(NSString *)filePath{
    
    _buffer_len = 0;
    _currentFrame = 0;
    
    OSStatus ret = noErr;
    ExtAudioFileRef extAudioFile;
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    CFURLRef urlRef = (__bridge CFURLRef )fileURL;
    ret = ExtAudioFileOpenURL(urlRef,&extAudioFile);
    if (ret < 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed ExtAudioFileOpenURL err=%d(%@)", ret, [err description]);
        return NO;
    }
    if (extAudioFile == 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to open file err=%d(%@)", ret, [err description]);
        return NO;
    }
    
    ret = ExtAudioFileSeek(extAudioFile, 0);
    if (ret < 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get format err=%d(%@)", ret, [err description]);
        return NO;
    }
    
    AudioStreamBasicDescription inputFormat = {0};
    UInt32 size = sizeof(AudioStreamBasicDescription);
    ret = ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_FileDataFormat, &size, &inputFormat);
    if (ret < 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get format err=%d(%@)", ret, [err description]);
        return NO;
    }
    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = 44100.0;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBytesPerPacket = 4;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 4;
    asbd.mChannelsPerFrame = 2;
    asbd.mBitsPerChannel = 32;
    
    ret = ExtAudioFileSetProperty(extAudioFile,
                                  kExtAudioFileProperty_ClientDataFormat, size, &asbd);
    
    if (ret < 0){
        NSError *err = [NSError errorWithDomain:NSOSStatusErrorDomain code:ret userInfo:nil];
        NSLog(@"Failed to get format err=%d(%@)", ret, [err description]);
        return NO;
    }
    
    //from RecordAudioToFile sample.
    AudioBufferList *bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) +  sizeof(AudioBuffer)); // for 2 buffers for left and right
    bufferList->mNumberBuffers = 2;
    bufferList->mBuffers[0].mDataByteSize = 32 * 4096;
    bufferList->mBuffers[1].mDataByteSize = 32 * 4096;
    bufferList->mBuffers[0].mNumberChannels = 1;
    bufferList->mBuffers[1].mNumberChannels = 1;
    
    size = sizeof(SInt64);
    SInt64 totalFrame = 0;
    SInt64 currentFrame = 0;
    ret = ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_FileLengthFrames, &size, &totalFrame);
    
    _buffer_len = 0;
    
    while(true){
        UInt32 readSampleLen = 4096;
        bufferList->mBuffers[0].mData = &(_leftBuf[_buffer_len]);
        bufferList->mBuffers[1].mData = &(_rightBuf[_buffer_len]);
        ret = ExtAudioFileRead(extAudioFile, &readSampleLen, bufferList);
        _buffer_len += readSampleLen;
        if (readSampleLen == 0){
            NSLog(@"readed sample = %u", (unsigned int)_buffer_len);
            break;
        }else{
            ret = ExtAudioFileTell(extAudioFile, &currentFrame);
        }
    }
    free(bufferList);
    
    _currentFrame = 0;
    
    NSLog(@"load file OK : %@", filePath);
    
    return YES;
}




- (IBAction)btnClicked:(id)sender {
    static int count = 0;
    NSLog(@"button clicked %d", count++);
}

- (IBAction)startClicked:(id)sender {
    _changeSpeed = NO;
    _reverse = NO;
    [ae start];
}

- (IBAction)stopClicked:(id)sender {
    [ae stop];
    _currentFrame = 0;
    _reverse = NO;
    _changeSpeed = NO;
}

- (IBAction)x13Clicked:(id)sender {
    _changeSpeed = YES;
    _speedRate = 1.3f;
    
    [ae start];
}


- (IBAction)x2Clicked:(id)sender {
    _changeSpeed = YES;
    _speedRate = 2.0f;
    
    [ae start];
}

- (IBAction)x4Clicked:(id)sender {
    _changeSpeed = YES;
    _speedRate = 4.0f;
    
    [ae start];
}

- (IBAction)x10Clicked:(id)sender {
    _changeSpeed = YES;
    _speedRate = 10.0f;
    
    [ae start];
}


- (IBAction)x0_5Clicked:(id)sender {
    _changeSpeed = YES;
    _speedRate = 0.5f;
    
    [ae start];

}

- (IBAction)onReverse:(id)sender {
    _reverse = YES;
    _changeSpeed = NO;
    _speedRate = -1.0f;
}

- (IBAction)Rx2Clicked:(id)sender {
    _reverse = YES;
    _changeSpeed = YES;
    _speedRate = -2.0f;
}
- (IBAction)Rx4Clicked:(id)sender {
    _reverse = YES;
    _changeSpeed = YES;
    _speedRate = -4.0f;
}

- (IBAction)rewind:(id)sender {
    if (_buffer_len != 0){
        if (_currentFrame > 44100){
            _currentFrame -= 44100;
        }
        double val = (double)_currentFrame / _buffer_len;
        [_sliderPlayTime setDoubleValue:val];
        [_lblPlayTime setStringValue:[self formatTimeFromSample:_currentFrame]];
    }
}

- (IBAction)fastforward:(id)sender {
    if (_buffer_len != 0){
        if (_currentFrame + 44100 < _buffer_len ){
            _currentFrame += 44100;
        }
        double val = (double)_currentFrame / _buffer_len;
        [_sliderPlayTime setDoubleValue:val];
        [_lblPlayTime setStringValue:[self formatTimeFromSample:_currentFrame]];
    }
}

- (IBAction)onDownStop:(id)sender {
    if (_timer){
        [_timer invalidate];
        _timer = nil;
    }
    
    _changeSpeed = YES;
    _speedRate = 2.0f;  //initial speed
    _slowDownAccel = 0.01;
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onSlowDownTimer:) userInfo:nil repeats:YES];
    
}
-(void)onSlowDownTimer:(NSTimer *)t{
    double result = _speedRate - _slowDownAccel;
    if (result < 0.1){
        result = 0.01;
        [_timer invalidate];
        _timer = nil;
        [ae stop];
    }else{
        
    }
    _changeSpeed = YES;
    _speedRate = result;
    [_lblSpeedRate setDoubleValue:result];
    
    
}


- (IBAction)speedSliderChanged:(id)sender {
    double val = [(NSSlider *)sender doubleValue];
    _changeSpeed = YES;
    _speedRate = val;
    [_lblSpeedRate setDoubleValue:val];
    
}

-(NSString *)formatTimeFromSample:(UInt32)count{
    UInt32 min = (count/44100.0 / 60);
    UInt32 sec = (count/44100 % 60);
    UInt32 msec = UInt32((count/44100.0) * 1000.0) % 1000;
    return [NSString stringWithFormat:@"%02u:%02u:%03u",
            (unsigned int)min,(unsigned int)sec,(unsigned int)msec];
    
}

-(void)onPlayTimeUpdate:(NSTimer *)t{
    [_lblPlayTime setStringValue:[self formatTimeFromSample:_currentFrame]];
    
    
    if (_buffer_len!=0){
        double playPosRate = (double)_currentFrame / _buffer_len;
        [_sliderPlayTime setDoubleValue:playPosRate];
    }
    
}

- (IBAction)sliderPlayTimeChanged:(id)sender {
    if (_buffer_len != 0){
        double val = [_sliderPlayTime doubleValue];
        _currentFrame = (UInt32)(_buffer_len * val);
        [_lblPlayTime setStringValue:[self formatTimeFromSample:_currentFrame]];
    }
}


@end
