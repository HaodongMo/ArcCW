-- Works around the 10 bodygroup limit on ENTITY:SetBodyGroups()
function ArcCW.SetBodyGroups(mdl, bodygroups)
    mdl:SetBodyGroups(bodygroups)
    local len = string.len(bodygroups or "")
    for i = 10, len - 1 do
        mdl:SetBodygroup(i, tonumber(string.sub(bodygroups, i + 1, i + 2)))
    end
end

-- doesn't work
function ArcCW.RotateAroundPoint(pos, ang, point, offset, offset_ang)
    local v = Vector(0, 0, 0)
    v = v + (point.x * ang:Right())
    v = v + (point.y * ang:Forward())
    v = v + (point.z * ang:Up())

    local newang = Angle()
    newang:Set(ang)

    newang:RotateAroundAxis(ang:Right(), offset_ang.p)
    newang:RotateAroundAxis(ang:Forward(), offset_ang.r)
    newang:RotateAroundAxis(ang:Up(), offset_ang.y)

    v = v + newang:Right() * offset.x
    v = v + newang:Forward() * offset.y
    v = v + newang:Up() * offset.z

    -- v:Rotate(offset_ang)

    v = v - (point.x * newang:Right())
    v = v - (point.y * newang:Forward())
    v = v - (point.z * newang:Up())

    return v + pos, newang
end

function ArcCW.RotateAroundPoint2(pos, ang, point, offset, offset_ang)

    debugoverlay.Cross(point, 1, 1, Color(255, 0, 0), true)

    local mat = Matrix()
    mat:SetTranslation(pos)
    mat:SetAngles(ang)
    debugoverlay.Cross(pos, 1.5, 1, Color(0, 0, 255), true)
    debugoverlay.Line(mat:GetTranslation(), mat:GetTranslation() + ang:Forward() * 32, 1, color_white, true)
    debugoverlay.Line(mat:GetTranslation(), point, 1, Color(255, 150, 150), true)

    mat:Translate(point)
    debugoverlay.Cross(mat:GetTranslation(), 2, 1, Color(255, 0, 255), true)

    local rot_mat = Matrix()
    rot_mat:SetAngles(offset_ang)
    rot_mat:Invert()
    mat:Mul(rot_mat)

    --mat:Rotate(offset_ang)
    mat:Translate(-point)

    mat:Translate(offset)

    debugoverlay.Cross(mat:GetTranslation(), 1, 1, Color(0, 255, 0), true)
    debugoverlay.Line(mat:GetTranslation(), mat:GetTranslation() + mat:GetAngles():Forward() * 8, 1, Color(0, 255, 0), true)

    return mat:GetTranslation(), mat:GetAngles()
end