local mod = get_mod("Radar")
local UIRenderer = require("scripts/managers/ui/ui_renderer")

local HudElementRadarDebug = class("HudElementRadarDebug", "HudElementBase")

local Definitions = {
    scenegraph_definition = {
        screen = {
            scale = "fit",
            position = { 0, 0, 0 },
            size = { 1920, 1080 },
        },
    },
    widget_definitions = {},
}

local COLORS = {
    background = Color(120, 0, 0, 0),
    border = Color(220, 190, 190, 190),
    center = Color(255, 255, 255, 255),
    pickup_ammo = Color(255, 90, 160, 255),
    pickup_grenade = Color(255, 255, 180, 60),
    pickup_medkit = Color(255, 80, 220, 120),
    pickup_stimm = Color(255, 220, 80, 220),
    pickup_unknown = Color(255, 180, 180, 180),
    crate_unknown = Color(255, 230, 210, 80),
    enemy_monstrosity = Color(255, 220, 60, 60),
    enemy_captain = Color(255, 255, 120, 40),
    enemy_karnak_twin = Color(255, 170, 90, 255),
    enemy_unknown = Color(255, 255, 255, 255),
    player_teammate = Color(255, 80, 180, 255),
}

local function _color(a, r, g, b)
    return Color(a, r, g, b)
end

local function _draw_box(ui_renderer, x, y, z, w, h, color)
    if not ui_renderer or not ui_renderer.gui then
        return
    end

    x = tonumber(x) or 0
    y = tonumber(y) or 0
    z = tonumber(z) or 0
    w = tonumber(w) or 0
    h = tonumber(h) or 0

    if w <= 0 or h <= 0 then
        return
    end

    local scale = ui_renderer.scale or 1
    local render_settings = ui_renderer.render_settings
    local start_layer = render_settings and render_settings.start_layer or 0
    local position = Vector3(x * scale, y * scale, start_layer + z)
    local size = Vector2(w * scale, h * scale)

    Gui.rect(ui_renderer.gui, position, size, color)
end

local function _draw_radar_frame(ui_renderer, x, y, z, size)
    local thickness = 2
    local center = size / 2

    _draw_box(ui_renderer, x, y, z, size, size, _color(90, 0, 0, 0))
    _draw_box(ui_renderer, x, y, z + 1, size, thickness, _color(255, 255, 255, 255))
    _draw_box(ui_renderer, x, y + size - thickness, z + 1, size, thickness, _color(255, 255, 255, 255))
    _draw_box(ui_renderer, x, y, z + 1, thickness, size, _color(255, 255, 255, 255))
    _draw_box(ui_renderer, x + size - thickness, y, z + 1, thickness, size, _color(255, 255, 255, 255))
    _draw_box(ui_renderer, x + center, y, z + 1, 1, size, _color(90, 255, 255, 255))
    _draw_box(ui_renderer, x, y + center, z + 1, size, 1, _color(90, 255, 255, 255))
end

local function _target_color(kind)
    return COLORS[kind] or COLORS.enemy_unknown
end

local function _safe_player_camera_rotation(self)
    local parent = self and self._parent
    if not parent or not parent.player_camera then
        return nil
    end

    local ok_camera, camera = pcall(function()
        return parent:player_camera()
    end)

    if not ok_camera or not camera then
        return nil
    end

    local ok_rotation, rotation = pcall(function()
        return Camera.local_rotation(camera)
    end)

    if ok_rotation and rotation then
        return rotation
    end

    return nil
end

HudElementRadarDebug.init = function(self, parent, draw_layer, start_scale, optional_context)
    HudElementRadarDebug.super.init(self, parent, draw_layer, start_scale, Definitions)
end

HudElementRadarDebug.update = function(self, dt, t)
    return
end

HudElementRadarDebug.draw = function(self, dt, t, ui_renderer, render_settings, input_service)
    if not mod:is_enabled() or mod:get("enable_radar") == false or not mod:should_draw_radar() then
        return
    end

    local snapshot = mod:get_radar_snapshot()

    render_settings = render_settings or {}
    render_settings.start_layer = self._draw_layer

    UIRenderer.begin_pass(ui_renderer, self._ui_scenegraph, input_service, dt, render_settings)

    local ok, err = pcall(function()
        local size = mod:get_radar_size()
        local range = mod:get_radar_range()
        local x, y, z, radius = mod:get_radar_origin(size)
        local center_x = x + radius
        local center_y = y + radius

        _draw_radar_frame(ui_renderer, x, y, z + 1, size)

        if snapshot and snapshot.player_position then
            local player_pos = snapshot.player_position
            local targets = snapshot.targets or {}
            local live_camera_rotation = _safe_player_camera_rotation(self)
            local projection_rotation = live_camera_rotation or snapshot.player_rotation

            _draw_box(ui_renderer, center_x - 2, center_y - 2, z + 4, 4, 4, _color(255, 0, 255, 0))

            for i = 1, #targets do
                local target = targets[i]
                local px, py = mod:project_target_to_radar(player_pos, projection_rotation, target.position, radius - 6, range)

                if px and py then
                    local draw_x = center_x + px - 4
                    local draw_y = center_y + py - 4
                    _draw_box(ui_renderer, draw_x, draw_y, z + 5, 8, 8, _target_color(target.kind))
                end
            end
        end
    end)

    UIRenderer.end_pass(ui_renderer)

    if not ok then
        mod:error("HudElementRadarDebug.draw failed: %s", tostring(err))
    end
end

return HudElementRadarDebug
