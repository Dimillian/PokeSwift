import SwiftUI
import PokeRender
import PokeUI

struct GameplayScene: View {
    @Environment(AppPreferences.self) private var preferences
    let props: GameplaySceneProps
    @State private var fieldDisplayStyle: FieldDisplayStyle
    @State private var isLoadConfirmationPresented = false

    init(props: GameplaySceneProps) {
        self.props = props
        _fieldDisplayStyle = State(initialValue: props.initialFieldDisplayStyle)
    }

    var body: some View {
        GameBoyScreen(style: .fieldShell) {
            GameplayShell(
                sidebarMode: props.sidebarMode,
                onSidebarAction: handleSidebarAction(_:),
                onPartyRowSelected: props.onPartyRowSelected,
                fieldDisplayStyle: $fieldDisplayStyle
            ) {
                stage
            }
        }
        .confirmationDialog(
            "Load saved game?",
            isPresented: $isLoadConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Load Save", role: .destructive) {
                props.onSidebarAction?("load")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces the current in-memory progress with the last saved game.")
        }
    }
}

private extension GameplayScene {
    @ViewBuilder
    var stage: some View {
        ZStack {
            fieldStageLayer
            battleStageLayer
        }
    }

    @ViewBuilder
    var fieldStageLayer: some View {
        if case let .field(fieldProps) = props.viewport {
            FieldStageView(
                props: fieldProps,
                fieldDisplayStyle: fieldDisplayStyle
            )
        }
    }

    @ViewBuilder
    var battleStageLayer: some View {
        if case let .battle(battleProps) = props.viewport {
            BattleStageView(
                props: battleProps,
                fieldDisplayStyle: fieldDisplayStyle
            )
        }
    }

    func handleSidebarAction(_ actionID: String) {
        if actionID == "load" {
            isLoadConfirmationPresented = true
            return
        }

        switch actionID {
        case "appearanceMode":
            preferences.cycleAppearanceMode()
            return
        case "gameplayHDR":
            preferences.toggleGameplayHDREnabled()
            return
        case "music":
            preferences.toggleMusicEnabled()
            return
        case "textSpeed":
            preferences.cycleTextSpeed()
            return
        case "battleScene":
            preferences.cycleBattleAnimation()
            return
        case "battleStyle":
            preferences.cycleBattleStyle()
            return
        default:
            break
        }

        props.onSidebarAction?(actionID)
    }
}
