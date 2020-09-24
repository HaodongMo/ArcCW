ArcCW = ArcCW or {}
ArcCW.AttachmentTable = {}
ArcCW.AttachmentIDTable = {}
ArcCW.AttachmentSlotTable = {}
ArcCW.AttachmentBlacklistTable = {}
ArcCW.NumAttachments = 1
ArcCW.GenerateAttEntities = true

local shortname = ""

function ArcCW.LoadAttachmentType(att)
    if !att.Ignore then
        ArcCW.AttachmentTable[shortname] = att
        ArcCW.AttachmentIDTable[ArcCW.NumAttachments] = shortname

        att.Blacklisted = false
        att.ShortName = shortname

        if !ArcCW.AttachmentSlotTable[att.Slot] then
            ArcCW.AttachmentSlotTable[att.Slot] = {}
        end
        table.insert(ArcCW.AttachmentSlotTable[att.Slot], ArcCW.NumAttachments)

        att.ID = ArcCW.NumAttachments

        if ArcCW.GenerateAttEntities and !att.DoNotRegister and !att.InvAtt and !att.Free and !att.Ignore then
            local attent = {}
            attent.Base = "arccw_att_base"
            attent.Icon = att.Icon
            attent.PrintName = att.PrintName or shortname
            attent.Spawnable = att.Spawnable or true
            attent.AdminOnly = att.AdminOnly or false
            attent.Category = "ArcCW - Attachments"
            attent.Model = att.DroppedModel or att.Model or "models/Items/BoxSRounds.mdl"
            attent.GiveAttachments = {
                [att.ShortName] = 1
            }

            for i, k in pairs(att) do
                attent[i] = k
            end

            scripted_ents.Register( attent, "acwatt_" .. shortname )
        end

        ArcCW.NumAttachments = ArcCW.NumAttachments + 1
    end
end

local function ArcCW_SendBlacklist(ply)
    if SERVER then
        -- Only load if table is empty, bruh
        if table.IsEmpty(ArcCW.AttachmentBlacklistTable) then
            ArcCW.AttachmentBlacklistTable = util.JSONToTable(file.Read("arccw_blacklist.txt") or "") or {}
            print("Loaded " .. table.Count(ArcCW.AttachmentBlacklistTable) .. " blacklisted ArcCW attachments.")
        end
        timer.Simple(0, function()
            net.Start("arccw_blacklist")
                net.WriteUInt(table.Count(ArcCW.AttachmentBlacklistTable), ArcCW.GetBitNecessity())
                for attName, bStatus in pairs(ArcCW.AttachmentBlacklistTable) do
                    net.WriteUInt(ArcCW.AttachmentTable[attName].ID, ArcCW.GetBitNecessity())
                end
            if ply then net.Send(ply) else net.Broadcast() end
        end)
    elseif CLIENT and ArcCW.AttachmentBlacklistTable == nil then
        -- Actively request the table, this happens on player load into server once
        net.Start("arccw_blacklist")
            net.WriteBool(true)
        net.SendToServer()
    end
end

local function ArcCW_LoadAtts()
    ArcCW.AttachmentTable = {}
    ArcCW.AttachmentIDTable = {}
    ArcCW.AttachmentSlotTable = {}
    ArcCW.NumAttachments = 1
    ArcCW.AttachmentBits = nil

    for k, v in pairs(file.Find("arccw/shared/attachments/*", "LUA")) do
        att = {}
        shortname = string.sub(v, 1, -5)

        include("arccw/shared/attachments/" .. v)
        AddCSLuaFile("arccw/shared/attachments/" .. v)

        ArcCW.LoadAttachmentType(att)
    end

    print("Loaded " .. tostring(ArcCW.NumAttachments) .. " ArcCW attachments.")

    if !game.SinglePlayer() then
        ArcCW_SendBlacklist()
    else
        -- Simply read the file and do no networking, since both client/server has access to it
        ArcCW.AttachmentBlacklistTable = util.JSONToTable(file.Read("arccw_blacklist.txt") or "") or {}
        for i, v in pairs(ArcCW.AttachmentTable) do
            v.Blacklisted = ArcCW.AttachmentBlacklistTable[i]
        end
        print("Loaded blacklist with " .. table.Count(ArcCW.AttachmentBlacklistTable) .. " attachments.")
    end
