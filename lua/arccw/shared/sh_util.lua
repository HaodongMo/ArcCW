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