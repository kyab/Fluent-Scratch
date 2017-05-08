//
//  MainView.h
//  Fluent Scratch
//
//  Created by kyab on 2017/05/08.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol MainViewDragDropDelegate <NSObject>
-(BOOL)mainViewDragDropTryAction:(NSString *)filePath;
-(BOOL)mainViewDragDropAction:(NSString *)filePath;
@optional

@end


@interface MainView : NSView{
    id<MainViewDragDropDelegate> _delegate;
    
}

-(void)setDelegate:(id<MainViewDragDropDelegate>)delegate;

@end
