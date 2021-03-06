EFFECT.StartPos = Vector(0, 0, 0)
EFFECT.EndPos = Vector(0, 0, 0)
EFFECT.StartTime = 0
EFFECT.LifeTime = 0.2
EFFECT.DieTime = 0
EFFECT.Color = Color(255, 255, 255)
-- EFFECT.Speed = 500

local head = Material("effects/whiteflare")
local tracer = Material("trails/smoke")

function EFFECT:Init(data)

    local start = data:GetStart()
    local hit = data:GetOrigin()

    -- self.LifeTime = (hit - start):Length() / self.Speed

    self.LifeTime = 0.25

    self.StartTime = CurTime()
    self.DieTime = CurTime() + self.LifeTime

    self.StartPos = start
    self.EndPos = hit
end

function EFFECT:Think()
    return self.DieTime > CurTime()
end

local function LerpColor(d, col1, col2)
    local r = Lerp(d, col1.r, col2.r)
    local g = Lerp(d, col1.g, col2.g)
    local b = Lerp(d, col1.b, col2.b)
    local a = Lerp(d, col1.a, col2.a)
    return Color(r, g, b, a)
end

function EFFECT:Render()
    local d = (CurTime() - self.StartTime) / self.LifeTime
    -- local endpos = self.StartPos + (d * (self.EndPos - self.StartPos))
    local endpos = self.EndPos
    local size = 1

    local col = LerpColor(d, self.Color, Color(0, 0, 0, 0))

    render.SetMaterial(head)
    render.DrawSprite(endpos, size, size, col)

    render.SetMaterial(tracer)
    render.DrawBeam(endpos, self.StartPos, size * 0.75, 0, 1, col)
end