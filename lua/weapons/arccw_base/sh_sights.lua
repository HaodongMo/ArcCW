SWEP.Sighted = false
SWEP.Sprinted = false

function SWEP:GetSightTime()
    return self:GetBuff("SightTime")
end

function SWEP:EnterSprint()
    if engine.ActiveGamemode() == "terrortown" and !(TTT2 and self:GetOwner().isSprinting) then return end
    if self:GetState() == ArcCW.STATE_SPRINT then return end
    if self:GetState() == ArcCW.STATE_CUSTOMIZE then return end
    self:SetState(ArcCW.STATE_SPRINT)
    self.Sighted = false
    self.Sprinted = true

    local ct = CurTime()

    -- self.SwayScale = 1
    -- self.BobScale = 5

    self:SetShouldHoldType()

    local s = self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint

    if !s and self:GetNextPrimaryFire() <= ct then
        self:SetNextPrimaryFire(ct)
    end

    local anim = self:SelectAnimation("enter_sprint")
    if anim and !s then
        self:PlayAnimation(anim, 1 * self:GetBuff_Mult("Mult_SightTime"), true, nil, false, nil, false, false)
        --self:SetReloading(ct + self:GetAnimKeyTime(anim) * self:GetBuff_Mult("Mult_SightTime"))
    --elseif !anim and !s then -- Not needed because ExitSprint handles it properly
        --self:SetReloading(ct + self:GetSprintTime())
    end
end

function SWEP:ExitSprint()
    if self:GetState() == ArcCW.STATE_IDLE then return end

    local delta = self:GetSprintDelta()
    local ct = CurTime()

    self:SetState(ArcCW.STATE_IDLE)
    self.Sighted = false
    self.Sprinted = false

    -- self.SwayScale = 1
    -- self.BobScale = 1.5

    self:SetShouldHoldType()

    local s = self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint

    if !s and self:GetNextPrimaryFire() <= ct then
        self:SetNextPrimaryFire(ct)
    end

    if self:GetOwner():KeyDown(IN_ATTACK2) then
        self:EnterSights()
    end

    local anim = self:SelectAnimation("exit_sprint")
    if anim and !s then
        self:PlayAnimation(anim, 1 * self:GetBuff_Mult("Mult_SightTime"), true, nil, false, nil, false, false)
        self:SetReloading(ct + self:GetAnimKeyTime(anim) * self:GetBuff_Mult("Mult_SightTime"))
    elseif !anim and !s then
        self:SetReloading(UnPredictedCurTime() + self:GetSprintTime() * delta)
    end
end

-- defined above already?

function SWEP:EnterSights()
    local asight = self:GetActiveSights()
    if !asight then return end
    if self:GetState() != ArcCW.STATE_IDLE then return end
    if self:GetCurrentFiremode().Mode == 0 then return end
    if !self.ReloadInSights and (self:GetReloading() or self:GetOwner():KeyDown(IN_RELOAD)) then return end
    if self:GetBuff_Hook("Hook_ShouldNotSight") then return end
    if (!game.SinglePlayer() and !IsFirstTimePredicted()) then return end

    self:SetupActiveSights()

    self:SetState(ArcCW.STATE_SIGHTS)
    self.Sighted = true
    self.Sprinted = false

    self:SetShouldHoldType()

    self:MyEmitSound(asight.SwitchToSound or "", 75, math.Rand(95, 105), 0.5, CHAN_AUTO)

    local anim = self:SelectAnimation("enter_sight")
    if anim then
        self:PlayAnimation(anim, self:GetSightTime(), true, nil, nil, nil, false, true)
    end

    self:GetBuff_Hook("Hook_SightToggle", true)
end

function SWEP:ExitSights()
    local asight = self:GetActiveSights()
    if self:GetState() != ArcCW.STATE_SIGHTS then return end
    if self.LockSightsInReload and self:GetReloading() then return end
    if (!game.SinglePlayer() and !IsFirstTimePredicted()) then return end

    self:SetState(ArcCW.STATE_IDLE)
    self.Sighted = false
    self.Sprinted = false

    self:SetShouldHoldType()

    self:MyEmitSound(asight.SwitchFromSound or "", 75, math.Rand(80, 90), 0.5, CHAN_AUTO)

    if self:InSprint() then
        self:EnterSprint()
    end

    self:MyEmitSound(asight.SwitchFromSound or "", 75, math.Rand(80, 90), 0.5, CHAN_AUTO)

    local anim = self:SelectAnimation("exit_sight")
    if anim then
        self:PlayAnimation(anim, self:GetSightTime(), true, nil, nil, nil, false, true)
    end

    self:GetBuff_Hook("Hook_SightToggle", false)
