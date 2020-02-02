if SERVER then
    util.AddNetworkString( "GNInventory.SetAllowed" )
end

function GNInventory.LoadAllowedList()
    return file.Exists( "gninventory/allowed_list.json", "DATA" ) and util.JSONToTable( file.Read( "gninventory/allowed_list.json", "DATA" ) ) or {}
end

local allowed_list = GNInventory.LoadAllowedList()

function GNInventory.SaveAllowedList()
    file.CreateDir( "gninventory" )
    file.Write( "gninventory/allowed_list.json", util.TableToJSON( allowed_list, true ) )
end

if SERVER then
    net.Receive( "GNInventory.SetAllowed", function( len, ply )
        if not ply:IsAdmin() then return end

        local type = net.ReadString()
        local spawnclass = net.ReadString()
        local allowed = net.ReadBool()

        GNInventory.SetAllowed( type, spawnclass, allowed )
    end )
else
    net.Receive( "GNInventory.SetAllowed", function( len )
        allowed_list = GNLib.ReadTable( len )
    end )
end

local content = {
    weapon = function( class )
        local cur = weapons.Get( class )

        return { name = cur and cur.PrintName or class, model = cur and cur.WorldModel, type = "weapon" }
    end
}

function GNInventory.SetAllowed( type, spawnclass, allowed )
    if CLIENT then
        net.Start( "GNInventory.SetAllowed" )
            net.WriteString( type )
            net.WriteString( spawnclass )
            net.WriteBool( allowed or false )
        net.SendToServer()
    else
        allowed_list = GNInventory.LoadAllowedList()

        allowed_list[ spawnclass ] = allowed and content[ type ]( spawnclass ) or nil

        if allowed then
            PrintTable( allowed_list[ spawnclass ] )
        end

        net.Start( "GNInventory.SetAllowed" )
            GNLib.WriteTable( allowed_list )
        net.Broadcast()

        GNInventory.SaveAllowedList()
    end
end

function GNInventory.IsAllowed( spawnclass )
    return allowed_list[ spawnclass ] and true or false
end

function GNInventory.GetItemInfos( spawnclass )
    allowed_list = GNInventory.LoadAllowedList()
    return allowed_list[ spawnclass ]
end