import AVFAudio
import PokeDataModel

enum PokeAudioMixDefaults {
    static let masterVolume: Float = 0.6
    static let musicVolume: Float = 0.4
    static let soundEffectVolume: Float = 1.0
    static let musicRenderedSampleGain: Float = 0.16
    static let soundEffectRenderedSampleGain: Float = 0.24
    static let musicNoiseGainMultiplier: Float = 0.68
    static let soundEffectNoiseGainMultiplier: Float = 1.0
    static let maxRenderableFrequencyRatio = 0.45
    static let dcBlockPole: Double = 0.995
}

struct PokeAudioRenderedChannelBuffers: @unchecked Sendable {
    let prelude: AVAudioPCMBuffer?
    let loop: AVAudioPCMBuffer?
    let duration: Double
}

struct PokeAudioRenderedSamples {
    var left: [Float]
    var right: [Float]
}

struct PokeAudioRenderedAsset: @unchecked Sendable {
    let channels: [Int: PokeAudioRenderedChannelBuffers]
    let playbackMode: AudioManifest.PlaybackMode
    let maxDuration: Double
}

struct PokeAudioRenderOptions {
    let sampleGain: Float
    let smoothNoise: Bool
    let noiseGainMultiplier: Float

    static let music = PokeAudioRenderOptions(
        sampleGain: PokeAudioMixDefaults.musicRenderedSampleGain,
        smoothNoise: true,
        noiseGainMultiplier: PokeAudioMixDefaults.musicNoiseGainMultiplier
    )

    static let soundEffect = PokeAudioRenderOptions(
        sampleGain: PokeAudioMixDefaults.soundEffectRenderedSampleGain,
        smoothNoise: true,
        noiseGainMultiplier: PokeAudioMixDefaults.soundEffectNoiseGainMultiplier
    )
}
