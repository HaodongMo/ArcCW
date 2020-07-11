function SWEP:InitTimers()
    self.ActiveTimers = {} -- {{time, callback}}
end

function SWEP:SetTimer(time, callback, id)
    if !IsFirstTimePredicted() then return end
    -- if time < 0 then return end
    id = id or ""
    table.insert(self.ActiveTimers, {time + UnPredictedCurTime(), id, callback})
end

function SWEP:TimerExists(id)
    for k, v in pairs(self.ActiveTimers) do
        if v[2] == id then
            return true
        end
    end

    return false
end

function SWEP:KillTimer(id)
    local keeptimers = {}

    for k, v in pairs(self.ActiveTimers) do
        if v[2] != id then
            table.insert(keeptimers, v)
        end
    end

    self.ActiveTimers = keeptimers
end

function SWEP:KillTimers()
    self.ActiveTimers = {}
end

local tick = 0

function SWEP:ProcessTimers()
    local ct = UnPredictedCurTime()

    if CLIENT then
        if ct == tick then return end
    end

    if !self.ActiveTimers then
        self:InitTimers()
    end

    for k, v in pairs(self.ActiveTimers) do
        if v[1] <= ct then
            v[3]()
        end
    end

    local keeptimers = {}

    for k, v in pairs(self.ActiveTimers) do
        if v[1] > ct then
            table.insert(keeptimers, v)
        end
    end

    self.ActiveTimers = keeptimers
end

function SWEP:PlaySoundTable(soundtable, mult, startfrom)
    if CLIENT and game.SinglePlayer() then return end
    mult = mult or 1
    mult = 1 / mult
    startfrom = startfrom or 0

    self:KillTimer("soundtable")
    for k, v in pairs(soundtable) do

        if !v.t then continue end

        local pitch = 100
        local vol = 75

        if v.p then
            pitch = v.p
        end

        if v.v then
            vol = v.v
        end

        local st = (v.t * mult) - startfrom

        if isnumber(v.t) then
            if st < 0 then continue end
            if self:GetOwner():IsNPC() then
                timer.Simple(st, function()
                    if !IsValid(self) then return end
                    if !IsValid(self:GetOwner()) then return end
                    self:EmitSound(v.s, vol, pitch, 1, CHAN_AUTO)
                    if v.e then
                        local posang = self:GetAttachment(v.att or self.CaseEffectAttachment)
                        if !posang then return end
                        local pos = posang.Pos
                        local ang = posang.Ang

                        local fx = EffectData()
                        fx:SetOrigin(pos)
                        fx:SetAngles(ang)
                        fx:SetAttachment(v.att or self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)
                        fx:SetScale(1)
                        fx:SetEntity(self)
                        fx:SetNormal(ang:Forward())
                        fx:SetMagnitude(v.mag or 100)
                        util.Effect(v.e, fx)
                    end
                    if v.s then
                        self:EmitSound(v.s, vol, pitch, 1, v.c or CHAN_AUTO)
                    end
                end)
            else
                self:SetTimer(st, function()
                    if v.e then
                        local posang = self:GetAttachment(v.att or self.CaseEffectAttachment)
                        if !posang then return end
                        local pos = posang.Pos
                        local ang = posang.Ang

                        local fx = EffectData()
                        fx:SetOrigin(pos)
                        fx:SetAngles(ang)
                        fx:SetAttachment(v.att or self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)
                        fx:SetScale(1)
                        fx:SetEntity(self)
                        fx:SetNormal(ang:Forward())
                        fx:SetMagnitude(v.mag or 100)
                        util.Effect(v.e, fx)
                    end
                    if v.s then
                        self:EmitSound(v.s, vol, pitch, 1, v.c or CHAN_AUTO)
                    end
                end, "soundtable")
            end
        end
    end
end