local tbl     = table
local tbl_ins = tbl.insert

local tick = 0

function SWEP:InitTimers()
    self.ActiveTimers = {} -- { { time, id, func } }
end

function SWEP:SetTimer(time, callback, id)
    if !IsFirstTimePredicted() then return end

    tbl_ins(self.ActiveTimers, { time + CurTime(), id or "", callback })
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
        if v[2] != id then tbl_ins(keeptimers, v) end
    end

    self.ActiveTimers = keeptimers
end

function SWEP:KillTimers()
    self.ActiveTimers = {}
end

function SWEP:ProcessTimers()
    local keeptimers, UCT = {}, CurTime()

    if CLIENT and UCT == tick then return end

    if !self.ActiveTimers then self:InitTimers() end

    for _, v in pairs(self.ActiveTimers) do
        if v[1] <= UCT then v[3]() end
    end

    for _, v in pairs(self.ActiveTimers) do
        if v[1] > UCT then tbl_ins(keeptimers, v) end
    end

    self.ActiveTimers = keeptimers
end

local function DoShell(wep, data)
    if !(IsValid(wep) and IsValid(wep:GetOwner())) then return end

    local att = data.att or wep:GetBuff_Override("Override_CaseEffectAttachment") or wep.CaseEffectAttachment or 2

    if !att then return end

    local getatt = wep:GetAttachment(att)

    if !getatt then return end

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
    --if CLIENT and game.SinglePlayer() then return end

    local owner = self:GetOwner()

    start = start or 0
    mult  = 1 / (mult or 1)

    for _, v in pairs(soundtable) do
        if table.IsEmpty(v) then continue end

        local ttime
        if v.t then
            ttime = (v.t * mult) - start
        else
            continue
        end
        if ttime < 0 then continue end
        if !(IsValid(self) and IsValid(owner)) then continue end

        local jhon = CurTime() + ttime

        --[[if game.SinglePlayer() then
            if SERVER then
                net.Start("arccw_networksound")
                v.ntttime = ttime
                net.WriteTable(v)
                net.WriteEntity(self)
                net.Send(owner)
            end
        end]]

        -- i may go fucking insane
        if !self.EventTable[1] then self.EventTable[1] = {} end

        for i, de in ipairs(self.EventTable) do
            if de[jhon] then
                if !self.EventTable[i + 1] then
                    --[[print(CurTime(), "Occupier at " .. i .. ", creating " .. i+1)]]
                    self.EventTable[i + 1] = {}
                    continue
                end
            else
                self.EventTable[i][jhon] = v
                --print(CurTime(), "Clean at " .. i)
            end
        end
    end
end

function SWEP:PlayEvent(v)
    if !v or !istable(v) then error("no event to play") end
    v = self:GetBuff_Hook("Hook_PrePlayEvent", v) or v
    if v.e and IsFirstTimePredicted() then
        DoShell(self, v)
    end

    if v.s then
        if v.s_km then
            self:StopSound(v.s)
        end
        self:MyEmitSound(v.s, v.l, v.p, v.v, v.c or CHAN_AUTO)
    end

    if v.bg then
        self:SetBodygroupTr(v.ind or 0, v.bg)
    end

    if v.pp then
        local vm = self:GetOwner():GetViewModel()

        vm:SetPoseParameter(pp, ppv)
    end

    v = self:GetBuff_Hook("Hook_PostPlayEvent", v) or v
end


if CLIENT then
    net.Receive("arccw_networksound", function(len)
        local v = net.ReadTable()
        local wep = net.ReadEntity()

        wep.EventTable[CurTime() + v.ntttime] = v
    end)
end