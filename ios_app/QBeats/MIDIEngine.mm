#import "MIDIEngineBridge.h"
#import <CoreMIDI/CoreMIDI.h>
#import <CoreMIDI/MIDINetworkSession.h>
#include <mach/mach_time.h>
#import <os/log.h>
#import <string.h>
#include <atomic>
#include <vector>
#include "../../core_engine/MIDISequencer.h"

struct MIDIEngine {
    MIDIClientRef   client;
    MIDIEndpointRef virtualSource;   // Out
    MIDIEndpointRef virtualDest;     // In
    
    MIDIPortRef _inputPort;
    MIDIPortRef _outputPort;
    MIDIEndpointRef _physicalDestinations[32];
    std::vector<MIDIEndpointRef> _connectedSources;
    std::atomic<int> _physicalDestCount;
    dispatch_queue_t _scanQueue; // seriale, label "com.qbeats.midi.scan"

    MIDISequencer sequencer;
    ScheduledEventBuffer outBuffer;
    Byte _processPacketBuffer[4 + MAX_EVENTS_PER_BUFFER * 16];

    uint64_t lastSamplePosition;
    uint64_t lastMachTime;
    double   sampleRate;

    void (*receiveCallback)(const uint8_t*, uint32_t, void*);
    void* receiveUserData;

    mach_timebase_info_data_t timebaseInfo;

    // Network MIDI
    id _networkSessionObserver; // NSNotification observer — retain in ARC-free context via __bridge_retained

    MIDIEngine() {
        client = 0;
        virtualSource = 0;
        virtualDest = 0;
        _inputPort = 0;
        _outputPort = 0;
        _physicalDestCount.store(0);
        lastSamplePosition = 0;
        lastMachTime = 0;
        sampleRate = 48000.0;
        receiveCallback = nullptr;
        receiveUserData = nullptr;
        _scanQueue = nullptr;
        memset(_processPacketBuffer, 0, sizeof(_processPacketBuffer));
    }

    void scanAndConnectPhysicalPorts() {
        // Step 1 — disconnetti tutte le sorgenti fisiche attualmente connesse
        for (MIDIEndpointRef ep : _connectedSources) {
            MIDIPortDisconnectSource(_inputPort, ep);
        }
        _connectedSources.clear();

        // Step 2 — enumera e connetti sorgenti fisiche
        int srcCount = (int)MIDIGetNumberOfSources();
        for (int i = 0; i < srcCount; i++) {
            MIDIEndpointRef ep = MIDIGetSource(i);
            if (ep == virtualSource) continue; // evita echo loop
            MIDIPortConnectSource(_inputPort, ep, NULL);
            _connectedSources.push_back(ep);
        }

        // Step 3 — enumera destinazioni fisiche
        int newDestCount = 0;
        int destTotal = (int)MIDIGetNumberOfDestinations();
        for (int i = 0; i < destTotal; i++) {
            MIDIEndpointRef ep = MIDIGetDestination(i);
            if (ep == virtualDest) continue; // evita echo loop
            if (newDestCount >= 32) continue;          // bounds check — mai overflow
            _physicalDestinations[newDestCount++] = ep;
        }

        // Step 4 — aggiorna contatore con release ordering
        _physicalDestCount.store(newDestCount, std::memory_order_release);
    }
};

static inline uint64_t nanosToMach(uint64_t nanos,
                                    const mach_timebase_info_data_t& tb) {
    return ((__uint128_t)nanos * tb.denom) / tb.numer;
}

static void midiReceiveProc(const MIDIPacketList* pktList,
                            void* readProcRefCon,
                            void* srcConnRefCon)
{
    MIDIEngine* engine = (MIDIEngine*)readProcRefCon;
    if (!engine || !engine->receiveCallback) return;

    const MIDIPacket* packet = &pktList->packet[0];
    for (UInt32 i = 0; i < pktList->numPackets; ++i) {
        engine->receiveCallback(packet->data, (uint32_t)packet->length, engine->receiveUserData);
        packet = MIDIPacketNext(packet);
    }
}

static void midiNotifyProc(const MIDINotification *message, void *refCon) {
    MIDIEngine* engine = (MIDIEngine*)refCon;
    switch (message->messageID) {
        case kMIDIMsgSetupChanged:
            dispatch_async(engine->_scanQueue, ^{
                engine->scanAndConnectPhysicalPorts();
            });
            break;
        default:
            break;
    }
}

void* midi_engine_create(void)
{
    MIDIEngine* engine = new MIDIEngine();
    mach_timebase_info(&engine->timebaseInfo);
    return engine;
}

