//
//  TurnTableView.m
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

    CGFloat r = self.bounds.size.width/2 - 10;
    NSRect circleRect = NSMakeRect(
                                   self.bounds.size.width/2 - r,
                                   self.bounds.size.height/2 - r,
                                   2*r,
                                   2*r);
    
    NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    

    [[NSColor blackColor] set];
    [circlePath fill];
    
    
    //angle 30 degree
    CGFloat centerX = self.bounds.size.width/2;
    CGFloat centerY = self.bounds.size.height/2;
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(centerX, centerY)];
    double theta = 28 * (M_PI / 180);
    [line lineToPoint:NSMakePoint(centerX + r*cos(theta), centerY + r*sin(theta))];

    if (_pressing){
        [[NSColor orangeColor] set];
    }else{
        [[NSColor cyanColor] set];
    }
    [line setLineWidth:3.0];
    [line stroke];
    

}

-(NSPoint)eventLocation:(NSEvent *) theEvent{
    return [self convertPoint:theEvent.locationInWindow fromView:nil];
}


-(void)mouseDown:(NSEvent *)theEvent{
    CGFloat x = [self eventLocation:theEvent].x;
    CGFloat y = [self eventLocation:theEvent].y;
    
    CGFloat xFromCenter = x - self.bounds.size.width/2;
    CGFloat yFromCenter = y - self.bounds.size.height/2;
    CGFloat dist = sqrt((xFromCenter*xFromCenter) + (yFromCenter*yFromCenter));
    CGFloat r = self.bounds.size.width/2 - 10;
    
    if (dist <= r){
        _pressing = YES;
    }else{
        _pressing = NO;
    }
    [self setNeedsDisplay:YES];
    
}

-(void)mouseUp:(NSEvent *)theEvent{
    _pressing = NO;
    [self setNeedsDisplay:YES];
}


@end
