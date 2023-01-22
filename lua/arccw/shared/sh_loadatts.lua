ArcCW = ArcCW or {}
ArcCW.AttachmentTable = {}
ArcCW.AttachmentIDTable = {}
ArcCW.AttachmentSlotTable = {}
ArcCW.AttachmentBlacklistTable = {}
ArcCW.NumAttachments = 1
ArcCW.GenerateAttEntities = true

ArcCW.AttachmentCachedLists = {}

local shortname = ""
local genAttCvar = GetConVar("arccw_reloadatts_registerentities")

function ArcCW.LoadAttachmentType(att, name)

    name = name or shortname

    if !att.Ignore or GetConVar("arccw_reloadatts_showignored"):GetBool() then
        ArcCW.AttachmentTable[name] = att
        ArcCW.AttachmentIDTable[ArcCW.NumAttachments] = name

        att.Blacklisted = false
        att.ShortName = name

        if !ArcCW.AttachmentSlotTable[att.Slot] then
            ArcCW.AttachmentSlotTable[att.Slot] = {}
        end
        table.insert(ArcCW.AttachmentSlotTable[att.Slot], ArcCW.NumAttachments)

        att.ID = ArcCW.NumAttachments

        if genAttCvar:GetBool() and !att.DoNotRegister and !att.InvAtt and !att.Free then
            local attent = {}
            attent.Base = "arccw_att_base"
            if att.Icon then
                attent.IconOverride = string.Replace( att.Icon:GetTexture( "$basetexture" ):GetName() .. ".png", "0001010", "" )
            end
            attent.PrintName = att.PrintName or name
            attent.Spawnable = att.Spawnable or true
            attent.AdminOnly = att.AdminOnly or false
            attent.Category = att.EntityCategory or "ArcCW - Attachments"
            attent.Model = att.DroppedModel or att.Model or "models/Items/BoxSRounds.mdl"
            attent.GiveAttachments = {
                [att.ShortName] = 1
            }

            scripted_ents.Register( attent, "acwatt_" .. name )
        end

        ArcCW.NumAttachments = ArcCW.NumAttachments + 1

        hook.Run("ArcCW_OnAttLoad", att)
    end
end

local function VerifyBlacklist()
    for attName, v in pairs(ArcCW.AttachmentBlacklistTable) do
        if !ArcCW.AttachmentTable[attName] then
            ArcCW.AttachmentBlacklistTable[attName] = nil
        end
    end
end

local function ArcCW_SendBlacklist(ply)
    if SERVER then
        -- Only load if table is empty, bruh
        if table.IsEmpty(ArcCW.AttachmentBlacklistTable) then
            ArcCW.AttachmentBlacklistTable = util.JSONToTable(file.Read("arccw_blacklist.txt") or "") or {}
            local curcount = table.Count(ArcCW.AttachmentBlacklistTable)
            VerifyBlacklist()
            print("Loaded " .. curcount .. " active (" .. curcount .. " total) blacklisted ArcCW attachments.")
        end
        if ArcCW.AttachmentBlacklistTable and player.GetCount() > 0 then
            timer.Simple(0, function()
                net.Start("arccw_blacklist")
                    net.WriteUInt(table.Count(ArcCW.AttachmentBlacklistTable), ArcCW.GetBitNecessity())
                    for attName, bStatus in pairs(ArcCW.AttachmentBlacklistTable) do
                        net.WriteUInt(ArcCW.AttachmentTable[attName].ID, ArcCW.GetBitNecessity())
                    end
                if ply then net.Send(ply) else net.Broadcast() end
            end)
        end
    elseif CLIENT and ArcCW.AttachmentBlacklistTable == nil then
        -- Actively request the table, this happens on player load into server once
        net.Start("arccw_blacklist")
            net.WriteBool(true)
        net.SendToServer()
    end
end


local attachments_path = "arccw/shared/attachments/"
local bulk_path = "arccw/shared/attachments_bulk/"

local function ArcCW_LoadAtt(att_file)
    att = {} -- Do not bleed over attributes from previous attachments
    --shortname = string.sub(att_file, 1, -5)
    local s = string.Explode("/", att_file)
    shortname = string.sub(s[#s], 1, -5)

    include(att_file)
    AddCSLuaFile(att_file)

    ArcCW.LoadAttachmentType(att)

end

local function ArcCW_LoadFolder(folder)
    folder = folder and (attachments_path .. folder .. "/") or attachments_path
    for k, v in pairs(file.Find(folder .. "*", "LUA")) do
        local yaya, yoyo = pcall(function() ArcCW_LoadAtt(folder .. v) end)
        if !yaya then
            print( "!!!! Attachment " .. v .. " has errors!", yoyo )
            -- Create a stub attachment to prevent customization UI freaking out
            ArcCW.AttachmentTable[shortname] = {
                PrintName = shortname or "ERROR",
                Description = "This attachment failed to load!\nIts file path is: " .. v
            }
        end
    end
end

local function ArcCW_LoadAtts()
    ArcCW.AttachmentTable = {}
    ArcCW.AttachmentIDTable = {}
    ArcCW.AttachmentSlotTable = {}
    ArcCW.NumAttachments = 1
    ArcCW.AttachmentBits = nil
    ArcCW.AttachmentCachedLists = {}

    ArcCW_LoadFolder()
    local _, folders = file.Find(attachments_path .. "/*", "LUA")
    if folders then
        for _, folder in pairs(folders) do
            ArcCW_LoadFolder(folder)
        end
    end

    local bulkfiles = file.Find(bulk_path .. "/*.lua", "LUA")
    for _, filename in pairs(bulkfiles) do
        if filename == "default.lua" then continue end
        local try = pcall(function()
            include(bulk_path .. filename)
            AddCSLuaFile(bulk_path .. filename)
        end)
        if !try then
            print("!!!! Bulk attachment file " .. filename .. " has errors!")
        end
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

    hook.Run("ArcCW_PostLoadAtts")
end

function ArcCW.GetBitNecessity()
    if !ArcCW.AttachmentBits then
        ArcCW.AttachmentBits = math.min(math.ceil(math.log(ArcCW.NumAttachments + 1, 2)), 32)
    end
    return ArcCW.AttachmentBits
end

if CLIENT then
    concommand.Add("arccw_reloadatts", function()
        if !LocalPlayer():IsSuperAdmin() then return end

        net.Start("arccw_reloadatts")
        net.SendToServer()
    end)

    net.Receive("arccw_reloadatts", function(len, ply)
        ArcCW_LoadAtts()
    end)

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
        if !game.SinglePlayer() then
            net.Start("arccw_blacklist")
                net.WriteBool(true)
            net.SendToServer()
        end
    end )
elseif SERVER then
    net.Receive("arccw_reloadatts", function(len, ply)
        if !ply:IsSuperAdmin() then return end

        ArcCW_LoadAtts()

        net.Start("arccw_reloadatts")
        net.Broadcast()
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

hook.Add("PostCleanupMap", "ArcCW_ReloadAttsDebug", function()
    if GetConVar("arccw_reloadatts_mapcleanup"):GetBool() then ArcCW_LoadAtts() end
end)

ArcCW_LoadAtts()
