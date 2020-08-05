hook.Add("PlayerSpawnedNPC", "ArcCW_PlayerSpawnedNPC", function( ply, ent )
    net.Start("arccw_npcgiverequest")
    net.Send(ply)

    ply.ArcCW_LastSpawnedNPC = ent
end)

net.Receive("arccw_npcgivereturn", function(len, ply)
    local class = net.ReadString()
    local ent = ply.ArcCW_LastSpawnedNPC

    if !ent then return end
    if !IsValid(ent) then return end
    if !ent:IsNPC() then return end
    if !class then return end

    local wpn = weapons.Get(class)

    local cap = ent:CapabilitiesGet()

    if bit.band(cap, CAP_USE_WEAPONS) != CAP_USE_WEAPONS then return end

    if weapons.IsBasedOn(class, "arccw_base") and wpn.Spawnable and !wpn.NotForNPCs and (!wpn.AdminOnly or ply:IsAdmin()) then
        ent:Give(class)
    end
end)

function ArcCW:GetRandomWeapon(wpn, nades)
    local tbl = {}
    local wgt = 0

    for i, k in pairs(weapons.GetList()) do
        if !weapons.IsBasedOn(k.ClassName, "arccw_base") then continue end
        if k.PrimaryBash then continue end
        if !k.Spawnable then continue end
        if !nades and k.NotForNPCs then continue end
        if nades and k.AutoSpawnable == false then continue end

        if GetConVar("arccw_limityear_enable"):GetBool() then
            local year = GetConVar("arccw_limityear"):GetInt()

            if k.Trivia_Year and isnumber(k.Trivia_Year) and k.Trivia_Year > year then
                continue
            end
        end

        local weight = (k.NPCWeight or 100)

        if wpn and k.TTTWeaponType then -- TTT weapon type(s) take priority over NPC weapon types
            if isstring(k.TTTWeaponType) then
                if k.TTTWeaponType != wpn then continue end
            elseif istable(k.TTTWeaponType) then
                if !table.HasValue(k.TTTWeaponType, wpn) then continue end
            end
        elseif wpn and k.NPCWeaponType then
            if isstring(k.NPCWeaponType) then
                if k.NPCWeaponType != wpn then continue end
            elseif istable(k.NPCWeaponType) then
                if !table.HasValue(k.NPCWeaponType, wpn) then continue end
            end
        else
            local og = weapons.Get(wpn)

            if og and og.ArcCW then continue end
            weight = 10
        end

        wgt = wgt + weight

        table.insert(tbl, {k.ClassName, wgt})
    end

    local r = math.random(0, wgt)

    for _, i in pairs(tbl) do
        if i[2] >= r then
            return i[1]
        end
    end
end

hook.Add( "OnEntityCreated", "ArcCW_NPCWeaponReplacement", function(ent)
    if CLIENT then return end
    if engine.ActiveGamemode() != "terrortown" and !GetConVar("arccw_npc_replace"):GetBool() then return end
    if engine.ActiveGamemode() == "terrortown" and !GetConVar("arccw_ttt_replace"):GetBool() then return end
    timer.Simple(0, function()
        if !ent:IsValid() then return end
        if !ent:IsNPC() then return end
        local cap = ent:CapabilitiesGet()

        if bit.band(cap, CAP_USE_WEAPONS) != CAP_USE_WEAPONS then return end

        local class

        if IsValid(ent:GetActiveWeapon()) then
            class = ent:GetActiveWeapon():GetClass()
        end

        if !class then return end

        local wpn = ArcCW:GetRandomWeapon(class)

        if engine.ActiveGamemode() == "terrortown" then
            wpn = ArcCW:TTT_GetRandomWeapon(class)
        end

        if wpn then
            ent:Give(wpn)
        end
    end)
    timer.Simple(0, function()
        if !ent:IsValid() then return end
        if !ent:IsWeapon() then return end
        if ent:GetOwner():IsValid() then return end

        local class = ent:GetClass()

        local wpn = ArcCW:GetRandomWeapon(class)

        if engine.ActiveGamemode() == "terrortown" then
            wpn = ArcCW:TTT_GetRandomWeapon(class)
        end

        if wpn then
            local wpnent = ents.Create(wpn)
            wpnent:SetPos(ent:GetPos())
            wpnent:SetAngles(ent:GetAngles())

            wpnent:NPC_Initialize()

            wpnent:Spawn()

            if GetConVar("arccw_ttt_atts") and GetConVar("arccw_ttt_atts"):GetBool() then
                wpnent:NPC_SetupAttachments()
            end

            timer.Simple(0, function()
                if !ent:IsValid() then return end
                wpnent:OnDrop(true)
                ent:Remove()
            end)
        end
    end)
end)

hook.Add("PlayerCanPickupWeapon", "ArcCW_PlayerCanPickupWeapon", function(ply, wep)
    if !wep.ArcCW then return end
    if !ply:HasWeapon(wep:GetClass()) then return end

    if wep.Singleton then return false end

    if !ArcCW.EnableCustomization or !GetConVar("arccw_enable_customization"):GetBool() or GetConVar("arccw_attinv_free"):GetBool() then return end

    -- This is often considered a bug even when it is normal behavior
    -- TODO make convar for it
    --[[]
    for _, i in pairs(wep.Attachments) do
        if i.Installed then
            ArcCW:PlayerGiveAtt(ply, i.Installed)
        end

        i.Installed = nil
    end

    ArcCW:PlayerSendAttInv(ply)
    wep:NetworkWeapon()
    ]]
end)

hook.Add("onDarkRPWeaponDropped", "ArcCW_DarkRP", function(ply, spawned_weapon, wep)
    if wep.ArcCW and wep.Attachments then
        for i, k in pairs(wep.Attachments) do
            if k.Installed then
                ArcCW:PlayerGiveAtt(ply, k.Installed, 1)
            end
        end
        -- Has to be sent to client or desync will happen
        ArcCW:PlayerSendAttInv(ply)
    end
end)

hook.Add("PlayerGiveSWEP", "ArcCW_SpawnRandomAttachments", function(ply, class, tbl)
    if tbl.ArcCW and GetConVar("arccw_atts_spawnrand"):GetBool() then
        timer.Simple(0, function()
            if IsValid(ply) and IsValid(ply:GetWeapon(class)) then
                ply:GetWeapon(class):NPC_SetupAttachments()
            end
        end)
    end
end)

hook.Add("PlayerSpawnedSWEP", "ArcCW_SpawnRandomAttachments", function(ply, wep)
    if wep.ArcCW and GetConVar("arccw_atts_spawnrand"):GetBool() then
        wep:NPC_SetupAttachments()
    end
end)