--[[

********************************************************************************
*                             Firmament Crafting                               *
********************************************************************************

Crafts the green Ishgard restoration item, turns them in for Kupo Vouchers,
plays the Kupo Voucher lottery when you're capped, and gets back to crafting.
Script will stop itself if you are out of materials or out of inventory space.

********************************************************************************
*                               Version 1.0.3                                  *
********************************************************************************

Created by: pot0to (https://ko-fi.com/pot0to)
        
    ->  1.0.2   Fixed the check where it tries to do one more craft in the
                    window between finishing the last craft and when it drops
                    in your inventory
                Fixed normal check when exiting crafting state, added /at y
                Redo order of kupo voucher
                First release

********************************************************************************
*                               Required Plugins                               *
********************************************************************************

Plugins that are needed for it to work:

    -> Something Need Doing [Expanded Edition] : Main Plugin for everything to work   (https://puni.sh/api/repository/croizat)
    -> VNavmesh :   For Pathing/Moving    (https://puni.sh/api/repository/veyn)
    -> TextAdvance: For interacting with NPCs
    -> Artisan:     For crafting

--#region Settings

--[[
********************************************************************************
*                                   Settings                                   *
********************************************************************************
]]

MinInventoryFreeSlots = 5

--#endregion Settings

--[[
********************************************************************************
*           Code: Don't touch this unless you know what you're doing           *
********************************************************************************
]]

SkybuildersCraftedItems =
{
    { className="Carpenter", classId=8, itemId=31953, recipeId=34473 },
    { className="Blacksmith", classId=9, itemId=31954, recipeId=34474 },
    { className="Armorer", classId=10, itemId=31955, recipeId=34475 },
    { className="Goldsmith", classId=11, itemId=31956, recipeId=34476 },
    { className="Leatherworker", classId=12, itemId=31957, recipeId=34477 },
    { className="Weaver", classId=13, itemId=31958, recipeId=34478 },
    { className="Alchemist", classId=14, itemId=31959, recipeId=34479 },
    { className="Culinarian", classId=15, itemId=31960, recipeId=34480 }
}

local Npcs =
{
    turnInNpc = "Potkin",
    kupoVouchersNpc = "Lizbeth",
    x = 52.750366, y = -16, z = 168.9325
}

CharacterCondition =
{
    normal = 1,
    craftingMode = 5, --kneel to craft
    occupiedInQuestEvent=32,
    executingCraftingSkill = 40, -- executing crafting skill
    preparingToCraft = 41
}

function OutOfMaterials()
    for i=0,5 do
        local materialCount = GetNodeText("RecipeNote", 18 + i, 8)
        local materialRequirement = GetNodeText("RecipeNote", 18 + i, 15)
        if materialCount ~= "" and materialRequirement ~= "" then
            if tonumber(materialCount) < tonumber(materialRequirement) then
                return true
            end
        end
    end
    return false
end

function Crafting()
    local slots = GetInventoryFreeSlotCount()
    if slots <= MinInventoryFreeSlots then
        yield("/echo Out of inventory slots")
        ArtisanSetEnduranceStatus(false)
        if IsAddonVisible("RecipeNote") and GetCharacterCondition(CharacterCondition.preparingToCraft) then
            yield("/wait 1")
            yield("/echo Closing crafting log 1")
            yield("/callback RecipeNote true -1")
        elseif GetCharacterCondition(CharacterCondition.normal) then
            yield("/echo Turning in")
            State = CharacterState.turnIn
            LogInfo("State Change: TurnIn")
        else
            yield("/wait 0.5")
        end
    elseif ArtisanGetEnduranceStatus() then
        -- let artisan keep crafting
    elseif IsAddonVisible("RecipeNote") and OutOfMaterials() then
        if GetItemCount(ItemId) == 0 then
            yield("/echo Out of materials. Stopping SND.")
            StopFlag = true
        else
            yield("/echo Out of materials, doing final turnin")
            yield("/callback RecipeNote true -1")
            yield("/wait 1")
            State = CharacterState.turnIn
            LogInfo("State Change: TurnIn")
        end
    elseif not ArtisanGetEnduranceStatus() and
        (GetCharacterCondition(CharacterCondition.preparingToCraft) or GetCharacterCondition(CharacterCondition.normal))
    then
        yield("/echo Crafting "..math.max(0, slots - MinInventoryFreeSlots).." items")
        ArtisanCraftItem(RecipeId, math.max(0, slots - MinInventoryFreeSlots))
        yield("/wait 5")
    end
end

function TurnIn()
    if IsAddonVisible("RecipeNote") then
        yield("/callback RecipeNote true -1")
    elseif GetItemCount(ItemId) == 0 then
        if IsAddonVisible("HWDSupply") then
            yield("/callback HWDSupply true -1")
        elseif GetInventoryFreeSlotCount() <= MinInventoryFreeSlots then
            yield("/echo Out of inventory space. Stopping SND")
            StopFlag = true
        else
            State = CharacterState.crafting
            LogInfo("State Change: Crafting")
        end
    elseif GetItemCount(28063) >= 9900 then
        yield("/echo Almost capped on Skybuilders' Scrips! Stopping SND.")
        StopFlag = true
    elseif GetDistanceToPoint(Npcs.x, Npcs.y, Npcs.z) > 5 then
        if not PathfindInProgress() and not PathIsRunning() then
            PathfindAndMoveTo(Npcs.x, Npcs.y, Npcs.z)
        end
    else
        if PathfindInProgress() or PathIsRunning() then
            yield("/vnav stop")
        end

        if not HasTarget() or GetTargetName() ~= Npcs.turnInNpc then
            yield("/target "..Npcs.turnInNpc)
        elseif not IsAddonVisible("HWDSupply") then
            yield("/interact")
            yield("/wait 1")
        elseif GetNodeText("HWDSupply", 16) == "10/10" then
            yield("/callback HWDSupply true -1")
            State = CharacterState.kupoVoucherLottery
            LogInfo("State Change: KupoVouchers")
        else
            yield("/callback HWDSupply true 1 0")
            yield("/wait 1")
        end
    end
end

Retries = 0
function KupoVoucherLottery()
    if GetInventoryFreeSlotCount() == 0 and GetItemCount(ItemId) > 0 then
        if IsAddonVisible("SelectYesno") then
            yield("/callback SelectYesno true -1")
        else
            State = CharacterState.turnIn
            LogInfo("State Change: TurnIn")
        end
    elseif IsAddonVisible("SelectYesno") then
        yield("/callback SelectYesno true 0")
    elseif IsAddonVisible("HWDLottery") then
        Retries = 0
        yield("/callback HWDLottery true 0 1")
        yield("/wait 1")
        yield("/callback HWDLottery true 2")
        yield("/wait 1")
    elseif Retries >= 3 then
        Retries = 0
        State = CharacterState.crafting
        LogInfo("State Change: Crafting")
    elseif GetDistanceToPoint(Npcs.x, Npcs.y, Npcs.z) > 5 then
        if not PathfindInProgress() and not PathIsRunning() then
            PathfindAndMoveTo(Npcs.x, Npcs.y, Npcs.z)
        end
    else
        yield("/target Lizbeth")
        yield("/wait 0.5")
        yield("/interact")
        yield("/wait 1")
        Retries = Retries + 1
    end
end

CharacterState =
{
    crafting = Crafting,
    turnIn = TurnIn,
    kupoVoucherLottery = KupoVoucherLottery
}

yield("/at y")
State = CharacterState.crafting
local classId = GetClassJobId()
ItemId = 0
RecipeId = 0
for _, data in ipairs(SkybuildersCraftedItems) do
    if data.classId == classId then
        ItemId = data.itemId
        RecipeId = data.recipeId
    end
end
if ItemId == 0 then
    yield("/echo Cannot recognize current class. Stopping SND.")
end

StopFlag = false
while not StopFlag do
    State()
    yield("/wait 0.1")
end
