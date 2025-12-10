#import "RubberBandProcessor.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

// Include Rubber Band C++ header
#include "rubberband/RubberBandStretcher.h"

#include <vector>
#include <memory>
#include <fstream>
#include <cstring>

using namespace RubberBand;

// Error domain for Rubber Band processing
NSString *const RubberBandErrorDomain = @"com.repeatlab.rubberband";

// WAV file structures
#pragma pack(push, 1)
struct WavHeader {
    char riff[4];
    uint32_t fileSize;
    char wave[4];
    char fmt[4];
    uint32_t fmtSize;
    uint16_t audioFormat;
    uint16_t numChannels;
    uint32_t sampleRate;
    uint32_t byteRate;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
};

struct DataChunkHeader {
    char data[4];
    uint32_t dataSize;
};
#pragma pack(pop)

@implementation RubberBandProcessor

#pragma mark - Public Methods

+ (nullable NSString *)processFileAtPath:(NSString *)inputPath
                              outputPath:(NSString *)outputPath
                                   speed:(double)speed
                                   pitch:(double)pitch
                                   error:(NSError **)error {
    
    NSLog(@"RubberBandProcessor: Processing %@ -> %@ (speed=%.2f, pitch=%.2f)",
          inputPath, outputPath, speed, pitch);
    
    // Validate parameters
    if (speed <= 0.0 || speed > 10.0) {
        if (error) {
            *error = [NSError errorWithDomain:RubberBandErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid speed ratio"}];
        }
        return nil;
    }
    
    if (pitch <= 0.0 || pitch > 10.0) {
        if (error) {
            *error = [NSError errorWithDomain:RubberBandErrorDomain
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid pitch scale"}];
        }
        return nil;
    }
    
    // Read input WAV file
    std::vector<float> samples;
    int sampleRate = 0;
    int numChannels = 0;
    int64_t totalFrames = 0;
    
    if (![self readWavFile:inputPath.UTF8String
                   samples:&samples
                sampleRate:&sampleRate
               numChannels:&numChannels
               totalFrames:&totalFrames]) {
        if (error) {
            *error = [NSError errorWithDomain:RubberBandErrorDomain
                                         code:3
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to read input file"}];
        }
        return nil;
    }
    
    NSLog(@"Input: %d Hz, %d channels, %lld frames", sampleRate, numChannels, totalFrames);
    
    // Configure Rubber Band for offline processing
    RubberBandStretcher::Options options =
        RubberBandStretcher::OptionProcessOffline |
        RubberBandStretcher::OptionStretchPrecise |
        RubberBandStretcher::OptionTransientsCrisp |
        RubberBandStretcher::OptionDetectorCompound |
        RubberBandStretcher::OptionPhaseLaminar |
        RubberBandStretcher::OptionThreadingNever |
        RubberBandStretcher::OptionWindowStandard |
        RubberBandStretcher::OptionSmoothingOff |
        RubberBandStretcher::OptionFormantShifted |
        RubberBandStretcher::OptionPitchHighQuality |
        RubberBandStretcher::OptionChannelsApart;
    
    std::unique_ptr<RubberBandStretcher> stretcher;
    try {
        stretcher = std::make_unique<RubberBandStretcher>(
            sampleRate,
            numChannels,
            options
        );
    } catch (const std::exception& e) {
        if (error) {
            *error = [NSError errorWithDomain:RubberBandErrorDomain
                                         code:4
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                    [NSString stringWithFormat:@"Failed to create stretcher: %s", e.what()]}];
        }
        return nil;
    }
    
    // Set time and pitch ratios
    double timeRatio = 1.0 / speed;
    stretcher->setTimeRatio(timeRatio);
    stretcher->setPitchScale(pitch);
    
    NSLog(@"Rubber Band configured: timeRatio=%.2f, pitchScale=%.2f", timeRatio, pitch);
    
    // Deinterleave input samples
    std::vector<std::vector<float>> channelBuffers(numChannels);
    for (int ch = 0; ch < numChannels; ++ch) {
        channelBuffers[ch].resize(totalFrames);
    }
    
    for (int64_t frame = 0; frame < totalFrames; ++frame) {
        for (int ch = 0; ch < numChannels; ++ch) {
            channelBuffers[ch][frame] = samples[frame * numChannels + ch];
        }
    }
    
    // Create pointer array for Rubber Band
    std::vector<const float*> inputPtrs(numChannels);
    for (int ch = 0; ch < numChannels; ++ch) {
        inputPtrs[ch] = channelBuffers[ch].data();
    }
    
    // Study phase (required for offline processing)
    NSLog(@"Starting study phase...");
    stretcher->study(inputPtrs.data(), totalFrames, true);
    
    // Prepare output buffers
    int64_t expectedOutputFrames = static_cast<int64_t>(totalFrames * timeRatio) + 8192;
    std::vector<std::vector<float>> outputChannels(numChannels);
    for (int ch = 0; ch < numChannels; ++ch) {
        outputChannels[ch].reserve(expectedOutputFrames);
    }
    
    // Processing phase
    NSLog(@"Starting processing phase...");
    
    const size_t blockSize = 1024;
    std::vector<float*> outputPtrs(numChannels);
    std::vector<std::vector<float>> tempOutput(numChannels);
    for (int ch = 0; ch < numChannels; ++ch) {
        tempOutput[ch].resize(blockSize * 2);
        outputPtrs[ch] = tempOutput[ch].data();
    }
    
    int64_t inputProcessed = 0;
    int64_t totalOutputFrames = 0;
    
    while (inputProcessed < totalFrames) {
        size_t toProcess = std::min(blockSize, static_cast<size_t>(totalFrames - inputProcessed));
        bool isFinal = (inputProcessed + toProcess >= totalFrames);
        
        // Update input pointers
        for (int ch = 0; ch < numChannels; ++ch) {
            inputPtrs[ch] = channelBuffers[ch].data() + inputProcessed;
        }
        
        stretcher->process(inputPtrs.data(), toProcess, isFinal);
        inputProcessed += toProcess;
        
        // Retrieve available output
        int available;
        while ((available = stretcher->available()) > 0) {
            size_t toRetrieve = std::min(static_cast<size_t>(available), blockSize * 2);
            stretcher->retrieve(outputPtrs.data(), toRetrieve);
            
            for (int ch = 0; ch < numChannels; ++ch) {
                outputChannels[ch].insert(
                    outputChannels[ch].end(),
                    tempOutput[ch].begin(),
                    tempOutput[ch].begin() + toRetrieve
                );
            }
            totalOutputFrames += toRetrieve;
        }
    }
    
    // Retrieve any remaining output
    int available;
    while ((available = stretcher->available()) > 0) {
        size_t toRetrieve = std::min(static_cast<size_t>(available), blockSize * 2);
        stretcher->retrieve(outputPtrs.data(), toRetrieve);
        
        for (int ch = 0; ch < numChannels; ++ch) {
            outputChannels[ch].insert(
                outputChannels[ch].end(),
                tempOutput[ch].begin(),
                tempOutput[ch].begin() + toRetrieve
            );
        }
        totalOutputFrames += toRetrieve;
    }
    
    NSLog(@"Processing complete: %lld input frames -> %lld output frames",
          (long long)totalFrames, (long long)totalOutputFrames);
    
    // Interleave output
    std::vector<float> outputSamples(totalOutputFrames * numChannels);
    for (int64_t frame = 0; frame < totalOutputFrames; ++frame) {
        for (int ch = 0; ch < numChannels; ++ch) {
            outputSamples[frame * numChannels + ch] = outputChannels[ch][frame];
        }
    }
    
    // Write output file
    if (![self writeWavFile:outputPath.UTF8String
                    samples:outputSamples
                 sampleRate:sampleRate
                numChannels:numChannels
                totalFrames:totalOutputFrames]) {
        if (error) {
            *error = [NSError errorWithDomain:RubberBandErrorDomain
                                         code:5
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to write output file"}];
        }
        return nil;
    }
    
    NSLog(@"Successfully wrote output: %@", outputPath);
    return outputPath;
}

+ (NSString *)version {
    return [NSString stringWithUTF8String:RubberBandStretcher::getVersion()];
}

#pragma mark - Private Methods

+ (BOOL)readWavFile:(const char *)path
            samples:(std::vector<float> *)samples
         sampleRate:(int *)sampleRate
        numChannels:(int *)numChannels
        totalFrames:(int64_t *)totalFrames {
    
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        NSLog(@"Failed to open file: %s", path);
        return NO;
    }
    
    // Read RIFF header
    WavHeader header;
    file.read(reinterpret_cast<char*>(&header), sizeof(WavHeader));
    
    if (std::strncmp(header.riff, "RIFF", 4) != 0 ||
        std::strncmp(header.wave, "WAVE", 4) != 0) {
        NSLog(@"Invalid WAV file format");
        return NO;
    }
    
    // Skip any extra format bytes
    if (header.fmtSize > 16) {
        file.seekg(header.fmtSize - 16, std::ios::cur);
    }
    
    // Find data chunk
    DataChunkHeader dataHeader;
    while (file.read(reinterpret_cast<char*>(&dataHeader), sizeof(DataChunkHeader))) {
        if (std::strncmp(dataHeader.data, "data", 4) == 0) {
            break;
        }
        file.seekg(dataHeader.dataSize, std::ios::cur);
    }
    
    if (std::strncmp(dataHeader.data, "data", 4) != 0) {
        NSLog(@"Could not find data chunk");
        return NO;
    }
    
    *sampleRate = header.sampleRate;
    *numChannels = header.numChannels;
    
    int bytesPerSample = header.bitsPerSample / 8;
    int64_t numSamples = dataHeader.dataSize / bytesPerSample;
    *totalFrames = numSamples / header.numChannels;
    
    samples->resize(numSamples);
    
    if (header.audioFormat == 1) {
        // PCM integer format
        if (header.bitsPerSample == 16) {
            std::vector<int16_t> intSamples(numSamples);
            file.read(reinterpret_cast<char*>(intSamples.data()), dataHeader.dataSize);
            
            for (size_t i = 0; i < numSamples; ++i) {
                (*samples)[i] = intSamples[i] / 32768.0f;
            }
        } else if (header.bitsPerSample == 24) {
            std::vector<uint8_t> rawData(dataHeader.dataSize);
            file.read(reinterpret_cast<char*>(rawData.data()), dataHeader.dataSize);
            
            for (size_t i = 0; i < numSamples; ++i) {
                int32_t sample = (rawData[i * 3 + 2] << 16) |
                                (rawData[i * 3 + 1] << 8) |
                                 rawData[i * 3];
                if (sample & 0x800000) {
                    sample |= 0xFF000000;
                }
                (*samples)[i] = sample / 8388608.0f;
            }
        } else if (header.bitsPerSample == 32) {
            std::vector<int32_t> intSamples(numSamples);
            file.read(reinterpret_cast<char*>(intSamples.data()), dataHeader.dataSize);
            
            for (size_t i = 0; i < numSamples; ++i) {
                (*samples)[i] = intSamples[i] / 2147483648.0f;
            }
        } else {
            NSLog(@"Unsupported bit depth: %d", header.bitsPerSample);
            return NO;
        }
    } else if (header.audioFormat == 3) {
        // IEEE float format
        if (header.bitsPerSample == 32) {
            file.read(reinterpret_cast<char*>(samples->data()), dataHeader.dataSize);
        } else {
            NSLog(@"Unsupported float bit depth: %d", header.bitsPerSample);
            return NO;
        }
    } else {
        NSLog(@"Unsupported audio format: %d", header.audioFormat);
        return NO;
    }
    
    return YES;
}

+ (BOOL)writeWavFile:(const char *)path
             samples:(const std::vector<float>&)samples
          sampleRate:(int)sampleRate
         numChannels:(int)numChannels
         totalFrames:(int64_t)totalFrames {
    
    std::ofstream file(path, std::ios::binary);
    if (!file.is_open()) {
        NSLog(@"Failed to create output file: %s", path);
        return NO;
    }
    
    // Convert to 16-bit PCM
    std::vector<int16_t> intSamples(samples.size());
    for (size_t i = 0; i < samples.size(); ++i) {
        float sample = samples[i];
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        intSamples[i] = static_cast<int16_t>(sample * 32767.0f);
    }
    
    uint32_t dataSize = static_cast<uint32_t>(intSamples.size() * sizeof(int16_t));
    uint32_t fileSize = 36 + dataSize;
    
    WavHeader header;
    std::memcpy(header.riff, "RIFF", 4);
    header.fileSize = fileSize;
    std::memcpy(header.wave, "WAVE", 4);
    std::memcpy(header.fmt, "fmt ", 4);
    header.fmtSize = 16;
    header.audioFormat = 1;
    header.numChannels = numChannels;
    header.sampleRate = sampleRate;
    header.bitsPerSample = 16;
    header.blockAlign = numChannels * 2;
    header.byteRate = sampleRate * header.blockAlign;
    
    file.write(reinterpret_cast<const char*>(&header), sizeof(WavHeader));
    
    DataChunkHeader dataHeader;
    std::memcpy(dataHeader.data, "data", 4);
    dataHeader.dataSize = dataSize;
    
    file.write(reinterpret_cast<const char*>(&dataHeader), sizeof(DataChunkHeader));
    file.write(reinterpret_cast<const char*>(intSamples.data()), dataSize);
    
    return YES;
}

@end

