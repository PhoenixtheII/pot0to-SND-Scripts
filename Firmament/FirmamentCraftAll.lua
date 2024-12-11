MacroName = "Craft Skybuilders' Items"

Classes = {
    "Carpenter",
    "Blacksmith",
    "Armorer",
    "Goldsmith",
    "Leatherworker",
    "Weaver",
    "Alcemist",
    "Culinarian"
}

FoundationZoneId = 418
FirmamentZoneId = 886
function TeleportTo(aetheryteName)
    yield("/tp "..aetheryteName)
    yield("/wait 1") -- wait for casting to begin
    while GetCharacterCondition(CharacterCondition.casting) do
        LogInfo("[FATE] Casting teleport...")
        yield("/wait 1")
    end
    yield("/wait 1") -- wait for that microsecond in between the cast finishing and the transition beginning
    while GetCharacterCondition(CharacterCondition.betweenAreas) do
        LogInfo("[FATE] Teleporting...")
        yield("/wait 1")
    end
    yield("/wait 1")
end

if not (IsInZone(FoundationZoneId) or IsInZone(FirmamentZoneId) or IsInZone(DiademZoneId)) then
    TeleportTo("Foundation")
end
if IsInZone(FoundationZoneId) then
    yield("/target aetheryte")
    yield("/wait 1")
    if GetTargetName() == "aetheryte" then
        yield("/interact")
    end
    repeat
        yield("/wait 1")
    until IsAddonVisible("SelectString")
    yield("/callback SelectString true 2")
    repeat
        yield("/wait 1")
    until IsInZone(FirmamentZoneId)
end

for _, class in ipairs(Classes) do
    yield("/echo Crafting for "..class)
    yield("/gs change "..class)
    yield("/wait 5")

    yield("/snd run "..MacroName)
    repeat
        yield("/wait 5")
    until not IsMacroRunningOrQueued(MacroName)

    repeat
        yield("/callback RecipeNote true -1")
        yield("/wait 1")
    until not IsAddonVisible("RecipeNote")
end