#import <Foundation/Foundation.h>

@interface MetronomeBridge : NSObject

- (instancetype)initWithSampleRate:(double)sampleRate bpm:(double)bpm;
- (void)setBPM:(double)bpm;
- (void)setAbsolutePositionForTesting:(uint64_t)pos;
- (NSArray<NSNumber *> *)processBuffer:(uint32_t)bufferSize;

@end
