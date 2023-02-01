ArcCW.AttachmentBlacklistTable = ArcCW.AttachmentBlacklistTable or {}

function ArcCW:PlayerCanAttach(ply, wep, attname, slot, detach)
    -- The global variable takes priority over everything
    if !ArcCW.EnableCustomization then return false end

    -- Spectators taking off your attachments is funny, but also cursed
    if wep:GetOwner() != ply then return false end

    -- Allow hooks to block or force allow attachment usage
    local ret = hook.Run("ArcCW_PlayerCanAttach", ply, wep, attname, slot, detach)

    if ret == nil and engine.ActiveGamemode() == "terrortown" then
        local mode = GetConVar("arccw_ttt_customizemode"):GetInt()
        if mode == 1 and !ply.ArcCW_AllowCustomize then return false
        elseif mode == 2 and !ply.ArcCW_AllowCustomize and GetRoundState() == ROUND_ACTIVE then return false
        elseif mode == 3 and !ply.ArcCW_AllowCustomize and !ply:IsActiveTraitor() and !ply:IsActiveDetective() then return false end
    elseif ret == nil and GetConVar("arccw_enable_customization"):GetInt() <= 0 then
        return false
    end

    return (ret == nil and true) or ret
end

function ArcCW:GetAttsForSlot(slot, wep, random)
    local ret = {}

    for id, atttbl in pairs(ArcCW.AttachmentTable) do

        if !ArcCW:SlotAcceptsAtt(slot, wep, id) then continue end
        if random and (atttbl.NoRandom or (atttbl.RandomWeight or 1) <= 0) then continue end

        table.insert(ret, id)
    end

    return ret
end

function ArcCW:GetAttList(name, filter)
    if self.AttachmentCachedLists[name] then return self.AttachmentCachedLists[name] end
    self.AttachmentCachedLists[name] = {}
    for k, v in pairs(self.AttachmentTable) do
        local k2, v2 = filter(k, v)
        if k2 then
            self.AttachmentCachedLists[name][k2] = v2
        end
    end
    return self.AttachmentCachedLists[name]
end

local function weighted_random(tbl, amt)
    amt = amt or 1
    local max = 0
    for k, v in pairs(tbl) do max = max + v end
    local ret = {}
    for i = 1, amt do
        local rng = math.random() * max
        for k, v in pairs(tbl) do
            rng = rng - v
            if rng <= 0 then
                ret[k] = (ret[k] or 0) + 1
                break
            end
        end
    end
    return ret
end

function ArcCW:RollRandomAttachment(all, wep, slot)
    for k, v in pairs(self:RollRandomAttachments(1, all, wep, slot)) do return k end
end

function ArcCW:RollRandomAttachments(amt, all, wep, slot)
    if wep == nil then
        -- cache the list results and randomly get one
        local tbl = self:GetAttList("random" .. (all and "_all" or ""), function(k, v)
            if ((!v.Free and !v.InvAtt) or all) and !v.NoRandom and (v.RandomWeight or 1) >= 0 then
                return k, v.RandomWeight or 1
            end
        end)
        return weighted_random(tbl, amt)
    else
        -- can't cache this because it is weapon-dependent
        local tbl = {}
        for id, atttbl in pairs(ArcCW.AttachmentTable) do
            if ((!atttbl.Free and !atttbl.InvAtt) or all) and (atttbl.NoRandom or (atttbl.RandomWeight or 1) <= 0) then continue end
            if !wep:CheckFlags(atttbl.ExcludeFlags, atttbl.RequireFlags) then continue end
            if slot != nil and !ArcCW:SlotAcceptsAtt(slot.Slot, wep, id) then continue end
            tbl[id] = atttbl.RandomWeight or 1
        end
        return weighted_random(tbl, amt)
    end
end

function ArcCW:SlotAcceptsAtt(slot, wep, att)
    local slots = {}

    if isstring(slot) then
        slots[slot] = true
    elseif istable(slot) then
        for _, i in pairs(slot) do
            slots[i] = true
        end
    end

    local atttbl = ArcCW.AttachmentTable[att]
    if !atttbl then return false end

    if atttbl.Hidden or atttbl.Blacklisted or ArcCW.AttachmentBlacklistTable[att] then return false end

    local Owner = wep.GetOwner and wep:GetOwner()
    if (atttbl.NotForNPC or atttbl.NotForNPCs) and Owner and Owner:IsNPC() then
        return false
    end
    if atttbl.AdminOnly and IsValid(Owner) and !(Owner:IsPlayer() and Owner:IsAdmin()) then return false end

    if wep.RejectAttachments and wep.RejectAttachments[att] then return false end

    if isstring(atttbl.Slot) then
        if !slots[atttbl.Slot] then return false end
    elseif istable(atttbl.Slot) then
        local yeah = false

        for _, i in pairs(atttbl.Slot) do
            if slots[i] then
                yeah = true
                break
            end
        end

        if !yeah then
            return false
        end
    end

    if wep and atttbl.Hook_Compatible then
        local compat = atttbl.Hook_Compatible(wep, {slot = slot, att = att})
        if compat == true then
            return true
        elseif compat == false then
            return false
        end
    end

    return true
