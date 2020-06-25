ArcCW.CSModels = {
    -- [entid] = {
    --     Weapon = NULL,
    --     WModels = {},
    --     VModels = {}
    -- }
}
ArcCW.CSModelPile = {}
-- {
-- {Model = NULL, Weapon = NULL}
--}

ArcCW.ReferenceModel = NULL

local function ArcCW_CollectGarbage()
    local removed = 0
    local removedents = {}

    for i, k in pairs(ArcCW.CSModels) do
        if !IsValid(k.Weapon) then
            removed = removed + 1
            table.insert(removedents, i)

            if k.WModels then
                for _, m in pairs(k.WModels) do
                    SafeRemoveEntity(m.Model)
                end
            end

            if k.VModels then
                for _, m in pairs(k.VModels) do
                    SafeRemoveEntity(m.Model)
                end
            end
        end
    end

    for _, i in pairs(removedents) do
        ArcCW.CSModels[i] = nil
    end

    local newpile = {}

    for i, k in pairs(ArcCW.CSModelPile) do
        if !IsValid(k.Weapon) then
            SafeRemoveEntity(k.Model)
            removed = removed + 1
        else
            table.insert(newpile, k)
        end
    end

    ArcCW.CSModelPile = newpile

    if GetConVar("developer"):GetBool() and removed > 0 then
        print("Removed " .. tostring(removed) .. " CSModels")
    end
end

timer.Create("ArcCW CSModel Garbage Collector", 5, 0, ArcCW_CollectGarbage)