end

function ArcCW.GetBitNecessity()
    if !ArcCW.AttachmentBits then
        ArcCW.AttachmentBits = math.min(math.ceil(math.log(ArcCW.NumAttachments + 1, 2)), 32)
    end
    return ArcCW.AttachmentBits
end

ArcCW_LoadAtts()

if CLIENT then

    spawnmenu.AddCreationTab( "#spawnmenu.category.entities", function()

        local ctrl = vgui.Create( "SpawnmenuContentPanel" )
        ctrl:EnableSearch( "entities", "PopulateEntities" )
        ctrl:CallPopulateHook( "PopulateEntities" )

        return ctrl

    end, "icon16/bricks.png", 20 )

    -- Client receives blacklist table from server and updates itself
    net.Receive("arccw_blacklist", function()
        ArcCW.AttachmentBlacklistTable = {}
        local amt = net.ReadUInt(ArcCW.GetBitNecessity())
        for i = 1, amt do
            local id = net.ReadUInt(ArcCW.GetBitNecessity())
            ArcCW.AttachmentBlacklistTable[ArcCW.AttachmentIDTable[id]] = true
        end
        for i, v in pairs(ArcCW.AttachmentTable) do
            v.Blacklisted = ArcCW.AttachmentBlacklistTable[i]
        end
        print("Received blacklist with " .. table.Count(ArcCW.AttachmentBlacklistTable) .. " attachments.")
    end)

    -- Gets around Listen server spawn issues
    hook.Add( "InitPostEntity", "Ready", function()
        net.Start("arccw_blacklist")
            net.WriteBool(true)
        net.SendToServer()
    end )

    concommand.Add("arccw_reloadatts", function()
        if !LocalPlayer():IsSuperAdmin() then return end

        ArcCW_LoadAtts()

        net.Start("arccw_reloadatts")
        net.SendToServer()
    end)

elseif SERVER then

    net.Receive("arccw_reloadatts", function(len, ply)
        if !ply:IsSuperAdmin() then return end

        ArcCW_LoadAtts()
    end)

    local antiSpam = {}
    net.Receive("arccw_blacklist", function(len, ply)

        -- If this message is a request to get blacklist, send it and return
        local isRequest = net.ReadBool()
        if isRequest then
            if antiSpam[ply] and antiSpam[ply] > CurTime() then return end
            -- Debounce client request so they can't attempt to spam netmessages
            antiSpam[ply] = CurTime() + 10

            ArcCW_SendBlacklist(ply)
            return
        elseif !isRequest and !ply:IsAdmin() then
            return
        end

        -- Server receives admin's changes to blacklist table
        local amt = net.ReadUInt(ArcCW.GetBitNecessity())
        ArcCW.AttachmentBlacklistTable = {}
        for i = 1, amt do
            local id = net.ReadUInt(ArcCW.GetBitNecessity())
            local attName = ArcCW.AttachmentIDTable[id]
            if attName and ArcCW.AttachmentTable[attName] then
                ArcCW.AttachmentBlacklistTable[attName] = true
            end
        end
        for i, k in pairs(ArcCW.AttachmentTable) do
            k.Blacklisted = ArcCW.AttachmentBlacklistTable[i] or false
        end
        print("Received blacklist with " .. table.Count(ArcCW.AttachmentBlacklistTable) .. " attachments.")
        file.Write("arccw_blacklist.txt", util.TableToJSON(ArcCW.AttachmentBlacklistTable))
        ArcCW_SendBlacklist()
    end)

end