end

function ArcCW:WeaponAcceptsAtt(wep, att)
    if wep.ArcCW and wep.Attachments then
        local tbl = {}
        for i, v in pairs(wep.Attachments) do
            table.insert(tbl, i)
        end
        return ArcCW:SlotAcceptsAtt(wep, wep, att)
    end
    return false
end

function ArcCW:PlayerGetAtts(ply, att)
    if !IsValid(ply) then return 0 end
    if GetConVar("arccw_attinv_free"):GetBool() then return 999 end

    if att == "" then return 999 end

    local atttbl = ArcCW.AttachmentTable[att]

    if !atttbl then return 0 end

    if atttbl.Free then return 999 end

    if !IsValid(ply) then return 0 end

    if !ply:IsAdmin() and atttbl.AdminOnly then
        return 0
    end

    if atttbl.InvAtt then att = atttbl.InvAtt end

    if !ply.ArcCW_AttInv then return 0 end

    if !ply.ArcCW_AttInv[att] then return 0 end

    return ply.ArcCW_AttInv[att]
end

function ArcCW:PlayerGiveAtt(ply, att, amt)
    amt = amt or 1

    if !IsValid(ply) then return end

    if !ply.ArcCW_AttInv then
        ply.ArcCW_AttInv = {}
    end

    local atttbl = ArcCW.AttachmentTable[att]

    if !atttbl then print("Invalid att " .. att) return end
    if atttbl.Free then return end -- You can't give a free attachment, silly
    if atttbl.AdminOnly and !(ply:IsPlayer() and ply:IsAdmin()) then return false end

    if atttbl.InvAtt then att = atttbl.InvAtt end

    if GetConVar("arccw_attinv_lockmode"):GetBool() then
        if ply.ArcCW_AttInv[att] == 1 then return end
        ply.ArcCW_AttInv[att] = 1
    else
        ply.ArcCW_AttInv[att] = (ply.ArcCW_AttInv[att] or 0) + amt
    end
end

function ArcCW:PlayerTakeAtt(ply, att, amt)
    amt = amt or 1

    if GetConVar("arccw_attinv_lockmode"):GetBool() then return end

    if !IsValid(ply) then return end

    if !ply.ArcCW_AttInv then
        ply.ArcCW_AttInv = {}
    end

    local atttbl = ArcCW.AttachmentTable[att]
    if !atttbl or atttbl.Free then return end

    if atttbl.InvAtt then att = atttbl.InvAtt end

    ply.ArcCW_AttInv[att] = ply.ArcCW_AttInv[att] or 0

    if ply.ArcCW_AttInv[att] < amt then
        return false
    end

    ply.ArcCW_AttInv[att] = ply.ArcCW_AttInv[att] - amt
    if ply.ArcCW_AttInv[att] <= 0 then
        ply.ArcCW_AttInv[att] = nil
    end
    return true
end

if CLIENT then

local function postsetup(wpn)
    if wpn.SetupModel then
        wpn:SetupModel(true)
        if wpn:GetOwner() == LocalPlayer() then
            wpn:SetupModel(false)
        end
        wpn:AdjustAtts()
    else
        timer.Simple(0.1, function()
            postsetup(wpn)
        end)
    end
end

net.Receive("arccw_networkatts", function(len, ply)
   local wpn = net.ReadEntity()
    if !IsValid(wpn) then return end
    if !wpn.ArcCW then return end

    local attnum = net.ReadUInt(8)
    wpn.Attachments = wpn.Attachments or {}
    wpn.SubSlotCount = 0

    for i = 1, attnum do
        local attid = net.ReadUInt(ArcCW.GetBitNecessity())

        wpn.Attachments[i] = wpn.Attachments[i] or {}

        if attid == 0 then
            if !istable(wpn.Attachments[i]) then continue end
            wpn.Attachments[i].Installed = nil
            continue
        end

        local att = ArcCW.AttachmentIDTable[attid]
        wpn.Attachments[i].Installed = att

        if wpn.Attachments[i].SlideAmount then
            wpn.Attachments[i].SlidePos = net.ReadFloat()
        end

        if ArcCW.AttachmentTable[att].ToggleStats then
            wpn.Attachments[i].ToggleNum = net.ReadUInt(8)
        end

        wpn:AddSubSlot(i, att)
    end

    wpn.CertainAboutAtts = true

    postsetup(wpn)
end)

