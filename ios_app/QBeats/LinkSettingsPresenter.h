#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LinkSettingsPresenter : NSObject

- (instancetype)initWithHandle:(void*)linkEngineHandle NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (UIViewController*)makeSettingsViewController;

@end

NS_ASSUME_NONNULL_END