void midi_engine_destroy(void* handle)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine) return;
    midi_engine_stop(handle);
    delete engine;
}

bool midi_engine_start(void* handle)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine) return false;

    OSStatus result;

    // 1. Crea _scanQueue
    engine->_scanQueue = dispatch_queue_create("com.qbeats.midi.scan", DISPATCH_QUEUE_SERIAL);

    // 2. Registra il client e la notify
    result = MIDIClientCreate(CFSTR("Q-BEATS"), midiNotifyProc, engine, &engine->client);
    if (result != noErr) return false;

    // 3. Crea porta input fisica
    MIDIInputPortCreate(engine->client, CFSTR("Q-BEATS In"), midiReceiveProc, engine, &engine->_inputPort);

    // 4. Crea porta output fisica
    MIDIOutputPortCreate(engine->client, CFSTR("Q-BEATS Out"), &engine->_outputPort);

    // La prima scan sincrona viene posticipata dopo la creazione delle virtual ports

    result = MIDISourceCreate(engine->client, CFSTR("Q-BEATS Virtual Out"), &engine->virtualSource);
    if (result != noErr) {
        MIDIClientDispose(engine->client);
        engine->client = 0;
        return false;
    }

    result = MIDIDestinationCreate(engine->client, CFSTR("Q-BEATS Virtual In"), midiReceiveProc, engine, &engine->virtualDest);
    if (result != noErr) {
        MIDIEndpointDispose(engine->virtualSource);
        engine->virtualSource = 0;
        MIDIClientDispose(engine->client);
        engine->client = 0;
        return false;
    }

    // 5. Prima scan sincrona (DOPO aver creato virtualSource e virtualDest)
    dispatch_sync(engine->_scanQueue, ^{ engine->scanAndConnectPhysicalPorts(); });

#if DEBUG
    os_log(OS_LOG_DEFAULT, "Q-BEATS MIDIEngine started successfully");
#endif

    // Network MIDI — observer per cambio stato sessione
    engine->_networkSessionObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:MIDINetworkSessionDidChangeNotification
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification* note) {
            os_log(OS_LOG_DEFAULT, "Q-BEATS MIDINetworkSession state changed");
        }];

    return true;
}

void midi_engine_stop(void* handle)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine) return;

    // 1. Drena la scan queue — deve essere la prima operazione assoluta
    if (engine->_scanQueue) {
        dispatch_sync(engine->_scanQueue, ^{});
    }

    // 2. Disconnetti sorgenti fisiche PRIMA di disporre le porte
    for (MIDIEndpointRef ep : engine->_connectedSources) {
        if (engine->_inputPort) MIDIPortDisconnectSource(engine->_inputPort, ep);
    }
    engine->_connectedSources.clear();

    // 3. Rimuovi observer Network MIDI
    if (engine->_networkSessionObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:engine->_networkSessionObserver];
        engine->_networkSessionObserver = nil;
    }

    // 4. Dispose porte ed endpoint nell'ordine corretto
    if (engine->virtualDest)   { MIDIEndpointDispose(engine->virtualDest);   engine->virtualDest = 0; }
    if (engine->virtualSource) { MIDIEndpointDispose(engine->virtualSource); engine->virtualSource = 0; }
    if (engine->_inputPort)    { MIDIPortDispose(engine->_inputPort);        engine->_inputPort = 0; }
    if (engine->_outputPort)   { MIDIPortDispose(engine->_outputPort);       engine->_outputPort = 0; }
    if (engine->client)        { MIDIClientDispose(engine->client);          engine->client = 0; }
}

void midi_engine_sync_clock(void* handle,
                            uint64_t currentSamplePosition,
                            uint64_t machTimeAtBufferStart,
                            double   sampleRate)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine) return;
    engine->lastSamplePosition = currentSamplePosition;
    engine->lastMachTime = machTimeAtBufferStart;
    if (engine->sampleRate != sampleRate) {
        engine->sampleRate = sampleRate;
        engine->sequencer.setSampleRate(sampleRate);
    }
}

