import Foundation
import SwiftUI
import PokeDataModel
import PokeRender

struct RenderedFieldSceneBox: @unchecked Sendable {
    let scene: FieldRenderedScene
}

struct FieldPresentationIdentity: Equatable {
    let mapID: String
    let playerPosition: TilePoint
    let objects: [FieldObjectPresentationIdentity]
}

struct PlayerStepAnimationState: Equatable {
    let mapID: String
    let destinationPosition: TilePoint
    let startedAt: Date
    let direction: FacingDirection
    let phaseOffset: Int
}

struct FieldObjectPresentationIdentity: Equatable {
    let id: String
    let position: TilePoint
    let movementMode: ActorMovementMode?
}

struct ObjectStepAnimationState: Equatable {
    let mapID: String
    let objectID: String
    let destinationPosition: TilePoint
    let startedAt: Date
}

struct FieldAlertActorPosition {
    let worldPosition: CGPoint
    let size: CGSize
}
