#import "LinkSettingsPresenter.h"
#include <ABLLink.h>
#include <ABLLinkSettingsViewController.h>
#include "MIDIEngineBridge.h"

#import "LinkEngine.h"

@interface LinkSettingsPresenter ()
@property (nonatomic, assign) ABLLinkRef linkRef;
@end

@implementation LinkSettingsPresenter

- (instancetype)initWithHandle:(void*)linkEngineHandle {
    self = [super init];
    if (self) {
        // Recupero ABLLinkRef tramite funzione helper dichiarata in LinkEngine.h
        _linkRef = ABLLinkRef(link_engine_get_abl_ref(linkEngineHandle));
    }
    return self;
}

- (UIViewController*)makeSettingsViewController {
    return [ABLLinkSettingsViewController instance:_linkRef];
}

@end
