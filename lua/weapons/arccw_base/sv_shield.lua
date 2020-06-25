SWEP.Shields = {}

function SWEP:SetupShields()
    self:KillShields()

    bonename = "ValveBiped.Bip01_R_Hand"

    local boneindex = self:GetOwner():LookupBone(bonename)

    if !boneindex then return end

    local bpos, bang = self:GetOwner():GetBonePosition(boneindex)

    for i, k in pairs(self.Attachments) do
        if !k then continue end
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl.ModelIsShield then

            for _, e in pairs(self:GetActiveElements()) do
                local ele = self.AttachmentElements[e]

                if !ele then continue end

                if ((ele.AttPosMods or {})[i] or {}).wpos then
                    wmelemod = ele.AttPosMods[i].wpos
                end

                if ((ele.AttPosMods or {})[i] or {}).slide then
                    slidemod = ele.AttPosMods[i].slide
                end
            end

            local delta = k.SlidePos or 0.5

            local offset = wmelemod or k.Offset.wpos or Vector(0, 0, 0)

            if k.SlideAmount then
                offset = LerpVector(delta, (slidemod or k.SlideAmount).wmin, (slidemod or k.SlideAmount).wmax)
            end

            local pos = offset + (atttbl.ShieldCorrectPos or Vector(0, 0, 0))
            local ang = k.Offset.wang or Angle(0, 0, 0)

            local apos = LocalToWorld(pos, ang, bpos, bang)

            local shield = ents.Create("physics_prop")
            if !shield then
                print("!!! Unable to spawn shield!")
                continue
            end

            shield:SetModel( atttbl.Model )
            shield:FollowBone( self:GetOwner(), self:GetOwner():LookupBone("ValveBiped.Bip01_R_Hand") )
            shield:SetPos( apos )
            shield:SetAngles( self.Owner:GetAngles() + ang + (atttbl.ShieldCorrectAng or Angle(0, 0, 0)) )
            shield:SetCollisionGroup( COLLISION_GROUP_WORLD )
            shield:SetColor( Color(0, 0, 0, 0) )
            table.insert(self.Shields, shield)
            shield:Spawn()
            shield:Activate()

            local phys = shield:GetPhysicsObject()

            phys:SetMass(1000)

            shield:SetRenderMode(RENDERMODE_NONE)
        end
    end
end

function SWEP:KillShields()
    for i, k in pairs(self.Shields) do
        SafeRemoveEntity(k)
    end
end