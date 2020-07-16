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

-- TODO send player blacklist with this function upon request
local function ArcCW_SendBlacklist(ply)
    if SERVER then
        -- ArcCW.AttachmentBlacklistTable = util.JSONToTable(file.Read("arccw_blacklist.txt") or "") or {}
        timer.Simple(0, function()
            net.Start("arccw_blacklist")
                net.WriteUInt(table.Count(ArcCW.AttachmentBlacklistTable), ArcCW.GetBitNecessity())
                for attName, bStatus in pairs(ArcCW.AttachmentBlacklistTable) do
                    net.WriteUInt(ArcCW.AttachmentTable[attName].ID, ArcCW.GetBitNecessity())
                end
            if ply then net.Send(ply) else net.Broadcast() end
        end)
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

    ArcCW_SendBlacklist()
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
    end)

elseif SERVER then

    net.Receive("arccw_blacklist", function(len, ply)
        if !ply:IsAdmin() then return end
        local amt = net.ReadUInt(ArcCW.GetBitNecessity())
        ArcCW.AttachmentBlacklistTable = {}
        for i = 1, amt do
            local id = net.ReadUInt(ArcCW.GetBitNecessity())
            local attName = ArcCW.AttachmentIDTable[id]
            ArcCW.AttachmentBlacklistTable[attName] = true
        end
        for i, k in pairs(ArcCW.AttachmentTable) do
            k.Blacklisted = ArcCW.AttachmentBlacklistTable[i] or false
        end
        file.Write("arccw_blacklist.txt", util.TableToJSON(ArcCW.AttachmentBlacklistTable))
        print("Saved " .. table.Count(ArcCW.AttachmentBlacklistTable) .. " blacklisted attachments to file.")
        ArcCW_SendBlacklist()
    end)

end

hook.Add("PostCleanupMap", "ArcCW_ReloadAttsDebug", function()
    if !GetConVar("arccw_reloadonrefresh"):GetBool() then return end

    ArcCW_LoadAtts()
end)