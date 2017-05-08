//
//  RecordView.m
//  Fluent Scratch
//
//  Created by kyab on 2017/05/08.
//  Copyright © 2017年 kyab. All rights reserved.
//

#import "TurnTableView.h"

@implementation TurnTableView

- (void)awakeFromNib{
    ;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] set];
    NSRectFill(self.bounds);
    
    CGFloat r = self.bounds.size.width/2 - 50;
    NSRect circleRect = NSMakeRect(
                                   self.bounds.size.width/2 - r,
                                   self.bounds.size.height/2 - r,
                                   2*r,
                                   2*r);
    
    NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    [[NSColor blackColor] set];
    [circlePath fill];
    
    
    
    // Drawing code here.
}

@end
