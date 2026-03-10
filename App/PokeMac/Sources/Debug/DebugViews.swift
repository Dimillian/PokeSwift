import SwiftUI
import PokeDataModel
import PokeUI

struct FieldStatusHUDProps {
    let mapName: String
    let positionLine: String
    let activeFlags: [String]
}

struct DebugPanel: View {
    let snapshot: RuntimeTelemetrySnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Telemetry")
                    .font(.title2.bold())
                Text("Scene: \(snapshot.scene.rawValue)")
                Text("Substate: \(snapshot.substate)")
                Text("Content: \(snapshot.contentVersion)")
                Text("Scale: \(snapshot.window.scale)x")
                if let titleMenu = snapshot.titleMenu, titleMenu.entries.isEmpty == false {
                    let safeIndex = max(0, min(titleMenu.focusedIndex, titleMenu.entries.count - 1))
                    Text("Focused Entry: \(titleMenu.entries[safeIndex].label)")
                }
                if let field = snapshot.field {
                    Text("Map: \(field.mapName) [\(field.mapID)]")
                    Text("Player: (\(field.playerPosition.x), \(field.playerPosition.y)) facing \(field.facing.rawValue)")
                    Text("Active Script: \(field.activeScriptID ?? "none")")
                }
                if let dialogue = snapshot.dialogue {
                    Text("Dialogue: \(dialogue.dialogueID) page \(dialogue.pageIndex + 1)/\(dialogue.pageCount)")
                }
                if let battle = snapshot.battle {
                    Text("Battle: \(battle.trainerName)")
                    Text("Player HP: \(battle.playerPokemon.currentHP)/\(battle.playerPokemon.maxHP)")
                    Text("Enemy HP: \(battle.enemyPokemon.currentHP)/\(battle.enemyPokemon.maxHP)")
                }
                if let flags = snapshot.eventFlags {
                    Text("Flags: \(flags.activeFlags.joined(separator: ", "))")
                        .font(.system(.body, design: .monospaced))
                }
                Text("Recent Inputs")
                    .font(.headline)
                ForEach(Array(snapshot.recentInputEvents.enumerated()), id: \.offset) { _, event in
                    Text("\(event.timestamp)  \(event.button.rawValue)")
                        .font(.system(.body, design: .monospaced))
                }
                Spacer()
            }
        }
    }
}

struct FieldStatusHUD: View {
    let props: FieldStatusHUDProps

    var body: some View {
        PlainWhitePanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(props.mapName)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                Text(props.positionLine)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.66))
                if props.activeFlags.isEmpty == false {
                    Text(props.activeFlags.joined(separator: " • "))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.5))
                }
            }
        }
        .frame(width: 400, alignment: .leading)
    }
}
