import Foundation
import PokeAudio
import PokeDataModel

@MainActor
private struct BattleIntroPresentationBuilder {
    let runtime: GameRuntime

    func makeIntroPresentationBeats(
        openingMessage: String,
        transitionStyle: BattleTransitionStyle,
        requiresConfirmAfterReveal: Bool,
        pendingActionAfterReveal: RuntimeBattlePendingAction?,
        revealSoundEffectRequest: SoundEffectPlaybackRequest?
    ) -> [RuntimeBattlePresentationBeat] {
        var beats: [RuntimeBattlePresentationBeat] = [
            .init(
                delay: runtime.battlePresentationDelay(base: 0),
                stage: .introFlash1,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText,
                pendingAction: .moveSelection
            ),
            .init(
                delay: runtime.battlePresentationDelay(base: 0.18),
                stage: .introFlash2,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: runtime.battlePresentationDelay(base: 0.18),
                stage: .introFlash3,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: runtime.battlePresentationDelay(base: 0.16),
                stage: .introSpiral,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: runtime.battlePresentationDelay(base: 0.92),
                stage: .introCrossing,
                uiVisibility: .hidden,
                transitionStyle: transitionStyle,
                phase: .introText
            ),
            .init(
                delay: runtime.battlePresentationDelay(base: 0.55),
                stage: .introReveal,
                uiVisibility: .visible,
                transitionStyle: transitionStyle,
                message: openingMessage,
                phase: requiresConfirmAfterReveal || pendingActionAfterReveal != nil ? .turnText : .introText,
                pendingAction: pendingActionAfterReveal ?? (requiresConfirmAfterReveal ? .moveSelection : nil),
                soundEffectRequest: revealSoundEffectRequest
            ),
        ]

        if requiresConfirmAfterReveal == false && pendingActionAfterReveal == nil {
            beats.append(runtime.commandReadyBeat(delay: runtime.battlePresentationDelay(base: 0.18)))
        }

        return beats
    }
}

extension GameRuntime {
    func makeIntroPresentationBeats(
        openingMessage: String,
        transitionStyle: BattleTransitionStyle,
        requiresConfirmAfterReveal: Bool = false,
        pendingActionAfterReveal: RuntimeBattlePendingAction? = nil,
        revealSoundEffectRequest: SoundEffectPlaybackRequest? = nil
    ) -> [RuntimeBattlePresentationBeat] {
        BattleIntroPresentationBuilder(runtime: self).makeIntroPresentationBeats(
            openingMessage: openingMessage,
            transitionStyle: transitionStyle,
            requiresConfirmAfterReveal: requiresConfirmAfterReveal,
            pendingActionAfterReveal: pendingActionAfterReveal,
            revealSoundEffectRequest: revealSoundEffectRequest
        )
    }
}
