//
//  iQStepper.h
//  iqStepper
//
//  Created by Kyle Smyth on 2015-12-11.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface iQStepper : UIControl

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic) NSInteger count;

@end