#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIControl.h>
#import "RandomHeaders.h"
#import "AXNView.h"

#define kIdentifier @"com.miwix.selenium"
#define kSettingsChangedNotification (CFStringRef)@"com.miwix.selenium/ReloadPrefs"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.miwix.selenium.plist"

@interface SBDashBoardNotificationAdjunctListViewController : UIViewController {
    UIStackView* _stackView;
}

@property (nonatomic, retain) AXNView *axnView;

-(void)adjunctListModel:(id)arg1 didAddItem:(id)arg2 ;
-(void)adjunctListModel:(id)arg1 didRemoveItem:(id)arg2 ;
-(void)_didUpdateDisplay;
-(CGSize)sizeToMimic;
-(void)_insertItem:(id)arg1 animated:(BOOL)arg2 ;
-(void)_removeItem:(id)arg1 animated:(BOOL)arg2 ;
-(BOOL)isPresentingContent;

@end
// iOS13 Support
@interface CSNotificationAdjunctListViewController : UIViewController {
    UIStackView* _stackView;
}

@property (nonatomic, retain) AXNView *axnView;

-(void)adjunctListModel:(id)arg1 didAddItem:(id)arg2 ;
-(void)adjunctListModel:(id)arg1 didRemoveItem:(id)arg2 ;
-(void)_didUpdateDisplay;
-(CGSize)sizeToMimic;
-(void)_insertItem:(id)arg1 animated:(BOOL)arg2 ;
-(void)_removeItem:(id)arg1 animated:(BOOL)arg2 ;
-(BOOL)isPresentingContent;

@end


@interface SBDashBoardCombinedListViewController (Axon)

@property (nonatomic, retain) AXNView *axnView;

@end
// iOS13 Support
@interface CSCombinedListViewController : UIViewController

@property (nonatomic, retain) AXNView *axnView;

@end

@interface SBNCScreenController : NSObject
-(void)turnOnScreenForNotificationRequest:(NCNotificationRequest *)arg1 ;

// %new
+ (id)sharedInstance;
@end

@interface SBNCSoundController : NSObject
-(void)playSoundForNotificationRequest:(id)arg1 presentingDestination:(id)arg2 ;

// %new
+ (id)sharedInstance;
@end
