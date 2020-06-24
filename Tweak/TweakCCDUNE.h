@interface CCUIContentModuleContentContainerView : UIView
@end

@interface CCUIContentModuleBackgroundView : UIView
@end 

@interface MTMaterialView : UIView
@end 

@interface CCUIRoundButton : UIControl
@property (nonatomic, retain) MTMaterialView *normalStateBackgroundView;
- (void)_unhighlight;
- (void)setHighlighted:(bool)arg1;
@end

@interface CCUILabeledRoundButton : UIView
@property (nonatomic, assign) bool centered;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) bool labelsVisible;
@property (nonatomic, retain) UIImage *glyphImage;
@property (nonatomic, retain) CCUIRoundButton *buttonView;
- (id)initWithGlyphImage:(id)arg1 highlightColor:(id)arg2 useLightStyle:(BOOL)arg3;
- (void)updatePosition;
@end

@interface CCUILabeledRoundButtonViewController : UIViewController
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *subtitle;
@property (nonatomic, retain) UIColor *highlightColor;
@property (nonatomic, assign) bool labelsVisible;
@property (nonatomic, retain) CCUILabeledRoundButton *buttonContainer;
@property (nonatomic, retain) CCUIRoundButton *button;
-(id)initWithGlyphImage:(id)arg1 highlightColor:(id)arg2 useLightStyle:(BOOL)arg3 ;
@end

@interface CCUIDisplayBackgroundViewController : UIViewController
@property (nonatomic, retain) CCUILabeledRoundButtonViewController *nightShiftButton;
@property (nonatomic, retain) CCUILabeledRoundButtonViewController *trueToneButton;
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@property (nonatomic,copy) NSString *moduleIdentifier;
@property (nonatomic,strong,readwrite) CCUIContentModuleBackgroundView *backgroundView;
@property (nonatomic,retain) CCUIDisplayBackgroundViewController *backgroundViewController;
@property (nonatomic, retain) CCUILabeledRoundButtonViewController *darkButton;
@end

@interface CAPackage : NSObject
@property (readonly) CALayer *rootLayer;
@property (readonly) BOOL geometryFlipped;
+ (id)packageWithContentsOfURL:(id)arg1 type:(id)arg2 options:(id)arg3 error:(id)arg4;
- (id)_initWithContentsOfURL:(id)arg1 type:(id)arg2 options:(id)arg3 error:(id)arg4;
@end

extern NSString const *kCAPackageTypeCAMLBundle;

@interface CCUICAPackageView : UIView
@property (nonatomic, retain) CAPackage *package;
- (void)setStateName:(id)arg1;
@end

@interface CCUIDuneButton : CCUIRoundButton
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) CCUICAPackageView *packageView;
- (id)initWithGlyphImage:(id)arg1 highlightColor:(id)arg2 useLightStyle:(BOOL)arg3;
- (void)updateStateAnimated:(bool)arg1;
@end

@interface DNDState : NSObject
-(BOOL)isActive;
@end
