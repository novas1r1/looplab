#ifndef AUDIO_FILE_HANDLER_H
#define AUDIO_FILE_HANDLER_H

#include <string>
#include <vector>
#include <cstdint>

namespace repeatlab {

struct AudioData {
    std::vector<float> samples;  // Interleaved samples
    int sampleRate;
    int channels;
    int64_t totalFrames;
    
    bool isValid() const {
        return !samples.empty() && sampleRate > 0 && channels > 0;
    }
};

class AudioFileHandler {
public:
    // Read audio file (supports WAV)
    static AudioData readFile(const std::string& path);
    
    // Write audio file as WAV
    static bool writeFile(const std::string& path, const AudioData& data);
    
private:
    static AudioData readWavFile(const std::string& path);
    static bool writeWavFile(const std::string& path, const AudioData& data);
};

} // namespace repeatlab

#endif // AUDIO_FILE_HANDLER_H

