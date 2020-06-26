local images_smoke = {"particle/smokesprites_0001", "particle/smokesprites_0002", "particle/smokesprites_0003", "particle/smokesprites_0004", "particle/smokesprites_0005", "particle/smokesprites_0006", "particle/smokesprites_0007", "particle/smokesprites_0008", "particle/smokesprites_0009", "particle/smokesprites_0010", "particle/smokesprites_0011", "particle/smokesprites_0012", "particle/smokesprites_0013", "particle/smokesprites_0014", "particle/smokesprites_0015", "particle/smokesprites_0016"}

local function TableRandomChoice(tbl)
    return tbl[math.random(#tbl)]
end

function EFFECT:Init(data)
    self.Origin = data:GetOrigin()

    util.Decal("FadingScorch", self.Origin, self.Origin - Vector(0, 0, 16))

    local emitter = ParticleEmitter( self.Origin + Vector( 0, 0, 16 ) )

    for i = 0,5 do
        local particle = emitter:Add( TableRandomChoice(images_smoke) , self.Origin )
        local scol = math.Rand( 200, 225 )

        particle:SetVelocity( 250 * VectorRand() )
        particle:SetDieTime( math.Rand(1.5, 5) )
        particle:SetStartAlpha( 255 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( math.Rand(100,200) )
        particle:SetEndSize( math.Rand(300,400) )
        particle:SetRoll( math.Rand(0,360) )
        particle:SetRollDelta( math.Rand(-1,1) )
        particle:SetColor( scol,scol,scol )
        particle:SetAirResistance( 100 )
        particle:SetGravity( Vector( math.Rand(-30,30) ,math.Rand(-30,30),math.Rand(10,40)) )
        particle:SetLighting( true )
        particle:SetCollide( true )
        particle:SetBounce( 0.5 )
    end

    local particle = emitter:Add( "sprites/heatwave", self.Origin )
        particle:SetAirResistance( 0 )
        particle:SetDieTime( 1.5 )
        particle:SetStartAlpha( 255 )
        particle:SetEndAlpha( 255 )
        particle:SetStartSize( 250 )
        particle:SetEndSize( 0 )
        particle:SetRoll( math.Rand(180,480) )
        particle:SetRollDelta( math.Rand(-5,5) )
        particle:SetColor( 255, 255, 255 )

    local fire = emitter:Add( "particle/fire", self.Origin )
        fire:SetAirResistance( 0 )
        fire:SetDieTime( 0.1 )
        fire:SetStartAlpha( 255 )
        fire:SetEndAlpha( 0 )
        fire:SetEndSize( 0 )
        fire:SetStartSize( 800 )
        fire:SetRoll( math.Rand(180,480) )
        fire:SetRollDelta( math.Rand(-1,1) )
        fire:SetColor( 255, 255, 255 )

    local light = DynamicLight(self:EntIndex())
    if (light) then
        light.Pos = self.Origin
        light.r = 255
        light.g = 255
        light.b = 255
        light.Brightness = 9
        light.Decay = 2500
        light.Size = 512
        light.DieTime = CurTime() + 0.1
    end

    emitter:Finish()

end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end