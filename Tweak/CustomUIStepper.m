//
//  iQStepper.m
//  iqStepper
//
//  Created by Kyle Smyth on 2015-12-11.
//

#import "CustomUIStepper.h"

@implementation iQStepper

 -(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setUp];
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self setUp];
    return self;
}

-(void)prepareForInterfaceBuilder
{
    [self setUp];
}

-(void)layoutSubviews
{
    CGFloat labelWidthWeight = 0.5;
    
    CGFloat buttonWidth = self.bounds.size
    .width * ((1-labelWidthWeight) /2);
    CGFloat labelWidth = self.bounds.size.width * labelWidthWeight;
    
    self.leftButton.frame = CGRectMake(buttonWidth, 0, buttonWidth, self.bounds.size.height);
    self.rightButton.frame = CGRectMake(labelWidth + buttonWidth, 0, buttonWidth, self.bounds.size.height);
    self.countLabel.frame = CGRectMake(0, 0, labelWidth, self.bounds.size.height);
}

-(void)setUp {
    self.leftButton = [[UIButton alloc] init];
    self.rightButton = [[UIButton alloc] init];
    self.countLabel = [[UILabel alloc] init];
    self.count = 0;
    
    [self.leftButton setTitle:@"-" forState:UIControlStateNormal];
    [self.leftButton setBackgroundColor:[UIColor redColor]];
    [self.leftButton addTarget:self action:@selector(leftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.rightButton setTitle:@"+" forState:UIControlStateNormal];
    [self.rightButton setBackgroundColor:[UIColor redColor]];
    [self.rightButton addTarget:self action:@selector(rightButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.countLabel setText:@"0"];
    [self.countLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.countLabel];
}

-(void)leftButtonPressed
{
    if(self.count > 0) {
        self.count-=1;
        [self updateCountLabel];
    }
}

-(void)rightButtonPressed
{
    self.count+=1;
    [self updateCountLabel];
}

-(void)updateCountLabel
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self.countLabel setText:[@(self.count) stringValue]];
}

@end