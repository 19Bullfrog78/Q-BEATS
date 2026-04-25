#import "LinkSettingsPresenter.h"
#import "LinkEngine.h"
#include <ABLLink.h>
#import <ABLLinkSettingsViewController.h>

@implementation LinkSettingsPresenter {
    void* _handle;
}

- (instancetype)initWithLinkHandle:(void*)handle {
    self = [super init];
    if (self) { _handle = handle; }
    return self;
}

- (UIViewController*)settingsViewController {
    ABLLinkRef ref = (ABLLinkRef)link_engine_get_abl_ref(_handle);
    return [ABLLinkSettingsViewController instance:ref];
}

- (BOOL)ablIsEnabled {
    return link_engine_abl_is_enabled(_handle);
}

@end
