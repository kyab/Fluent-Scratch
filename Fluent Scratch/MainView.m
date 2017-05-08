//
//  MainView.m
//  Fluent Scratch
//
//  Created by kyab on 2017/05/08.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import "MainView.h"

@implementation MainView

- (void)awakeFromNib
{
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *board = [sender draggingPasteboard];
    NSArray *files = [board propertyListForType:NSFilenamesPboardType];
    NSURL *fileURL = [NSURL fileURLWithPath:files[0]];
    
    NSLog(@"dragginEntered");
    
    if ([_delegate mainViewDragDropTryAction:fileURL.path]){
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
    
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *board = [sender draggingPasteboard];
    NSArray *files = [board propertyListForType:NSFilenamesPboardType];
    NSURL *fileURL = [NSURL fileURLWithPath:files[0]];
    
    return [_delegate mainViewDragDropAction:fileURL.path];
}


-(void)setDelegate:(id<MainViewDragDropDelegate>)delegate{
    _delegate = delegate;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


@end