end

function SWEP:GetSprintTime()
    return self:GetSightTime()
end

SWEP.SightTable = {}
SWEP.SightMagnifications = {}

function SWEP:SetupActiveSights()
    if !self.IronSightStruct then return end
    if self:GetBuff_Hook("Hook_ShouldNotSight") then return false end

    if !self:GetOwner():IsPlayer() then return end

    local sighttable = {}
    local vm = self:GetOwner():GetViewModel()

    if !vm or !vm:IsValid() then return end

    local kbi = self.KeepBaseIrons or true
    local bif = self.BaseIronsFirst or true

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        local addsights = self:GetBuff_Stat("AdditionalSights", i)
        if !addsights then continue end

        if !k.KeepBaseIrons and !atttbl.KeepBaseIrons then kbi = false end
        if !k.BaseIronsFirst and !atttbl.BaseIronsFirst then bif = false end

        for _, s in pairs(addsights) do
            local stab = table.Copy(s)

            stab.Slot = i

            if stab.HolosightData then atttbl = stab.HolosightData end

            stab.HolosightData = atttbl

            if atttbl.HolosightMagnification then
                stab.MagnifiedOptic = true
                stab.ScopeMagnification = atttbl.HolosightMagnification or 1

                if atttbl.HolosightMagnificationMin then
                    stab.ScopeMagnificationMin = atttbl.HolosightMagnificationMin
                    stab.ScopeMagnificationMax = atttbl.HolosightMagnificationMax

                    stab.ScopeMagnification = math.max(stab.ScopeMagnificationMax, stab.ScopeMagnificationMin)

                    if !i and self.SightMagnifications[0] then
                        stab.ScopeMagnification = self.SightMagnifications[0]
                    elseif self.SightMagnifications[i] then
                        stab.ScopeMagnification = self.SightMagnifications[i]
                    end
                else
                    stab.ScopeMagnification = atttbl.HolosightMagnification
                end
            end

            if atttbl.Holosight then
                stab.Holosight = true
            end

            if !k.Bone then return end

            local boneid = vm:LookupBone(k.Bone)

            if !boneid then return end

            if CLIENT then

                if atttbl.HolosightPiece then
                    stab.HolosightPiece = (k.HSPElement or {}).Model
                end

                if atttbl.Holosight then
                    stab.HolosightModel = (k.VElement or {}).Model
                end

                local bpos, bang = self:GetFromReference(boneid)

                local offset
                local offset_ang

                local vmang = Angle()

                offset = k.Offset.vpos or Vector(0, 0, 0)

                local attslot = k

                local delta = attslot.SlidePos or 0.5

                local vmelemod = nil
                local slidemod = nil

                for _, e in pairs(self:GetActiveElements()) do
                    local ele = self.AttachmentElements[e]

                    if !ele then continue end

                    if ((ele.AttPosMods or {})[i] or {}).vpos then
                        vmelemod = ele.AttPosMods[i].vpos
                    end

                    if ((ele.AttPosMods or {})[i] or {}).slide then
                        slidemod = ele.AttPosMods[i].slide
                    end

                    -- Refer to sh_model Line 837
                    if ((ele.AttPosMods or {})[k.Slot] or {}).SlideAmount then
                        slidemod = ele.AttPosMods[i].SlideAmount
                    end
                end

                offset = vmelemod or attslot.Offset.vpos

                if slidemod or attslot.SlideAmount then
                    offset = LerpVector(delta, (slidemod or attslot.SlideAmount).vmin, (slidemod or attslot.SlideAmount).vmax)
                end

                offset_ang = k.Offset.vang or Angle(0, 0, 0)
                offset_ang = offset_ang + (atttbl.OffsetAng or Angle(0, 0, 0))

                offset_ang = k.VMOffsetAng or offset_ang

                bpos, bang = WorldToLocal(Vector(0, 0, 0), Angle(0, 0, 0), bpos, bang)

                bpos = bpos + bang:Forward() * offset.x
                bpos = bpos + bang:Right() * offset.y
                bpos = bpos + bang:Up() * offset.z

                bang:RotateAroundAxis(bang:Right(), offset_ang.p)
                bang:RotateAroundAxis(bang:Up(), -offset_ang.y)
                bang:RotateAroundAxis(bang:Forward(), offset_ang.r)

                local vpos = Vector()

                vpos.y = -bpos.x
                vpos.x = bpos.y
                vpos.z = -bpos.z

                local corpos = (k.CorrectivePos or Vector(0, 0, 0))

                vpos = vpos + bang:Forward() * corpos.x
                vpos = vpos + bang:Right() * corpos.y
                vpos = vpos + bang:Up() * corpos.z

                -- vpos = vpos + (bang:Forward() * s.Pos.x)
                -- vpos = vpos - (bang:Right() * s.Pos.y)
                -- vpos = vpos + (bang:Up() * s.Pos.z)

                vmang:Set(-bang)

                bang.r = -bang.r
                bang.p = -bang.p
                bang.y = -bang.y

                corang = k.CorrectiveAng or Angle(0, 0, 0)

                bang:RotateAroundAxis(bang:Right(), corang.p)
                bang:RotateAroundAxis(bang:Up(), corang.y)
                bang:RotateAroundAxis(bang:Forward(), corang.r)

                -- vpos = LocalToWorld(s.Pos + Vector(0, self.ExtraSightDist or 0, 0), Angle(0, 0, 0), vpos, bang)

                -- local vmf = (vmang):Forward():GetNormalized()
                -- local vmr = (vmang):Right():GetNormalized()
                -- local vmu = (vmang):Up():GetNormalized()

                -- print(" ----- vmf, vmr, vmu")
                -- print(vmf)
                -- print(vmr)
                -- print(vmu)

                -- vmf = -vmf
                -- vmf.x = -vmf.x

                -- local r = vmf.y
                -- vmf.y = vmf.z
                -- vmf.z = r

                -- vmr = -vmr
                -- vmr.y = -vmr.y

                -- -- local r = vmr.y
                -- -- vmr.y = vmr.z
                -- -- vmr.z = r

                -- vmu = -vmu
                -- vmu.z = vmu.z

                -- local evpos = Vector(0, 0, 0)

                -- evpos = evpos + (vmf * (s.Pos.x + k.CorrectivePos.x))
                -- evpos = evpos - (vmr * (s.Pos.y + (self.ExtraSightDist or 0) + k.CorrectivePos.y))
                -- evpos = evpos + (vmu * (s.Pos.z + k.CorrectivePos.z))

                -- print(vmang:Forward())

                local evpos = s.Pos

                evpos = evpos * (k.VMScale or Vector(1, 1, 1))

                --if !s.IgnoreExtra then
                if false then -- Always ignore extra. Allow the sight creator to define the distance.
                    evpos = evpos + Vector(0, k.ExtraSightDist or self.ExtraSightDist or 0, 0)
                end

                evpos = evpos + (k.CorrectivePos or Vector(0, 0, 0))

                stab.Pos, stab.Ang = vpos, bang

                stab.EVPos = evpos
                stab.EVAng = s.Ang

                if s.GlobalPos then
                    stab.EVPos = Vector(0, 0, 0)
                    stab.Pos = s.Pos
                end

                if s.GlobalAng then
                    stab.Ang = Angle(0, 0, 0)
                end

            end

            table.insert(sighttable, stab)
        end
    end

    if kbi then
        local t = table.Copy(self:GetBuff_Override("Override_IronSightStruct") or self.IronSightStruct)
        if bif then
            table.insert(sighttable, 1, t)
        else
            table.insert(sighttable, t)
        end
    end

    self.SightTable = sighttable
