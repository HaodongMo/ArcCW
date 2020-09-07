local tbl     = table
local tbl_ins = tbl.insert

local tick = 0

function SWEP:InitTimers()
    self.ActiveTimers = {} -- { { time, id, func } }
end

function SWEP:SetTimer(time, callback, id)
    if not IsFirstTimePredicted() then return end

    tbl_ins(self.ActiveTimers, { time + UnPredictedCurTime(), id or "", callback })
end

function SWEP:TimerExists(id)
    for _, v in pairs(self.ActiveTimers) do
        if v[2] == id then return true end
    end

    return false
end

function SWEP:KillTimer(id)
    local keeptimers = {}

    for _, v in pairs(self.ActiveTimers) do
        if v[2] ~= id then tbl_ins(keeptimers, v) end
    end

    self.ActiveTimers = keeptimers
end

function SWEP:KillTimers()
    self.ActiveTimers = {}
end

function SWEP:ProcessTimers()
    local keeptimers, UCT = {}, UnPredictedCurTime()

    if CLIENT and UCT == tick then return end

    if not self.ActiveTimers then self:InitTimers() end

    for _, v in pairs(self.ActiveTimers) do
        if v[1] <= UCT then v[3]() end
    end

    for _, v in pairs(self.ActiveTimers) do
        if v[1] > UCT then tbl_ins(keeptimers, v) end
    end

    self.ActiveTimers = keeptimers
end

local function DoShell(wep, data)
    if not (IsValid(wep) and IsValid(wep:GetOwner())) then return end

    if not data.e then return end

    local att = data.att or wep:GetBuff_Override("Override_CaseEffectAttachment") or wep.CaseEffectAttachment or 2

    if not att then return end

    local getatt = wep:GetAttachment(att)

    if not getatt then return end

    local pos, ang = getatt.Pos, getatt.Ang

    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetAngles(ang)
    ed:SetAttachment(att)
    ed:SetScale(1)
    ed:SetEntity(wep)
    ed:SetNormal(ang:Forward())
    ed:SetMagnitude(data.mag or 100)

    util.Effect(data.e, ed)
end

function SWEP:PlaySoundTable(soundtable, mult, start)
    if CLIENT and game.SinglePlayer() then return end

    local owner = self:GetOwner()

    start = start or 0
    mult  = 1 / (mult or 1)

    for _, v in pairs(soundtable) do
        if table.IsEmpty(v) or not v.t then continue end

        local ttime = (v.t * mult) - start

        if not isnumber(v.t) then continue end

        if ttime < 0 then continue end

        if not (IsValid(self) and IsValid(owner)) then continue end

        self:SetTimer(ttime, function()
            DoShell(self, v)

            if SERVER and v.s then
                net.Start("arccw_networksound")
                net.WriteTable(v)
                net.Send(owner)
            end
        end, "soundtable")
    end
end

if CLIENT then
    net.Receive("arccw_networksound", function(len)
        local wep = LocalPlayer():GetActiveWeapon()
        local snd = net.ReadTable()

        if not (IsValid(wep) and wep.ArcCW and snd.s) then return end

        wep:MyEmitSound(snd.s, snd.v or 75, snd.p or 100, 1, snd.c or CHAN_AUTO)
    end)
end