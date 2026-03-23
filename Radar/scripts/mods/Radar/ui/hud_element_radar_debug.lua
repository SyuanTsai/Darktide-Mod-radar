local mod = get_mod("Radar")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UISettings = require("scripts/settings/ui/ui_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

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

local _logged_visuals = {}
local _logged_draws = {}

local PLAYER_CLASS_ICONS = {
    veteran = "content/ui/materials/icons/classes/veteran",
    zealot = "content/ui/materials/icons/classes/zealot",
    psyker = "content/ui/materials/icons/classes/psyker",
    ogryn = "content/ui/materials/icons/classes/ogryn",
    adamant = "content/ui/materials/icons/classes/adamant",
    broker = "content/ui/materials/icons/classes/broker",
}

local function _log_once(bucket, key, message)
    if bucket[key] then
        return
    end

    bucket[key] = true
    mod:echo(message)
end

local function _widget_color(a, r, g, b)
    return { a, r, g, b }
end

local function _color(a, r, g, b)
    return Color(a, r, g, b)
end

local function _widget_to_color(color)
    if not color then
        return Color(255, 255, 255, 255)
    end

    local a = color[1] or color.a or 255
    local r = color[2] or color.r or 255
    local g = color[3] or color.g or 255
    local b = color[4] or color.b or 255

    return Color(a, r, g, b)
end

local function _any_to_widget_color(color, fallback)
    local src = color or fallback or { 255, 255, 255, 255 }
    return {
        src[1] or src.a or 255,
        src[2] or src.r or 255,
        src[3] or src.g or 255,
        src[4] or src.b or 255,
    }
end

local function _with_alpha_widget(color, alpha)
    local c = _any_to_widget_color(color)
    c[1] = alpha or c[1] or 255
    return c
end

local PRESENTATIONS = {
    enemy_daemonhost = {
        icon = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_heinous_rituals",
        color = _widget_color(255, 255, 64, 64),
        accent_color = _widget_color(220, 255, 0, 0),
        size = 16,
    },
    enemy_monstrosity = {
        icon = "content/ui/materials/icons/presets/preset_05",
        color = _widget_color(255, 255, 64, 64),
        accent_color = _widget_color(220, 255, 0, 0),
        size = 16,
    },
    enemy_captain = {
        icon = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_fading_light_1",
        color = _widget_color(255, 255, 64, 64),
        accent_color = _widget_color(220, 255, 0, 0),
        size = 16,
    },
    enemy_karnak_twin = {
        icon = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_fading_light_2",
        color = _widget_color(255, 255, 64, 64),
        accent_color = _widget_color(220, 255, 0, 0),
        size = 16,
    },
    pickup_ammo_small = {
        icon = "content/ui/materials/hud/communication_wheel/icons/ammo",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pickup_ammo_big = {
        icon = "content/ui/materials/icons/presets/preset_16",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pickup_grenade = {
        icon = "content/ui/materials/hud/interactions/icons/grenade",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pickup_medkit = {
        icon = "content/ui/materials/hud/interactions/icons/respawn",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pickup_stimm = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_syringe_power",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pickup_unknown = {
        icon = "content/ui/materials/icons/pickups/default",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    crate_unknown = {
        icon = "content/ui/materials/icons/pickups/default",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    material_diamantine = {
        icon = "content/ui/materials/icons/currencies/diamantine_big",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    material_plasteel = {
        icon = "content/ui/materials/icons/currencies/plasteel_big",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    material_expeditions_currency = {
        icon = "content/ui/materials/icons/currencies/salvage_big",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    material_expeditions_loot = {
        icon = "content/ui/materials/icons/currencies/tech_remnant_big",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_ammo_crate = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_ammo_crate",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_breach_charge = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_ammo_crate",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_corrupted_auspex_scanner = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_corrupted_auspex_scanner",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_expedition_loot_crate = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_scripture",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_airstrike = {
        icon = "content/ui/materials/icons/throwables/hud/valkyrie_payload",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_artillery_strike = {
        icon = "content/ui/materials/icons/throwables/hud/artillery_strike",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_big_grenade = {
        icon = "content/ui/materials/icons/throwables/hud/big_fn_grenade",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_grimoire = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_grimoire",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_landmine_explosive = {
        icon = "content/ui/materials/icons/pocketables/hud/landmine_explosive",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_landmine_fire = {
        icon = "content/ui/materials/icons/pocketables/hud/landmine_fire",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_landmine_shock = {
        icon = "content/ui/materials/icons/pocketables/hud/landmine_shock",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_medical_crate = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_medic_crate",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_scripture = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_scripture",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_syringe_ability = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_syringe_ability",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_syringe_corruption = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_syringe_corruption",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_syringe_power = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_syringe_power",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_syringe_speed = {
        icon = "content/ui/materials/icons/pocketables/hud/small/party_syringe_speed",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_valkyrie_hover = {
        icon = "content/ui/materials/icons/throwables/hud/valkyrie_hover",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
    pocketable_void_shield = {
        icon = "content/ui/materials/icons/pocketables/hud/void_shield",
        color = _widget_color(255, 255, 255, 255),
        size = 14,
    },
}

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

local function _draw_marker_brackets(ui_renderer, x, y, z, size, color)
    local thickness = size >= 16 and 2 or 1
    local length = math.max(4, math.floor(size * 0.35))
    local pad = 1
    local left = x - pad
    local top = y - pad
    local right = x + size + pad
    local bottom = y + size + pad
    local bracket_color = _widget_to_color(color)

    _draw_box(ui_renderer, left, top, z, length, thickness, bracket_color)
    _draw_box(ui_renderer, left, top, z, thickness, length, bracket_color)

    _draw_box(ui_renderer, right - length, top, z, length, thickness, bracket_color)
    _draw_box(ui_renderer, right - thickness, top, z, thickness, length, bracket_color)

    _draw_box(ui_renderer, left, bottom - thickness, z, length, thickness, bracket_color)
    _draw_box(ui_renderer, left, bottom - length, z, thickness, length, bracket_color)

    _draw_box(ui_renderer, right - length, bottom - thickness, z, length, thickness, bracket_color)
    _draw_box(ui_renderer, right - thickness, bottom - length, z, thickness, length, bracket_color)
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

local function _marker_definition()
    return UIWidget.create_definition({
        {
            pass_type = "texture",
            value_id = "icon",
            style_id = "icon",
            style = {
                vertical_alignment = "top",
                horizontal_alignment = "left",
                offset = { 0, 0, 10 },
                size = { 16, 16 },
                color = { 255, 255, 255, 255 },
            },
            visibility_function = function(content, style)
                return content.icon ~= nil and content.icon ~= ""
            end,
        },
    }, "screen")
end

local MAX_RADAR_MARKERS = 64

local function _create_marker_widget(index)
    return UIWidget.init("RadarMarker_" .. index, _marker_definition())
end

local function _clear_marker_widget(widget)
    widget.content.icon = nil
end

local function _ensure_marker_widgets(self)
    if self._marker_widgets then
        return
    end

    self._marker_widgets = {}

    for i = 1, MAX_RADAR_MARKERS do
        self._marker_widgets[i] = _create_marker_widget(i)
    end

    if mod:get("debug_mode") then
        _log_once(_logged_draws, "widget_pool_init",
            string.format("[Radar] widget pool created | count=%d", MAX_RADAR_MARKERS))
    end
end

local function _apply_marker_widget(widget, visual, x, y, z)
    local style = widget.style.icon
    local size = visual and visual.size or 14

    widget.content.icon = visual and visual.icon or nil
    style.offset[1] = math.floor((x or 0) + 0.5)
    style.offset[2] = math.floor((y or 0) + 0.5)
    style.offset[3] = math.floor((z or 0) + 0.5)
    style.size[1] = size
    style.size[2] = size
    style.color = _any_to_widget_color(visual and visual.color or nil)
end

local function _target_visual(target)
    if not target then
        return nil
    end

    if target.kind == "player_teammate" then
        local meta = target.meta or {}
        local archetype_name = meta.archetype_name and string.lower(tostring(meta.archetype_name)) or nil
        local player_slot = tonumber(meta.player_slot)
        local slot_colors = UISettings and UISettings.player_slot_colors
        local player_color = player_slot and slot_colors and slot_colors[player_slot] or nil
        local icon = PLAYER_CLASS_ICONS[archetype_name] or "content/ui/materials/icons/pickups/default"
        local widget_color = _any_to_widget_color(player_color)

        if mod:get("debug_mode") then
            _log_once(
                _logged_visuals,
                "player:" .. tostring(archetype_name) .. ":" .. tostring(player_slot),
                string.format("[Radar] visual player | archetype=%s slot=%s icon=%s", tostring(archetype_name),
                    tostring(player_slot), tostring(icon))
            )
        end

        return {
            icon = icon,
            color = widget_color,
            accent_color = _with_alpha_widget(widget_color, 180),
            size = 15,
        }
    end

    local presentation = PRESENTATIONS[target.kind]
    if presentation then
        if mod:get("debug_mode") then
            _log_once(
                _logged_visuals,
                "kind:" .. tostring(target.kind),
                string.format("[Radar] visual presentation | kind=%s icon=%s", tostring(target.kind),
                    tostring(presentation.icon))
            )
        end

        return presentation
    end

    local meta = target.meta or {}
    if meta.interaction_icon and meta.interaction_icon ~= "" then
        if mod:get("debug_mode") then
            _log_once(
                _logged_visuals,
                "interaction:" .. tostring(meta.interaction_icon),
                string.format("[Radar] visual interaction_icon | kind=%s icon=%s", tostring(target.kind),
                    tostring(meta.interaction_icon))
            )
        end

        return {
            icon = meta.interaction_icon,
            color = _widget_color(255, 255, 255, 255),
            size = 14,
        }
    end

    if mod:get("debug_mode") then
        _log_once(
            _logged_visuals,
            "fallback_kind:" .. tostring(target.kind),
            string.format("[Radar] visual fallback | kind=%s icon=%s", tostring(target.kind),
                tostring(PRESENTATIONS.pickup_unknown.icon))
        )
    end

    return PRESENTATIONS.pickup_unknown
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
    _ensure_marker_widgets(self)
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
        _ensure_marker_widgets(self)

        local size = mod:get_radar_size()
        local range = mod:get_radar_range()
        local x, y, z, radius = mod:get_radar_origin(size)
        local center_x = x + radius
        local center_y = y + radius

        _draw_radar_frame(ui_renderer, x, y, z + 1, size)

        local next_widget_index = 1

        if snapshot and snapshot.player_position then
            local player_pos = snapshot.player_position
            local targets = snapshot.targets or {}
            local live_camera_rotation = _safe_player_camera_rotation(self)
            local projection_rotation = live_camera_rotation or snapshot.player_rotation

            _draw_box(ui_renderer, center_x - 2, center_y - 2, z + 4, 4, 4, _color(255, 0, 255, 0))

            if #targets > MAX_RADAR_MARKERS then
                if mod:get("debug_mode") then
                    _log_once(
                        _logged_draws,
                        "marker_pool_overflow",
                        string.format("[Radar] marker pool overflow | targets=%d pool=%d", #targets, MAX_RADAR_MARKERS)
                    )
                end
            end

            for i = 1, #targets do
                if next_widget_index > MAX_RADAR_MARKERS then
                    break
                end

                local target = targets[i]
                local px, py = mod:project_target_to_radar(player_pos, projection_rotation, target.position, radius - 8,
                    range)

                if px and py then
                    local visual = _target_visual(target)
                    local icon_size = visual and visual.size or 14
                    local draw_x = center_x + px - icon_size / 2
                    local draw_y = center_y + py - icon_size / 2
                    local widget = self._marker_widgets[next_widget_index]

                    if visual and visual.accent_color then
                        _draw_marker_brackets(ui_renderer, draw_x, draw_y, z + 4, icon_size, visual.accent_color)
                    end

                    _apply_marker_widget(widget, visual, draw_x, draw_y, z + 5)

                    if mod:get("debug_mode") then
                        _log_once(
                            _logged_draws,
                            "widget_material:" .. tostring(visual and visual.icon),
                            string.format("[Radar] widget material scheduled | material=%s",
                                tostring(visual and visual.icon))
                        )
                    end

                    local widget_ok, widget_err = pcall(function()
                        UIWidget.draw(widget, ui_renderer)
                    end)

                    if not widget_ok then
                        if mod:get("debug_mode") then
                            _log_once(
                                _logged_draws,
                                "widget_draw_fail:" .. tostring(visual and visual.icon),
                                string.format("[Radar] widget draw failed | material=%s err=%s",
                                    tostring(visual and visual.icon), tostring(widget_err))
                            )
                        end
                        _draw_box(ui_renderer, draw_x, draw_y, z + 5, icon_size, icon_size,
                            _widget_to_color(visual and visual.color or nil))
                    end

                    next_widget_index = next_widget_index + 1
                end
            end
        end

        for i = next_widget_index, #self._marker_widgets do
            _clear_marker_widget(self._marker_widgets[i])
        end
    end)

    UIRenderer.end_pass(ui_renderer)

    if not ok then
        mod:error("HudElementRadarDebug.draw failed: %s", tostring(err))
    end
end

return HudElementRadarDebug
