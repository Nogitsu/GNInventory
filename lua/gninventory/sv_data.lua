local PLAYER = FindMetaTable( "Player" )

function PLAYER:SaveInventory( inv )
    file.CreateDir( "gninventory/inventory" )
    file.Write( "gninventory/inventory/" .. self:SteamID64() .. ".json", util.TableToJSON( inv ) )
end

function PLAYER:GetInventory()
    return file.Exists( "gninventory/inventory/" .. self:SteamID64() .. ".json", "DATA" ) and util.JSONToTable( file.Read( "gninventory/inventory/" .. self:SteamID64() .. ".json" ) ) or {}
end

function PLAYER:EditInventory( key, value )
    local inv = self:GetInventory()

    inv[ key ] = value

    self:SaveInventory( inv )
end

function PLAYER:InventoryGet( class )
    return self:GetInventory()[ class ]
end

function PLAYER:InventoryGive( class, count )
    local inv = self:GetInventory()
    local old_value = inv[ class ] or 0

    self:EditInventory( class, old_value + count )
end

function PLAYER:InventoryTake( class, count )
    local inv = self:GetInventory()
    local old_value = inv[ class ] or 0

    self:EditInventory( class, math.max( 0, old_value - count ) )
end

util.AddNetworkString( "GNInventory.OpenInventory" )
net.Receive( "GNInventory.OpenInventory", function( _, ply ) 
    net.Start( "GNInventory.OpenInventory" )
        net.WriteString( net.ReadString() )
        GNLib.WriteTable( ply:GetInventory() )
    net.Send( ply )
end )

util.AddNetworkString( "GNInventory.Give" )
net.Receive( "GNInventory.Give", function( _, ply )
    if not ply:IsAdmin() then return end
    ply:InventoryGive( net.ReadString(), 1 )
end )