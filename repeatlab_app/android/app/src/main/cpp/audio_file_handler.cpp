#include "audio_file_handler.h"
#include <fstream>
#include <cstring>
#include <android/log.h>

#define LOG_TAG "RubberBandAudio"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace repeatlab {

#pragma pack(push, 1)
struct WavHeader {
    char riff[4];           // "RIFF"
    uint32_t fileSize;      // File size - 8
    char wave[4];           // "WAVE"
    char fmt[4];            // "fmt "
    uint32_t fmtSize;       // Format chunk size (16 for PCM)
    uint16_t audioFormat;   // 1 = PCM, 3 = IEEE float
    uint16_t numChannels;   // Number of channels
    uint32_t sampleRate;    // Sample rate
    uint32_t byteRate;      // Bytes per second
    uint16_t blockAlign;    // Bytes per sample frame
    uint16_t bitsPerSample; // Bits per sample
};

struct DataChunkHeader {
    char data[4];           // "data"
    uint32_t dataSize;      // Size of audio data
};
#pragma pack(pop)

AudioData AudioFileHandler::readFile(const std::string& path) {
    // Check file extension
    std::string extension;
    size_t dotPos = path.rfind('.');
    if (dotPos != std::string::npos) {
        extension = path.substr(dotPos);
        for (auto& c : extension) c = tolower(c);
    }
    
    if (extension == ".wav") {
        return readWavFile(path);
    }
    
    LOGE("Unsupported audio format: %s", extension.c_str());
    return AudioData{};
}

bool AudioFileHandler::writeFile(const std::string& path, const AudioData& data) {
    return writeWavFile(path, data);
}

AudioData AudioFileHandler::readWavFile(const std::string& path) {
    AudioData result;
    
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        LOGE("Failed to open file: %s", path.c_str());
        return result;
    }
    
    // Read RIFF header
    WavHeader header;
    file.read(reinterpret_cast<char*>(&header), sizeof(WavHeader));
    
    if (std::strncmp(header.riff, "RIFF", 4) != 0 ||
        std::strncmp(header.wave, "WAVE", 4) != 0) {
        LOGE("Invalid WAV file format");
        return result;
    }
    
    // Skip any extra format bytes
    if (header.fmtSize > 16) {
        file.seekg(header.fmtSize - 16, std::ios::cur);
    }
    
    // Find data chunk (skip any chunks until we find "data")
    DataChunkHeader dataHeader;
    while (file.read(reinterpret_cast<char*>(&dataHeader), sizeof(DataChunkHeader))) {
        if (std::strncmp(dataHeader.data, "data", 4) == 0) {
            break;
        }
        // Skip this chunk
        file.seekg(dataHeader.dataSize, std::ios::cur);
    }
    
    if (std::strncmp(dataHeader.data, "data", 4) != 0) {
        LOGE("Could not find data chunk");
        return result;
    }
    
    result.sampleRate = header.sampleRate;
    result.channels = header.numChannels;
    
    int bytesPerSample = header.bitsPerSample / 8;
    int64_t numSamples = dataHeader.dataSize / bytesPerSample;
    result.totalFrames = numSamples / header.numChannels;
    
    LOGI("Reading WAV: %d Hz, %d channels, %lld frames, %d bits",
         result.sampleRate, result.channels, (long long)result.totalFrames, header.bitsPerSample);
    
    result.samples.resize(numSamples);
    
    if (header.audioFormat == 1) {
        // PCM integer format
        if (header.bitsPerSample == 16) {
            std::vector<int16_t> intSamples(numSamples);
            file.read(reinterpret_cast<char*>(intSamples.data()), dataHeader.dataSize);
            
            for (size_t i = 0; i < numSamples; ++i) {
                result.samples[i] = intSamples[i] / 32768.0f;
            }
        } else if (header.bitsPerSample == 24) {
            std::vector<uint8_t> rawData(dataHeader.dataSize);
            file.read(reinterpret_cast<char*>(rawData.data()), dataHeader.dataSize);
            
            for (size_t i = 0; i < numSamples; ++i) {
                int32_t sample = (rawData[i * 3 + 2] << 16) |
                                (rawData[i * 3 + 1] << 8) |
                                 rawData[i * 3];
                // Sign extend
                if (sample & 0x800000) {
                    sample |= 0xFF000000;
                }
                result.samples[i] = sample / 8388608.0f;
            }
        } else if (header.bitsPerSample == 32) {
            std::vector<int32_t> intSamples(numSamples);
            file.read(reinterpret_cast<char*>(intSamples.data()), dataHeader.dataSize);
            
            for (size_t i = 0; i < numSamples; ++i) {
                result.samples[i] = intSamples[i] / 2147483648.0f;
            }
        } else {
            LOGE("Unsupported bit depth: %d", header.bitsPerSample);
            result.samples.clear();
            return result;
        }
    } else if (header.audioFormat == 3) {
        // IEEE float format
        if (header.bitsPerSample == 32) {
            file.read(reinterpret_cast<char*>(result.samples.data()), dataHeader.dataSize);
        } else {
            LOGE("Unsupported float bit depth: %d", header.bitsPerSample);
            result.samples.clear();
            return result;
        }
    } else {
        LOGE("Unsupported audio format: %d", header.audioFormat);
        result.samples.clear();
        return result;
    }
    
    return result;
}

bool AudioFileHandler::writeWavFile(const std::string& path, const AudioData& data) {
    if (!data.isValid()) {
        LOGE("Invalid audio data for writing");
        return false;
    }
    
    std::ofstream file(path, std::ios::binary);
    if (!file.is_open()) {
        LOGE("Failed to create output file: %s", path.c_str());
        return false;
    }
    
    // Convert to 16-bit PCM
    std::vector<int16_t> intSamples(data.samples.size());
    for (size_t i = 0; i < data.samples.size(); ++i) {
        float sample = data.samples[i];
        // Clamp to [-1, 1]
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        intSamples[i] = static_cast<int16_t>(sample * 32767.0f);
    }
    
    uint32_t dataSize = intSamples.size() * sizeof(int16_t);
    uint32_t fileSize = 36 + dataSize;
    
    WavHeader header;
    std::memcpy(header.riff, "RIFF", 4);
    header.fileSize = fileSize;
    std::memcpy(header.wave, "WAVE", 4);
    std::memcpy(header.fmt, "fmt ", 4);
    header.fmtSize = 16;
    header.audioFormat = 1;  // PCM
    header.numChannels = data.channels;
    header.sampleRate = data.sampleRate;
    header.bitsPerSample = 16;
    header.blockAlign = data.channels * 2;
    header.byteRate = data.sampleRate * header.blockAlign;
    
    file.write(reinterpret_cast<const char*>(&header), sizeof(WavHeader));
    
    DataChunkHeader dataHeader;
    std::memcpy(dataHeader.data, "data", 4);
    dataHeader.dataSize = dataSize;
    
    file.write(reinterpret_cast<const char*>(&dataHeader), sizeof(DataChunkHeader));
    file.write(reinterpret_cast<const char*>(intSamples.data()), dataSize);
    
    LOGI("Wrote WAV file: %s (%d Hz, %d channels, %zu samples)",
         path.c_str(), data.sampleRate, data.channels, data.samples.size());
    
    return true;
}

} // namespace repeatlab

