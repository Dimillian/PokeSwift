import PokeDataModel

enum WildCaptureResolution {
    case handled
    case continueEnemyTurn
}

extension GameRuntime {
    func canSendCapturedPokemonToCurrentBox(_ gameplayState: GameplayState) -> Bool {
        guard gameplayState.boxedPokemon.indices.contains(gameplayState.currentBoxIndex) else {
            return true
        }
        return gameplayState.boxedPokemon[gameplayState.currentBoxIndex].pokemon.count < Self.storageBoxCapacity
    }

    func attemptWildCapture(
        battle: inout RuntimeBattleState,
        gameplayState: inout GameplayState,
        item: ItemManifest
    ) -> WildCaptureResolution {
        if battle.kind != .wild {
            battle.lastCaptureResult = .uncatchable
            addItem(item.id, quantity: 1, to: &gameplayState)
            presentBattleMessages(
                [captureFailureMessage(from: battle.lastCaptureResult)],
                battle: &battle,
                pendingAction: .moveSelection
            )
            return .handled
        }

        if gameplayState.playerParty.count >= 6,
           canSendCapturedPokemonToCurrentBox(gameplayState) == false {
            battle.lastCaptureResult = .boxFull
            addItem(item.id, quantity: 1, to: &gameplayState)
            presentBattleMessages(
                ["The #MON BOX is full! Can't use that item!"],
                battle: &battle,
                pendingAction: .moveSelection
            )
            return .handled
        }

        let captureResult = resolveCaptureResult(for: battle.enemyPokemon, item: item)
        battle.lastCaptureResult = captureResult

        guard captureResult == .success else {
            return .continueEnemyTurn
        }

        let capturedPokemon = battle.enemyPokemon
        gameplayState.ownedSpeciesIDs.insert(capturedPokemon.speciesID)
        var messages = ["All right! \(capturedPokemon.nickname) was caught!"]

        if gameplayState.playerParty.count < 6 {
            gameplayState.playerParty.append(capturedPokemon)
        } else if addPokemonToCurrentBox(capturedPokemon, in: &gameplayState) {
            messages.append("\(capturedPokemon.nickname) was transferred to BOX \(gameplayState.currentBoxIndex + 1).")
        } else {
            battle.lastCaptureResult = .boxFull
            addItem(item.id, quantity: 1, to: &gameplayState)
            messages = ["The #MON BOX is full! Can't use that item!"]
            presentBattleMessages(messages, battle: &battle, pendingAction: .moveSelection)
            return .handled
        }

        presentBattleMessages(messages, battle: &battle, pendingAction: .captured)
        return .handled
    }

    func resolveCaptureResult(for pokemon: RuntimePokemonState, item: ItemManifest) -> RuntimeBattleCaptureResult {
        let catchRate = max(0, content.species(id: pokemon.speciesID)?.catchRate ?? 0)
        guard catchRate > 0 else {
            return .uncatchable
        }

        if item.id == "MASTER_BALL" {
            return .success
        }

        var rand1 = nextBattleRandomByte()
        switch item.id {
        case "GREAT_BALL":
            while rand1 > 200 {
                rand1 = nextBattleRandomByte()
            }
        case "ULTRA_BALL", "SAFARI_BALL":
            while rand1 > 150 {
                rand1 = nextBattleRandomByte()
            }
        default:
            break
        }

        let statusValue = captureStatusBonus(for: pokemon.majorStatus)
        if statusValue > rand1 {
            return .success
        }

        let randMinusStatus = rand1 - statusValue
        let w = captureWValue(for: pokemon, item: item)
        let x = min(w, 255)

        if randMinusStatus <= catchRate {
            if w > 255 {
                return .success
            }

            let rand2 = nextBattleRandomByte()
            if rand2 <= x {
                return .success
            }
        }

        return .failed(shakes: captureFailureShakeCount(catchRate: catchRate, x: x, status: pokemon.majorStatus, item: item))
    }

    func captureWValue(for pokemon: RuntimePokemonState, item: ItemManifest) -> Int {
        let ballFactor = item.id == "GREAT_BALL" ? 8 : 12
        let maxHP = max(1, pokemon.maxHP)
        let hpDivisor = max(1, pokemon.currentHP / 4)
        let scaledHP = (maxHP * 255) / ballFactor
        return scaledHP / hpDivisor
    }

    func captureFailureShakeCount(
        catchRate: Int,
        x: Int,
        status: MajorStatusCondition,
        item: ItemManifest
    ) -> Int {
        let ballFactor2: Int
        switch item.id {
        case "GREAT_BALL":
            ballFactor2 = 200
        case "ULTRA_BALL", "SAFARI_BALL":
            ballFactor2 = 150
        default:
            ballFactor2 = 255
        }

        let y = (catchRate * 100) / ballFactor2
        let z = ((x * y) / 255) + captureShakeStatusBonus(for: status)

        switch z {
        case ..<10:
            return 0
        case ..<30:
            return 1
        case ..<70:
            return 2
        default:
            return 3
        }
    }

    func captureStatusBonus(for status: MajorStatusCondition) -> Int {
        switch status {
        case .sleep, .freeze:
            return 25
        case .burn, .paralysis, .poison:
            return 12
        case .none:
            return 0
        }
    }

    func captureShakeStatusBonus(for status: MajorStatusCondition) -> Int {
        switch status {
        case .sleep, .freeze:
            return 10
        case .burn, .paralysis, .poison:
            return 5
        case .none:
            return 0
        }
    }

    func captureFailureMessage(from result: RuntimeBattleCaptureResult?) -> String {
        switch result {
        case .uncatchable:
            return battleDialogueText(id: "capture_uncatchable", fallback: "It dodged the thrown BALL! This #MON can't be caught!")
        case .boxFull:
            return "The #MON BOX is full! Can't use that item!"
        case let .failed(shakes):
            switch shakes {
            case 0:
                return battleDialogueText(id: "capture_missed", fallback: "You missed the #MON!")
            case 1:
                return battleDialogueText(id: "capture_broke_free", fallback: "Darn! The #MON broke free!")
            case 2:
                return battleDialogueText(id: "capture_almost", fallback: "Aww! It appeared to be caught!")
            default:
                return battleDialogueText(id: "capture_so_close", fallback: "Shoot! It was so close too!")
            }
        case .success, nil:
            return "Aww! It appeared to be caught!"
        }
    }

    func battleDialogueText(id: String, fallback: String) -> String {
        dialogueText(id: id, fallback: fallback)
    }
}
