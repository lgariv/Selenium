#include "SLNMPRootListController.h"

@implementation SLNMPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)respring {
	UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
	[view setBackgroundColor:[UIColor blackColor]];
	UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
	stackView.axis = UILayoutConstraintAxisVertical;
	stackView.alignment = UIStackViewAlignmentCenter;
	stackView.distribution = UIStackViewDistributionEqualSpacing;
	stackView.spacing = 4;
	[stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
	UIImage *iconImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/SeleniumExtra.bundle/Assets/icon.PNG"];
	UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
	[iconImageView setFrame:CGRectMake(0,0,200,200)];
	[iconImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[iconImageView.widthAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width*0.4f].active = YES;
	[iconImageView.heightAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width*0.4f].active = YES;
	UIView *backgroundView = [[UIView alloc] initWithFrame:iconImageView.frame];
	UIView *iconContainingView = [[UIView alloc] initWithFrame:iconImageView.frame];
	[iconContainingView setBackgroundColor:[UIColor clearColor]];
	[backgroundView.layer setCornerRadius:[backgroundView frame].size.height/4];
	[backgroundView setBackgroundColor:[UIColor whiteColor]];
	[iconContainingView addSubview:backgroundView];
	[iconContainingView addSubview:iconImageView];
	[iconContainingView sendSubviewToBack:backgroundView];
	[iconContainingView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[iconContainingView.widthAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width*0.4f].active = YES;
	[iconContainingView.heightAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width*0.4f].active = YES;
	[backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[backgroundView.widthAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width*0.4f].active = YES;
	[backgroundView.heightAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width*0.4f].active = YES;
	[stackView addArrangedSubview:iconContainingView];
	UILabel *labelOne = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
	NSDictionary *attribs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle]};
	NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:@"Selenium" attributes:attribs];
	labelOne.attributedText = attributedText;
	labelOne.textColor = [UIColor whiteColor];
	labelOne.textAlignment = NSTextAlignmentCenter;
	labelOne.adjustsFontForContentSizeCategory = YES;
	[stackView addArrangedSubview:labelOne];
	UILabel *labelTwo = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
	NSDictionary *attribsTwo = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
	NSMutableAttributedString *attributedTextTwo = [[NSMutableAttributedString alloc] initWithString:@"You will be back in a moment." attributes:attribsTwo];
	labelTwo.attributedText = attributedTextTwo;
	labelTwo.textColor = [UIColor whiteColor];
	labelTwo.textAlignment = NSTextAlignmentCenter;
	labelOne.adjustsFontForContentSizeCategory = YES;
	[stackView addArrangedSubview:labelTwo];
	[view addSubview:stackView];
	[stackView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor constant:0].active = YES;
	[stackView.centerYAnchor constraintEqualToAnchor:view.centerYAnchor constant:0].active = YES;
	[view setAlpha:0];
	[[UIApplication sharedApplication].keyWindow.rootViewController.view.superview addSubview:view];
	[UIView animateWithDuration:1.0f animations:^{
		[view setAlpha:1];
	} completion:^(BOOL finished) {
		SBSRelaunchAction *restartAction = [NSClassFromString(@"SBSRelaunchAction") actionWithReason:@"RestartRenderServer" options:2 targetURL:nil];
		[[NSClassFromString(@"FBSSystemService") sharedService] sendActions:[NSSet setWithObject:restartAction] withResult:nil];
	}];
}

- (instancetype)init {
    self = [super init];

    if (self) {
		self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
		
		self.respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring"
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(respring)];
        self.respringButton.tintColor = [UIColor labelColor];
        self.navigationItem.rightBarButtonItem = self.respringButton;
        self.navigationItem.titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,40)];
		NSString *_title = @"Selenium";
		NSString *_subtitle = @"Version 1.1.1";

		UIStackView *text = [[UIStackView alloc] initWithFrame:CGRectMake(0,0,64,16)];
		text.axis = 1;
		text.distribution = 0;
		text.alignment = UIStackViewAlignmentCenter;
		text.layoutMarginsRelativeArrangement = 0;
		text.spacing = 0;

		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,64,8)];
		titleLabel.text = _title;
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        titleLabel.textColor = [UIColor labelColor];
		titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		titleLabel.textAlignment = NSTextAlignmentCenter;
		titleLabel.numberOfLines = 1;

		UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,64,8)];
		subtitleLabel.text = _subtitle;
        subtitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightUltraLight];
        subtitleLabel.textColor = [UIColor labelColor];
		subtitleLabel.adjustsFontSizeToFitWidth = YES;
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		subtitleLabel.textAlignment = NSTextAlignmentCenter;
		subtitleLabel.numberOfLines = 1;

		[text addArrangedSubview:titleLabel];
		[text addArrangedSubview:subtitleLabel];

        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,32,40)];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconView.image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/SeleniumPrefs.bundle/icon.png"];
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;

		UIStackView *titleStackView = [[UIStackView alloc] initWithFrame:CGRectMake(0,0,64,80)];
		titleStackView.axis = 1;
		titleStackView.distribution = 0;
		titleStackView.alignment = UIStackViewAlignmentCenter;
		titleStackView.layoutMarginsRelativeArrangement = 0;
		titleStackView.spacing = 1;

		[titleStackView addArrangedSubview:self.iconView];
		[titleStackView addArrangedSubview:text];

        [self.navigationItem.titleView addSubview:titleStackView];
		

		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		appearanceSettings.navigationBarTintColor = [UIColor labelColor];
		//appearanceSettings.navigationBarTitleColor = [UIColor colorWithWhite:0 alpha:1];

		self.hb_appearanceSettings = appearanceSettings;
    }

    return self;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {

    CGFloat offsetY = scrollView.contentOffset.y;

    if (offsetY > (scrollView.minimumContentOffset.y+1)) {
        [UIView animateWithDuration:0.133 animations:^{
			self.navigationItem.titleView.frame = CGRectMake(self.navigationItem.titleView.frame.origin.x, -40, self.navigationItem.titleView.frame.size.width, self.navigationItem.titleView.frame.size.height);
        }];
    } else {
        [UIView animateWithDuration:0.133 animations:^{
			self.navigationItem.titleView.frame = CGRectMake(self.navigationItem.titleView.frame.origin.x, 0, self.navigationItem.titleView.frame.size.width, self.navigationItem.titleView.frame.size.height);
        }];
    }
}
@end
