local slot_size = 200
local function CreateSlot( list, class, quantity )
    local infos = GNInventory.GetItemInfos( class )

    local slot = list:Add( "DPanel" )
    slot:SetSize( slot_size, slot_size + 32 )

    local mdl = slot:Add( "DModelPanel" )
    mdl:SetSize( slot_size, slot_size )
    mdl:SetModel( infos.model and #string.Trim( infos.model ) ~= 0 and infos.model or "models/maxofs2d/logo_gmod_b.mdl" )
    function mdl:LayoutEntity() return end

    if mdl.Entity then
        local mn, mx = mdl.Entity:GetRenderBounds()
        local size = 0
        size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
        size = math.max( size, math.abs( mn.y ) + math.abs( mx.y ) )
        size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )
        
        mdl:SetFOV( 50 )
        mdl:SetCamPos( Vector( size, size, size ) )
        mdl:SetLookAt( ( mn + mx ) * 0.5 )
    end

    local hover = slot:Add( "DButton" )
    hover:SetSize( slot:GetSize() )
    function hover:Paint( w, h )
        draw.SimpleText( "x" .. (quantity or 0), "GNLFontB20", w - 5, 5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
        return true
    end
    function hover:DoClick()
        ChangeInfos( class, quantity )
    end

    function slot:IsHovered() return hover:IsHovered() end

    return slot
end

local function OpenInventory( inventory, selected )
    local frame = GNLib.CreateFrame( "Inventory" )
    local selected = (selected and inventory[ selected ] and inventory[ selected ] > 0) and selected or ""
    
    local scroll = frame:Add( "DScrollPanel" )
    scroll:Dock( FILL )
    scroll:DockMargin( 5, 5, 0, 5 )

    local list = scroll:Add( "DIconLayout" )
    list:Dock( FILL )
    list:SetSpaceY( 5 )
    list:SetSpaceX( 5 )

    local infos = frame:Add( "DScrollPanel" )
    infos:Dock( RIGHT )
    infos:DockMargin( 0, 5, 5, 5 )
    infos:SetWide( frame:GetWide() / 3 )
    infos:SetVisible( false )
    function infos:Paint( w, h )
        draw.RoundedBox( 10, 0, 0, w, h, GNLib.Colors.WetAsphalt )
    end

    local top = infos:Add( "DPanel" )
    top:Dock( TOP )
    top:SetTall( frame:GetWide() / 6 )
    function top:Paint( w, h )
        local size = h / 2
        GNLib.DrawCircle( size, size, size * 0.95, _, _, GNLib.Colors.Amethyst )
    end

    local model = top:Add( "DModelPanel" )
    model:Dock( LEFT )
    model:SetSize( top:GetTall(), top:GetTall() )
    function model:LayoutEntity() return end

    local actions = top:Add( "DPanel" )
    actions:Dock( RIGHT )
    actions:DockMargin( 0, 0, 5, 0 )
    actions:SetWide( top:GetTall() )
    function actions:Paint() end

    local takeout = actions:Add( "GNButton" )
    takeout:SetText( "Take out" )
    takeout:SetFont( "GNLFontB20" )
    takeout:Dock( TOP )
    takeout:DockMargin( 0, 5, 0, 0 )
    function takeout:DoClick()
        net.Start( "GNInventory.Action" )
            net.WriteString( selected )
            net.WriteString( "takeout" )
        net.SendToServer()

        frame:Remove()
    end

    local drop = actions:Add( "GNButton" )
    drop:SetText( "Drop" )
    drop:SetFont( "GNLFontB20" )
    drop:Dock( TOP )
    drop:DockMargin( 0, 5, 0, 0 )
    function drop:DoClick()
        net.Start( "GNInventory.Action" )
            net.WriteString( selected )
            net.WriteString( "drop" )
        net.SendToServer()

        frame:Remove()
    end

    local name = infos:Add( "DLabel" )
    name:Dock( TOP )
    name:SetText( "N/A" )
    name:SetFont( "GNLFontB40" )
    name:SetTall( 50 )
    name:DockMargin( 5, 5, 5, 5 )

    local description = infos:Add( "GNRichText" )
    description:Dock( TOP )
    description:DockMargin( 5, 5, 5, 5 )

    local changed = false
    function ChangeInfos( class, quantity )
        local data = GNInventory.GetItemInfos( class )

        model:SetModel( data.model and #string.Trim( data.model ) ~= 0 and data.model or "models/maxofs2d/logo_gmod_b.mdl" )
        if model.Entity then
            local mn, mx = model.Entity:GetRenderBounds()
            local size = 0
            size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
            size = math.max( size, math.abs( mn.y ) + math.abs( mx.y ) )
            size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )
            
            model:SetFOV( 50 )
            model:SetCamPos( Vector( size, size, size ) )
            model:SetLookAt( ( mn + mx ) * 0.5 )
        end

        name:SetText( data.name )

        description:Clear()
        if data.desc or data.description then
            description:AppendText( data.desc or data.description )
        end

        infos:SetVisible( true )

        selected = class
    end

    if #selected ~= 0 then ChangeInfos( selected, 0 ) end

    for class, quantity in pairs( inventory ) do
        if quantity == 0 then continue end
        if not GNInventory.IsAllowed( class ) then continue end

        local slot = CreateSlot( list, class, quantity )

        local name = GNInventory.GetItemInfos( class ).name

        function slot:Paint( w, h )
            draw.RoundedBox( 5, 0, 0, w, h, selected == class and GNLib.Colors.Amethyst or self:IsHovered() and GNLib.Colors.Wisteria or GNLib.Colors.WetAsphalt )
            GNLib.DrawCircle( w / 2, w / 2, w * 0.48, _, _, selected == class and GNLib.Colors.WetAsphalt or GNLib.Colors.MidnightBlue )
            draw.SimpleText( name, "GNLFontB20", w / 2, w + 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end
    end
end

net.Receive( "GNInventory.OpenInventory", function( len )
    local selected = net.ReadString()
    local inv = GNLib.ReadTable( len - #selected )

    OpenInventory( inv, selected )
end )

concommand.Add( "gninventory", function()
    net.Start( "GNInventory.OpenInventory" )
        net.WriteString( "" )
    net.SendToServer()
end )

--  > Adding spawnmenu's configuration
--  > Icons
local add_icon = "icon16/tick.png"
local creator_icon = "icon16/wand.png"
local delete_icon = "icon16/cross.png"
local copy_icon = "icon16/page_copy.png"
local config_icon = "icon16/wrench.png"

spawnmenu.AddContentType( "weapon", function( container, obj )

    if ( !obj.material ) then return end
    if ( !obj.nicename ) then return end
    if ( !obj.spawnname ) then return end

    local icon = vgui.Create( "ContentIcon", container )
    icon:SetContentType( "weapon" )
    icon:SetSpawnName( obj.spawnname )
    icon:SetName( obj.nicename )
    icon:SetMaterial( obj.material )
    icon:SetAdminOnly( obj.admin )
    icon:SetColor( Color( 135, 206, 250, 255 ) )
    icon.DoClick = function()
        RunConsoleCommand( "gm_giveswep", obj.spawnname )
        surface.PlaySound( "ui/buttonclickrelease.wav" )
    end

    icon.DoMiddleClick = function()
        RunConsoleCommand( "gm_spawnswep", obj.spawnname )
        surface.PlaySound( "ui/buttonclickrelease.wav" )
    end

    icon.OpenMenu = function( icon )
        local menu = DermaMenu()

            menu:AddOption( "Copy to Clipboard", function()
                SetClipboardText( obj.spawnname )
            end ):SetImage( copy_icon )

            menu:AddOption( "Spawn Using Toolgun", function()
                RunConsoleCommand( "gmod_tool", "creator" )
                RunConsoleCommand( "creator_type", "3" )
                RunConsoleCommand( "creator_name", obj.spawnname )
            end ):SetImage( creator_icon )

            if LocalPlayer():IsAdmin() then
                menu:AddSpacer()

                local GNInv, forIcon = menu:AddSubMenu( "GNInventory" )
                forIcon:SetIcon( config_icon )

                if GNInventory.IsAllowed( obj.spawnname ) then
                    GNInv:AddOption( "Disallow", function()
                        GNInventory.SetAllowed( "weapon", obj.spawnname, false )
                    end ):SetImage( delete_icon )

                    GNInv:AddOption( "Give to my inventory", function()
                        if GNInventory.IsAllowed( obj.spawnname ) then
                            net.Start( "GNInventory.Give" )
                                net.WriteString( obj.spawnname )
                            net.SendToServer()
                        end
                    end ):SetImage( creator_icon )
                else
                    GNInv:AddOption( "Allow", function()
                        GNInventory.SetAllowed( "weapon", obj.spawnname, true )
                    end ):SetImage( add_icon )
                end
            end

            menu:AddSpacer()

            menu:AddOption( "Delete", function()
                icon:Remove()
                hook.Run( "SpawnlistContentChanged", icon )
            end ):SetImage( delete_icon )

        menu:Open()
    end

    if ( IsValid( container ) ) then
        container:Add( icon )
    end

    return icon
end )