net.Receive("arccw_sendattinv", function(len, ply)
    if !IsValid(LocalPlayer()) then return end -- This might be called before we are valid
    LocalPlayer().ArcCW_AttInv = {}

    local count = net.ReadUInt(32)

    for i = 1, count do
        local attid = net.ReadUInt(ArcCW.GetBitNecessity())
        local acount = net.ReadUInt(32)

        local att = ArcCW.AttachmentIDTable[attid]

        LocalPlayer().ArcCW_AttInv[att] = acount
    end

    -- This function will not exist until initialized (by having an ArcCW weapon exist)!
    -- It also obviously needs menu2 open
    if ArcCW.InvHUD_FormAttachmentSelect and IsValid(ArcCW.InvHUD) and IsValid(ArcCW.InvHUD_Menu2) then
        ArcCW.InvHUD_FormAttachmentSelect()
    end
end)

net.Receive("arccw_sendatthp", function(len, ply)
    local wpn = LocalPlayer():GetActiveWeapon()

    while net.ReadBool() do
        local slot = net.ReadUInt(8)
        local hp = net.ReadFloat()

        wpn.Attachments[slot].HP = hp
    end
end)

elseif SERVER then

hook.Add("PlayerDeath", "ArcCW_DeathAttInv", function(ply)
    ply.ArcCW_AttInv = ply.ArcCW_AttInv or {}
    if !table.IsEmpty(ply.ArcCW_AttInv) 
            and GetConVar("arccw_attinv_loseondie"):GetInt() >= 2
            and !GetConVar("arccw_attinv_free"):GetBool() then
        local boxEnt = ents.Create("arccw_att_dropped")
        boxEnt:SetPos(ply:GetPos() + Vector(0, 0, 4))
        boxEnt.GiveAttachments = ply.ArcCW_AttInv
        boxEnt:Spawn()
        boxEnt:SetNWString("boxname", ply:GetName() .. "'s Death Box")
        local count = 0
        for i, v in pairs(boxEnt.GiveAttachments) do count = count + v end
        boxEnt:SetNWInt("boxcount", count)
    end
end)

hook.Add("PlayerSpawn", "ArcCW_SpawnAttInv", function(ply, trans)
    if trans then return end

    if GetConVar("arccw_attinv_loseondie"):GetInt() >= 1 then
        ply.ArcCW_AttInv = {}
    end
    local amt = GetConVar("arccw_attinv_giveonspawn"):GetInt()
    if amt > 0 then
        local giv = ArcCW:RollRandomAttachments(amt)
        for k, v in pairs(giv) do
            ArcCW:PlayerGiveAtt(ply, k, v)
        end
    end
    ArcCW:PlayerSendAttInv(ply)
end)

net.Receive("arccw_rqwpnnet", function(len, ply)
    local wpn = net.ReadEntity()

    if !wpn.ArcCW then return end

    wpn:RecalcAllBuffs()
    wpn:NetworkWeapon()
end)

net.Receive("arccw_slidepos", function(len, ply)
    local wpn = ply:GetActiveWeapon()

    local slot = net.ReadUInt(8)
    local pos = net.ReadFloat()

    if !wpn.ArcCW then return end

    if !wpn.Attachments[slot] then return end

    wpn.Attachments[slot].SlidePos = pos
end)


net.Receive("arccw_togglenum", function(len, ply)
    local wpn = ply:GetActiveWeapon()

    local slot = net.ReadUInt(8)
    local num = net.ReadUInt(8)

    if !wpn.ArcCW then return end

    if !wpn.Attachments[slot] then return end

    wpn.Attachments[slot].ToggleNum = num

    wpn:AdjustAtts()
    wpn:NetworkWeapon()
    wpn:SetupModel(false)
    wpn:SetupModel(true)
end)


net.Receive("arccw_asktoattach", function(len, ply)
    local wpn = ply:GetActiveWeapon()

    local slot = net.ReadUInt(8)
    local attid = net.ReadUInt(24)

    local att = ArcCW.AttachmentIDTable[attid]

    if !wpn.ArcCW then return end
    if !wpn.Attachments[slot] then return end
    if !att then return end

    wpn:Attach(slot, att)
end)

