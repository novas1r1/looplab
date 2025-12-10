#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Rubber Band audio processor for pitch-preserving time-stretching.
 */
@interface RubberBandProcessor : NSObject

/**
 * Process an audio file with time-stretching and/or pitch-shifting.
 *
 * @param inputPath Path to the input audio file (WAV format)
 * @param outputPath Path where the processed audio will be written
 * @param speed Speed multiplier (1.0 = original, 0.5 = half speed, 2.0 = double speed)
 * @param pitch Pitch scale (1.0 = original, 2.0 = one octave up)
 * @param error Error object if processing fails
 * @return Path to the output file on success, nil on failure
 */
+ (nullable NSString *)processFileAtPath:(NSString *)inputPath
                              outputPath:(NSString *)outputPath
                                   speed:(double)speed
                                   pitch:(double)pitch
                                   error:(NSError **)error;

/**
 * Get the Rubber Band library version.
 */
+ (NSString *)version;

@end

NS_ASSUME_NONNULL_END

