#import "MIDIEngineBridge.h"
#import <CoreMIDI/CoreMIDI.h>
#include <mach/mach_time.h>
#import <os/log.h>
#import <string.h>

struct MIDIEngine {
    MIDIClientRef   client;
    MIDIEndpointRef virtualSource;   // Out
    MIDIEndpointRef virtualDest;     // In

    uint64_t lastSamplePosition;
    uint64_t lastMachTime;
    double   sampleRate;

    void (*receiveCallback)(const uint8_t*, uint32_t, void*);
    void* receiveUserData;

    mach_timebase_info_data_t timebaseInfo;
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

void* midi_engine_create(void)
{
    MIDIEngine* engine = new MIDIEngine();
    memset(engine, 0, sizeof(MIDIEngine));
    engine->sampleRate = 48000.0;
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

    result = MIDIClientCreate(CFSTR("Q-BEATS"), nullptr, nullptr, &engine->client);
    if (result != noErr) return false;

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

#if DEBUG
    os_log(OS_LOG_DEFAULT, "Q-BEATS MIDIEngine started successfully");
#endif
    return true;
}

void midi_engine_stop(void* handle)
{
    MIDIEngine* engine = (MIDIEngine*)handle;
    if (!engine) return;

    if (engine->virtualDest)   { MIDIEndpointDispose(engine->virtualDest);   engine->virtualDest = 0; }
    if (engine->virtualSource) { MIDIEndpointDispose(engine->virtualSource); engine->virtualSource = 0; }
    if (engine->client)        { MIDIClientDispose(engine->client); engine->client = 0; }
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
    engine->sampleRate = sampleRate;
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

    MIDIPacketList pktList;
    MIDIPacket* pkt = MIDIPacketListInit(&pktList);
    pkt = MIDIPacketListAdd(&pktList, sizeof(pktList), pkt, targetMach, length, packet);
    if (pkt) {
        MIDIReceived(engine->virtualSource, &pktList);
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
