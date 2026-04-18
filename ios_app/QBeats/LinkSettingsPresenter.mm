#import "LinkSettingsPresenter.h"
#include <ABLLink.h>
#include <ABLLinkSettingsViewController.h>
#include "MIDIEngineBridge.h"

// LinkEngine è definita in LinkEngine.mm — accesso tramite handle opaco.
// Per ottenere ABLLinkRef, aggiungere funzione interna:
// Questa funzione NON è nel bridge pubblico — uso interno a questo file only.
// Forward declaration:
struct LinkEngine;
extern "C" {
    // Accesso diretto al membro link_ tramite cast — safe perché siamo in .mm
    // e conosciamo la struttura. Alternativa: funzione statica interna.
}

// APPROCCIO PULITO: LinkSettingsPresenter riceve direttamente ABLLinkRef
// tramite una funzione file-scope dichiarata in LinkEngine.mm come friend.
// Per evitare dipendenza circolare, usiamo il pattern seguente:
// LinkSettingsPresenter.mm include il header di LinkEngine (solo per il cast).

#import "LinkEngine.h"

// LinkEngine struct è definita in LinkEngine.mm — non in LinkEngine.h.
// Soluzione: aggiungere in LinkEngine.mm una funzione C statica con
// linkage esterno limitato a questo file. Implementazione alternativa
// che NON richiede conoscere la struttura:
// Passare ABLLinkRef direttamente nell'init di LinkSettingsPresenter.

// ——— REVISIONE DESIGN ———
// LinkSettingsPresenter riceve ABLLinkRef direttamente.
// AudioEngine lo ottiene chiamando link_engine_get_abl_ref (1 funzione interna
// dichiarata solo in LinkEngine.h, NON in MIDIEngineBridge.h — non è API pubblica Swift).

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
