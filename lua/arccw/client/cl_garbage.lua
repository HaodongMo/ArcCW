local tbl     = table
local tbl_ins = tbl.insert
local rem_ent = SafeRemoveEntity

ArcCW.CSModels       = {} -- [entid] = { Weapon = NULL, WModels = {}, VModels = {} }
ArcCW.CSModelPile    = {} -- { {Model = NULL, Weapon = NULL} }
ArcCW.FlashlightPile = {} -- { {Weapon = NULL, ProjectedTexture = NULL}}
ArcCW.ReferenceModel = NULL

local function ArcCW_CollectGarbage()
    local removed, removedents = 0, {}

    for i, k in pairs(ArcCW.CSModels) do
        if !IsValid(k.Weapon) then
            removed = removed + 1

            tbl_ins(removedents, i)

            if k.WModels then for _, m in pairs(k.WModels) do rem_ent(m.Model) end end
            if k.VModels then for _, m in pairs(k.VModels) do rem_ent(m.Model) end end
        end
    end

    for _, i in pairs(removedents) do ArcCW.CSModels[i] = nil end

    local newpile = {}

    for _, k in pairs(ArcCW.CSModelPile) do
        if IsValid(k.Weapon) then
            tbl_ins(newpile, k)

            continue
        end

        rem_ent(k.Model)

        removed = removed + 1
    end

    ArcCW.CSModelPile = newpile

    if GetConVar("developer"):GetBool() and removed > 0 then
        print("Removed " .. tostring(removed) .. " CSModels")
    end
end

hook.Add("PostCleanupMap", "ArcCW_CleanGarbage", function()
    ArcCW_CollectGarbage()
end)

timer.Create("ArcCW CSModel Garbage Collector", 5, 0, ArcCW_CollectGarbage)

hook.Add("PostDrawEffects", "ArcCW_CleanFlashlights", function()
    local newflashlightpile = {}

    for _, k in pairs(ArcCW.FlashlightPile) do
        if IsValid(k.Weapon) and k.Weapon == LocalPlayer():GetActiveWeapon() then
            tbl_ins(newflashlightpile, k)

            continue
        end

        if k.ProjectedTexture and k.ProjectedTexture:IsValid() then
            k.ProjectedTexture:Remove()
        end
    end

    ArcCW.FlashlightPile = newflashlightpile

    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn then return end
    if !IsValid(wpn) then return end
    if !wpn.ArcCW then return end

    if GetViewEntity() == LocalPlayer() then return end

    wpn:KillFlashlightsVM()
end)