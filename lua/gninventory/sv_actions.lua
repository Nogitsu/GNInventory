util.AddNetworkString( "GNInventory.Action" )

net.Receive( "GNInventory.Action", function( _, ply )
    local class = net.ReadString()
    local mode = net.ReadString()

    if ply:InventoryGet( class ) <= 0 then return end

    if mode == "drop" then
        ply:InventoryTake( class, 1 )

        local tr = util.TraceLine( {
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:EyeAngles():Forward() * 250,
            filter = function( ent )
                if ent == ply then
                    return false
                end
            end
        } )

        local ent = ents.Create( class )
        ent:SetPos( tr.HitPos )
        ent:Spawn()
        ent:Activate()
    elseif mode == "takeout" then
        if not ply:HasWeapon( class ) then
            ply:InventoryTake( class, 1 )
            ply:Give( class, true )
        end
    end

    net.Start( "GNInventory.OpenInventory" )
        net.WriteString( class )
        GNLib.WriteTable( ply:GetInventory() )
    net.Send( ply )
end )

hook.Add( "PlayerSay", "GNInventory:Commands", function( ply, str )
    if str == "/inventory" or str == "/inv" then
        net.Start( "GNInventory.OpenInventory" )
            net.WriteString( "" )
            GNLib.WriteTable( ply:GetInventory() )
        net.Send( ply )
        return ""
    elseif str == "/holster" or str == "/invholster" then
        local class = ply:GetActiveWeapon():GetClass()
        if not GNInventory.IsAllowed( class ) then return end

        ply:InventoryGive( class, 1 )
        ply:StripWeapon( class )

        return ""
    end
end )