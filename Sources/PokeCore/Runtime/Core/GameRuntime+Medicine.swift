import PokeDataModel

struct ResolvedMedicineUse {
    let updatedPokemon: RuntimePokemonState
    let message: String
}

extension GameRuntime {
    var medicineNoEffectMessage: String {
        "It won't have any effect."
    }

    var medicineEmptyPartyMessage: String {
        "You don't have any #MON!"
    }

    func medicineItem(for itemID: String) -> ItemManifest? {
        guard let item = content.item(id: itemID), item.medicine != nil else {
            return nil
        }
        return item
    }

    func medicineSelectableIndices(itemID: String, party: [RuntimePokemonState]) -> Set<Int> {
        guard let item = medicineItem(for: itemID) else {
            return []
        }

        return Set(
            party.indices.filter { index in
                applyMedicine(item, to: party[index]) != nil
            }
        )
    }

    func firstMedicineTargetIndex(itemID: String, party: [RuntimePokemonState]) -> Int? {
        medicineSelectableIndices(itemID: itemID, party: party).sorted().first
    }

    func hasUsableMedicineTarget(itemID: String, party: [RuntimePokemonState]) -> Bool {
        firstMedicineTargetIndex(itemID: itemID, party: party) != nil
    }

    func medicineTargetAnnotations(
        itemID: String,
        party: [RuntimePokemonState],
        activeIndex: Int? = nil
    ) -> [Int: String] {
        guard let item = medicineItem(for: itemID) else {
            return [:]
        }

        return Dictionary(
            uniqueKeysWithValues: party.indices.compactMap { index in
                let annotation = medicineTargetAnnotation(
                    item: item,
                    pokemon: party[index],
                    isActive: activeIndex == index
                )
                return annotation.map { (index, $0) }
            }
        )
    }

    func medicinePartyPromptText(itemID: String) -> String {
        guard let item = content.item(id: itemID) else {
            return "Use on which #MON?"
        }
        return "Use \(item.displayName) on which #MON?"
    }

    func applyMedicine(itemID: String, to pokemon: RuntimePokemonState) -> ResolvedMedicineUse? {
        guard let item = medicineItem(for: itemID) else {
            return nil
        }
        return applyMedicine(item, to: pokemon)
    }

    func applyMedicine(_ item: ItemManifest, to pokemon: RuntimePokemonState) -> ResolvedMedicineUse? {
        guard let medicine = item.medicine else {
            return nil
        }

        let previousPokemon = pokemon
        let canCureStatus = canMedicineCureStatus(medicine.statusMode, on: previousPokemon)

        var updatedPokemon = previousPokemon
        var healedAmount = 0

        switch medicine.hpMode {
        case .none:
            break
        case .fixed:
            guard previousPokemon.currentHP > 0 else {
                return nil
            }
            if previousPokemon.currentHP < previousPokemon.maxHP {
                let amount = max(0, medicine.hpAmount ?? 0)
                let nextHP = min(previousPokemon.maxHP, previousPokemon.currentHP + amount)
                healedAmount = max(0, nextHP - previousPokemon.currentHP)
                updatedPokemon.currentHP = nextHP
            } else if canCureStatus == false {
                return nil
            }
        case .healToFull:
            guard previousPokemon.currentHP > 0 else {
                return nil
            }
            if previousPokemon.currentHP < previousPokemon.maxHP {
                healedAmount = previousPokemon.maxHP - previousPokemon.currentHP
                updatedPokemon.currentHP = previousPokemon.maxHP
            } else if canCureStatus == false {
                return nil
            }
        case .reviveHalfMax:
            guard previousPokemon.currentHP == 0 else {
                return nil
            }
            let revivedHP = max(1, previousPokemon.maxHP / 2)
            updatedPokemon.currentHP = revivedHP
            healedAmount = revivedHP
        case .reviveFull:
            guard previousPokemon.currentHP == 0 else {
                return nil
            }
            updatedPokemon.currentHP = previousPokemon.maxHP
            healedAmount = previousPokemon.maxHP
        }

        if canCureStatus {
            updatedPokemon.majorStatus = .none
            updatedPokemon.statusCounter = 0
            updatedPokemon.isBadlyPoisoned = false
        }

        guard healedAmount > 0 || canCureStatus else {
            return nil
        }

        return ResolvedMedicineUse(
            updatedPokemon: updatedPokemon,
            message: medicineSuccessMessage(
                item: item,
                previousPokemon: previousPokemon,
                healedAmount: healedAmount,
                curedStatus: canCureStatus
            )
        )
    }

    private func canMedicineCureStatus(
        _ statusMode: ItemManifest.MedicineAttributes.StatusMode,
        on pokemon: RuntimePokemonState
    ) -> Bool {
        switch statusMode {
        case .none:
            return false
        case .all:
            return pokemon.majorStatus != .none
        case .poison:
            return pokemon.majorStatus == .poison
        case .burn:
            return pokemon.majorStatus == .burn
        case .freeze:
            return pokemon.majorStatus == .freeze
        case .sleep:
            return pokemon.majorStatus == .sleep
        case .paralysis:
            return pokemon.majorStatus == .paralysis
        }
    }

    private func medicineTargetAnnotation(
        item: ItemManifest,
        pokemon: RuntimePokemonState,
        isActive: Bool
    ) -> String? {
        guard let medicine = item.medicine else {
            return isActive ? "ACTIVE" : nil
        }

        if applyMedicine(item, to: pokemon) != nil {
            return isActive ? "ACTIVE" : nil
        }

        switch medicine.hpMode {
        case .reviveHalfMax, .reviveFull:
            return pokemon.currentHP == 0 ? (isActive ? "ACTIVE" : nil) : "NOT FAINTED"
        case .fixed, .healToFull:
            if pokemon.currentHP == 0 {
                return "FAINTED"
            }
            if pokemon.currentHP >= pokemon.maxHP, medicine.statusMode == .none {
                return "FULL HP"
            }
        case .none:
            break
        }

        switch medicine.statusMode {
        case .none:
            return isActive ? "ACTIVE" : nil
        case .all:
            return pokemon.majorStatus == .none ? "NO STATUS" : "NO EFFECT"
        case .poison, .burn, .freeze, .sleep, .paralysis:
            return pokemon.majorStatus == .none ? "NO STATUS" : "NO EFFECT"
        }
    }

    private func medicineSuccessMessage(
        item: ItemManifest,
        previousPokemon: RuntimePokemonState,
        healedAmount: Int,
        curedStatus: Bool
    ) -> String {
        guard let medicine = item.medicine else {
            return medicineNoEffectMessage
        }

        if case .reviveHalfMax = medicine.hpMode {
            return "\(previousPokemon.nickname) is revitalized!"
        }
        if case .reviveFull = medicine.hpMode {
            return "\(previousPokemon.nickname) is revitalized!"
        }

        if healedAmount > 0 {
            return "\(previousPokemon.nickname) recovered by \(healedAmount)!"
        }

        guard curedStatus else {
            return medicineNoEffectMessage
        }

        switch medicine.statusMode {
        case .poison:
            return "\(previousPokemon.nickname) was cured of poison!"
        case .burn:
            return "\(previousPokemon.nickname)'s burn was healed!"
        case .freeze:
            return "\(previousPokemon.nickname) was defrosted!"
        case .sleep:
            return "\(previousPokemon.nickname) woke up!"
        case .paralysis:
            return "\(previousPokemon.nickname)'s rid of paralysis!"
        case .all:
            return "\(previousPokemon.nickname)'s health returned!"
        case .none:
            return medicineNoEffectMessage
        }
    }
}
