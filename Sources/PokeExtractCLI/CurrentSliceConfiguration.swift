struct CurrentGameplaySliceMapDefinition {
    let mapID: String
    let displayName: String
    let objectFile: String
    let blockFile: String
    let parentMapID: String?
    let isOutdoor: Bool
}

let currentGameplaySliceMaps: [CurrentGameplaySliceMapDefinition] = [
    .init(
        mapID: "REDS_HOUSE_2F",
        displayName: "Red's House 2F",
        objectFile: "data/maps/objects/RedsHouse2F.asm",
        blockFile: "maps/RedsHouse2F.blk",
        parentMapID: nil,
        isOutdoor: false
    ),
    .init(
        mapID: "REDS_HOUSE_1F",
        displayName: "Red's House 1F",
        objectFile: "data/maps/objects/RedsHouse1F.asm",
        blockFile: "maps/RedsHouse1F.blk",
        parentMapID: "PALLET_TOWN",
        isOutdoor: false
    ),
    .init(
        mapID: "PALLET_TOWN",
        displayName: "Pallet Town",
        objectFile: "data/maps/objects/PalletTown.asm",
        blockFile: "maps/PalletTown.blk",
        parentMapID: nil,
        isOutdoor: true
    ),
    .init(
        mapID: "ROUTE_1",
        displayName: "Route 1",
        objectFile: "data/maps/objects/Route1.asm",
        blockFile: "maps/Route1.blk",
        parentMapID: nil,
        isOutdoor: true
    ),
    .init(
        mapID: "VIRIDIAN_CITY",
        displayName: "Viridian City",
        objectFile: "data/maps/objects/ViridianCity.asm",
        blockFile: "maps/ViridianCity.blk",
        parentMapID: nil,
        isOutdoor: true
    ),
    .init(
        mapID: "VIRIDIAN_SCHOOL_HOUSE",
        displayName: "Viridian School House",
        objectFile: "data/maps/objects/ViridianSchoolHouse.asm",
        blockFile: "maps/ViridianSchoolHouse.blk",
        parentMapID: "VIRIDIAN_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "VIRIDIAN_NICKNAME_HOUSE",
        displayName: "Viridian Nickname House",
        objectFile: "data/maps/objects/ViridianNicknameHouse.asm",
        blockFile: "maps/ViridianNicknameHouse.blk",
        parentMapID: "VIRIDIAN_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "VIRIDIAN_POKECENTER",
        displayName: "Viridian Pokecenter",
        objectFile: "data/maps/objects/ViridianPokecenter.asm",
        blockFile: "maps/ViridianPokecenter.blk",
        parentMapID: "VIRIDIAN_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "VIRIDIAN_MART",
        displayName: "Viridian Mart",
        objectFile: "data/maps/objects/ViridianMart.asm",
        blockFile: "maps/ViridianMart.blk",
        parentMapID: "VIRIDIAN_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "OAKS_LAB",
        displayName: "Oak's Lab",
        objectFile: "data/maps/objects/OaksLab.asm",
        blockFile: "maps/OaksLab.blk",
        parentMapID: "PALLET_TOWN",
        isOutdoor: false
    ),
]

let currentGameplaySliceMapIDs = Set(currentGameplaySliceMaps.map(\.mapID))

let currentGameplaySliceItemIDs = [
    "POTION",
    "OAKS_PARCEL",
]

struct CurrentGameplaySliceWildEncounterDefinition {
    let mapID: String
    let path: String
}

let currentGameplaySliceWildEncounterMaps: [CurrentGameplaySliceWildEncounterDefinition] = [
    .init(
        mapID: "ROUTE_1",
        path: "data/wild/maps/Route1.asm"
    ),
]
