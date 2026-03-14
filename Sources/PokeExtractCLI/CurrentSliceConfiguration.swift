struct GameplayCoverageMapDefinition {
    let mapID: String
    let displayName: String
    let objectFile: String
    let blockFile: String
    let parentMapID: String?
    let isOutdoor: Bool
}

let gameplayCoverageMaps: [GameplayCoverageMapDefinition] = [
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
        mapID: "ROUTE_2",
        displayName: "Route 2",
        objectFile: "data/maps/objects/Route2.asm",
        blockFile: "maps/Route2.blk",
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
        mapID: "VIRIDIAN_FOREST_SOUTH_GATE",
        displayName: "Viridian Forest South Gate",
        objectFile: "data/maps/objects/ViridianForestSouthGate.asm",
        blockFile: "maps/ViridianForestSouthGate.blk",
        parentMapID: "ROUTE_2",
        isOutdoor: false
    ),
    .init(
        mapID: "VIRIDIAN_FOREST",
        displayName: "Viridian Forest",
        objectFile: "data/maps/objects/ViridianForest.asm",
        blockFile: "maps/ViridianForest.blk",
        parentMapID: nil,
        isOutdoor: true
    ),
    .init(
        mapID: "VIRIDIAN_FOREST_NORTH_GATE",
        displayName: "Viridian Forest North Gate",
        objectFile: "data/maps/objects/ViridianForestNorthGate.asm",
        blockFile: "maps/ViridianForestNorthGate.blk",
        parentMapID: "ROUTE_2",
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
    .init(
        mapID: "PEWTER_CITY",
        displayName: "Pewter City",
        objectFile: "data/maps/objects/PewterCity.asm",
        blockFile: "maps/PewterCity.blk",
        parentMapID: nil,
        isOutdoor: true
    ),
    .init(
        mapID: "PEWTER_POKECENTER",
        displayName: "Pewter Pokecenter",
        objectFile: "data/maps/objects/PewterPokecenter.asm",
        blockFile: "maps/PewterPokecenter.blk",
        parentMapID: "PEWTER_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "PEWTER_MART",
        displayName: "Pewter Mart",
        objectFile: "data/maps/objects/PewterMart.asm",
        blockFile: "maps/PewterMart.blk",
        parentMapID: "PEWTER_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "PEWTER_NIDORAN_HOUSE",
        displayName: "Pewter Nidoran House",
        objectFile: "data/maps/objects/PewterNidoranHouse.asm",
        blockFile: "maps/PewterNidoranHouse.blk",
        parentMapID: "PEWTER_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "PEWTER_SPEECH_HOUSE",
        displayName: "Pewter Speech House",
        objectFile: "data/maps/objects/PewterSpeechHouse.asm",
        blockFile: "maps/PewterSpeechHouse.blk",
        parentMapID: "PEWTER_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "MUSEUM_1F",
        displayName: "Museum 1F",
        objectFile: "data/maps/objects/Museum1F.asm",
        blockFile: "maps/Museum1F.blk",
        parentMapID: "PEWTER_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "MUSEUM_2F",
        displayName: "Museum 2F",
        objectFile: "data/maps/objects/Museum2F.asm",
        blockFile: "maps/Museum2F.blk",
        parentMapID: "MUSEUM_1F",
        isOutdoor: false
    ),
    .init(
        mapID: "PEWTER_GYM",
        displayName: "Pewter Gym",
        objectFile: "data/maps/objects/PewterGym.asm",
        blockFile: "maps/PewterGym.blk",
        parentMapID: "PEWTER_CITY",
        isOutdoor: false
    ),
    .init(
        mapID: "ROUTE_3",
        displayName: "Route 3",
        objectFile: "data/maps/objects/Route3.asm",
        blockFile: "maps/Route3.blk",
        parentMapID: nil,
        isOutdoor: true
    ),
]

let gameplayCoverageMapIDs = Set(gameplayCoverageMaps.map(\.mapID))
