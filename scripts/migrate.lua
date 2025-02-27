local Migrate = {}

Migrate.version = 020300

function Migrate.Run()
    if not storage.version then
        storage.version = 0
    end

    if storage.version < Migrate.version then
        if storage.version < 010003 then Migrate.v1_0_3() end
        if storage.version < 010100 then Migrate.v1_1_0() end
        if storage.version < 010401 then Migrate.v1_4_1() end
        if storage.version < 010500 then Migrate.v1_5_0() end
        if storage.version < 010600 then Migrate.v1_6_0() end
        if storage.version < 010700 then Migrate.v1_7_0() end
        if storage.version < 010703 then Migrate.v1_7_3() end
        if storage.version < 010704 then Migrate.v1_7_4() end
        if storage.version < 011000 then Migrate.v1_10_0() end
        if storage.version < 011001 then Migrate.v1_10_1() end
        if storage.version < 011101 then Migrate.v1_11_1() end
        if storage.version < 011103 then Migrate.v1_11_3() end
        if storage.version < 011500 then Migrate.v1_15_0() end
        if storage.version < 011604 then Migrate.v1_16_4() end
        if storage.version < 011606 then Migrate.v1_16_6() end
        if storage.version < 020000 then Migrate.v2_0_0() end
        if storage.version < 020106 then Migrate.v2_1_6() end
        if storage.version < 020107 then Migrate.v2_1_7() end
        if storage.version < 020201 then Migrate.v2_2_1() end
    end

    storage.version = Migrate.version
end

function Migrate.RecreateGuis()
    for _, player in pairs(game.players) do
        ToggleGUI.Destroy(player)
        ToggleGUI.Init(player)
    end
end

function Migrate.v1_0_3()
    --[[
    It was discovered that in on_configuration_changed Space Exploration would
    "fix" all Tiles for all Zones that it knows of, which causes problems
    specifically for the Planetary Sandbox, which initially used Stars.
    At this point, we unfortunately have to completely remove those Sandboxes,
    which is unavoidable because by the nature of this update we would have
    triggered the complete-reset of that Surface anyway.
    ]]

    log("Migration 1.0.3 Starting")

    if SpaceExploration.enabled() then
        local planetaryLabId = 3
        local planetaryLabsOnStars = {}
        local playersToKickFromPlanetaryLabs = {}

        for name, surfaceData in pairs(storage.seSurfaces) do
            if (not surfaceData.orbital) and SpaceExploration.IsStar(name) then
                table.insert(planetaryLabsOnStars, {
                    zoneName = name,
                    sandboxForceName = surfaceData.sandboxForceName,
                })
            end
        end

        for index, player in pairs(game.players) do
            local playerData = storage.players[index]
            if playerData.insideSandbox == planetaryLabId
                    and SpaceExploration.IsStar(player.surface.name)
            then
                table.insert(playersToKickFromPlanetaryLabs, player)
            end
        end

        for _, player in pairs(playersToKickFromPlanetaryLabs) do
            log("Kicking Player out of Planetary Lab: " .. player.name)
            Sandbox.Exit(player)
        end

        for _, surfaceData in pairs(planetaryLabsOnStars) do
            log("Destroying Planetary Lab inside Star: " .. surfaceData.zoneName)
            SpaceExploration.DeleteSandbox(
                    storage.sandboxForces[surfaceData.sandboxForceName],
                    surfaceData.zoneName
            )
        end
    end

    log("Migration 1.0.3 Finished")
end

