local translate = ArcCW.GetTranslation

local function ScreenScaleMulti(input)
    return ScreenScale(input) * ArcCW.ConVars["hud_size"]:GetFloat()
end

local temp = 0
local SolidBlack = Color(temp, temp, temp)
-- don't fucking mess with the shadow, makes the menu hurt your goddamn eyes

local function DrawTextRot(span, txt, x, y, tx, ty, maxw, only)
    local tw, th = surface.GetTextSize(txt)

    if tw > maxw then
        local realx, realy = span:LocalToScreen(x, y)
        render.SetScissorRect(realx, realy, realx + maxw, realy + (th * 2), true)

        if !only then
            span.TextRot = span.TextRot or 0
            span.StartTextRot = span.StartTextRot or CurTime()
            span.TextRotState = span.TextRotState or 0 -- 0: start, 1: moving, 2: end
            if span.TextRotState == 0 then
                span.TextRot = 0
                if span.StartTextRot < CurTime() - 2 then
                    span.TextRotState = 1
                end
            elseif span.TextRotState == 1 then
                span.TextRot = span.TextRot + (FrameTime() * ScreenScaleMulti(16))
                if span.TextRot >= (tw - maxw) + ScreenScaleMulti(8) then
                    span.StartTextRot = CurTime()
                    span.TextRotState = 2
                end
            elseif span.TextRotState == 2 then
                if span.StartTextRot < CurTime() - 2 then
                    span.TextRotState = 0
                    span.StartTextRot = CurTime()
                end
            end
        end
        surface.SetTextPos(tx - span.TextRot, ty)
        surface.DrawText(txt)
        render.SetScissorRect(0, 0, 0, 0, false)
    else
        surface.DrawText(txt)
    end
end


function SWEP:ToggleCustomizeHUD(ic)
    if ic and self:GetState() == ArcCW.STATE_SPRINT then return end
    if self:GetReloading() then ic = false end
    if self:GetState() == ArcCW.STATE_DISABLE then return end

    local noinspect = (CLIENT and ArcCW.ConVars["noinspect"]:GetBool()) or (SERVER and self:GetOwner():GetInfoNum("arccw_noinspect", 0) > 0)

    if ic then
        if (self:GetNextPrimaryFire() + 0.1) >= CurTime() then return end

        self:SetState(ArcCW.STATE_CUSTOMIZE)
        self:ExitSights()
        self:SetShouldHoldType()
        self:ExitBipod()
        if !noinspect then
            self:PlayAnimation(self:SelectAnimation("enter_inspect"), nil, true, nil, nil, true, false)
        end

        if CLIENT then
            self:OpenCustomizeHUD()
        end
    else
        self:SetState(ArcCW.STATE_IDLE)
        self.Sighted = false
        self.Sprinted = false
        self:SetShouldHoldType()

        if !noinspect then
            self:PlayAnimation(self:SelectAnimation("exit_inspect"), nil, true, nil, nil, true, false)
        end

        if CLIENT then
            self:CloseCustomizeHUD()
        end
    end
end

if CLIENT then

local function multlinetext(text, maxw, font)
    local content = {}
    local tline = ""
    local x = 0
    surface.SetFont(font)

    local newlined = string.Split(text, "\n")

    for _, line in pairs(newlined) do
        local words = string.Split(line, " ")

        for _, word in pairs(words) do
            local tx = surface.GetTextSize(word)

            if x + tx >= maxw then
                table.insert(content, tline)
                tline = ""
                x = surface.GetTextSize(word)
            end

            tline = tline .. word .. " "

            x = x + surface.GetTextSize(word .. " ")
        end

        table.insert(content, tline)
        tline = ""
        x = 0
    end

    -- local space_len = surface.GetTextSize(" ")

    -- for _, word in pairs(string.Split(text, " ")) do
    --     if word == "\n" then
    --         table.insert(content, line)
    --         line = ""
    --         x = 0
    --     else
    --         x = x + surface.GetTextSize(word)

    --         if x >= limitx then
    --             table.insert(content, line)
    --             line = ""
    --             x = 0
    --             x = x + surface.GetTextSize(word)
    --         end

    --         line = line .. word .. " "

    --         x = x + space_len

    --         -- print(word .. " at " .. tostring(x))
    --     end
    -- end

    -- table.insert(content, line)

    return content
end

-- Same snippet of code in Paint() moved to its own function so the button won't be added if it's not valid to begin with
function SWEP:ValidateAttachment(attname, attslot, i)
    if !self:IsValid() or !self.Attachments then return false end
    local atttbl = ArcCW.AttachmentTable[attname]
    if !atttbl then return true, nil, nil, nil end

    attslot = attslot or self.Attachments[i]

    local show = true
    local showqty = true
    local installed = false
    local blocked = !self:CheckFlags(atttbl.ExcludeFlags, atttbl.RequireFlags)
    local owned = self:PlayerOwnsAtt(attname)

    if !ArcCW:SlotAcceptsAtt(attslot.Slot or "", self, attname) then
        blocked = true
    end

    if !atttbl or atttbl.Free then
        showqty = false
    end

    if ArcCW.ConVars["attinv_free"]:GetBool() then
        showqty = false
    end

    -- if !owned then
    --     showqty = false
    -- end

    if ArcCW.ConVars["attinv_lockmode"]:GetBool() then
        showqty = false
    end

    -- orighas checks if the original slot accepts this attachment.
    -- If the original slot is ok but the mergeslot that has the same attachment is not, we're still okay
    local orighas = ArcCW:SlotAcceptsAtt(self.Attachments[i], self, attname) and self:CheckFlags(self.Attachments[i].ExcludeFlags, self.Attachments[i].RequireFlags)

    if attslot.Installed == attname then
        installed = true
    end

    if attname == "" and !attslot.Installed then
        installed = true

        for _, slot in pairs(attslot.MergeSlots or {}) do
            if self.Attachments[slot].Installed then
                installed = false
                break
            end
        end
    end

    for _, slot in pairs(attslot.MergeSlots or {}) do
        if !slot then continue end
        if !self.Attachments[slot] then continue end
        if !blocked and ArcCW:SlotAcceptsAtt(self.Attachments[slot], self, attname) and
                !self:CheckFlags(self.Attachments[slot].ExcludeFlags, self.Attachments[slot].RequireFlags) and
                !orighas then
            blocked = true
            if self.Attachments[slot].HideIfBlocked then
                show = false
            end
            break
        end
        if self.Attachments[slot].Installed == attname then
            installed = true
            break
        end
    end

    if blocked and atttbl and atttbl.HideIfBlocked then
        show = false
    end

    if !owned and atttbl and atttbl.HideIfUnavailable then
        show = false
    end

    if !owned and ArcCW.ConVars["attinv_hideunowned"]:GetBool() then
        show = false
    end

    return show, installed, blocked, showqty
end

function SWEP:OpenCustomizeHUD()
    if self:GetPriorityAnim() then return end
    if IsValid(ArcCW.InvHUD) then
        ArcCW.InvHUD:Show()
        -- ArcCW.InvHUD:RequestFocus()
    else
        --if GetConVar("arccw_dev_cust2beta"):GetBool() then self:CreateCustomize2HUD() else self:CreateCustomizeHUD() end
        self:CreateCustomize2HUD()
        gui.SetMousePos(ScrW() / 2, ScrH() / 2)
    end

    ArcCW.Inv_Hidden = false
    gui.EnableScreenClicker(true)

    if ArcCW.ConVars["cust_sounds"]:GetBool() then surface.PlaySound("weapons/arccw/extra.wav") end

end

function SWEP:CloseCustomizeHUD( hide )
    if IsValid(ArcCW.InvHUD) then
        --if !GetConVar("arccw_dev_cust2beta"):GetBool() then
        if false then
            ArcCW.InvHUD:Hide()
            ArcCW.InvHUD:Clear()
            if vrmod and vrmod.MenuExists( "ArcCW_Customize" ) then
                vrmod.MenuClose( "ArcCW_Customize" )
            end
            if !hide then
                ArcCW.InvHUD:Remove()
            end
        else
            -- The new hud fades out instead of commiting sudoku, only do this if we're debugging
            if ArcCW.ConVars["dev_removeonclose"]:GetBool() then
                ArcCW.InvHUD:Remove()
            end
        end

        if !hide then
            gui.EnableScreenClicker(false)
        end
        ArcCW.Inv_Hidden = false

        if ArcCW.ConVars["cust_sounds"]:GetBool() then surface.PlaySound("weapons/arccw/extra2.wav") end
    end
end

local defaultatticon = Material("arccw/hud/atts/default.png", "smooth mips")
local blockedatticon = Material("arccw/hud/atts/blocked.png", "smooth mips")
local activeslot = nil
local bird = Material("arccw/hud/arccw_bird.png", "mips smooth")

SWEP.InAttMenu = false

