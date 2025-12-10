#include <jni.h>
#include <string>
#include <vector>
#include <memory>
#include <android/log.h>

#include "audio_file_handler.h"
#include "rubberband/RubberBandStretcher.h"

#define LOG_TAG "RubberBandJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

using namespace RubberBand;
using namespace repeatlab;

extern "C" {

/**
 * Process an audio file with Rubber Band time-stretching/pitch-shifting.
 *
 * @param inputPath Path to input audio file (WAV format)
 * @param outputPath Path where processed audio will be written
 * @param speed Time ratio (1.0 = original speed, 0.5 = half speed, 2.0 = double speed)
 * @param pitch Pitch scale (1.0 = original pitch, 2.0 = one octave up)
 * @return Output path on success, empty string on failure
 */
JNIEXPORT jstring JNICALL
Java_com_repeatlab_app_RubberBandPlugin_processFile(
    JNIEnv *env,
    jobject /* this */,
    jstring inputPath,
    jstring outputPath,
    jdouble speed,
    jdouble pitch) {
    
    const char* inputPathStr = env->GetStringUTFChars(inputPath, nullptr);
    const char* outputPathStr = env->GetStringUTFChars(outputPath, nullptr);
    
    std::string input(inputPathStr);
    std::string output(outputPathStr);
    
    env->ReleaseStringUTFChars(inputPath, inputPathStr);
    env->ReleaseStringUTFChars(outputPath, outputPathStr);
    
    LOGI("Processing: %s -> %s (speed=%.2f, pitch=%.2f)", 
         input.c_str(), output.c_str(), speed, pitch);
    
    // Validate parameters
    if (speed <= 0.0 || speed > 10.0) {
        LOGE("Invalid speed ratio: %.2f", speed);
        return env->NewStringUTF("");
    }
    
    if (pitch <= 0.0 || pitch > 10.0) {
        LOGE("Invalid pitch scale: %.2f", pitch);
        return env->NewStringUTF("");
    }
    
    // Read input audio file
    AudioData inputData = AudioFileHandler::readFile(input);
    if (!inputData.isValid()) {
        LOGE("Failed to read input file");
        return env->NewStringUTF("");
    }
    
    LOGI("Input: %d Hz, %d channels, %lld frames",
         inputData.sampleRate, inputData.channels, (long long)inputData.totalFrames);
    
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
            inputData.sampleRate,
            inputData.channels,
            options
        );
    } catch (const std::exception& e) {
        LOGE("Failed to create RubberBandStretcher: %s", e.what());
        return env->NewStringUTF("");
    }
    
    // Set time and pitch ratios
    // Time ratio: 1.0 = original duration, 0.5 = half duration (2x speed)
    // For speed multiplier: timeRatio = 1.0 / speed
    double timeRatio = 1.0 / speed;
    stretcher->setTimeRatio(timeRatio);
    stretcher->setPitchScale(pitch);
    
    LOGI("Rubber Band configured: timeRatio=%.2f, pitchScale=%.2f", timeRatio, pitch);
    
    // Prepare deinterleaved input buffers
    std::vector<std::vector<float>> channelBuffers(inputData.channels);
    for (int ch = 0; ch < inputData.channels; ++ch) {
        channelBuffers[ch].resize(inputData.totalFrames);
    }
    
    // Deinterleave input samples
    for (int64_t frame = 0; frame < inputData.totalFrames; ++frame) {
        for (int ch = 0; ch < inputData.channels; ++ch) {
            channelBuffers[ch][frame] = inputData.samples[frame * inputData.channels + ch];
        }
    }
    
    // Create pointer array for Rubber Band
    std::vector<const float*> inputPtrs(inputData.channels);
    for (int ch = 0; ch < inputData.channels; ++ch) {
        inputPtrs[ch] = channelBuffers[ch].data();
    }
    
    // Study phase (required for offline processing)
    LOGI("Starting study phase...");
    stretcher->study(inputPtrs.data(), inputData.totalFrames, true);
    
    // Calculate expected output size
    int64_t expectedOutputFrames = static_cast<int64_t>(inputData.totalFrames * timeRatio) + 8192;
    
    // Prepare output buffers
    std::vector<std::vector<float>> outputChannels(inputData.channels);
    for (int ch = 0; ch < inputData.channels; ++ch) {
        outputChannels[ch].reserve(expectedOutputFrames);
    }
    
    // Processing phase
    LOGI("Starting processing phase...");
    
    const size_t blockSize = 1024;
    std::vector<float*> outputPtrs(inputData.channels);
    std::vector<std::vector<float>> tempOutput(inputData.channels);
    for (int ch = 0; ch < inputData.channels; ++ch) {
        tempOutput[ch].resize(blockSize * 2);
        outputPtrs[ch] = tempOutput[ch].data();
    }
    
    int64_t inputProcessed = 0;
    int64_t totalOutputFrames = 0;
    
    while (inputProcessed < inputData.totalFrames) {
        size_t toProcess = std::min(blockSize, 
            static_cast<size_t>(inputData.totalFrames - inputProcessed));
        bool isFinal = (inputProcessed + toProcess >= inputData.totalFrames);
        
        // Update input pointers
        for (int ch = 0; ch < inputData.channels; ++ch) {
            inputPtrs[ch] = channelBuffers[ch].data() + inputProcessed;
        }
        
        stretcher->process(inputPtrs.data(), toProcess, isFinal);
        inputProcessed += toProcess;
        
        // Retrieve available output
        int available;
        while ((available = stretcher->available()) > 0) {
            size_t toRetrieve = std::min(static_cast<size_t>(available), blockSize * 2);
            stretcher->retrieve(outputPtrs.data(), toRetrieve);
            
            for (int ch = 0; ch < inputData.channels; ++ch) {
                outputChannels[ch].insert(
                    outputChannels[ch].end(),
                    tempOutput[ch].begin(),
                    tempOutput[ch].begin() + toRetrieve
                );
            }
            totalOutputFrames += toRetrieve;
        }
        
        // Log progress periodically
        if (inputProcessed % (inputData.totalFrames / 10 + 1) == 0) {
            int progress = static_cast<int>(100.0 * inputProcessed / inputData.totalFrames);
            LOGI("Processing progress: %d%%", progress);
        }
    }
    
    // Retrieve any remaining output
    int available;
    while ((available = stretcher->available()) > 0) {
        size_t toRetrieve = std::min(static_cast<size_t>(available), blockSize * 2);
        stretcher->retrieve(outputPtrs.data(), toRetrieve);
        
        for (int ch = 0; ch < inputData.channels; ++ch) {
            outputChannels[ch].insert(
                outputChannels[ch].end(),
                tempOutput[ch].begin(),
                tempOutput[ch].begin() + toRetrieve
            );
        }
        totalOutputFrames += toRetrieve;
    }
    
    LOGI("Processing complete: %lld input frames -> %lld output frames",
         (long long)inputData.totalFrames, (long long)totalOutputFrames);
    
    // Interleave output
    AudioData outputData;
    outputData.sampleRate = inputData.sampleRate;
    outputData.channels = inputData.channels;
    outputData.totalFrames = totalOutputFrames;
    outputData.samples.resize(totalOutputFrames * inputData.channels);
    
    for (int64_t frame = 0; frame < totalOutputFrames; ++frame) {
        for (int ch = 0; ch < inputData.channels; ++ch) {
            outputData.samples[frame * inputData.channels + ch] = outputChannels[ch][frame];
        }
    }
    
    // Write output file
    if (!AudioFileHandler::writeFile(output, outputData)) {
        LOGE("Failed to write output file");
        return env->NewStringUTF("");
    }
    
    LOGI("Successfully wrote output: %s", output.c_str());
    return env->NewStringUTF(output.c_str());
}

/**
 * Get Rubber Band library version.
 */
JNIEXPORT jstring JNICALL
Java_com_repeatlab_app_RubberBandPlugin_getVersion(
    JNIEnv *env,
    jobject /* this */) {
    return env->NewStringUTF(RubberBandStretcher::getVersion());
}

} // extern "C"

