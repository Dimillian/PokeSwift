import AVFAudio
import PokeDataModel

enum PokeAudioRenderer {
    static func renderedAudioAsset(
        playbackMode: AudioManifest.PlaybackMode,
        channels: [AudioManifest.ChannelProgram],
        sampleRate: Double,
        options: PokeAudioRenderOptions,
        soundEffectRequest: SoundEffectPlaybackRequest? = nil
    ) -> PokeAudioRenderedAsset {
        var renderedChannels: [Int: PokeAudioRenderedChannelBuffers] = [:]
        var maxDuration = 0.0

        for channel in channels {
            let hardwareChannel = hardwareChannelIndex(forSoftwareChannel: channel.channelNumber)
                ?? max(0, min(3, channel.channelNumber - 1))
            let preludeEvents = adjusted(
                events: channel.prelude,
                for: soundEffectRequest,
                channelNumber: channel.channelNumber
            )
            let loopEvents = adjusted(
                events: channel.loop,
                for: soundEffectRequest,
                channelNumber: channel.channelNumber
            )
            let preludeSamples = renderSegment(
                events: preludeEvents,
                sampleRate: sampleRate,
                options: options
            )
            let loopSamples = renderSegment(
                events: loopEvents,
                sampleRate: sampleRate,
                options: options
            )
            let preludeDuration = renderedDuration(for: preludeEvents)
            let loopDuration = renderedDuration(for: loopEvents)
            let duration = max(preludeDuration, loopDuration)
            maxDuration = max(maxDuration, duration)
            renderedChannels[hardwareChannel] = PokeAudioRenderedChannelBuffers(
                prelude: makeBuffer(from: preludeSamples, sampleRate: sampleRate),
                loop: makeBuffer(from: loopSamples, sampleRate: sampleRate),
                duration: duration
            )
        }

        return PokeAudioRenderedAsset(
            channels: renderedChannels,
            playbackMode: playbackMode,
            maxDuration: maxDuration
        )
    }

    static func hardwareChannelIndex(forSoftwareChannel channelNumber: Int) -> Int? {
        switch channelNumber {
        case 1, 5:
            return 0
        case 2, 6:
            return 1
        case 3, 7:
            return 2
        case 4, 8:
            return 3
        default:
            return nil
        }
    }

    private static func adjusted(
        events: [AudioManifest.Event],
        for request: SoundEffectPlaybackRequest?,
        channelNumber: Int
    ) -> [AudioManifest.Event] {
        guard let request else { return events }
        let tempoScale = tempoScale(for: request.tempoModifier, channelNumber: channelNumber)
        return events.map {
            adjusted(
                event: $0,
                frequencyModifier: request.frequencyModifier,
                tempoScale: tempoScale
            )
        }
    }

    private static func adjusted(
        event: AudioManifest.Event,
        frequencyModifier: Int?,
        tempoScale: Double
    ) -> AudioManifest.Event {
        let adjustedRegister = adjustedFrequencyRegister(
            event.frequencyRegister,
            modifier: frequencyModifier
        )
        let adjustedTargetRegister = adjustedFrequencyRegister(
            event.pitchSlideTargetRegister,
            modifier: frequencyModifier
        )
        let adjustedFrequencyHz = adjustedRegister.map {
            frequencyHz(forRegister: $0, waveform: event.waveform)
        } ?? event.frequencyHz
        let adjustedTargetHz = adjustedTargetRegister.map {
            frequencyHz(forRegister: $0, waveform: event.waveform)
        } ?? event.pitchSlideTargetHz

        return .init(
            startTime: event.startTime * tempoScale,
            duration: event.duration * tempoScale,
            frequencyHz: adjustedFrequencyHz,
            frequencyRegister: adjustedRegister,
            amplitude: event.amplitude,
            dutyCycle: event.dutyCycle,
            dutyCyclePattern: event.dutyCyclePattern,
            dutyCyclePatternStepOffset: event.dutyCyclePatternStepOffset,
            envelopeStepDuration: event.envelopeStepDuration,
            envelopeDirection: event.envelopeDirection,
            waveSamples: event.waveSamples,
            stereoLeftEnabled: event.stereoLeftEnabled,
            stereoRightEnabled: event.stereoRightEnabled,
            vibratoDelaySeconds: event.vibratoDelaySeconds,
            vibratoDepthSemitones: event.vibratoDepthSemitones,
            vibratoRateHz: event.vibratoRateHz,
            vibratoDelayFrames: event.vibratoDelayFrames,
            vibratoExtentUp: event.vibratoExtentUp,
            vibratoExtentDown: event.vibratoExtentDown,
            vibratoRateFrames: event.vibratoRateFrames,
            pitchSlideTargetHz: adjustedTargetHz,
            pitchSlideTargetRegister: adjustedTargetRegister,
            pitchSlideFrameCount: event.pitchSlideFrameCount,
            noiseShortMode: event.noiseShortMode,
            waveform: event.waveform
        )
    }