function SWEP:CreateCustomizeHUD()
    local barsize = ScreenScaleMulti(160)
    local airgap = ScreenScaleMulti(16)
    local smallgap = ScreenScaleMulti(2)
    local linesize = ScreenScaleMulti(1)
    local buttonsize = ScreenScaleMulti(32)
    local fg_col = Color(255, 255, 255, 255)
    local bg_col = Color(0, 0, 0, 150)

    if !self:IsValid() then return end

    self.InAttMenu = false
    activeslot = nil

    local scrw, scrh = ScrW(), ScrH()
    if vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
        -- Other resolutions seem to cause stretching issues
        scrw = 1366
        scrh = 768
    end

    ArcCW.InvHUD = vgui.Create("DFrame")

            local scrwmult = ArcCW.ConVars["hud_deadzone_x"]:GetFloat() * ScrW()
            local scrhmult = ArcCW.ConVars["hud_deadzone_y"]:GetFloat() * ScrH()

    scrw, scrh = scrw - scrwmult, scrh - scrhmult

    ArcCW.InvHUD:SetPos(0, 0)
    ArcCW.InvHUD:SetSize(scrw, scrh)
    ArcCW.InvHUD:Center()
    ArcCW.InvHUD:SetText("")
    ArcCW.InvHUD:SetTitle("")
    ArcCW.InvHUD.Paint = function(span)
        if !IsValid(self) then
            gui.EnableScreenClicker(false)
            span:Remove()
        end

        if --[[self:GetState() != ArcCW.STATE_CUSTOMIZE or]] self:GetReloading() then
            span:Remove()
        end
    end
    ArcCW.InvHUD.ActiveWeapon = self
    ArcCW.InvHUD.OnRemove = function()
        local close = false
        if self:IsValid() and self:GetState() == ArcCW.STATE_CUSTOMIZE then
            close = true
        end

        if LocalPlayer():GetActiveWeapon() != ArcCW.InvHUD.ActiveWeapon then
            close = true
        end

        if close then
            net.Start("arccw_togglecustomize")
            net.WriteBool(false)
            net.SendToServer()

            if IsValid(self) and self.ToggleCustomizeHUD then
                self:ToggleCustomizeHUD(false)
            end
        end

        gui.EnableScreenClicker(false)
    end

    if ArcCW.ConVars["attinv_onlyinspect"]:GetBool() then
        return
    end

    local loadpresets = vgui.Create("DButton", ArcCW.InvHUD)
    loadpresets:SetSize((barsize - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
    loadpresets:SetText("")
    loadpresets:SetPos(scrw - barsize - airgap, airgap)

    loadpresets.OnMousePressed = function(spaa, kc)
        self:CreatePresetMenu()
    end

    loadpresets.Paint = function(spaa, w, h)
        if !self:IsValid() then return end
        if !self.Attachments then return end
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 100)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = (translate("ui.loadpreset"))

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(smallgap, ScreenScaleMulti(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local savepresets = vgui.Create("DButton", ArcCW.InvHUD)
    savepresets:SetSize((barsize - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
    savepresets:SetText("")
    savepresets:SetPos(scrw - (barsize / 2) + ScreenScaleMulti(1) - airgap, airgap)

    savepresets.OnMousePressed = function(spaa, kc)
        self:CreatePresetSave()
    end

    savepresets.Paint = function(spaa, w, h)
        if !self:IsValid() then return end
        if !self.Attachments then return end
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 100)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = (translate("ui.savepreset"))

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(smallgap, ScreenScaleMulti(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local attcatsy = scrh - ScreenScaleMulti(64) - airgap

    local attcats = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    attcats:SetText("")
    attcats:SetSize(barsize, attcatsy)
    attcats:SetPos(airgap, airgap)
    attcats.Paint = function(span, w, h)
        -- surface.SetDrawColor(bg_col)
        -- surface.DrawRect(0, 0, w, h)
    end

    local triviabox = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    triviabox:SetText("")
    triviabox:SetSize(barsize, scrh - ScreenScaleMulti(64) - (3 * airgap))
    triviabox:SetPos(scrw - barsize - airgap, 2 * airgap)
    triviabox.Paint = function(span, w, h)
        surface.SetDrawColor(bg_col)
        surface.DrawRect(0, 0, w, h)
    end

    local sbar = attcats:GetVBar()
    sbar.Paint = function() end

    sbar.btnUp.Paint = function(span, w, h)
    end

    sbar.btnDown.Paint = function(span, w, h)
    end

    sbar.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(fg_col)
        surface.DrawRect(0, 0, w, h)
    end

    local wpninfo = attcats:Add("DLabel")
    wpninfo:SetSize(barsize, buttonsize)
    wpninfo:SetText("")
    wpninfo:Dock( TOP )
    wpninfo:DockMargin( 0, 0, 0, smallgap )

    wpninfo.Paint = function(span, w, h)
        if !IsValid(self) then return end
        local Bfg_col = fg_col
        local Bbg_col = bg_col

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)
        surface.DrawRect(0, 0, w, h / 2)

        surface.SetDrawColor(Bfg_col)
        surface.DrawRect(0, (h - linesize) / 2, w, linesize)

        surface.SetTextColor(SolidBlack)
        surface.SetTextPos(smallgap, 0)
        surface.SetFont("ArcCW_12_Glow")
        surface.DrawText(translate("name." .. self:GetClass() .. (ArcCW.ConVars["truenames"]:GetBool() and ".true" or "")) or self.PrintName)

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(smallgap, 0)
        surface.SetFont("ArcCW_12")
        surface.DrawText(translate("name." .. self:GetClass() .. (ArcCW.ConVars["truenames"]:GetBool() and ".true" or "")) or self.PrintName)

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(smallgap * 2, (h - linesize) / 2 + smallgap)
        surface.SetFont("ArcCW_12")

        local pick = self:GetPickX()

        if pick <= 0 then
            surface.DrawText(ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Class") or self.Trivia_Class))
        else
            local txt = self:CountAttachments() .. "/" .. pick .. " Attachments"

            surface.DrawText(txt)
        end
    end

    local statbox = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    statbox:SetText("")
    statbox:SetSize(barsize, scrh - ScreenScaleMulti(64) - (3 * airgap))
    statbox:SetPos(scrw - barsize - airgap, 2 * airgap)
    statbox.Paint = function(span, w, h)
        surface.SetDrawColor(bg_col)
        surface.DrawRect(0, 0, w, h)
    end
    statbox:Hide()
    local regenStatList -- early definition so category unequiping can update

    local sbar3 = statbox:GetVBar()
    sbar3.Paint = function() end

    sbar3.btnUp.Paint = function(span, w, h)
    end

    sbar3.btnDown.Paint = function(span, w, h)
    end

    sbar3.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(fg_col)
        surface.DrawRect(0, 0, w, h)
    end

    local attmenuh = scrh - (2 * airgap)

    local attmenu = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    attmenu:SetText("")
    attmenu:SetSize(barsize + ScreenScaleMulti(12), attmenuh)
    attmenu:SetPos(airgap + barsize + smallgap, airgap)
    attmenu.Paint = function(span, w, h)
        -- surface.SetDrawColor(bg_col)
        -- surface.DrawRect(0, 0, w, h)
    end
    attmenu:Hide()

    local sbar4 = attmenu:GetVBar()
    sbar4.Paint = function() end

    sbar4.btnUp.Paint = function(span, w, h)
    end

    sbar4.btnDown.Paint = function(span, w, h)
    end

    sbar4.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(fg_col)
        surface.DrawRect(0, 0, w, h)
    end

    local attslidebox = vgui.Create("DPanel", ArcCW.InvHUD)
    attslidebox:SetSize(barsize, ScreenScaleMulti(20))
    attslidebox:SetPos(scrw - barsize - airgap, scrh - ScreenScaleMulti(64) - (1 * airgap))
    attslidebox.Paint = function(span, w, h)
        surface.SetDrawColor(bg_col)
        surface.DrawRect(0, 0, w, h)

        surface.SetTextColor(fg_col)
        surface.SetFont("ArcCW_6")
        surface.SetTextPos(smallgap, smallgap)
        surface.DrawText(translate("ui.position"))
    end

    local attslider = vgui.Create("DSlider", attslidebox)
    attslider:SetPos(ScreenScaleMulti(4), ScreenScaleMulti(12))
    attslider:SetSize(barsize - ScreenScaleMulti(4 * 2), ScreenScaleMulti(4))

    attslider.Paint = function(span, w, h)
        surface.SetDrawColor(fg_col)
        surface.DrawRect(0, h / 2, w, ScreenScaleMulti(1))
    end

    local lastslidepos = 0
    local lastsoundtime = 0

    attslider.Knob.Paint = function(span, w, h)
        if !self:IsValid() then return end
        if !self.Attachments then return end

        if span:IsHovered() or attslider:GetDragging() then
            surface.SetDrawColor(fg_col)
            surface.DrawRect((w - ScreenScaleMulti(2)) / 2, 0, ScreenScaleMulti(2), h)
        else
            surface.SetDrawColor(fg_col)
            surface.DrawRect((w - ScreenScaleMulti(1)) / 2, 0, ScreenScaleMulti(1), h)
        end

        if attslider:GetDragging() and activeslot then
            local delta = attslider:GetSlideX()
            if lastslidepos != delta and lastsoundtime <= CurTime() then

                EmitSound("weapons/arccw/dragatt.wav", EyePos(), -2, CHAN_ITEM, 1,75, 0, math.Clamp(delta * 200, 90, 110))

                lastsoundtime = CurTime() + 0.05
            end

            self.Attachments[activeslot].SlidePos = delta
            lastslidepos = delta
        end

        attslider:SetSlideX((self.Attachments[activeslot] or {}).SlidePos or 0.5)
    end

    local og_attsliderknobmr = attslider.Knob.OnMouseReleased

    attslider.Knob.OnMouseReleased = function(span, kc)
        og_attsliderknobmr(span, kc)
        self:SendDetail_SlidePos(activeslot)
        self:SavePreset("autosave")
    end

    attslidebox:Hide()

    local atttogglebtn = vgui.Create("DButton", ArcCW.InvHUD)
    atttogglebtn:SetSize(barsize * 0.25, ScreenScaleMulti(15))
    atttogglebtn:SetPos(scrw - barsize - airgap + barsize * 0.75, scrh - ScreenScaleMulti(64) - (1 * airgap))
    atttogglebtn:SetText("")
    atttogglebtn.OnMousePressed = function(spaa, kc)
        if !self.Attachments[activeslot] then return end
        local catttbl = ArcCW.AttachmentTable[self.Attachments[activeslot].Installed]
        if !catttbl or !catttbl.ToggleStats then return end

        self:ToggleSlot(activeslot)
        --[[]
        self.Attachments[activeslot].ToggleNum = (self.Attachments[activeslot].ToggleNum or 1) + 1
        if self.Attachments[activeslot].ToggleNum > #catttbl.ToggleStats then
            self.Attachments[activeslot].ToggleNum = 1
        end
        self:SendDetail_ToggleNum(activeslot)
        self:AdjustAtts()
        if self:GetHasFlashlights() then
            self:CreateFlashlightsVM()
        end

        EmitSound("weapons/arccw/firemode.wav", EyePos(), -2, CHAN_ITEM, 1,75, 0, 100)
        ]]
    end
    atttogglebtn.Paint = function(spaa, w, h)
        if !self:IsValid() then return end
        if !self.Attachments then return end
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 100)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = (translate("ui.toggle"))
        local catttbl = activeslot and ArcCW.AttachmentTable[self.Attachments[activeslot].Installed]
        if catttbl and catttbl.ToggleStats[self.Attachments[activeslot].ToggleNum]
                and catttbl.ToggleStats[self.Attachments[activeslot].ToggleNum].PrintName then
            txt = ArcCW.TryTranslation(catttbl.ToggleStats[self.Attachments[activeslot].ToggleNum].PrintName)
        end

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(smallgap, ScreenScaleMulti(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    atttogglebtn:Hide()

    local atttrivia = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    atttrivia:SetSize(barsize, scrh - ScreenScaleMulti(116))
    atttrivia:SetPos(scrw - barsize - airgap, 2 * airgap)
    atttrivia.Paint = function(span, w, h)
        surface.SetDrawColor(bg_col)
        surface.DrawRect(0, 0, w, h)
    end
    atttrivia:Hide()

    local sbar5 = atttrivia:GetVBar()
    sbar5.Paint = function() end

    sbar5.btnUp.Paint = function(span, w, h)
    end

    sbar5.btnDown.Paint = function(span, w, h)
    end

    sbar5.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(fg_col)
        surface.DrawRect(0, 0, w, h)
    end

    local last_atttrivia = nil

    local function atttrivia_do(att, slot)

        if !att then
            last_atttrivia = att
            atttrivia:Hide()
            atttrivia:Clear()
            return
        end

        if att == "" then
            last_atttrivia = att
            atttrivia:Hide()
            atttrivia:Clear()
            return
        end

        if att == last_atttrivia then
            last_atttrivia = att
            return
        end

        atttrivia:Clear()

        last_atttrivia = att

        local atttbl = ArcCW.AttachmentTable[att]

        atttrivia:Show()

        -- att name

        local triv_attname = vgui.Create("DLabel", atttrivia)
            triv_attname:SetSize(barsize, ScreenScaleMulti(16))
            triv_attname:Dock(TOP)
            triv_attname:DockMargin( 0, 0, 0, 0 )
            triv_attname:SetText("")
            triv_attname.Paint = function(span, w, h)
                local txt = multlinetext(translate("name." .. att) or atttbl.PrintName, w, "ArcCW_16")

                c = 0

                for _, i in pairs(txt) do
                    surface.SetFont("ArcCW_16")
                    local tw = surface.GetTextSize(i)

                    surface.SetFont("ArcCW_16_Glow")
                    surface.SetTextPos((smallgap + (w - tw)) / 2, c)
                    surface.SetTextColor(SolidBlack)
                    surface.DrawText(i)

                    surface.SetFont("ArcCW_16")
                    surface.SetTextPos((smallgap + (w - tw)) / 2, c)
                    surface.SetTextColor(fg_col)
                    surface.DrawText(i)

                    c = c + ScreenScaleMulti(16)
                end

                span:SetSize(barsize, c)
            end

        -- att pic

        local triv_pic = vgui.Create("DLabel", atttrivia)
            triv_pic:SetSize(barsize, barsize / 2)
            triv_pic:Dock(TOP)
            triv_pic:DockMargin( 0, 0, 0, smallgap )
            triv_pic:SetText("")
            triv_pic.Paint = function(span, w, h)
                local img = atttbl.Icon or defaultatticon
                if !img or img:IsError() then img = bird end

                surface.SetDrawColor(fg_col)
                surface.SetMaterial(img)
                surface.DrawTexturedRect(h / 2, 0, h, h)
            end

        -- att desc

        desctext = multlinetext(translate("desc." .. att) or atttbl.Description, barsize - smallgap * 2, "ArcCW_8")

        local triv_desc = vgui.Create("DLabel", atttrivia)
        triv_desc:SetSize(barsize, ScreenScaleMulti(8) * (table.Count(desctext) + 1))
        triv_desc:SetText("")
        triv_desc:DockMargin( 0, 0, 0, smallgap )
        triv_desc:Dock(TOP)
        triv_desc.Paint = function(span, w, h)
            local y = ScreenScaleMulti(8)
            for i, line in pairs(desctext) do
                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap * 2, y)
                surface.SetTextColor(fg_col)
                surface.DrawText(line)
                y = y + ScreenScaleMulti(8)
            end
        end

        local neutrals = atttbl.Desc_Neutrals or {}

        local pros, cons = ArcCW:GetProsCons(self, atttbl, self.Attachments[slot].ToggleNum)

        if (pros and #pros or 0) > 0 then

            local triv_pros = vgui.Create("DLabel", atttrivia)
            triv_pros:SetSize(barsize, ScreenScaleMulti(10))
            triv_pros:SetText("")
            triv_pros:Dock(TOP)
            triv_pros.Paint = function(span, w, h)
                surface.SetDrawColor(Color(0, 50, 0, 100))
                surface.DrawRect(0, 0, w, h)

                surface.SetTextColor(Color(125, 200, 125))
                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap, 0)
                surface.DrawText(translate("ui.positives"))
            end

            for _, i in pairs(pros) do
                local triv_pro = vgui.Create("DLabel", atttrivia)
                triv_pro:SetSize(barsize, ScreenScaleMulti(10))
                triv_pro:SetText("")
                triv_pro:Dock(TOP)
                triv_pro.Paint = function(span, w, h)

                    surface.SetTextColor(Color(150, 225, 150))
                    surface.SetFont("ArcCW_8")
                    surface.SetTextPos(smallgap, 0)
                    surface.DrawText(i)
                end
            end
        end

        if (cons and #cons or 0) > 0 then
            local triv_cons = vgui.Create("DLabel", atttrivia)
            triv_cons:SetSize(barsize, ScreenScaleMulti(10))
            triv_cons:SetText("")
            triv_cons:Dock(TOP)
            triv_cons.Paint = function(span, w, h)
                surface.SetDrawColor(Color(50, 0, 0, 100))
                surface.DrawRect(0, 0, w, h)

                surface.SetTextColor(Color(200, 125, 125))
                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap, 0)
                surface.DrawText(translate("ui.negatives"))
            end

            for _, i in pairs(cons) do
                local triv_con = vgui.Create("DLabel", atttrivia)
                triv_con:SetSize(barsize, ScreenScaleMulti(10))
                triv_con:SetText("")
                triv_con:Dock(TOP)
                triv_con.Paint = function(span, w, h)

                    surface.SetTextColor(Color(225, 150, 150))
                    surface.SetFont("ArcCW_8")
                    surface.SetTextPos(smallgap, 0)
                    surface.DrawText(i)
                end
            end
        end

        if #neutrals > 0 then

            local triv_neutrals = vgui.Create("DLabel", atttrivia)
            triv_neutrals:SetSize(barsize, ScreenScaleMulti(10))
            triv_neutrals:SetText("")
            triv_neutrals:Dock(TOP)
            triv_neutrals.Paint = function(span, w, h)
                surface.SetDrawColor(Color(0, 0, 50, 100))
                surface.DrawRect(0, 0, w, h)

                surface.SetTextColor(Color(125, 125, 200))
                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap, 0)
                surface.DrawText(translate("ui.information"))
            end

            for _, i in pairs(neutrals) do
                local triv_neutral = vgui.Create("DLabel", atttrivia)
                triv_neutral:SetSize(barsize, ScreenScaleMulti(10))
                triv_neutral:SetText("")
                triv_neutral:Dock(TOP)
                triv_neutral.Paint = function(span, w, h)

                    surface.SetTextColor(Color(150, 150, 225))
                    surface.SetFont("ArcCW_8")
                    surface.SetTextPos(smallgap, 0)
                    surface.DrawText(ArcCW.TryTranslation(i))
                end
            end
        end
    end

    ArcCW.InvHUD.OnMousePressed = function(span, kc)
        if (kc == MOUSE_LEFT or kc == MOUSE_RIGHT) and
                !triviabox:IsVisible() and !statbox:IsVisible() then
            activeslot = nil
            triviabox:Show()
            statbox:Hide()
            attmenu:Hide()
            self.InAttMenu = false
            atttrivia:Hide()
            attslidebox:Hide()
            atttogglebtn:Hide()
            if ArcCW.ConVars["cust_sounds"]:GetBool() then surface.PlaySound("weapons/arccw/close.wav") end
        end
    end

    for i, k in pairs(self.Attachments) do
        if !k.PrintName then continue end
        if i == "BaseClass" then continue end
        if k.Hidden or k.Blacklisted then continue end
        if k.Integral then continue end

        local attcatb = attcats:Add("DButton")
        if ArcCW.ConVars["hud_embracetradition"]:GetBool() then
            attcatb:SetSize(barsize, buttonsize )
        else
            attcatb:SetSize(barsize, buttonsize / 2)
        end
        attcatb:SetText("")
        attcatb:Dock( TOP )
        attcatb:DockMargin( 0, 0, 0, smallgap )

        attcatb.AttIndex = i
        attcatb.AttSlot = k

        local function attcatb_regen(span)
            local catt = self.Attachments[span.AttIndex].Installed
            local catttbl
            if catt then
                catttbl = ArcCW.AttachmentTable[catt]
            end

            if self.Attachments[span.AttIndex].Installed and self.Attachments[span.AttIndex].SlideAmount and !catttbl.MountPositionOverride then
                attslidebox:Show()
            else
                attslidebox:Hide()
            end

            if self.Attachments[span.AttIndex].Installed and catttbl and catttbl.ToggleStats then
                if attslidebox:IsVisible() then
                    atttogglebtn:SetPos(scrw - barsize - airgap + barsize * 0.75, scrh - ScreenScaleMulti(40) - (1 * airgap))
                else
                    atttogglebtn:SetPos(scrw - barsize - airgap + barsize * 0.75, scrh - ScreenScaleMulti(64) - (1 * airgap))
                end
                atttogglebtn:Show()
            else
                atttogglebtn:Hide()
            end

            attmenu:Clear()

            local atts = {}
            local slots = {i}
            local attCheck = {}

            table.Add(slots, k.MergeSlots or {})

            for _, y in pairs(slots) do
                for _, bruh in pairs(ArcCW:GetAttsForSlot((self.Attachments[y] or {}).Slot, self)) do
                    if attCheck[bruh] then continue end
                    table.insert(atts, {
                        att = bruh,
                        slot = y
                    })
                    attCheck[bruh] = true
                end
            end

            atts[0] = ""

            table.sort(atts, function(a, b)
                a = a.att or ""
                b = b.att or ""
                local atttbl_a = ArcCW.AttachmentTable[a]
                local atttbl_b = ArcCW.AttachmentTable[b]

                local order_a = 0
                local order_b = 0

                order_a = atttbl_a.SortOrder or order_a
                order_b = atttbl_b.SortOrder or order_b

                if order_a == order_b then
                    return (translate("name." .. a) or atttbl_a.PrintName or "") > (translate("name." .. b) or atttbl_b.PrintName or "")
                end

                return order_a > order_b
            end)

            local ca = 0

            for _, att in pairs(atts) do
                local aslot = att
                if istable(att) then
                    aslot = aslot.slot
                    att = att.att
                end
                local owned = self:PlayerOwnsAtt(att)

                if !owned and ArcCW.ConVars["attinv_hideunowned"]:GetBool() then continue end

                local valid, installed, blocked, showqty = self:ValidateAttachment(att, k, i)

                if !valid then continue end

                local attbtn = attmenu:Add("DButton")
                attbtn:SetSize(barsize + ScreenScaleMulti(12), ScreenScaleMulti(14))
                attbtn:SetText("")
                attbtn:Dock( TOP )
                attbtn:DockMargin( 0, 0, 0, smallgap )

                ca = ca + 1

                attbtn.AttName = att

                attbtn.OnMousePressed = function(spaa, kc2)

                    owned = self:PlayerOwnsAtt(spaa.AttName)
                    local installed = false
                    local orighas = ArcCW:SlotAcceptsAtt(self.Attachments[i], self, spaa.AttName) and self:CheckFlags(self.Attachments[i].ExcludeFlags, self.Attachments[i].RequireFlags)

                    local atttbl = ArcCW.AttachmentTable[spaa.AttName]
                    if atttbl then
                        if !self:CheckFlags(atttbl.ExcludeFlags, atttbl.RequireFlags) then return end
                        for _, slot in pairs(k.MergeSlots or {}) do
                            if self.Attachments[slot].Installed then
                                installed = true
                            end

                            if slot and self.Attachments[slot] and
                                    ArcCW:SlotAcceptsAtt(self.Attachments[slot], self, spaa.AttName) and
                                    !self:CheckFlags(self.Attachments[slot].ExcludeFlags, self.Attachments[slot].RequireFlags) and
                                    !orighas then
                                return
                            end
                        end
                    end

                    if kc2 == MOUSE_LEFT and owned then

                        if spaa.AttName == "" then
                            self:DetachAllMergeSlots(span.AttIndex)
                        else
                            self:DetachAllMergeSlots(span.AttIndex, true)
                            self:Attach(aslot, spaa.AttName)
                        end
                    elseif kc2 == MOUSE_RIGHT and spaa.AttName != "" then
                        if span.AttSlot.Installed == spaa.AttName then
                            -- Unequip
                            self:DetachAllMergeSlots(span.AttIndex)
                        elseif installed then
                            self:DetachAllMergeSlots(span.AttIndex)
                        elseif owned then
                            -- Drop attachment
                            if ArcCW.ConVars["attinv_free"]:GetBool() then return end
                            if ArcCW.ConVars["attinv_lockmode"]:GetBool() then return end
                            if ArcCW.ConVars["enable_customization"]:GetInt() < 0 then return end
                            if !ArcCW.ConVars["enable_dropping"]:GetBool() then return end

                            net.Start("arccw_asktodrop")
                                net.WriteUInt(ArcCW.AttachmentTable[spaa.AttName].ID, 24)
                            net.SendToServer()

                            ArcCW:PlayerTakeAtt(self:GetOwner(), spaa.AttName)
                        end
                    end

                    attcatb_regen(span)
                end

                attbtn.Paint = function(spaa, w, h)
                    if !self:IsValid() then return end
                    if !self.Attachments then return end
                    local Bfg_col = Color(255, 255, 255, 255)
                    local Bbg_col = Color(0, 0, 0, 100)
                    local atttbl = ArcCW.AttachmentTable[spaa.AttName]
                    local qty = ArcCW:PlayerGetAtts(self:GetOwner(), spaa.AttName)

                    valid, installed, blocked, showqty = self:ValidateAttachment(att, k, i)
                    if !valid then
                        attbtn:Remove()
                        return
                    end

                    owned = self:PlayerOwnsAtt(spaa.AttName)

                    if !atttbl and ArcCW.AttachmentTable[k.EmptyFallback] then
                        atttbl = ArcCW.AttachmentTable[k.EmptyFallback]
                    elseif !atttbl then
                        atttbl = {
                            PrintName = k.DefaultAttName and ArcCW.TryTranslation(k.DefaultAttName) or translate("attslot.noatt"),
                            Icon = k.DefaultAttIcon or defaultatticon,
                            Free = true
                        }
                    end

                    if spaa:IsHovered() or installed then
                        Bbg_col = Color(255, 255, 255, 100)
                        Bfg_col = Color(0, 0, 0, 255)
                    end

                    if spaa:IsHovered() and installed then
                        Bbg_col = Color(255, 255, 255, 200)
                        Bfg_col = Color(0, 0, 0, 255)
                    end

                    if spaa:IsHovered() then
                        atttrivia_do(spaa.AttName, i)
                    end

                    if !owned and ArcCW.ConVars["attinv_darkunowned"]:GetBool() then
                        if spaa:IsHovered() then
                            Bbg_col = Color(50, 50, 50, 150)
                            Bfg_col = Color(150, 150, 150, 255)
                        else
                            Bbg_col = Color(20, 20, 20, 150)
                            Bfg_col = Color(150, 150, 150, 255)
                        end
                    elseif !owned or blocked then
                        if spaa:IsHovered() then
                            Bbg_col = Color(125, 25, 25, 150)
                            Bfg_col = Color(150, 50, 50, 255)
                        else
                            Bbg_col = Color(75, 0, 0, 150)
                            Bfg_col = Color(150, 50, 50, 255)
                        end
                    end

                    local max = atttbl.Max

                    if max then
                        local amt = 0

                        for i2, k2 in pairs(self.Attachments) do
                            if k2.Installed == spaa.AttName then
                                amt = amt + 1
                            end
                        end

                        if amt >= max and self.Attachments[i].Installed != spaa.AttName then
                            if spaa:IsHovered() then
                                Bbg_col = Color(125, 25, 25, 150)
                                Bfg_col = Color(150, 50, 50, 255)
                            else
                                Bbg_col = Color(75, 0, 0, 150)
                                Bfg_col = Color(150, 50, 50, 255)
                            end
                        end
                    end

                    surface.SetDrawColor(Bbg_col)
                    surface.DrawRect(0, 0, w, h)
                    surface.DrawRect(0, 0, h * 1.5, h)

                    surface.SetDrawColor(Bfg_col)
                    surface.DrawRect((h * 1.5) - (linesize / 2), 0, linesize, h)

                    local txt = translate("name." .. spaa.AttName) or atttbl.PrintName or "???"

                    if showqty then
                        txt = txt .. " (" .. tostring(qty) .. ")"
                    end

                    surface.SetTextColor(Bfg_col)
                    surface.SetTextPos((h * 1.5) + smallgap, ScreenScaleMulti(1))
                    surface.SetFont("ArcCW_12")

                    DrawTextRot(spaa, txt, h * 1.5, 0, (h * 1.5) + smallgap, ScreenScaleMulti(1), w - (h * 1.5))

                    -- surface.DrawText(txt)

                    local icon = k.DefaultAttIcon or defaultatticon
                    if atttbl then
                        icon = atttbl.Icon
                    end
                    if (!icon or icon:IsError()) then icon = bird end

                    surface.SetDrawColor(Bfg_col)
                    surface.SetMaterial(icon)
                    surface.DrawTexturedRect(h / 4, 0, h, h)

                    if blocked then
                        surface.SetDrawColor(color_white)
                        surface.SetMaterial(blockedatticon)
                        surface.DrawTexturedRect(h / 4 - h * 0.1, - h * 0.1, h * 1.2, h * 1.2)
                    end
                end
            end

            local specsize = ca * (ScreenScaleMulti(14) + smallgap)

            attmenu:SetSize(barsize + ScreenScaleMulti(12), math.min(specsize, attmenuh))
        end

        attcatb.OnMousePressed = function(span, kc)
            if !self:CheckFlags(span.AttSlot.ExcludeFlags, span.AttSlot.RequireFlags) then
                return
            end

            if kc == MOUSE_LEFT then
                if activeslot == span.AttIndex then
                    activeslot = nil
                    triviabox:Show()
                    statbox:Hide()
                    attmenu:Hide()
                    self.InAttMenu = false
                    atttrivia:Hide()
                    attslidebox:Hide()
                    atttogglebtn:Hide()
                    surface.PlaySound("weapons/arccw/close.wav")
                else
                    activeslot = span.AttIndex
                    triviabox:Hide()
                    statbox:Hide()
                    attmenu:Show()
                    attslider:SetSlideX(self.Attachments[span.AttIndex].SlidePos)
                    lastslidepos = self.Attachments[span.AttIndex].SlidePos
                    self.InAttMenu = true
                    surface.PlaySound("weapons/arccw/open.wav")

                    span.TextRot = 0
                    span.StartTextRot = CurTime()
                    span.TextRotState = 0

                    if self.Attachments[span.AttIndex].Installed then
                        atttrivia_do(self.Attachments[span.AttIndex].Installed, span.AttIndex)
                    end

                    attcatb_regen(span)
                end
            elseif kc == MOUSE_RIGHT then
                self:DetachAllMergeSlots(span.AttIndex)
                attcatb_regen(span)
                if statbox:IsVisible() then
                    regenStatList()
                end
            end
        end

        attcatb.Paint = function(span, w, h)

            -- Might error when player dies
            if !self or !self.Attachments then return end

            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 100)

            if span:IsHovered() or activeslot == span.AttIndex then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            if span:IsHovered() and activeslot == span.AttIndex then
                Bbg_col = Color(255, 255, 255, 200)
                Bfg_col = Color(0, 0, 0, 255)
            end

            if self.CheckFlags and !self:CheckFlags(span.AttSlot.ExcludeFlags, span.AttSlot.RequireFlags) then
                Bbg_col = Color(75, 0, 0, 150)
                Bfg_col = Color(150, 50, 50, 255)
            end

            local txt =  ArcCW.TryTranslation(k.PrintName)

            local att_txt = k.DefaultAttName and ArcCW.TryTranslation(k.DefaultAttName) or translate("attslot.noatt")
            local att_icon = k.DefaultAttIcon or defaultatticon

            local installed = k.Installed

            if !installed then
                (k.MergeSlots or {})["BaseClass"] = nil
                for _, slot in pairs(k.MergeSlots or {}) do
                    if self.Attachments[slot] and self.Attachments[slot].Installed then
                        installed = self.Attachments[slot].Installed
                        break
                    elseif !self.Attachments[slot] then
                        print("ERROR! No attachment " .. tostring(slot))
                    end
                end
            end

            if installed then
                local atttbl = ArcCW.AttachmentTable[installed]

                if atttbl.Health then
                    local perc = (self:GetAttachmentHP(i) / self:GetAttachmentMaxHP(i)) * 100
                    perc = math.Round(perc)
                    txt = txt .. " (" .. tostring(perc) .. "%)"
                end
                if !ArcCW.ConVars["hud_embracetradition"]:GetBool() then
                    att_txt = translate("name." .. installed) or atttbl.PrintName

                    if atttbl.Icon then
                        att_icon = atttbl.Icon
                        if (!att_icon or att_icon:IsError()) then att_icon = bird end
                    end
                end
            end

            if ArcCW.ConVars["hud_embracetradition"]:GetBool() then
                surface.SetDrawColor(Bbg_col)
                surface.DrawRect(0, 0, w, h)
                surface.DrawRect(0, 0, w, h / 2)
                surface.DrawRect(w - (1.5 * h), h / 2, 1.5 * h, h / 2)

                surface.SetDrawColor(Bbg_col)
                surface.DrawRect(0, 0, w, h)
                surface.DrawRect(0, 0, w, h / 2)
                surface.DrawRect(w - (1.5 * h), h / 2, 1.5 * h, h / 2)

                surface.SetDrawColor(Bfg_col)
                surface.DrawRect(0, (h - linesize) / 2, w - (1.5 * h), linesize)

                surface.SetTextColor(SolidBlack)
                surface.SetTextPos(smallgap, 0)
                surface.SetFont("ArcCW_12_Glow")
                surface.DrawText(txt)

                surface.SetTextColor(Bfg_col)
                surface.SetTextPos(smallgap, 0)
                surface.SetFont("ArcCW_12")
                surface.DrawText(txt)

                if installed then
                    local atttbl = ArcCW.AttachmentTable[installed]

                    att_txt = translate("name." .. installed) or atttbl.PrintName

                    if atttbl.Icon then
                        att_icon = atttbl.Icon
                        if (!att_icon or att_icon:IsError()) then att_icon = bird end
                    end
                end

                surface.SetTextColor(Bfg_col)
                surface.SetTextPos(smallgap * 2, (h - linesize) / 2 + smallgap)
                surface.SetFont("ArcCW_12")
                DrawTextRot(span, att_txt, 0, h / 2, smallgap * 2, (h - linesize) / 2 + smallgap, w - 1.5 * h)

                surface.SetDrawColor(Bfg_col)
                surface.DrawRect(w - (1.5 * h), 0, linesize, h)

                surface.SetDrawColor(Bfg_col)
                surface.SetMaterial(att_icon)
                surface.DrawTexturedRect(w - (1.25 * h), 0, h, h)
            ----------------------------------------------------------------------
            elseif activeslot == span.AttIndex then
                span:SetSize(barsize, buttonsize)

                surface.SetDrawColor(Bbg_col)
                surface.DrawRect(0, 0, w, h)
                surface.DrawRect(0, 0, w, h / 2)
                surface.DrawRect(w - (1.5 * h), h / 2, 1.5 * h, h / 2)

                surface.SetDrawColor(Bfg_col)
                surface.DrawRect(0, (h - linesize) / 2, w - (1.5 * h), linesize)

                surface.SetTextColor(SolidBlack)
                surface.SetTextPos(smallgap, 0)
                surface.SetFont("ArcCW_12_Glow")
                surface.DrawText(txt)

                surface.SetTextColor(Bfg_col)
                surface.SetTextPos(smallgap, 0)
                surface.SetFont("ArcCW_12")
                surface.DrawText(txt)

                surface.SetTextColor(Bfg_col)
                surface.SetTextPos(smallgap * 2, (h - linesize) / 2 + smallgap)
                surface.SetFont("ArcCW_12")

                DrawTextRot(span, att_txt, 0, h / 2, smallgap * 2, (h - linesize) / 2 + smallgap, w - 1.5 * h)

                surface.SetDrawColor(Bfg_col)
                surface.DrawRect(w - (1.5 * h), 0, linesize, h)

                surface.SetDrawColor(Bfg_col)
                surface.SetMaterial(att_icon)
                surface.DrawTexturedRect(w - (1.25 * h), 0, h, h)
            else
                if installed then
                    local atttbl = ArcCW.AttachmentTable[installed]
                    txt = att_txt

                    if atttbl.Health then
                        local perc = (self:GetAttachmentHP(i) / self:GetAttachmentMaxHP(i)) * 100
                        perc = math.Round(perc)
                        txt = txt .. " (" .. tostring(perc) .. "%)"
                    end
                end

                span:SetSize(barsize, buttonsize / 2)

                surface.SetDrawColor(Bbg_col)
                surface.DrawRect(0, 0, w, h)
                surface.DrawRect(w - (1.5 * h), 0, 1.5 * h, h)

                surface.SetTextColor(SolidBlack)
                surface.SetTextPos(smallgap, 0)
                surface.SetFont("ArcCW_12_Glow")
                -- surface.DrawText(txt)
                DrawTextRot(span, txt, 0, 0, smallgap, 0, w - 1.5 * h)

                surface.SetTextColor(Bfg_col)
                surface.SetTextPos(smallgap, 0)
                surface.SetFont("ArcCW_12")
                DrawTextRot(span, txt, 0, 0, smallgap, 0, w - 1.5 * h, true)

                surface.SetDrawColor(Bfg_col)
                surface.DrawRect(w - (1.5 * h), 0, linesize, h)

                surface.SetDrawColor(Bfg_col)
                surface.SetMaterial(att_icon)
                surface.DrawTexturedRect(w - (1.25 * h), 0, h, h)
            end
        end
    end

    local sbar2 = triviabox:GetVBar()
    sbar2.Paint = function() end

    sbar2.btnUp.Paint = function(span, w, h)
    end

    sbar2.btnDown.Paint = function(span, w, h)
    end

    sbar2.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(fg_col)
        surface.DrawRect(0, 0, w, h)
    end

    local triv_wpnnamelabel = vgui.Create("DLabel", triviabox)
    triv_wpnnamelabel:SetSize(barsize, buttonsize)
    triv_wpnnamelabel:Dock(TOP)
    triv_wpnnamelabel:DockMargin( 0, 0, 0, smallgap )
    triv_wpnnamelabel:SetText("")
    triv_wpnnamelabel.Paint = function(span, w, h)
        if !IsValid(self) then return end
        local txt = translate("name." .. self:GetClass()) or self.PrintName

        surface.SetFont("ArcCW_20")
        local tw, th = surface.GetTextSize(txt)

        surface.SetFont("ArcCW_20_Glow")
        surface.SetTextPos((w - tw) / 2, th / 2)
        surface.SetTextColor(SolidBlack)
        surface.DrawText(txt)

        surface.SetFont("ArcCW_20")
        surface.SetTextPos((w - tw) / 2, th / 2)
        surface.SetTextColor(fg_col)
        surface.DrawText(txt)
    end

    local year = self:GetBuff_Override("Override_Trivia_Year") or self.Trivia_Year

    if isnumber(year) and year < 0 then
        year = tostring(math.abs(year)) .. "BC"
    end

    year = tostring(year)

    local trivia = {
        function() return translate("trivia.class") .. ": " .. ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Class") or self.Trivia_Class) or "Unknown" end,
        function() return translate("trivia.year") .. ": " .. year or "Unknown" end,
        function() return translate("trivia.mechanism") .. ": " .. ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Mechanism") or self.Trivia_Mechanism or "Unknown") end,
        function() return translate("trivia.calibre") .. ": " .. ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Calibre") or self.Trivia_Calibre or "Unknown") end,
        function() return translate("trivia.ammo") .. ": " .. language.GetPhrase(self.Primary.Ammo or self.PrintName) end,
        function() return translate("trivia.country") .. ": " .. ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Country") or self.Trivia_Country or "Unknown") end,
        function() return translate("trivia.manufacturer") .. ": " .. ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Manufacturer") or self.Trivia_Manufacturer or "Unknown") end,
        function() return translate("trivia.clipsize") .. ": " .. self:GetCapacity() end,
        function() return translate("trivia.precision") .. ": " .. self:GetBuff("AccuracyMOA") .. " MOA" end,
        function() return translate("trivia.noise") .. ": " .. (self:GetBuff("ShootVol")) .. "dB" end,
        function() return translate("trivia.recoil") .. ": " .. math.Truncate(self.Recoil * 41.4 * self:GetBuff_Mult("Mult_Recoil"), 1) .. " lb-fps" end,
        function() return translate("trivia.penetration") .. ": " .. math.Round(self:GetBuff("Penetration"), 1) .. "mm" end,
    }

    if !self.ManualAction and !self:GetBuff_Override("Override_ManualAction") then
        table.insert(trivia, function()
            local rpm = math.Round(60 / self:GetFiringDelay())
            return translate("trivia.firerate") .. ": " .. rpm .. "RPM"
        end)
    end

    if !(self:GetBuff_Override("Override_Trivia_Class") or self.Trivia_Class) then
        trivia[1] = nil
    end

    if !(self:GetBuff_Override("Override_Trivia_Year") or self.Trivia_Year) then
        trivia[2] = nil
    end

    if !(self:GetBuff_Override("Override_Trivia_Mechanism") or self.Trivia_Mechanism) then
        trivia[3] = nil
    end

    if !(self:GetBuff_Override("Override_Trivia_Calibre") or self.Trivia_Calibre) then
        trivia[4] = nil
    end

    if !(self:GetBuff_Override("Override_Trivia_Country") or self.Trivia_Country) then
        trivia[6] = nil
    end

    if !(self:GetBuff_Override("Override_Trivia_Manufacturer") or self.Trivia_Manufacturer) then
        trivia[7] = nil
    end

    if self.PrimaryBash then
        trivia[4] = nil
        trivia[5] = nil
        trivia[8] = nil
        trivia[9] = nil
        trivia[10] = nil
        trivia[11] = nil
        trivia[12] = nil
        trivia[13] = nil
    end

    if self.Throwing then
        trivia[4] = nil
        trivia[8] = nil
        trivia[9] = nil
        trivia[10] = nil
        trivia[11] = nil
        trivia[12] = nil
        trivia[13] = nil
    end

    local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

    if ft then
        table.insert(trivia, function() return translate("trivia.fusetime") .. ": " .. tostring(ft) end)
    end

    for _, i in pairs(trivia) do
        if !i then continue end
        local triv_misc = vgui.Create("DLabel", triviabox)
        triv_misc:SetSize(barsize, ScreenScaleMulti(8))
        triv_misc:Dock(TOP)
        triv_misc:SetText("")
        triv_misc:DockMargin( 0, 0, 0, 0 )
        triv_misc.Paint = function(span, w, h)
            if !IsValid(self) then return end
            local txt = i()

            surface.SetFont("ArcCW_8")
            surface.SetTextPos(smallgap, 0)
            surface.SetTextColor(fg_col)
            surface.DrawText(txt)
        end
    end

    -- multlinetext(text, maxw, font)

    local adesctext = multlinetext(ArcCW.TryTranslation(self:GetBuff_Override("Override_Trivia_Desc")) or translate("desc." .. self:GetClass()) or self.Trivia_Desc, barsize - smallgap, "ArcCW_8")

    table.insert(adesctext, "")

    local triv_desc = vgui.Create("DLabel", triviabox)
    triv_desc:SetSize(barsize, ScreenScaleMulti(8) * (table.Count(adesctext) + 1))
    triv_desc:SetText("")
    triv_desc:Dock(TOP)
    triv_desc.Paint = function(span, w, h)
        local y = ScreenScaleMulti(8)
        for _, line in pairs(adesctext) do
            surface.SetFont("ArcCW_8")
            surface.SetTextPos(smallgap, y)
            surface.SetTextColor(fg_col)
            surface.DrawText(line)
            y = y + ScreenScaleMulti(8)
        end
    end

    if !self.ShootEntity and !self.PrimaryBash and !self.Throwing and !self.NoRangeGraph then
        local rangegraph = vgui.Create("DLabel", triviabox)
        rangegraph:SetSize(barsize, ScreenScaleMulti(64))
        rangegraph:SetText("")
        rangegraph:Dock(TOP)
        rangegraph.Paint = function(span, w, h)
            if !IsValid(self) then return end
            local sidegap = 0
            local gx, gy = 0, smallgap
            local gw, gh = w - (2 * sidegap), h - smallgap - ScreenScaleMulti(6)

            local dmgmax = math.Round(self:GetDamage(0))
            local dmgmin = math.Round(self:GetDamage(math.huge))

            local grsh = math.max(dmgmax, dmgmin)

            grsh = math.ceil((grsh / 12) + 1) * 12

            local mingr = self.RangeMin * self:GetBuff_Mult("Mult_Range") * self:GetBuff_Mult("Mult_RangeMin")
            local maxgr = self.Range * self:GetBuff_Mult("Mult_Range")

            if dmgmax < dmgmin then
                maxgr = (self.Range / self:GetBuff_Mult("Mult_Range"))
            end

            maxgr = math.Round(maxgr)

            local grsw = math.ceil((maxgr / 12) + 1) * 12

            local convw = gw / grsw
            local convh = gh / grsh

            local starty = gh - (dmgmax * convh)
            local endy = gh - (dmgmin * convh)
            local startx = mingr * convw
            local endx = maxgr * convw

            surface.SetDrawColor(bg_col)
            surface.DrawRect(gx, gy, gw, gh)

            surface.SetDrawColor(fg_col)

            -- start
            surface.DrawLine(0, gy + starty, gx + startx, gy + starty)
            -- before mid
            surface.DrawLine(gx + startx, gy + starty, gx + endx, gy + endy)
            if mingr != 0 then
                surface.DrawLine(gx + startx, gy+ScreenScaleMulti(2) + starty, gx + startx, gy-ScreenScaleMulti(2) + starty)
            end
            -- long and into the void
            surface.DrawLine(gx + endx, gy + endy, gx + gw, gy + endy)
            surface.DrawLine(gx + endx, gy+ScreenScaleMulti(2) + endy, gx + endx, gy-ScreenScaleMulti(2) + endy)

            -- start dmg
            surface.SetTextColor(fg_col)
            surface.SetFont("ArcCW_6")
            surface.SetTextPos(0, gy + starty - ScreenScaleMulti(7) - 1)
            surface.DrawText(tostring(dmgmax) .. "DMG")

            -- end dmg
            surface.SetTextColor(fg_col)
            surface.SetFont("ArcCW_6")

            local dtw = surface.GetTextSize(tostring(dmgmin) .. "DMG")
            surface.SetTextPos(gx + gw - dtw, gy + endy - ScreenScaleMulti(7) - 1)
            surface.DrawText(tostring(dmgmin) .. "DMG")

            -- start range
            surface.SetTextColor(fg_col)
            surface.SetFont("ArcCW_6")
            surface.SetTextPos(sidegap, smallgap + gh)
            surface.DrawText("0m")

            -- before mid range
            if mingr != 0 then
                surface.SetTextColor(fg_col)
                surface.SetFont("ArcCW_6")
                local btw = surface.GetTextSize(tostring(mingr) .. "m")
                surface.SetTextPos(gx + startx - (btw / 2), smallgap + gh)
                surface.DrawText(tostring(mingr) .. "m")
            end

            -- mid range
            surface.SetTextColor(fg_col)
            surface.SetFont("ArcCW_6")
            local mtw = surface.GetTextSize(tostring(maxgr) .. "m")
            surface.SetTextPos(gx + endx - (mtw / 2), smallgap + gh)
            surface.DrawText(tostring(maxgr) .. "m")

            -- end range
            surface.SetTextColor(fg_col)
            surface.SetFont("ArcCW_6")
            local rtw = surface.GetTextSize(tostring(grsw) .. "m")
            surface.SetTextPos(w - sidegap - rtw, smallgap + gh)
            surface.DrawText(tostring(grsw) .. "m")

            local mousex, mousey = span:CursorPos()

            if mousex > gx and mousex < (gx + gw) and
                    (mousey > gy and mousey < (gy + gh)) then
                local mouser = (mousex - gx) / convw

                local shy
                local shdmg

                if mouser < mingr then
                    shy = starty
                    shdmg = dmgmax
                elseif mouser < maxgr then
                    local delta = mouser / maxgr
                    shy = Lerp(delta, starty, endy)
                    shdmg = Lerp(delta, dmgmax, dmgmin)
                else
                    shy = endy
                    shdmg = dmgmin
                end

                surface.SetDrawColor(Color(fg_col.r, fg_col.g, fg_col.b, 150))
                surface.DrawLine(gx, gy + shy, gw, gy + shy)
                surface.DrawLine(mousex, gy, mousex, gh + gy)

                shy = shy + ScreenScaleMulti(4)

                mouser = math.Round(mouser)
                shdmg = math.Round(shdmg)

                local alignleft = true

                surface.SetFont("ArcCW_6")
                local twmr = surface.GetTextSize(tostring(mouser) .. "m")
                local twmb = surface.GetTextSize(tostring(shdmg) .. "DMG")

                if mousex < math.max(twmr, twmb) + ScreenScaleMulti(2) then
                    alignleft = false
                end

                surface.SetTextColor(fg_col)
                surface.SetFont("ArcCW_6")
                if alignleft then
                    surface.SetTextPos(mousex - ScreenScaleMulti(2) - twmr, shy)
                else
                    surface.SetTextPos(mousex + ScreenScaleMulti(2), shy)
                end
                surface.DrawText(tostring(mouser) .. "m")

                surface.SetTextColor(fg_col)
                surface.SetFont("ArcCW_6")
                if alignleft then
                    surface.SetTextPos(mousex - ScreenScaleMulti(2) - twmb, ScreenScaleMulti(2) + gy)
                else
                    surface.SetTextPos(mousex + ScreenScaleMulti(2), ScreenScaleMulti(2) + gy)
                end
                surface.DrawText(tostring(shdmg) .. "DMG")
            end
        end
    end

    local function defaultStatFunc(name, unit, round)
        local orig = self[name]
        if ArcCW.ConVar_BuffMults["Mult_" .. name] then
            orig = orig * GetConVar(ArcCW.ConVar_BuffMults["Mult_" .. name]):GetFloat()
        end
        return math.Round((unit == "%" and 100 or unit == "ms" and 1000 or 1) * orig, round) .. (unit or ""),
               math.Round((unit == "%" and 100 or unit == "ms" and 1000 or 1) * self[name] * self:GetBuff_Mult("Mult_" .. name), round) .. (unit or "")
    end

    local function defaultBetterFunc(name, inverse)
        local mult = self:GetBuff_Mult("Mult_" .. name)
        if ArcCW.ConVar_BuffMults[name] then
            mult = mult / GetConVar(ArcCW.ConVar_BuffMults[name]):GetFloat()
        end
        if inverse then mult = 1 / mult end
        if mult > 1 then return true
        elseif mult < 1 then return false
        else return nil end
    end

    local statList
    regenStatList = function()
        statList = {
            {translate("stat.stat"), "",
                function() return translate("stat.original"), translate("stat.current") end,
                function() return nil end,
            },
            {translate("stat.damage"), translate("stat.damage.tooltip"),
                function()
                    local curNum = self:GetBuff("Num")
                    local orig = math.Round(self.Damage * ArcCW.ConVars["mult_damage"]:GetFloat()) .. (self.Num != 1 and ("×" .. self.Num) or "")
                    local cur = math.Round(self:GetDamage(0) / curNum * ArcCW.ConVars["mult_damage"]:GetFloat()) .. (curNum != 1 and ("×" .. curNum) or "")
                    return orig, cur
                end,
                function()
                    local orig = self.Damage * self.Num * ArcCW.ConVars["mult_damage"]:GetFloat()
                    local cur = self:GetDamage(0)
                    if orig == cur then return nil else return cur > orig end
                end,
            },
            {translate("stat.damagemin"), translate("stat.damagemin.tooltip"),
                function()
                    local curNum = self:GetBuff("Num")
                    local orig = math.Round(self.DamageMin * ArcCW.ConVars["mult_damage"]:GetFloat()) .. (self.Num != 1 and ("×" .. self.Num) or "")
                    local cur = math.Round(self:GetDamage(self.Range) / curNum * ArcCW.ConVars["mult_damage"]:GetFloat()) .. (curNum != 1 and ("×" .. curNum) or "")
                    return orig, cur
                end,
                function()
                    local orig = self.DamageMin * self.Num * ArcCW.ConVars["mult_damage"]:GetFloat()
                    local maxgr = (self:GetBuff("Range"))
                    if math.Round(self:GetDamage(self.Range)) < math.Round(self:GetDamage(0)) then
                        maxgr = (self.Range / self:GetBuff_Mult("Mult_Range"))
                    end
                    local cur = self:GetDamage(maxgr)
                    if orig == cur then return nil else return cur > orig end
                end,
            },
            {translate("stat.range"), translate("stat.range.tooltip"),
                function() return defaultStatFunc("Range", "m") end,
                function() return defaultBetterFunc("Range") end,
            },
            {translate("stat.firerate"), translate("stat.firerate.tooltip"),
                function()

                local orig = math.Round(60 / self.Delay) .. "RPM"
                local cur = math.Round(60 / self:GetFiringDelay()) .. "RPM"

                if self.ManualAction then
                    orig = translate("stat.firerate.manual")
                end
                if self:GetBuff_Override("Override_ManualAction") or self.ManualAction then
                    cur = translate("stat.firerate.manual")
                end

                return orig, cur
                end,
                function()
                    if !self:GetBuff_Override("Override_ManualAction") and !self.ManualAction then
                        return defaultBetterFunc("RPM")
                    end
                    -- Funky calculations for when some manual gun goes automatic
                    if !self.ManualAction and self:GetBuff_Override("Override_ManualAction") == true then
                        return false
                    elseif self.ManualAction and self:GetBuff_Override("Override_ManualAction") == false then
                        return true
                    end
                    return nil
                end,
            },
            {translate("stat.capacity"), translate("stat.capacity.tooltip"),
                function()
                    local m = self.RegularClipSize
                    local m2 = self.Primary.ClipSize
                    local cs = self.ChamberSize
                    local cs2 = self:GetChamberSize()
                    return m .. (cs > 0 and " +" .. cs or ""), m2 .. (cs2 > 0 and " +" .. cs2 or "")
                end,
                function()
                    local m = self.RegularClipSize
                    local m2 = self.Primary.ClipSize
                    local cs = self.ChamberSize
                    local cs2 = self:GetChamberSize()
                    if m + cs == m2 + cs2 then return nil end
                    return m + cs < m2 + cs2
                end,
            },
            {translate("stat.precision"), translate("stat.precision.tooltip"),
                function() return defaultStatFunc("AccuracyMOA", " MOA", 3) end,
                function() return defaultBetterFunc("AccuracyMOA", true) end,
            },
            {translate("stat.hipdisp"), translate("stat.hipdisp.tooltip"),
                function() return defaultStatFunc("HipDispersion", " MOA") end,
                function() return defaultBetterFunc("HipDispersion", true) end,
            },
            {translate("stat.movedisp"), translate("stat.movedisp.tooltip"),
                function() return defaultStatFunc("MoveDispersion", " MOA") end,
                function() return defaultBetterFunc("MoveDispersion", true) end,
            },
            {translate("stat.recoil"), translate("stat.recoil.tooltip"),
                function() return defaultStatFunc("Recoil", nil, 2) end,
                function() return defaultBetterFunc("Recoil", true) end,
            },
            {translate("stat.recoilside"), translate("stat.recoilside.tooltip"),
                function() return defaultStatFunc("RecoilSide", nil, 2) end,
                function() return defaultBetterFunc("RecoilSide", true) end,
            },
            {translate("stat.sighttime"), translate("stat.sighttime.tooltip"),
                function() return defaultStatFunc("SightTime", "ms") end,
                function() return defaultBetterFunc("SightTime", true) end,
            },
            {translate("stat.speedmult"), translate("stat.speedmult.tooltip"),
                function()
                    return math.Round(self.SpeedMult * 100) .. "%", math.Round(math.Clamp(self:GetBuff("SpeedMult") * self:GetBuff_Mult("Mult_MoveSpeed"), 0, 1) * 100) .. "%"
                end,
                function()
                    local mult = self:GetBuff_Mult("Mult_SpeedMult") * self:GetBuff_Mult("Mult_MoveSpeed")
                    if mult == 1 then return nil
                    elseif mult > 1 then return true
                    else return false end
                end,
            },
            {translate("stat.sightspeed"), translate("stat.sightspeed.tooltip"),
                function()
                    return math.Round(self.SightedSpeedMult * 100) .. "%", math.Round(math.Clamp(self:GetBuff("SightedSpeedMult") * self:GetBuff_Mult("Mult_SightedMoveSpeed"), 0, 1) * 100) .. "%"
                end,
                function()
                    local mult = self:GetBuff_Mult("Mult_SightedSpeedMult") * self:GetBuff_Mult("Mult_SightedMoveSpeed")
                    if mult == 1 then return nil
                    elseif mult > 1 then return true
                    else return false end
                end,
            },
            {translate("stat.meleedamage"), translate("stat.meleedamage.tooltip"),
                function() return defaultStatFunc("MeleeDamage") end,
                function() return defaultBetterFunc("MeleeDamage") end,
            },
            {translate("stat.meleetime"), translate("stat.meleetime.tooltip"),
                function() return defaultStatFunc("MeleeTime", "ms", 2) end,
                function() return defaultBetterFunc("MeleeTime", true) end,
            },
            {translate("stat.shootvol"), translate("stat.shootvol.tooltip"),
                function() return defaultStatFunc("ShootVol","dB") end,
                function() return defaultBetterFunc("ShootVol", true) end,
            },
            {translate("stat.barrellen"), translate("stat.barrellen.tooltip"),
                function()
                    local orig = self.BarrelLength
                    local cur = orig + self:GetBuff_Add("Add_BarrelLength")
                    return orig .. "in", cur .. "in"
                end,
                function()
                    local add = self:GetBuff_Add("Add_BarrelLength")
                    if add == 0 then return nil else return add < 0 end
                end,
            },
            {translate("stat.pen"), translate("stat.pen.tooltip"),
                function() return defaultStatFunc("Penetration","mm") end,
                function() return defaultBetterFunc("Penetration") end,
            },
        }

        statbox:Clear()

        for _, i in pairs(statList) do
            if !i then continue end
            local stat_panel = vgui.Create("DPanel", statbox)
            stat_panel:SetSize(barsize, ScreenScaleMulti(10))
            stat_panel:Dock(TOP)
            stat_panel:SetText("")
            stat_panel:DockMargin( 0, ScreenScaleMulti(1), 0, ScreenScaleMulti(1) )
            stat_panel.Paint = function(spaa, w, h)
                local Bbg_col = Color(0, 0, 0, 50)

                if spaa:IsHovered() then
                    Bbg_col = Color(100, 100, 100, 50)
                end

                surface.SetDrawColor(Bbg_col)
                surface.DrawRect(0, 0, w, h)
            end

            local stat_title = vgui.Create("DLabel", stat_panel)
            stat_title:SetSize(barsize * 0.5, ScreenScaleMulti(10))
            stat_title:SetText("")
            stat_title:Dock(LEFT)
            stat_title.Paint = function(span, w, h)
                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap, 0)
                surface.SetTextColor(fg_col)
                surface.DrawText(i[1])
            end

            local origStat, curStat = i[3]()
            local better = i[4]()
            local stat_orig = vgui.Create("DLabel", stat_panel)
            stat_orig:SetSize(barsize * 0.25, ScreenScaleMulti(10))
            stat_orig:SetText("")
            stat_orig:Dock(LEFT)
            stat_orig.Paint = function(span, w, h)
                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap, 0)
                surface.SetTextColor(fg_col)
                surface.DrawText(origStat)
            end
            local stat_cur = vgui.Create("DLabel", stat_panel)
            stat_cur:SetSize(barsize * 0.25, ScreenScaleMulti(10))
            stat_cur:SetText("")
            stat_cur:Dock(LEFT)
            stat_cur.Paint = function(span, w, h)
                local color = better == true and Color(150, 255, 150) or better == false and Color(255, 150, 150) or fg_col

                surface.SetFont("ArcCW_8")
                surface.SetTextPos(smallgap, 0)
                surface.SetTextColor(color)
                surface.DrawText(curStat)
            end
        end
    end

    if !self.Throwing and !self.PrimaryBash and !self.ShootEntity then
        local togglestat = vgui.Create("DButton", ArcCW.InvHUD)
        togglestat:SetSize((barsize - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
        togglestat:SetText("")
        togglestat:SetPos(scrw - barsize - airgap - ScreenScaleMulti(1) - (barsize / 2), airgap)

        togglestat.OnMousePressed = function(spaa, kc)
            if statbox:IsVisible() then
                statbox:Hide()
                triviabox:Show()
            else
                regenStatList()
                statbox:Show()
                triviabox:Hide()
                attmenu:Hide()
                self.InAttMenu = false
                atttrivia:Hide()
                attslidebox:Hide()
                atttogglebtn:Hide()
            end
        end

        togglestat.Paint = function(spaa, w, h)
            if !self:IsValid() then return end
            if !self.Attachments then return end
            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 100)

            if spaa:IsHovered() then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            surface.SetDrawColor(Bbg_col)
            surface.DrawRect(0, 0, w, h)

            local txt = translate(statbox:IsVisible() and "ui.trivia" or "ui.stats")

            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(smallgap, ScreenScaleMulti(1))
            surface.SetFont("ArcCW_12")
            surface.DrawText(txt)
        end
    end

    if engine.ActiveGamemode() == "terrortown" then
        local gap = airgap

        if GetRoundState() == ROUND_ACTIVE and (LocalPlayer():GetTraitor() or LocalPlayer():GetDetective() or (TTT2 and LocalPlayer().IsShopper and LocalPlayer():IsShopper())) then
            local buymenu = vgui.Create("DButton", ArcCW.InvHUD)
            buymenu:SetSize((barsize - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
            buymenu:SetText("")
            buymenu:SetPos(scrw - barsize - airgap - ScreenScaleMulti(1) - (barsize / 2), airgap + gap)
            gap = gap + airgap

            buymenu.OnMousePressed = function(spaa, kc)
                RunConsoleCommand("ttt_cl_traitorpopup")
            end

            buymenu.Paint = function(spaa, w, h)
                if !self:IsValid() then return end
                if !self.Attachments then return end
                local Bfg_col = Color(255, 255, 255, 255)
                local Bbg_col = Color(0, 0, 0, 100)

                if spaa:IsHovered() then
                    Bbg_col = Color(255, 255, 255, 100)
                    Bfg_col = Color(0, 0, 0, 255)
                end

                surface.SetDrawColor(Bbg_col)
                surface.DrawRect(0, 0, w, h)

                local txt = translate("ui.tttequip")

                surface.SetTextColor(Bfg_col)
                surface.SetTextPos(smallgap, ScreenScaleMulti(1))
                surface.SetFont("ArcCW_12")
                surface.DrawText(txt)
            end
        end

        local radiomenu = vgui.Create("DButton", ArcCW.InvHUD)
        radiomenu:SetSize((barsize - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
        radiomenu:SetText("")
        radiomenu:SetPos(scrw - barsize - airgap - ScreenScaleMulti(1) - (barsize / 2), airgap + gap)

        radiomenu.OnMousePressed = function(spaa, kc)
            RADIO:ShowRadioCommands(!RADIO.Show)
        end

        radiomenu.Paint = function(spaa, w, h)
            if !self:IsValid() then return end
            if !self.Attachments then return end
            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 100)

            if spaa:IsHovered() then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            surface.SetDrawColor(Bbg_col)
            surface.DrawRect(0, 0, w, h)

            local txt = translate("ui.tttchat")

            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(smallgap, ScreenScaleMulti(1))
            surface.SetFont("ArcCW_12")
            surface.DrawText(txt)
        end
    end

    if CLIENT and vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
        local w, h = ArcCW.InvHUD:GetSize()
        local ang = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45)
        local pos = g_VR.tracking.hmd.pos + Vector(0,0,-20) + Angle(0,g_VR.tracking.hmd.ang.yaw,0):Forward() * 30 + ang:Forward() * w * -0.02 + ang:Right() * h * -0.02
        pos, ang = WorldToLocal(pos, ang, g_VR.origin, g_VR.originAngle)
        vrmod.MenuCreate( "ArcCW_Customize", w, h, ArcCW.InvHUD, 4,
                pos, ang, 0.04, true, function()
            self:CloseCustomizeHUD()
        end)
    end

end

end