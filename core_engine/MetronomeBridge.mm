#import "MetronomeBridge.h"
#import "MetronomeDSP.h"
#import <memory>

@implementation MetronomeBridge {
    std::unique_ptr<MetronomeDSP> _dsp;
}

- (instancetype)initWithSampleRate:(double)sampleRate bpm:(double)bpm {
    self = [super init];
    if (self) {
        _dsp = std::make_unique<MetronomeDSP>(sampleRate, bpm);
    }
    return self;
}

- (void)setBPM:(double)bpm {
    if (_dsp) {
        _dsp->setBPM(bpm);
    }
}

- (void)setAbsolutePositionForTesting:(uint64_t)pos {
    if (_dsp) {
        _dsp->setAbsolutePositionForTesting(pos);
    }
}

- (NSArray<NSNumber *> *)processBuffer:(uint32_t)bufferSize {
    if (!_dsp) return @[];
    
    std::vector<uint32_t> beatIndices = _dsp->processBuffer(bufferSize);
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:beatIndices.size()];
    
    for (uint32_t index : beatIndices) {
        [result addObject:@(index)];
    }
    
    return result;
}

@end
