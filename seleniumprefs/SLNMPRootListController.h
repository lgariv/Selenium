#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBListController.h>
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>

@interface BSAction : NSObject
@end

@interface SBSRelaunchAction : BSAction
+(id)actionWithReason:(id)arg1 options:(unsigned long long)arg2 targetURL:(id)arg3 ;
@end

@interface FBSSystemService : NSObject
+(id)sharedService;
-(void)sendActions:(id)arg1 withResult:(/*^block*/id)arg2 ;
@end

@interface UIScrollView (fix)
@property (getter=_minimumContentOffset,nonatomic,readonly) CGPoint minimumContentOffset;
@end

@interface SLNMPRootListController : HBRootListController

@property (nonatomic, retain, nullable) NSMutableDictionary *savedSpecifiers;

@property (nonatomic, retain, nullable) UIBarButtonItem *respringButton;

@property (readwrite, copy, nonatomic, nullable)
    UIColor *navigationBarBackgroundColor;

@property (readwrite, copy, nonatomic, nullable)
    UIColor *navigationBarTitleColor;

@property (readwrite, copy, nonatomic, nullable)
    UIColor *navigationBarTintColor;

@property (nonatomic, readwrite, assign)
	BOOL prefersLargeTitles;

@property (nonatomic, strong, readwrite, nullable)
	UIView *titleView;

@property (nonatomic, retain, nullable) UILabel* titleLabel;
@property (nonatomic, retain, nullable) UIImageView* iconView;

//@property(nonatomic, readwrite, copy) UINavigationBarAppearance *scrollEdgeAppearance;

@end
