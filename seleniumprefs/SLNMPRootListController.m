#include "SLNMPRootListController.h"

@implementation SLNMPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
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
		NSString *_subtitle = @"Version 1.0.0";

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