    private static func adjustedFrequencyRegister(
        _ register: Int?,
        modifier: Int?
    ) -> Int? {
        guard let register, let modifier else { return register }
        let lowByte = register & 0xff
        let highByte = register & 0x700
        let summedLowByte = lowByte + (modifier & 0xff)
        let adjustedHighByte = min(0x700, highByte + ((summedLowByte >> 8) << 8))
        return adjustedHighByte | (summedLowByte & 0xff)
    }

    private static func tempoScale(
        for modifier: Int?,
        channelNumber: Int
    ) -> Double {
        guard let modifier else { return 1 }
        guard channelNumber != 8 else { return 1 }
        return Double(0x80 + (modifier & 0xff)) / Double(0x100)
    }

    private static func makeBuffer(from samples: PokeAudioRenderedSamples?, sampleRate: Double) -> AVAudioPCMBuffer? {
        guard let samples,
              samples.left.isEmpty == false,
              samples.left.count == samples.right.count,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.left.count)),
              let leftChannelData = buffer.floatChannelData?[0],
              let rightChannelData = buffer.floatChannelData?[1] else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(samples.left.count)
        samples.left.withUnsafeBufferPointer { source in
            leftChannelData.update(from: source.baseAddress!, count: source.count)
        }
        samples.right.withUnsafeBufferPointer { source in
            rightChannelData.update(from: source.baseAddress!, count: source.count)
        }
        return buffer
    }

    private static func renderSegment(
        events: [AudioManifest.Event],
        sampleRate: Double,
        options: PokeAudioRenderOptions
    ) -> PokeAudioRenderedSamples? {
        let totalDuration = renderedDuration(for: events)
        guard totalDuration > 0 else { return nil }
        let frameCount = max(1, Int(ceil(totalDuration * sampleRate)))
        var leftSamples = Array(repeating: Float.zero, count: frameCount)
        var rightSamples = Array(repeating: Float.zero, count: frameCount)

        leftSamples.withUnsafeMutableBufferPointer { leftBuffer in
            guard let leftBaseAddress = leftBuffer.baseAddress else { return }
            rightSamples.withUnsafeMutableBufferPointer { rightBuffer in
                guard let rightBaseAddress = rightBuffer.baseAddress else { return }
                for event in events {
                    render(
                        event: event,
                        leftChannel: leftBaseAddress,
                        rightChannel: rightBaseAddress,
                        frameCount: frameCount,
                        sampleRate: sampleRate,
                        options: options
                    )
                }
            }
        }

        if shouldApplyDCBlock(to: events) {
            conditionRenderedSamples(&leftSamples)
            conditionRenderedSamples(&rightSamples)
        }
        return PokeAudioRenderedSamples(left: leftSamples, right: rightSamples)
    }

    private static func renderedDuration(for events: [AudioManifest.Event]) -> Double {
        events.map { $0.startTime + $0.duration }.max() ?? 0
    }

    private static func render(
        event: AudioManifest.Event,
        leftChannel: UnsafeMutablePointer<Float>,
        rightChannel: UnsafeMutablePointer<Float>,
        frameCount: Int,
        sampleRate: Double,
        options: PokeAudioRenderOptions
    ) {
        guard event.duration > 0 else { return }
        let startFrame = max(0, Int(event.startTime * sampleRate))
        let endFrame = min(frameCount, Int((event.startTime + event.duration) * sampleRate))
        guard endFrame > startFrame else { return }
        guard event.stereoLeftEnabled || event.stereoRightEnabled else { return }
        let declickFrames = max(1, Int(sampleRate * 0.00035))

        switch event.waveform {
        case .square:
            renderSquareEvent(
                event: event,
                leftChannel: leftChannel,
                rightChannel: rightChannel,
                startFrame: startFrame,
                endFrame: endFrame,
                sampleRate: sampleRate,
                declickFrames: declickFrames,
                sampleGain: options.sampleGain
            )
        case .wave:
            renderWaveEvent(
                event: event,
                leftChannel: leftChannel,
                rightChannel: rightChannel,
                startFrame: startFrame,
                endFrame: endFrame,
                sampleRate: sampleRate,
                declickFrames: declickFrames,
                sampleGain: options.sampleGain
            )
        case .noise:
            renderNoiseEvent(
                event: event,
                leftChannel: leftChannel,
                rightChannel: rightChannel,
                startFrame: startFrame,
                endFrame: endFrame,
                sampleRate: sampleRate,
                declickFrames: declickFrames,
                sampleGain: options.sampleGain,
                smoothNoise: options.smoothNoise,
                noiseGainMultiplier: options.noiseGainMultiplier
            )
        }
    }

    private static func modulatedFrequency(for event: AudioManifest.Event, localTime: Double) -> Double {
        let pitchAdjustedRegister = pitchSlideAdjustedRegister(event: event, localTime: localTime)
        let baseFrequency = pitchAdjustedRegister.map {
            frequencyHz(forRegister: $0, waveform: event.waveform)
        } ?? event.frequencyHz ?? 440
        return vibratoAdjustedFrequency(
            baseFrequency: baseFrequency,
            frequencyRegister: pitchAdjustedRegister ?? event.frequencyRegister,
            event: event,
            localTime: localTime
        )
    }

    private static func pitchSlideAdjustedRegister(
        event: AudioManifest.Event,
        localTime: Double
    ) -> Int? {
        guard let startRegister = event.frequencyRegister,
              let targetRegister = event.pitchSlideTargetRegister,
              let pitchSlideFrameCount = event.pitchSlideFrameCount,
              pitchSlideFrameCount > 0 else {
            return nil
        }
        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        let appliedFrames = min(pitchSlideFrameCount, elapsedFrames)
        let registerDelta = targetRegister - startRegister
        if appliedFrames >= pitchSlideFrameCount {
            return targetRegister
        }
        return startRegister + Int(
            (Double(registerDelta) * Double(appliedFrames)) / Double(pitchSlideFrameCount)
        )
    }

    private static func vibratoAdjustedFrequency(
        baseFrequency: Double,
        frequencyRegister: Int?,
        event: AudioManifest.Event,
        localTime: Double
    ) -> Double {
        if let adjustedRegister = gbVibratoAdjustedRegister(
            baseRegister: frequencyRegister,
            event: event,
            localTime: localTime
        ) {
            return frequencyHz(forRegister: adjustedRegister, waveform: event.waveform)
        }
        guard event.vibratoDepthSemitones > 0, event.vibratoRateHz > 0 else { return baseFrequency }
        guard localTime >= event.vibratoDelaySeconds else { return baseFrequency }
        let semitoneOffset = sin(2 * .pi * localTime * event.vibratoRateHz) * event.vibratoDepthSemitones
        return baseFrequency * pow(2, semitoneOffset / 12)
    }

    private static func gbVibratoAdjustedRegister(
        baseRegister: Int?,
        event: AudioManifest.Event,
        localTime: Double
    ) -> Int? {
        guard let baseRegister else { return nil }
        guard event.vibratoExtentUp > 0 || event.vibratoExtentDown > 0 else { return nil }

        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        guard elapsedFrames >= event.vibratoDelayFrames else { return baseRegister }

        let stepFrames = max(1, event.vibratoRateFrames + 1)
        let phase = (elapsedFrames - event.vibratoDelayFrames) / stepFrames
        let lowByte = baseRegister & 0xff
        let adjustedLowByte: Int
        if phase.isMultiple(of: 2) {
            adjustedLowByte = min(0xff, lowByte + event.vibratoExtentUp)
        } else {
            adjustedLowByte = max(0, lowByte - event.vibratoExtentDown)
        }

        return (baseRegister & 0x0700) | adjustedLowByte
    }

    private static func envelopeAdjustedAmplitude(for event: AudioManifest.Event, localTime: Double) -> Double {
        guard let stepDuration = event.envelopeStepDuration, event.envelopeDirection != 0 else {
            return event.amplitude
        }
        let steps = Int(localTime / stepDuration)
        let delta = Double(event.envelopeDirection * steps) / 15
        return max(0, min(1, event.amplitude + delta))
    }

    private static func effectiveDutyCycle(for event: AudioManifest.Event, localTime: Double) -> Double {
        guard let pattern = event.dutyCyclePattern else {
            return event.dutyCycle ?? 0.5
        }

        let elapsedFrames = max(0, Int((localTime * 60).rounded(.down)))
        let stepOffset = (event.dutyCyclePatternStepOffset + elapsedFrames) & 0x3
        let rotatedPattern = rotateDutyCyclePattern(pattern, stepOffset: stepOffset)
        return dutyCycle(forPatternValue: (rotatedPattern >> 6) & 0x3)
    }

    private static func rotateDutyCyclePattern(_ pattern: Int, stepOffset: Int) -> Int {
        let rotation = (stepOffset & 0x3) * 2
        let byte = pattern & 0xff
        return ((byte << rotation) | (byte >> (8 - rotation))) & 0xff
    }

    private static func dutyCycle(forPatternValue value: Int) -> Double {
        switch value {
        case 0: return 0.125
        case 1: return 0.25
        case 3: return 0.75
        default: return 0.5
        }
    }

    private static func renderSquareEvent(
        event: AudioManifest.Event,
        leftChannel: UnsafeMutablePointer<Float>,
        rightChannel: UnsafeMutablePointer<Float>,
        startFrame: Int,
        endFrame: Int,
        sampleRate: Double,
        declickFrames: Int,
        sampleGain: Float
    ) {
        var phase = 0.0
        for frame in startFrame..<endFrame {
            let localTime = Double(frame - startFrame) / sampleRate
            let frequency = min(
                modulatedFrequency(for: event, localTime: localTime),
                sampleRate * PokeAudioMixDefaults.maxRenderableFrequencyRatio
            )
            let phaseIncrement = max(0, min(frequency / sampleRate, PokeAudioMixDefaults.maxRenderableFrequencyRatio))
            let dutyCycle = effectiveDutyCycle(for: event, localTime: localTime)
            let wrappedDutyPhase = positiveFractionalPart(phase - dutyCycle)
            var sampleValue = phase < dutyCycle ? 1.0 : -1.0
            sampleValue += polyBLEP(phase: phase, phaseIncrement: phaseIncrement)
            sampleValue -= polyBLEP(phase: wrappedDutyPhase, phaseIncrement: phaseIncrement)
            mixSample(
                sampleValue,
                for: event,
                leftChannel: leftChannel,
                rightChannel: rightChannel,
                frame: frame,
                startFrame: startFrame,
                endFrame: endFrame,
                localTime: localTime,
                declickFrames: declickFrames,
                sampleGain: sampleGain
            )
            phase = positiveFractionalPart(phase + phaseIncrement)
        }
    }

    private static func renderWaveEvent(
        event: AudioManifest.Event,
        leftChannel: UnsafeMutablePointer<Float>,
        rightChannel: UnsafeMutablePointer<Float>,
        startFrame: Int,
        endFrame: Int,
        sampleRate: Double,
        declickFrames: Int,
        sampleGain: Float
    ) {
        var phase = 0.0
        for frame in startFrame..<endFrame {
            let localTime = Double(frame - startFrame) / sampleRate
            let frequency = min(
                modulatedFrequency(for: event, localTime: localTime),
                sampleRate * PokeAudioMixDefaults.maxRenderableFrequencyRatio
            )
            let phaseIncrement = max(0, min(frequency / sampleRate, PokeAudioMixDefaults.maxRenderableFrequencyRatio))
            let sampleValue = waveTableSample(event.waveSamples, phase: phase)
            mixSample(
                sampleValue,
                for: event,
                leftChannel: leftChannel,
                rightChannel: rightChannel,
                frame: frame,
                startFrame: startFrame,
                endFrame: endFrame,
                localTime: localTime,
                declickFrames: declickFrames,
                sampleGain: sampleGain
            )
            phase = positiveFractionalPart(phase + phaseIncrement)
        }
    }

    private static func renderNoiseEvent(
        event: AudioManifest.Event,
        leftChannel: UnsafeMutablePointer<Float>,
        rightChannel: UnsafeMutablePointer<Float>,
        startFrame: Int,
        endFrame: Int,
        sampleRate: Double,
        declickFrames: Int,
        sampleGain: Float,
        smoothNoise: Bool,
        noiseGainMultiplier: Float
    ) {
        let clockHz = max(1, min(event.frequencyHz ?? 4_096, sampleRate * PokeAudioMixDefaults.maxRenderableFrequencyRatio))
        let stepDuration = 1 / clockHz
        var nextStepTime = stepDuration
        var lfsr = 0x7fff
        var sampleValue = gbNoiseOutputLevel(lfsr: lfsr)
        var filteredSampleValue = sampleValue
        let lowPassAlpha = noiseLowPassAlpha(sampleRate: sampleRate, clockHz: clockHz)

        for frame in startFrame..<endFrame {
            let localTime = Double(frame - startFrame) / sampleRate
            while localTime >= nextStepTime {
                lfsr = advancedNoiseLFSR(lfsr: lfsr, shortMode: event.noiseShortMode ?? false)
                sampleValue = gbNoiseOutputLevel(lfsr: lfsr)
                nextStepTime += stepDuration
            }
            if smoothNoise {
                filteredSampleValue += (sampleValue - filteredSampleValue) * lowPassAlpha
            } else {
                filteredSampleValue = sampleValue
            }
            mixSample(
                filteredSampleValue,
                for: event,
                leftChannel: leftChannel,
                rightChannel: rightChannel,
                frame: frame,
                startFrame: startFrame,
                endFrame: endFrame,
                localTime: localTime,
                declickFrames: declickFrames,
                sampleGain: sampleGain * noiseGainMultiplier
            )
        }
    }

    private static func mixSample(
        _ sampleValue: Double,
        for event: AudioManifest.Event,
        leftChannel: UnsafeMutablePointer<Float>,
        rightChannel: UnsafeMutablePointer<Float>,
        frame: Int,
        startFrame: Int,
        endFrame: Int,
        localTime: Double,
        declickFrames: Int,
        sampleGain: Float
    ) {
        let amplitude = envelopeAdjustedAmplitude(for: event, localTime: localTime)
        let startDistance = frame - startFrame
        let endDistance = (endFrame - 1) - frame
        let edgeFrames = min(startDistance, endDistance)
        let declickEnvelope: Float
        if edgeFrames < declickFrames {
            declickEnvelope = Float(edgeFrames + 1) / Float(declickFrames + 1)
        } else {
            declickEnvelope = 1
        }

        let sample = Float(sampleValue * amplitude) * sampleGain * declickEnvelope
        if event.stereoLeftEnabled {
            leftChannel[frame] += sample
        }
        if event.stereoRightEnabled {
            rightChannel[frame] += sample
        }
    }

    private static func polyBLEP(phase: Double, phaseIncrement: Double) -> Double {
        guard phaseIncrement > 0 else { return 0 }
        if phase < phaseIncrement {
            let t = phase / phaseIncrement
            return t + t - t * t - 1
        }
        if phase > 1 - phaseIncrement {
            let t = (phase - 1) / phaseIncrement
            return t * t + t + t + 1
        }
        return 0
    }

    private static func positiveFractionalPart(_ value: Double) -> Double {
        let fractional = value.truncatingRemainder(dividingBy: 1)
        return fractional >= 0 ? fractional : fractional + 1
    }

    private static func advancedNoiseLFSR(lfsr: Int, shortMode: Bool) -> Int {
        let feedbackBit = (lfsr ^ (lfsr >> 1)) & 0x1
        var next = (lfsr >> 1) | (feedbackBit << 14)
        if shortMode {
            next = (next & ~(1 << 6)) | (feedbackBit << 6)
        }
        return next & 0x7fff
    }

    private static func gbNoiseOutputLevel(lfsr: Int) -> Double {
        (lfsr & 0x1) == 0 ? 1 : -1
    }

    private static func noiseLowPassAlpha(sampleRate: Double, clockHz: Double) -> Double {
        let targetCutoffHz = max(280, min(1_400, clockHz * 1.5))
        let clampedCutoff = min(targetCutoffHz, sampleRate * 0.45)
        let dt = 1 / sampleRate
        let rc = 1 / (2 * Double.pi * clampedCutoff)
        return dt / (rc + dt)
    }

    private static func conditionRenderedSamples(_ samples: inout [Float]) {
        guard samples.isEmpty == false else { return }
        var previousInput = 0.0
        var previousOutput = 0.0
        for index in samples.indices {
            let input = Double(samples[index])
            let output = input - previousInput + (PokeAudioMixDefaults.dcBlockPole * previousOutput)
            previousInput = input
            previousOutput = output
            samples[index] = Float(output)
        }
    }

    private static func shouldApplyDCBlock(to events: [AudioManifest.Event]) -> Bool {
        events.contains { $0.waveform == .square }
    }

    private static func waveTableSample(_ waveSamples: [Double]?, phase: Double) -> Double {
        guard let waveSamples, waveSamples.isEmpty == false else {
            return sin(2 * .pi * phase)
        }
        let position = positiveFractionalPart(phase) * Double(waveSamples.count)
        let sampleIndex = Int(position.rounded(.down)) % waveSamples.count
        let nextIndex = (sampleIndex + 1) % waveSamples.count
        let fraction = position - Double(sampleIndex)
        let currentSample = waveSamples[sampleIndex]
        let nextSample = waveSamples[nextIndex]
        return currentSample + ((nextSample - currentSample) * fraction)
    }

    private static func frequencyHz(forRegister hardwareRegister: Int, waveform: AudioManifest.Waveform) -> Double {
        let frequencyBits = hardwareRegister & 0x07ff
        let denominator = 2048 - frequencyBits
        guard denominator > 0 else { return 440 }
        let numerator: Double = waveform == .wave ? 65_536 : 131_072
        return numerator / Double(denominator)
    }
}
