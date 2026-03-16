import Foundation
import PokeDataModel

func buildOverworldSprites() -> [OverworldSpriteManifest] {
    [
        buildCharacterSprite(id: "SPRITE_RED", imagePath: "Assets/field/sprites/red.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_OAK", imagePath: "Assets/field/sprites/oak.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_BLUE", imagePath: "Assets/field/sprites/blue.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_MOM", imagePath: "Assets/field/sprites/mom.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_GIRL", imagePath: "Assets/field/sprites/girl.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_FISHER", imagePath: "Assets/field/sprites/fisher.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_SCIENTIST", imagePath: "Assets/field/sprites/scientist.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_YOUNGSTER", imagePath: "Assets/field/sprites/youngster.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_GAMBLER", imagePath: "Assets/field/sprites/gambler.png", hasWalkingFrames: true),
        buildStaticOverworldSprite(id: "SPRITE_GAMBLER_ASLEEP", imagePath: "Assets/field/sprites/gambler_asleep.png"),
        buildCharacterSprite(id: "SPRITE_SUPER_NERD", imagePath: "Assets/field/sprites/super_nerd.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_BRUNETTE_GIRL", imagePath: "Assets/field/sprites/brunette_girl.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_COOLTRAINER_F", imagePath: "Assets/field/sprites/cooltrainer_f.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_BALDING_GUY", imagePath: "Assets/field/sprites/balding_guy.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_LITTLE_GIRL", imagePath: "Assets/field/sprites/little_girl.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_BIRD", imagePath: "Assets/field/sprites/bird.png", hasWalkingFrames: true),
        buildStaticOverworldSprite(id: "SPRITE_CLIPBOARD", imagePath: "Assets/field/sprites/clipboard.png"),
        buildCharacterSprite(id: "SPRITE_CLERK", imagePath: "Assets/field/sprites/clerk.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_COOLTRAINER_M", imagePath: "Assets/field/sprites/cooltrainer_m.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_NURSE", imagePath: "Assets/field/sprites/nurse.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_GENTLEMAN", imagePath: "Assets/field/sprites/gentleman.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_FAIRY", imagePath: "Assets/field/sprites/fairy.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_GRAMPS", imagePath: "Assets/field/sprites/gramps.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_GUARD", imagePath: "Assets/field/sprites/guard.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_HIKER", imagePath: "Assets/field/sprites/hiker.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_GYM_GUIDE", imagePath: "Assets/field/sprites/gym_guide.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_SWIMMER", imagePath: "Assets/field/sprites/swimmer.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_LITTLE_BOY", imagePath: "Assets/field/sprites/little_boy.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_LINK_RECEPTIONIST", imagePath: "Assets/field/sprites/link_receptionist.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_MIDDLE_AGED_MAN", imagePath: "Assets/field/sprites/middle_aged_man.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_MONSTER", imagePath: "Assets/field/sprites/monster.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_ROCKET", imagePath: "Assets/field/sprites/rocket.png", hasWalkingFrames: true),
        buildStaticOverworldSprite(id: "SPRITE_OLD_AMBER", imagePath: "Assets/field/sprites/old_amber.png"),
        buildStaticOverworldSprite(id: "SPRITE_FOSSIL", imagePath: "Assets/field/sprites/fossil.png"),
        .init(
            id: "SPRITE_POKE_BALL",
            imagePath: "Assets/field/sprites/poke_ball.png",
            frameWidth: 16,
            frameHeight: 16,
            facingFrames: .init(
                down: .init(x: 0, y: 0, width: 16, height: 16),
                up: .init(x: 0, y: 0, width: 16, height: 16),
                left: .init(x: 0, y: 0, width: 16, height: 16),
                right: .init(x: 0, y: 0, width: 16, height: 16)
            )
        ),
        .init(
            id: "SPRITE_POKEDEX",
            imagePath: "Assets/field/sprites/pokedex.png",
            frameWidth: 16,
            frameHeight: 16,
            facingFrames: .init(
                down: .init(x: 0, y: 0, width: 16, height: 16),
                up: .init(x: 0, y: 0, width: 16, height: 16),
                left: .init(x: 0, y: 0, width: 16, height: 16),
                right: .init(x: 0, y: 0, width: 16, height: 16)
            )
        ),
    ]
}

private func buildCharacterSprite(id: String, imagePath: String, hasWalkingFrames: Bool) -> OverworldSpriteManifest {
    let leftFrame = PixelRect(x: 0, y: 32, width: 16, height: 16)
    return OverworldSpriteManifest(
        id: id,
        imagePath: imagePath,
        frameWidth: 16,
        frameHeight: 16,
        facingFrames: .init(
            down: .init(x: 0, y: 0, width: 16, height: 16),
            up: .init(x: 0, y: 16, width: 16, height: 16),
            left: leftFrame,
            right: .init(x: leftFrame.x, y: leftFrame.y, width: leftFrame.width, height: leftFrame.height, flippedHorizontally: true)
        ),
        walkingFrames: hasWalkingFrames ? .init(
            down: .init(x: 0, y: 48, width: 16, height: 16),
            up: .init(x: 0, y: 64, width: 16, height: 16),
            left: .init(x: 0, y: 80, width: 16, height: 16),
            right: .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true)
        ) : nil
    )
}

private func buildStaticOverworldSprite(id: String, imagePath: String) -> OverworldSpriteManifest {
    .init(
        id: id,
        imagePath: imagePath,
        frameWidth: 16,
        frameHeight: 16,
        facingFrames: .init(
            down: .init(x: 0, y: 0, width: 16, height: 16),
            up: .init(x: 0, y: 0, width: 16, height: 16),
            left: .init(x: 0, y: 0, width: 16, height: 16),
            right: .init(x: 0, y: 0, width: 16, height: 16)
        )
    )
}
