#pragma once

@class UIViewController;

@interface LinkSettingsPresenter : NSObject
- (instancetype)initWithLinkHandle:(void*)handle;
- (UIViewController*)settingsViewController;
- (BOOL)ablIsEnabled;
@end
