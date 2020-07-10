ArcCW = ArcCW or {}
ArcCW.AttachmentTable = {}
ArcCW.AttachmentIDTable = {}
ArcCW.AttachmentSlotTable = {}
ArcCW.NumAttachments = 1

ArcCW.GenerateAttEntities = true

shortname = ""

function ArcCW.LoadAttachmentType(att)
    if !att.Ignore then
        ArcCW.AttachmentTable[shortname] = att
        ArcCW.AttachmentIDTable[ArcCW.NumAttachments] = shortname

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
end

function ArcCW.GetBitNecessity()
    if !ArcCW.AttachmentBits then
        ArcCW.AttachmentBits = math.ceil(math.log(ArcCW.NumAttachments, 2))
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
end

hook.Add("PostCleanupMap", "ArcCW_ReloadAttsDebug", function()
    if !GetConVar("arccw_reloadonrefresh"):GetBool() then return end

    ArcCW_LoadAtts()
end)