net.Receive("arccw_asktodetach", function(len, ply)
    local wpn = ply:GetActiveWeapon()

    local slot = net.ReadUInt(8)

    if !wpn.ArcCW then return end
    if !wpn.Attachments[slot] then return end

    wpn:Detach(slot)
end)

net.Receive("arccw_asktodrop", function(len, ply)

    local attid = net.ReadUInt(24)
    local att = ArcCW.AttachmentIDTable[attid]

    if GetConVar("arccw_attinv_free"):GetBool() then return end
    if GetConVar("arccw_attinv_lockmode"):GetBool() then return end
    if GetConVar("arccw_enable_customization"):GetInt() < 0 then return end
    if !GetConVar("arccw_enable_dropping"):GetBool() then return end

    if !att then return end

    local atttbl = ArcCW.AttachmentTable[att]

    if !atttbl then return end
    if atttbl.Free then return end
    if ArcCW:PlayerGetAtts(ply, att) < 1 then return end

    -- better to do it like this in case you don't want to generate the attachment entities
    local ent = ents.Create("arccw_att_base")
    if !IsValid(ent) then return end
    ent:SetPos(ply:EyePos() + ply:EyeAngles():Forward() * 32)

    ent:SetNWInt("attid", attid)

    ent.GiveAttachments = {[att] = 1}
    ent.Model = atttbl.DroppedModel or atttbl.Model or "models/Items/BoxSRounds.mdl"
    ent.Icon = atttbl.Icon
    ent.PrintName = atttbl.PrintName or att

    ent:Spawn()
    timer.Simple(0, function()
        local phys = ent:GetPhysicsObject()
        if phys:IsValid() then
            phys:SetVelocity(ply:EyeAngles():Forward() * 32 * math.max(phys:GetMass(), 4))
        end
    end)
    ArcCW:PlayerTakeAtt(ply, att, 1)
    ArcCW:PlayerSendAttInv(ply)
end)

if SERVER then
    net.Receive("arccw_applypreset", function(len, ply)
        local wpn = net.ReadEntity()

        if wpn:GetOwner() != ply or !wpn.ArcCW then return end

        for k, v in pairs(wpn.Attachments) do
            wpn:Detach(k, true, true)
        end

        wpn.Attachments.BaseClass = nil -- AGHHHHHHHHHH
        for k, v in SortedPairs(wpn.Attachments) do
            local attid = net.ReadUInt(ArcCW.GetBitNecessity())

            local attname = ArcCW.AttachmentIDTable[attid or 0] or ""
            local atttbl = ArcCW.AttachmentTable[attname]
            if !atttbl then continue end

            wpn:Attach(k, attname, true, true)

            if net.ReadBool() then
                v.SlidePos = net.ReadFloat()
                v.SlidePos = atttbl.MountPositionOverride or v.SlidePos
            else
                v.SlidePos = 0.5
            end

            if atttbl.ToggleStats then
                v.ToggleNum = math.Clamp(net.ReadUInt(8), 1, #atttbl.ToggleStats)
            else
                v.ToggleNum = 1
            end
        end

        wpn:AdjustAtts()

        if ply.ArcCW_Sandbox_FirstSpawn then
            -- Curiously, RestoreAmmo has a sync delay only in singleplayer
            ply.ArcCW_Sandbox_FirstSpawn = nil
            wpn:RestoreAmmo()
        end

        wpn:NetworkWeapon()
        wpn:SetupModel(false)
        wpn:SetupModel(true)

        net.Start("arccw_applypreset")
            net.WriteEntity(wpn)
        net.Send(ply)

    end)
else
    net.Receive("arccw_applypreset", function()
        local wpn = net.ReadEntity()
        if !IsValid(wpn) then return end
        wpn:SavePreset("autosave")
    end)
end

function ArcCW:PlayerSendAttInv(ply)
    if GetConVar("arccw_attinv_free"):GetBool() then return end

    if !IsValid(ply) then return end

    if !ply.ArcCW_AttInv then return end

    net.Start("arccw_sendattinv")

    net.WriteUInt(table.Count(ply.ArcCW_AttInv), 32)

    for att, count in pairs(ply.ArcCW_AttInv) do
        local atttbl = ArcCW.AttachmentTable[att]
        local attid = atttbl.ID
        net.WriteUInt(attid, ArcCW.GetBitNecessity())
        net.WriteUInt(count, 32)
    end

    net.Send(ply)
end

end
