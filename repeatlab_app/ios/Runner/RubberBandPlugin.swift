import Flutter
import Foundation

/**
 * Flutter plugin for Rubber Band audio processing.
 * Provides pitch-preserving time-stretching capabilities.
 */
public class RubberBandPlugin: NSObject, FlutterPlugin {
    
    private static let channelName = "com.repeatlab.rubberband"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = RubberBandPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        NSLog("RubberBandPlugin: Registered with Flutter")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "processFile":
            handleProcessFile(call: call, result: result)
        case "getVersion":
            handleGetVersion(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleProcessFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let speed = args["speed"] as? Double else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing required arguments: inputPath, outputPath, speed",
                details: nil
            ))
            return
        }
        
        let pitch = args["pitch"] as? Double ?? 1.0
        
        NSLog("RubberBandPlugin: processFile \(inputPath) -> \(outputPath) (speed=\(speed), pitch=\(pitch))")
        
        // Process on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSError?
            let outputResult = RubberBandProcessor.processFile(
                atPath: inputPath,
                outputPath: outputPath,
                speed: speed,
                pitch: pitch,
                error: &error
            )
            
            DispatchQueue.main.async {
                if let output = outputResult {
                    NSLog("RubberBandPlugin: Processing completed: \(output)")
                    result(output)
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error during audio processing"
                    NSLog("RubberBandPlugin: Processing failed: \(errorMessage)")
                    result(FlutterError(
                        code: "PROCESSING_FAILED",
                        message: errorMessage,
                        details: nil
                    ))
                }
            }
        }
    }
    
    private func handleGetVersion(result: @escaping FlutterResult) {
        let version = RubberBandProcessor.version()
        result(version)
    }
}