function Migrate.v1_1_0()
    --[[
    A "persistent" Sandbox Inventory was created for each Player.
    ]]

    log("Migration 1.1.0 Starting")

    for index, player in pairs(game.players) do
        local playerData = storage.players[index]
        playerData.sandboxInventory = game.create_inventory(#player.get_main_inventory())
        if Sandbox.IsPlayerInsideSandbox(player) then
            log("Player inside Sandbox, fully-syncing the inventory.")
            Inventory.Persist(
                    player.get_main_inventory(),
                    playerData.sandboxInventory
            )
        end
    end

    log("Migration 1.1.0 Finished")
end

function Migrate.v1_4_1()
    --[[
    The levels for level-based Research wasn't being synchronized.
    ]]

    log("Migration 1.4.1 Starting")

    Research.SyncAllForces()

    log("Migration 1.4.1 Finished")
end

function Migrate.v1_5_0()
    --[[
    Bonus Slots for Sandbox Force Inventories were added.
    ]]

    log("Migration 1.5.0 Starting")

    Force.SyncAllForces()

    log("Migration 1.5.0 Finished")
end

function Migrate.v1_6_0()
    --[[
    Last-known positions inside Sandboxes were added.
    ]]

    log("Migration 1.6.0 Starting")

    for index, _ in pairs(game.players) do
        local playerData = storage.players[index]
        playerData.lastSandboxPositions = {}
    end

    log("Migration 1.6.0 Finished")
end

function Migrate.v1_7_0()
    --[[
    Configurable-per-Sandbox daytime was added.
    ]]

    log("Migration 1.7.0 Starting")

    for surfaceName, _ in pairs(storage.labSurfaces) do
        local surface = game.surfaces[surfaceName]
        if surface then
            surface.always_day = false
            surface.freeze_daytime = true
            surface.daytime = 0.95
            storage.labSurfaces[surfaceName].daytime = 0.95
        end
    end

    for surfaceName, _ in pairs(storage.seSurfaces) do
        local surface = game.surfaces[surfaceName]
        if surface then
            surface.always_day = false
            surface.freeze_daytime = true
            surface.daytime = 0.95
            storage.seSurfaces[surfaceName].daytime = 0.95
        end
    end

    Migrate.RecreateGuis()

    log("Migration 1.7.0 Finished")
end

function Migrate.v1_7_3()
    --[[
    The daylight portrait icon had the same name as the Reset Button.
    ]]

    log("Migration 1.7.3 Starting")

    Migrate.RecreateGuis()

    log("Migration 1.7.3 Finished")
end

function Migrate.v1_7_4()
    --[[
    The 1.7.3 migration wasn't correctly applied to 1.7.x
    Allow-all-Tech was incorrectly applying the existing Force's bonuses
    ]]

    Migrate.v1_7_3()

    log("Migration 1.7.4 Starting")

    if settings.global[Settings.allowAllTech].value then
        game.print("Blueprint Sandboxes Notice: You had the Unlock-all-Technologies " ..
                "Setting enabled, but there was a bug pre-1.7.4 that was incorrectly " ..
                "overriding some of the bonuses from leveled-research. You should " ..
                "disable, then re-enable this setting in order to fix that.")
    end

    log("Migration 1.7.4 Finished")
end

function Migrate.v1_10_0()
    --[[
    Internal Queues for Asynchronous Sandbox requests
    replace the old find_entities_filtered
    ]]

    log("Migration 1.10.0 Starting")

    storage.asyncCreateQueue = Queue.New()
    storage.asyncUpgradeQueue = Queue.New()
    storage.asyncDestroyQueue = Queue.New()

    for _, surfaceData in pairs(storage.labSurfaces) do
        surfaceData.hasRequests = nil
    end

    for _, surfaceData in pairs(storage.seSurfaces) do
        surfaceData.hasRequests = nil
    end

    log("Migration 1.10.0 Finished")
end

function Migrate.v1_10_1()
    --[[
    Planetary Labs were possibly created within a Player's Home System
    and on Planets that could be dangerous.
    ]]

    log("Migration 1.10.1 Starting")

    if SpaceExploration.enabled() then
        local planetaryLabId = 3
        local badPlanetaryLabs = {}
        local badPlanetaryLabNames = {}
        local playersToKickFromPlanetaryLabs = {}
        local zoneIndex = remote.call(SpaceExploration.name, "get_zone_index", {})

        for name, surfaceData in pairs(storage.seSurfaces) do
            if not surfaceData.orbital then
                local zone = remote.call(SpaceExploration.name, "get_zone_from_name", {
                    zone_name = name,
                })
                local rootZone = SpaceExploration.GetRootZone(zoneIndex, zone)
                if SpaceExploration.IsZoneThreatening(zone)
                        or rootZone.special_type == "homesystem" then
                    table.insert(badPlanetaryLabs, {
                        zoneName = name,
                        sandboxForceName = surfaceData.sandboxForceName,
                    })
                    badPlanetaryLabNames[name] = true
                end
            end
        end

        for index, player in pairs(game.players) do
            local playerData = storage.players[index]
            if playerData.insideSandbox == planetaryLabId
                    and badPlanetaryLabNames[player.surface.name]
            then
                table.insert(playersToKickFromPlanetaryLabs, player)
            end
        end

        for _, player in pairs(playersToKickFromPlanetaryLabs) do
            log("Kicking Player out of Planetary Lab: " .. player.name)
            Sandbox.Exit(player)
        end

        for _, surfaceData in pairs(badPlanetaryLabs) do
            log("Destroying Planetary Lab: " .. surfaceData.zoneName)
            SpaceExploration.DeleteSandbox(
                    storage.sandboxForces[surfaceData.sandboxForceName],
                    surfaceData.zoneName
            )
            local message = "Unfortunately, your Planetary Sandbox was generated in a " ..
                    "non-ideal or dangerous location, so it was destroyed. Accessing " ..
                    "the Sandbox again will create a new one in a safer location."
            game.forces[surfaceData.sandboxForceName].print(message)
            game.forces[storage.sandboxForces[surfaceData.sandboxForceName].forceName].print(message)
        end
    end

    log("Migration 1.10.1 Finished")
end

function Migrate.v1_11_1()
    --[[
    dangOreus was applying to Labs and causing significant lag
    ]]

    log("Migration 1.11.1 Starting")

    if remote.interfaces["dangOreus"] then
        for labName, _ in pairs(storage.labSurfaces) do
            pcall(remote.call, "dangOreus", "toggle", labName)
        end
    end

    log("Migration 1.11.1 Finished")
end

function Migrate.v1_11_3_surface(surfaceName)
    local surface = game.surfaces[surfaceName]
    if not surface then
        return
    end

    local entitiesToSwap = surface.find_entities_filtered({ name = Illusion.realNameFilters, })
    for _, entity in pairs(entitiesToSwap) do
        Illusion.ReplaceIfNecessary(entity)
    end

    local ghostsToSwap = surface.find_entities_filtered({ ghost_name = Illusion.realNameFilters, })
    for _, entity in pairs(ghostsToSwap) do
        Illusion.ReplaceIfNecessary(entity)
    end
end

function Migrate.v1_11_3()
    --[[
    1.11.0 did not include a migration of real-to-illusion Entities,
    but it was found that some older Entities combined with Space Exploration 0.6
    could cause a crash.
    ]]

    log("Migration 1.11.3 Starting")

    for surfaceName, _ in pairs(storage.labSurfaces) do
        Migrate.v1_11_3_surface(surfaceName)
    end

    for surfaceName, _ in pairs(storage.seSurfaces) do
        Migrate.v1_11_3_surface(surfaceName)
    end

    log("Migration 1.11.3 Finished")
end

function Migrate.v1_15_0()
    --[[
    1.15.0 introduced a default Equipment Inventory for each Sandbox
    ]]

    log("Migration 1.15.0 Starting")

    for surfaceName, surfaceData in pairs(storage.labSurfaces) do
        surfaceData.equipmentBlueprints = Equipment.Init(Lab.equipmentString)
    end

    for surfaceName, surfaceData in pairs(storage.seSurfaces) do
        if (surfaceData.orbital) then
            surfaceData.equipmentBlueprints = Equipment.Init(SpaceExploration.orbitalEquipmentString)
        else
            surfaceData.equipmentBlueprints = Equipment.Init(Lab.equipmentString)
        end
    end

    log("Migration 1.15.0 Finished")
end

function Migrate.v1_16_4()
    --[[
    1.16.4 introduced an alternative Equipment placement technique
    ]]

    log("Migration 1.16.4 Starting")

    storage.equipmentInProgress = {}

    log("Migration 1.16.4 Finished")
end

function Migrate.v1_16_6()
    --[[
    1.16.6 added Remote Interface support for Editor Extensions
    ]]

    log("Migration 1.16.6 Starting")

    for _, force in pairs(game.forces) do
        if Sandbox.IsSandboxForce(force) then
            EditorExtensionsCheats.EnableTestingRecipes(force)
        end
    end

    log("Migration 1.16.6 Finished")
end

function Migrate.v2_0_0()
    --[[
    2.0.0 has many necessary updates for Factorio 2.0
    ]]

    log("Migration 2.0.0 Starting")

    Force.SyncAllForces()
    for _, force in pairs(game.forces) do
        RemoteView.HideAllSandboxes(force)
        if Sandbox.IsSandboxForce(force) then
            RemoteView.HideEverythingInSandboxes(force)
            force.rechart()
        end
    end

    for _, player in pairs(game.players) do
        local playerData = storage.players[player.index]
        if Sandbox.IsPlayerInsideSandbox(player) then
            if player.permission_group
                    and not Permissions.IsSandboxPermissions(player.permission_group.name)
            then
                playerData.preSandboxPermissionGroupId = player.permission_group.name
                local newPermissions = Permissions.GetOrCreate(player)
                if newPermissions then
                    player.permission_group = newPermissions
                end
            end
        end
    end

    log("Migration 2.0.0 Finished")
end

function Migrate.v2_1_6()
    --[[
    2.1.6 attempts to re-initialize some Remote View settings for some users
    ]]

    log("Migration 2.1.6 Starting")

    RemoteView.Init()

    log("Migration 2.1.6 Finished")
end

function Migrate.v2_1_7()
    --[[
    2.1.7 attempts to reduce inconsistencies with hidden recipes
    ]]

    log("Migration 2.1.7 Starting")

    for _, force in pairs(game.forces) do
        local sandboxForce = storage.sandboxForces[force.name]
        if sandboxForce then
            sandboxForce.hiddenItemsUnlocked = nil
        end
    end

    log("Migration 2.1.7 Finished")
end

function Migrate.v2_2_1()
    --[[
    2.2.1 associated players with their characters when entering sandboxes
    ]]

    log("Migration 2.2.1 Starting")
    
    for index, player in pairs(game.players) do
        local character = storage.players[index].preSandboxCharacter
        if character and character.valid
            and not character.associated_player
            and player.controller_type ~= defines.controllers.character
        then
            character.associated_player = player
        end
    end

    log("Migration 2.2.1 Finished")
end

return Migrate
