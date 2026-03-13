import PokeDataModel

extension GameRuntime {
    func makePokemon(speciesID: String, level: Int, nickname: String) -> RuntimePokemonState {
        let dvs = nextRuntimeDVs()
        return makeConfiguredPokemon(
            speciesID: speciesID,
            nickname: nickname,
            level: level,
            experience: experienceRequired(for: level, speciesID: speciesID),
            dvs: dvs,
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            speedStage: 0,
            specialStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
    }

    func makeTrainerBattlePokemon(speciesID: String, level: Int, nickname: String) -> RuntimePokemonState {
        makeConfiguredPokemon(
            speciesID: speciesID,
            nickname: nickname,
            level: level,
            experience: experienceRequired(for: level, speciesID: speciesID),
            dvs: trainerBattleDVs,
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            speedStage: 0,
            specialStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
    }

    var trainerBattleDVs: PokemonDVs {
        PokemonDVs(attack: 9, defense: 8, speed: 8, special: 8)
    }

    func makeConfiguredPokemon(
        speciesID: String,
        nickname: String,
        level: Int,
        experience: Int,
        dvs: PokemonDVs,
        statExp: PokemonStatExp,
        currentHP: Int?,
        attackStage: Int,
        defenseStage: Int,
        speedStage: Int = 0,
        specialStage: Int = 0,
        accuracyStage: Int,
        evasionStage: Int,
        majorStatus: MajorStatusCondition = .none,
        moves: [RuntimeMoveState]?
    ) -> RuntimePokemonState {
        guard let species = content.species(id: speciesID) else {
            return RuntimePokemonState(
                speciesID: speciesID,
                nickname: nickname,
                level: level,
                experience: experience,
                dvs: dvs,
                statExp: statExp,
                maxHP: 20,
                currentHP: min(20, max(0, currentHP ?? 20)),
                attack: 10,
                defense: 10,
                speed: 10,
                special: 10,
                attackStage: attackStage,
                defenseStage: defenseStage,
                speedStage: speedStage,
                specialStage: specialStage,
                accuracyStage: accuracyStage,
                evasionStage: evasionStage,
                majorStatus: majorStatus,
                moves: moves ?? []
            )
        }

        let resolvedMoves = moves ?? defaultMoveSet(for: species, level: level)

        let calculatedStats = calculatedStats(for: species, level: level, dvs: dvs, statExp: statExp)

        return RuntimePokemonState(
            speciesID: species.id,
            nickname: nickname,
            level: level,
            experience: experience,
            dvs: dvs,
            statExp: statExp,
            maxHP: calculatedStats.maxHP,
            currentHP: min(calculatedStats.maxHP, max(0, currentHP ?? calculatedStats.maxHP)),
            attack: calculatedStats.attack,
            defense: calculatedStats.defense,
            speed: calculatedStats.speed,
            special: calculatedStats.special,
            attackStage: attackStage,
            defenseStage: defenseStage,
            speedStage: speedStage,
            specialStage: specialStage,
            accuracyStage: accuracyStage,
            evasionStage: evasionStage,
            majorStatus: majorStatus,
            moves: resolvedMoves
        )
    }

    func calculatedStats(for species: SpeciesManifest, level: Int, dvs: PokemonDVs, statExp: PokemonStatExp) -> (maxHP: Int, attack: Int, defense: Int, speed: Int, special: Int) {
        (
            maxHP: calculatedStat(baseStat: species.baseHP, level: level, dv: dvs.hp, statExp: statExp.hp, isHP: true),
            attack: calculatedStat(baseStat: species.baseAttack, level: level, dv: dvs.attack, statExp: statExp.attack, isHP: false),
            defense: calculatedStat(baseStat: species.baseDefense, level: level, dv: dvs.defense, statExp: statExp.defense, isHP: false),
            speed: calculatedStat(baseStat: species.baseSpeed, level: level, dv: dvs.speed, statExp: statExp.speed, isHP: false),
            special: calculatedStat(baseStat: species.baseSpecial, level: level, dv: dvs.special, statExp: statExp.special, isHP: false)
        )
    }

    func defaultMoveSet(for species: SpeciesManifest, level: Int) -> [RuntimeMoveState] {
        var knownMoveIDs: [String] = []

        func learn(_ moveID: String) {
            guard moveID != "NO_MOVE",
                  content.move(id: moveID) != nil,
                  knownMoveIDs.contains(moveID) == false else {
                return
            }

            knownMoveIDs.append(moveID)
            if knownMoveIDs.count > 4 {
                knownMoveIDs.removeFirst()
            }
        }

        for moveID in species.startingMoves {
            learn(moveID)
        }

        for learnsetEntry in species.levelUpLearnset where learnsetEntry.level <= level {
            learn(learnsetEntry.moveID)
        }

        return knownMoveIDs.compactMap { moveID in
            guard let move = content.move(id: moveID) else { return nil }
            return RuntimeMoveState(id: move.id, currentPP: move.maxPP)
        }
    }

    func calculatedStat(baseStat: Int, level: Int, dv: Int, statExp: Int, isHP: Bool) -> Int {
        let statExpTerm = ceilSquareRoot(of: statExp) / 4
        let scaledBase = (((baseStat + dv) * 2) + statExpTerm) * level
        let baseValue = scaledBase / 100
        return isHP ? baseValue + level + 10 : baseValue + 5
    }

    func ceilSquareRoot(of value: Int) -> Int {
        guard value > 0 else { return 0 }
        var candidate = 1
        while candidate * candidate < value && candidate < 255 {
            candidate += 1
        }
        return candidate
    }

    func reseedRuntimeRNG() {
        runtimeRNGState = runtimeRNGSeedSource()
    }

    func nextAcquisitionRandomByte() -> Int {
        if acquisitionRandomOverrides.isEmpty == false {
            return min(255, max(0, acquisitionRandomOverrides.removeFirst()))
        }

        return nextRuntimeRandomByte()
    }

    func nextRuntimeDVs() -> PokemonDVs {
        let attackDefenseByte = nextAcquisitionRandomByte()
        let speedSpecialByte = nextAcquisitionRandomByte()
        return PokemonDVs(
            attack: (attackDefenseByte >> 4) & 0xF,
            defense: attackDefenseByte & 0xF,
            speed: (speedSpecialByte >> 4) & 0xF,
            special: speedSpecialByte & 0xF
        )
    }

    func experienceRequired(for level: Int, speciesID: String) -> Int {
        guard let growthRate = content.species(id: speciesID)?.growthRate else {
            return 0
        }
        return experienceRequired(for: level, growthRate: growthRate)
    }

    func experienceRequired(for level: Int, growthRate: PokemonGrowthRate) -> Int {
        let boundedLevel = min(100, max(1, level))
        let levelSquared = boundedLevel * boundedLevel
        let levelCubed = levelSquared * boundedLevel

        switch growthRate {
        case .mediumFast:
            return levelCubed
        case .slightlyFast:
            return ((3 * levelCubed) / 4) + (10 * levelSquared) - 30
        case .slightlySlow:
            return ((3 * levelCubed) / 4) + (20 * levelSquared) - 70
        case .mediumSlow:
            return ((6 * levelCubed) / 5) - (15 * levelSquared) + (100 * boundedLevel) - 140
        case .fast:
            return (4 * levelCubed) / 5
        case .slow:
            return (5 * levelCubed) / 4
        }
    }

    func nextBattleRandomByte() -> Int {
        if battleRandomOverrides.isEmpty == false {
            return min(255, max(0, battleRandomOverrides.removeFirst()))
        }

        return nextRuntimeRandomByte()
    }

    func nextRuntimeRandomByte() -> Int {
        runtimeRNGState = runtimeRNGState &* 6364136223846793005 &+ 1
        return Int((runtimeRNGState >> 32) & 0xFF)
    }
}