void midi_engine_send(void* handle,
                      const uint8_t* packet,
                      uint32_t length,
                      uint64_t samplePosition)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine || !engine->virtualSource || length == 0) return;

    uint64_t sampleOffset = samplePosition - engine->lastSamplePosition;
    double   offsetNanos  = ((double)sampleOffset / engine->sampleRate) * 1.0e9;
    uint64_t targetMach   = engine->lastMachTime + nanosToMach((uint64_t)offsetNanos, engine->timebaseInfo);

    Byte virtualPacketBuffer[256];
    MIDIPacketList* pktList = (MIDIPacketList*)virtualPacketBuffer;
    MIDIPacket* pkt = MIDIPacketListInit(pktList);
    pkt = MIDIPacketListAdd(pktList, sizeof(virtualPacketBuffer), pkt, targetMach, length, packet);
    if (pkt) {
        MIDIReceived(engine->virtualSource, pktList);
    }

    // Lettura con acquire ordering — OBBLIGATORIO
    int count = engine->_physicalDestCount.load(std::memory_order_acquire);

    if (count > 0) {
        // Buffer stack sicuro per MIDIPacketList
        Byte packetBuffer[256];
        MIDIPacketList* physPacketList = (MIDIPacketList*)packetBuffer;
        MIDIPacket* physPkt = MIDIPacketListInit(physPacketList);
        physPkt = MIDIPacketListAdd(physPacketList, sizeof(packetBuffer),
                                   physPkt, targetMach, length, packet);

        // Invia a tutte le destinazioni fisiche
        for (int i = 0; i < count; i++) {
            MIDISend(engine->_outputPort, engine->_physicalDestinations[i], physPacketList);
        }
    }
}

void midi_engine_set_receive_callback(void* handle,
                                      void (*callback)(const uint8_t*, uint32_t, void*),
                                      void* userData)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine) return;
    engine->receiveCallback = callback;
    engine->receiveUserData = userData;
}

void midi_engine_set_bpm(void* handle, double bpm) {
    if (!handle) return;
    MIDIEngine* engine = (MIDIEngine*)handle;
    engine->sequencer.setBPM(bpm);
}

void midi_engine_set_pattern(void* handle, const MIDIEvent* events, uint32_t count, uint32_t lengthTicks) {
    if (!handle) return;
    MIDIEngine* engine = (MIDIEngine*)handle;
    std::vector<MIDIEvent> patternEvents;
    patternEvents.reserve(count);
    for (uint32_t i = 0; i < count; ++i) {
        patternEvents.push_back(events[i]);
    }
    engine->sequencer.setPattern(patternEvents, lengthTicks);
}

void midi_engine_process(void* handle, uint32_t bufferSize) {
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine || !engine->virtualSource || bufferSize == 0) return;

    engine->sequencer.processBuffer(engine->lastSamplePosition, bufferSize, engine->outBuffer);
    if (engine->outBuffer.count == 0) return;

    MIDIPacketList* pktList = (MIDIPacketList*)engine->_processPacketBuffer;
    MIDIPacket* pkt = MIDIPacketListInit(pktList);

    for (uint32_t i = 0; i < engine->outBuffer.count; ++i) {
        ScheduledEvent& se = engine->outBuffer.events[i];
        
        uint64_t sampleOffset = se.samplePosition - engine->lastSamplePosition;
        double offsetNanos = ((double)sampleOffset / engine->sampleRate) * 1.0e9;
        uint64_t targetMach = engine->lastMachTime + nanosToMach((uint64_t)offsetNanos, engine->timebaseInfo);

        pkt = MIDIPacketListAdd(pktList, sizeof(engine->_processPacketBuffer), pkt, targetMach, se.event.length, se.event.data);
        if (!pkt) break; 
    }

    MIDIReceived(engine->virtualSource, pktList);

    int count = engine->_physicalDestCount.load(std::memory_order_acquire);
    for (int i = 0; i < count; ++i) {
        MIDIEndpointRef dest = engine->_physicalDestinations[i];
        MIDISend(engine->_outputPort, dest, pktList);
    }
}

void midi_engine_network_enable(void* handle, const char* sessionName) {
    if (!handle) return;
    MIDINetworkSession* session = [MIDINetworkSession defaultSession];
    if (sessionName && strlen(sessionName) > 0) {
        session.localName = [NSString stringWithUTF8String:sessionName];
    }
    session.connectionMode = MIDINetworkConnectionPolicy_Anyone;
    session.enabled = YES;
    os_log(OS_LOG_DEFAULT, "Q-BEATS Network MIDI enabled: %{public}s", sessionName ? sessionName : "Q-BEATS");
}

void midi_engine_network_disable(void* handle) {
    if (!handle) return;
    MIDINetworkSession* session = [MIDINetworkSession defaultSession];
    session.enabled = NO;
    os_log(OS_LOG_DEFAULT, "Q-BEATS Network MIDI disabled");
}
