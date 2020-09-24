
EFFECT.Sounds = {}
EFFECT.Pitch = 90
EFFECT.Scale = 1.5
EFFECT.PhysScale = 1
EFFECT.Model = "models/shells/shell_57.mdl"
EFFECT.Material = nil
EFFECT.JustOnce = true
EFFECT.AlreadyPlayedSound = false
EFFECT.ShellTime = 1

EFFECT.SpawnTime = 0

function EFFECT:Init(data)

    local att = data:GetAttachment()
    local ent = data:GetEntity()
    local mag = data:GetMagnitude()

    local mdl = LocalPlayer():GetViewModel()

    if LocalPlayer():ShouldDrawLocalPlayer() then
        mdl = ent.WMModel or ent
    end

    if !IsValid(ent) then self:Remove() return end

    if ent.Owner != LocalPlayer() then
        mdl = ent.WMModel or ent
    end

    if ent.Owner != LocalPlayer() then
        if !GetConVar("arccw_shelleffects"):GetBool() then self:Remove() return end
    end

    if !mdl or !IsValid(mdl) then self:Remove() return end

    if !mdl:GetAttachment(att) then self:Remove() return end

    local origin, ang = mdl:GetAttachment(att).Pos, mdl:GetAttachment(att).Ang

    ang:RotateAroundAxis(ang:Right(), -90 + ent.ShellRotate)

    ang:RotateAroundAxis(ang:Right(), (ent.ShellRotateAngle or Angle(0, 0, 0))[1])
    ang:RotateAroundAxis(ang:Up(), (ent.ShellRotateAngle or Angle(0, 0, 0))[2])
    ang:RotateAroundAxis(ang:Forward(), (ent.ShellRotateAngle or Angle(0, 0, 0))[3])

    local dir = ang:Up()

    local st = GetConVar("arccw_shelltime"):GetFloat()

    if ent then
        self.Model = ent:GetBuff_Override("Override_ShellModel") or ent.ShellModel
        self.Material = ent:GetBuff_Override("Override_ShellMaterial") or ent.ShellMaterial
        self.Scale = ent:GetBuff_Override("Override_ShellScale") or ent.ShellScale or 1
        self.PhysScale = ent:GetBuff_Override("Override_ShellPhysScale") or ent.ShellPhysScale or 1
        self.Pitch = ent:GetBuff_Override("Override_ShellPitch") or ent.ShellPitch or 100
        self.Sounds = ent:GetBuff_Override("Override_ShellSounds") or ent.ShellSounds
        self.ShellTime = st <= 0 and ent.ShellTime or st
    end

    self:SetPos(origin)
    self:SetModel(self.Model)
    self:SetModelScale(self.Scale)
    self:DrawShadow(true)
    self:SetAngles(ang)

    if self.Material then
        self:SetMaterial(self.Material)
    end

    local pb_vert = 2 * self.Scale * self.PhysScale
    local pb_hor = 0.5 * self.Scale * self.PhysScale

    self:PhysicsInitBox(Vector(-pb_vert,-pb_hor,-pb_hor), Vector(pb_vert,pb_hor,pb_hor))

    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

    local phys = self:GetPhysicsObject()

    local plyvel = Vector(0, 0, 0)

    if IsValid(ent.Owner) then
        plyvel = ent.Owner:GetAbsVelocity()
    end

    phys:Wake()
    phys:SetDamping(0, 0)
    phys:SetMass(1)
    phys:SetMaterial("gmod_silent")

    phys:SetVelocity((dir * mag * math.Rand(1, 2)) + plyvel)
    phys:AddAngleVelocity(VectorRand() * 400)

    self.HitPitch = self.Pitch + math.Rand(-5,5)

    local emitter = ParticleEmitter(origin)

    for i = 1, 3 do
        local particle = emitter:Add("particles/smokey", origin + (dir * 2))

        if (particle) then
            particle:SetVelocity(VectorRand() * 10 + (dir * i * math.Rand(48, 64)) + plyvel)
            particle:SetLifeTime(0)
            particle:SetDieTime(math.Rand(0.05, 0.15))
            particle:SetStartAlpha(math.Rand(40, 60))
            particle:SetEndAlpha(0)
            particle:SetStartSize(0)
            particle:SetEndSize(math.Rand(18, 24))
            particle:SetRoll(math.rad(math.Rand(0, 360)))
            particle:SetRollDelta(math.Rand(-1, 1))
            particle:SetLighting(true)
            particle:SetAirResistance(96)
            particle:SetGravity(Vector(-7, 3, 20))
            particle:SetColor(150, 150, 150)
        end
    end

    self.SpawnTime = CurTime()
end

function EFFECT:PhysicsCollide()
    if self.AlreadyPlayedSound and self.JustOnce then return end

    sound.Play(self.Sounds[math.random(#self.Sounds)], self:GetPos(), 65, self.HitPitch, 1)

    self.AlreadyPlayedSound = true
end

function EFFECT:Think()
    if (self.SpawnTime + self.ShellTime) <= CurTime() then
        self:SetRenderFX( kRenderFxFadeFast )
        if (self.SpawnTime + self.ShellTime + 1) <= CurTime() then
            self:Remove()
            return
        end
    end
    return true
end

function EFFECT:Render()
    if !IsValid(self) then return end
    self:DrawModel()
end