end

function SWEP:SwitchActiveSights()
    if table.Count(self.SightTable) == 1 then return end

    self.ActiveSight = (self.ActiveSight or 1) + 1

    if self.ActiveSight > table.Count(self.SightTable) then
        self.ActiveSight = 1
    end

    local asight = self:GetActiveSights()

    local tbl = self:GetBuff_Hook("Hook_SwitchActiveSights", {active = self.ActiveSight, asight = asight})

    self.ActiveSight = tbl.active or self.ActiveSight

    if self.ActiveSight > table.Count(self.SightTable) then
        self.ActiveSight = 1
    end

    local asight2 = self:GetActiveSights()

    if asight2.SwitchToSound then
        self:MyEmitSound(asight2.SwitchToSound, 75, math.Rand(95, 105), 0.5, CHAN_VOICE2)
    end
end

function SWEP:GetActiveSights()
    if (self.ActiveSight or 1) > table.Count(self.SightTable) then
        self.ActiveSight = 1
    end

    if table.Count(self.SightTable) == 0 then
        return self.IronSightStruct
    else
        return self.SightTable[self.ActiveSight or 1]
    end
end

function SWEP:TranslateFOV(fov)
    local irons = self:GetActiveSights()

    if CLIENT and GetConVar("arccw_dev_benchgun"):GetBool() then self.CurrentFOV = fov self.CurrentViewModelFOV = fov return fov end
    --if !irons then return end
    --if !irons.Magnification then return fov end
    --if irons.Magnification == 1 then return fov end

    self.ApproachFOV = self.ApproachFOV or fov
    self.CurrentFOV = self.CurrentFOV or fov

    local div = 1
    local app_vm = self.ViewModelFOV + self:GetOwner():GetInfoNum("arccw_vm_fov", 0) + 10

    if self:GetState() == ArcCW.STATE_SIGHTS then
        local sgreloading = (self:GetShotgunReloading() == 2 or self:GetShotgunReloading() == 4)
        local delta = self:GetSightDelta()
        delta = math.pow(delta, 2)
        if CLIENT then fov = math.Clamp(( (75*(1-delta)) + (GetConVar("fov_desired"):GetInt()*delta) ), 75, 100) end
        app_vm = irons.ViewModelFOV or 45
        div = irons.Magnification * ((sgreloading or self:GetReloadingREAL() - self.ReloadInSights_CloseIn > CurTime()) and self.ReloadInSights_FOVMult or 1)
        div = math.max(div, 1)
        div = (1 * (1-delta)) + div*delta
    end

    -- something about this doesn't work in multiplayer
    -- if game.SinglePlayer() then self.CurrentFOV = self.CurrentFOV + (self.RecoilAmount * -0.1 * self:GetSightDelta()) end
    -- it also fucking sucks

    self.ApproachFOV = fov / div

    self.CurrentFOV = math.Approach(self.CurrentFOV, self.ApproachFOV, FrameTime() * (self.CurrentFOV - self.ApproachFOV))

    self.CurrentViewModelFOV = self.CurrentViewModelFOV or self.ViewModelFOV
    self.CurrentViewModelFOV = math.Approach(self.CurrentViewModelFOV, app_vm, FrameTime() * (self.CurrentViewModelFOV - app_vm))

    -- DOES A WEIRD SNAPPY THING WHEN YOU ENTER IRONSIGHTS
    -- DOES A WEIRD SNAPPY THING WHEN YOU ENTER IRONSIGHTS
    --[[if CLIENT and self:GetState() != ArcCW.STATE_SIGHTS and math.abs(GetConVar("fov_desired"):GetFloat() - self.CurrentFOV) > 0.0001 then
        -- This mainly exists to handle suitzoom, as you can now hold USE to use it
        self.CurrentViewModelFOV = app_vm * (self.CurrentFOV / GetConVar("fov_desired"):GetFloat())
    end]]
    return self.CurrentFOV

    -- return 90
end

function SWEP:SetShouldHoldType()
    if self:GetCurrentFiremode().Mode == 0 then
        self:SetHoldType(self.HoldtypeHolstered)
        return
    end

    if self:GetState() == ArcCW.STATE_SIGHTS then
        self:SetHoldType(self:GetBuff_Override("Override_HoldtypeSights") or self.HoldtypeSights)
    elseif self:GetState() == ArcCW.STATE_SPRINT then
        if (self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then
            self:SetHoldType(self:GetBuff_Override("Override_HoldtypeActive") or self.HoldtypeActive)
        else
            self:SetHoldType(self:GetBuff_Override("Override_HoldtypeHolstered") or self.HoldtypeHolstered)
        end
    elseif self:GetState() == ArcCW.STATE_CUSTOMIZE then
        self:SetHoldType(self:GetBuff_Override("Override_HoldtypeCustomize") or self.HoldtypeCustomize)
    elseif self:GetCurrentFiremode().Mode == 0 then
        self:SetHoldType(self:GetBuff_Override("Override_HoldtypeHolstered") or self.HoldtypeHolstered)
    else
        self:SetHoldType(self:GetBuff_Override("Override_HoldtypeActive") or self.HoldtypeActive)
    end
end
