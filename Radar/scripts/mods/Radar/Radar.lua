local mod = get_mod("Radar")

local SCAN_INTERVAL = 0.25

mod._next_scan_t = 0
mod._tracked_units = {}
mod._logged_units = {}
mod._radar_targets = {}
mod._radar_snapshot = nil
mod._gameplay_run = false
mod._last_update_t = nil
mod._last_scan_signature = nil
mod._last_block_signature = nil

local MONSTROSITY_BREEDS = {
    chaos_daemonhost = true,
    chaos_beast_of_nurgle = true,
    chaos_plague_ogryn = true,
    chaos_spawn = true,
    chaos_ogryn_houndmaster = true,
}

local CAPTAIN_BREEDS = {
    renegade_captain = true,
    cultist_captain = true,
}

local TWIN_BREEDS = {
    renegade_twin_captain = true,
    renegade_twin_captain_two = true,
}

local KIND_TO_SETTING = {
    pickup_ammo = "show_ammo",
    pickup_grenade = "show_grenades",
    pickup_medkit = "show_medkits",
    pickup_stimm = "show_stimms",
    pickup_unknown = "show_unknown_pickups",
    crate_unknown = "show_crates",
    enemy_monstrosity = "show_monstrosities",
    enemy_captain = "show_captains",
    enemy_karnak_twin = "show_karnak_twins",
    player_teammate = "show_teammates",
}

local function _safe_gameplay_time()
    local time_manager = Managers and Managers.time
    if not time_manager then
        return nil
    end

    local timers = time_manager._timers
    if not timers or not timers.gameplay then
        return nil
    end

    return time_manager:time("gameplay")
end

local function _safe_unit_alive(unit)
    return unit and ALIVE and ALIVE[unit]
end

local function _safe_unit_name(unit)
    if not _safe_unit_alive(unit) then
        return "<dead>"
    end

    local ok, result = pcall(Unit.debug_name, unit, false)
    if ok and result then
        return tostring(result)
    end

    return tostring(unit)
end

local function _is_finite_number(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function _vector3_components(vec)
    if not vec then
        return nil, nil, nil
    end

    if type(vec) == "table" then
        return vec.x, vec.y, vec.z
    end

    local ok_x, x = pcall(function()
        return Vector3.x(vec)
    end)
    local ok_y, y = pcall(function()
        return Vector3.y(vec)
    end)
    local ok_z, z = pcall(function()
        return Vector3.z(vec)
    end)

    if ok_x and ok_y and ok_z then
        return x, y, z
    end

    return nil, nil, nil
end

local function _copy_vector3(vec)
    local x, y, z = _vector3_components(vec)

    if not _is_finite_number(x) or not _is_finite_number(y) or not _is_finite_number(z) then
        return nil
    end

    return { x = x, y = y, z = z }
end

local function _safe_lower_string(value)
    if value == nil then
        return nil
    end

    return string.lower(tostring(value))
end

local function _table_size(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function _log_once(key, text)
    if mod._logged_units[key] then
        return
    end

    mod._logged_units[key] = true
    mod:echo(text)
end

local function _position_lookup(unit)
    if not unit or not POSITION_LOOKUP then
        return nil
    end

    return _copy_vector3(POSITION_LOOKUP[unit])
end

local function _safe_unit_position(unit)
    if not _safe_unit_alive(unit) then
        return nil
    end

    local position = _position_lookup(unit)
    if position then
        return position
    end

    local ok, world_position = pcall(Unit.world_position, unit, 1)
    if ok and world_position then
        return _copy_vector3(world_position)
    end

    return nil
end

local function _safe_world_rotation(unit, node)
    if not _safe_unit_alive(unit) then
        return nil
    end

    local ok, rotation = pcall(Unit.world_rotation, unit, node or 1)
    if ok then
        return rotation
    end

    return nil
end

local function _safe_flat_direction_xy(vector_getter, rotation)
    if not rotation or not vector_getter then
        return nil, nil
    end

    local ok, direction = pcall(vector_getter, rotation)
    if not ok or not direction then
        return nil, nil
    end

    local x, y = _vector3_components(direction)
    if not _is_finite_number(x) or not _is_finite_number(y) then
        return nil, nil
    end

    local length = math.sqrt(x * x + y * y)
    if length <= 0 then
        return nil, nil
    end

    return x / length, y / length
end

local function _safe_forward_xy(rotation)
    return _safe_flat_direction_xy(Quaternion.forward, rotation)
end

local function _safe_right_xy(rotation)
    return _safe_flat_direction_xy(Quaternion.right, rotation)
end

local function _safe_mission_name()
    local state_gameplay = mod._last_state_gameplay
    if state_gameplay then
        local shared_state = state_gameplay._shared_state
        local mission_name = shared_state and shared_state.mission_name
        if mission_name ~= nil then
            return mission_name
        end
    end

    local game_mode_manager = Managers and Managers.state and Managers.state.game_mode
    if game_mode_manager and game_mode_manager.mission_name then
        local ok, mission_name = pcall(function()
            return game_mode_manager:mission_name()
        end)

        if ok and mission_name ~= nil then
            return mission_name
        end
    end

    local state_manager = Managers and Managers.state
    local candidates = {
        function()
            local gameplay = state_manager and state_manager.gameplay
            local shared_state = gameplay and gameplay._shared_state
            return shared_state and shared_state.mission_name
        end,
        function()
            local package_synchronizer_client = Managers and Managers.package_synchronizer_client
            return package_synchronizer_client and package_synchronizer_client._mission_name
        end,
        function()
            local mechanism = Managers and Managers.mechanism and Managers.mechanism._mechanism
            return mechanism and mechanism._mission_name
        end,
    }

    for _, getter in ipairs(candidates) do
        local ok, mission_name = pcall(getter)
        if ok and mission_name ~= nil then
            return mission_name
        end
    end

    return nil
end

local function _safe_presence_activity()
    local presence_manager = Managers and Managers.presence
    if not presence_manager then
        return nil
    end

    local candidates = {
        function()
            if presence_manager.activity then
                return presence_manager:activity()
            end
        end,
        function()
            if presence_manager.current_activity then
                return presence_manager:current_activity()
            end
        end,
        function()
            return presence_manager._current_activity
        end,
        function()
            return presence_manager._activity
        end,
        function()
            return presence_manager._presence_name
        end,
    }

    for _, getter in ipairs(candidates) do
        local ok, value = pcall(getter)
        if ok and value ~= nil then
            return tostring(value)
        end
    end

    return nil
end

local function _safe_mechanism_name()
    local mechanism_manager = Managers and Managers.mechanism
    if not mechanism_manager then
        return nil
    end

    local candidates = {
        function()
            if mechanism_manager.current_mechanism_name then
                return mechanism_manager:current_mechanism_name()
            end
        end,
        function()
            if mechanism_manager.mechanism_name then
                return mechanism_manager:mechanism_name()
            end
        end,
        function()
            return mechanism_manager._mechanism_name
        end,
        function()
            local mechanism = mechanism_manager._mechanism
            if type(mechanism) == "table" then
                return mechanism.name or mechanism._name
            end
            return mechanism
        end,
    }

    for _, getter in ipairs(candidates) do
        local ok, value = pcall(getter)
        if ok and value ~= nil then
            return tostring(value)
        end
    end

    return nil
end

local function _is_hub_runtime()
    local mission_name = _safe_mission_name()
    local activity = _safe_presence_activity()
    local mechanism_name = _safe_mechanism_name()

    return mission_name == "hub_ship"
        or activity == "hub"
        or activity == "main_menu"
        or activity == "title_screen"
        or mechanism_name == "hub"
end

local function _player_manager()
    return Managers and Managers.player
end

local function _local_player()
    local player_manager = _player_manager()
    if not player_manager then
        return nil
    end

    local num_players = tonumber(player_manager._num_players) or 0
    if num_players <= 0 then
        return nil
    end

    local getter = player_manager.local_player_safe or player_manager.local_player
    if not getter then
        return nil
    end

    local ok, player = pcall(function()
        return getter(player_manager, 1)
    end)

    if ok then
        return player
    end

    return nil
end

local function _player_unit()
    local local_player = _local_player()
    return local_player and local_player.player_unit
end

local function _safe_camera_rotation()
    local local_player = _local_player()
    if not local_player then
        return nil
    end

    local viewport_name = local_player.viewport_name
    if not viewport_name then
        return nil
    end

    local camera_manager = Managers and Managers.state and Managers.state.camera
    if not camera_manager then
        return nil
    end

    if camera_manager.has_camera then
        local ok_has_camera, has_camera = pcall(function()
            return camera_manager:has_camera(viewport_name)
        end)

        if ok_has_camera and not has_camera then
            return nil
        end
    end

    if not camera_manager.camera_rotation then
        return nil
    end

    local ok_rotation, rotation = pcall(function()
        return camera_manager:camera_rotation(viewport_name)
    end)

    if ok_rotation and rotation then
        return rotation
    end

    return nil
end

local function _safe_player_rotation(player_unit)
    local camera_rotation = _safe_camera_rotation()
    if camera_rotation then
        return camera_rotation
    end

    if not _safe_unit_alive(player_unit) then
        return nil
    end

    local unit_data_extension = ScriptUnit and ScriptUnit.has_extension and ScriptUnit.has_extension(player_unit, "unit_data_system")
    if unit_data_extension and unit_data_extension.read_component then
        local ok_component, first_person_component = pcall(function()
            return unit_data_extension:read_component("first_person")
        end)

        if ok_component and first_person_component and first_person_component.rotation then
            return first_person_component.rotation
        end
    end

    local first_person_extension = ScriptUnit and ScriptUnit.has_extension and ScriptUnit.has_extension(player_unit, "first_person_system")
    if first_person_extension and first_person_extension.extrapolated_rotation then
        local ok_rotation, rotation = pcall(function()
            return first_person_extension:extrapolated_rotation()
        end)

        if ok_rotation and rotation then
            return rotation
        end
    end

    return _safe_world_rotation(player_unit, 1)
end

local function _safe_extension_system(system_name)
    local extension_manager = Managers and Managers.state and Managers.state.extension
    if not extension_manager or not extension_manager.system then
        return nil
    end

    local ok, system = pcall(function()
        return extension_manager:system(system_name)
    end)

    if ok then
        return system
    end

    return nil
end

local function _safe_unit_to_extension_map(system_name)
    local system = _safe_extension_system(system_name)
    if not system or not system.unit_to_extension_map then
        return nil
    end

    local ok, map = pcall(function()
        return system:unit_to_extension_map()
    end)

    if ok and type(map) == "table" then
        return map
    end

    return nil
end

local function _get_runtime_state()
    local gameplay_t = _safe_gameplay_time()
    local mission_name = _safe_mission_name()
    local activity = _safe_presence_activity()
    local mechanism_name = _safe_mechanism_name()
    local player_unit = _player_unit()
    local player_pos = _safe_unit_position(player_unit)

    if activity == "loading" then
        return false, "loading", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if mechanism_name == "left_session" or mechanism_name == "hub" then
        return false, "hub_mechanism", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if not mission_name then
        return false, "no_mission", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if mission_name == "hub_ship" then
        return false, "hub_mission", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if mechanism_name == "onboarding" and mission_name ~= "tg_shooting_range" then
        return false, "onboarding_non_psykhanium", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if _is_hub_runtime() then
        return false, "hub_runtime", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if not _safe_unit_alive(player_unit) then
        return false, "no_player_unit", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    if not player_pos then
        return false, "no_player_position", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
    end

    return true, "ok", gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos
end

local function _is_allowed_runtime()
    local allowed = _get_runtime_state()
    return allowed
end

local function _kind_enabled(kind)
    local setting_id = KIND_TO_SETTING[kind]
    if not setting_id then
        return true
    end

    return mod:get(setting_id) ~= false
end

local function _classify_pickup_like(interaction_type, icon, description, unit_name)
    local key = string.format("%s|%s|%s|%s",
        tostring(interaction_type or ""),
        tostring(icon or ""),
        tostring(description or ""),
        tostring(unit_name or ""))
    key = string.lower(key)

    if string.find(key, "ammunition", 1, true) or string.find(key, "ammo", 1, true) then
        return "pickup_ammo"
    end

    if string.find(key, "grenade", 1, true) then
        return "pickup_grenade"
    end

    if string.find(key, "medical_crate", 1, true)
        or string.find(key, "medkit", 1, true)
        or string.find(key, "health_kit", 1, true)
        or string.find(key, "healthkit", 1, true)
        or string.find(key, "health", 1, true) then
        return "pickup_medkit"
    end

    if string.find(key, "stimm", 1, true)
        or string.find(key, "stim", 1, true)
        or string.find(key, "syringe", 1, true)
        or string.find(key, "pocketable", 1, true) then
        return "pickup_stimm"
    end

    if string.find(key, "grimoire", 1, true)
        or string.find(key, "scripture", 1, true)
        or string.find(key, "side_mission", 1, true)
        or string.find(key, "objective_side", 1, true)
        or string.find(key, "objective_pickup", 1, true)
        or string.find(key, "luggable", 1, true)
        or string.find(key, "forge_material", 1, true)
        or string.find(key, "expeditions_loot", 1, true)
        or string.find(key, "expeditions_currency", 1, true)
        or string.find(key, "tainted_skull", 1, true)
        or string.find(key, "saints_pickup", 1, true)
        or string.find(key, "stolen_rations", 1, true)
        or string.find(key, "penance_collectible", 1, true) then
        return "pickup_unknown"
    end

    return nil
end

local function _classify_interactee(extension, unit)
    if not extension then
        return nil
    end

    local interaction_type = nil
    local icon = nil
    local description = nil

    local ok_interaction_type, interaction_type_value = pcall(function()
        return extension:interaction_type()
    end)
    if ok_interaction_type then
        interaction_type = _safe_lower_string(interaction_type_value)
    end

    local ok_icon, icon_value = pcall(function()
        return extension:interaction_icon()
    end)
    if ok_icon then
        icon = _safe_lower_string(icon_value)
    end

    local ok_description, description_value = pcall(function()
        local value = extension:description()
        return value
    end)
    if ok_description then
        description = _safe_lower_string(description_value)
    end

    local unit_name = _safe_lower_string(_safe_unit_name(unit))

    if interaction_type == "chest" then
        return "crate_unknown"
    end

    return _classify_pickup_like(interaction_type, icon, description, unit_name)
end

local function _classify_enemy_from_breed(breed_name)
    local key = string.lower(breed_name or "")

    if TWIN_BREEDS[key] or string.find(key, "twin_captain", 1, true) then
        return "enemy_karnak_twin"
    end

    if CAPTAIN_BREEDS[key] or string.find(key, "captain", 1, true) then
        return "enemy_captain"
    end

    if MONSTROSITY_BREEDS[key]
        or string.find(key, "daemonhost", 1, true)
        or string.find(key, "beast_of_nurgle", 1, true)
        or string.find(key, "plague_ogryn", 1, true)
        or string.find(key, "chaos_spawn", 1, true)
        or string.find(key, "houndmaster", 1, true) then
        return "enemy_monstrosity"
    end

    return nil
end

local function _track_unit(unit, kind, source, meta)
    if not kind or not _safe_unit_alive(unit) then
        return
    end

    local existing = mod._tracked_units[unit]
    local now = _safe_gameplay_time() or 0
    local position = _safe_unit_position(unit)

    if existing then
        existing.kind = kind or existing.kind
        existing.source = source or existing.source
        existing.last_seen_t = now
        existing.position = position or existing.position
        if meta ~= nil then
            existing.meta = meta
        end
    else
        mod._tracked_units[unit] = {
            kind = kind,
            source = source,
            last_seen_t = now,
            position = position,
            meta = meta,
        }
    end
end

local function _refresh_player_units()
    local player_manager = _player_manager()
    if not player_manager or not player_manager.players then
        return
    end

    local local_player = _local_player()

    for _, player in pairs(player_manager:players()) do
        local unit = player.player_unit
        if unit and _safe_unit_alive(unit) and player ~= local_player then
            local archetype_name = nil

            local unit_data_extension = ScriptUnit.has_extension(unit, "unit_data_system")
            if unit_data_extension and unit_data_extension.archetype_name then
                local ok_archetype, value = pcall(function()
                    return unit_data_extension:archetype_name()
                end)
                if ok_archetype then
                    archetype_name = value
                end
            end

            _track_unit(unit, "player_teammate", "player_manager", {
                player = player:name(),
                archetype_name = archetype_name,
            })
        end
    end
end

local function _scan_interactees()
    local interactee_map = _safe_unit_to_extension_map("interactee_system")
    if not interactee_map then
        return
    end

    local player_unit = _player_unit()

    for unit, extension in pairs(interactee_map) do
        if _safe_unit_alive(unit) then
            local is_active = true
            local is_used = false
            local show_marker = true

            if extension.active then
                local ok_active, value = pcall(function()
                    return extension:active()
                end)
                if ok_active then
                    is_active = value
                end
            end

            if extension.used then
                local ok_used, value = pcall(function()
                    return extension:used()
                end)
                if ok_used then
                    is_used = value
                end
            end

            if player_unit and extension.show_marker then
                local ok_show, value = pcall(function()
                    return extension:show_marker(player_unit)
                end)
                if ok_show then
                    show_marker = value
                end
            end

            if is_active and not is_used and show_marker then
                local kind = _classify_interactee(extension, unit)
                if kind then
                    _track_unit(unit, kind, "interactee_system")
                end
            end
        end
    end
end

local function _scan_chests()
    local chest_map = _safe_unit_to_extension_map("chest_system")
    if not chest_map then
        return
    end

    for unit, extension in pairs(chest_map) do
        if _safe_unit_alive(unit) and extension and extension.is_open then
            local ok_open, is_open = pcall(function()
                return extension:is_open()
            end)

            if ok_open and not is_open then
                _track_unit(unit, "crate_unknown", "chest_system")
            end
        end
    end
end

local function _scan_minions()
    local unit_data_map = _safe_unit_to_extension_map("unit_data_system")
    if not unit_data_map then
        return
    end

    for unit, extension in pairs(unit_data_map) do
        if _safe_unit_alive(unit) and extension and extension.breed_name then
            local ok_breed, breed_name = pcall(function()
                return extension:breed_name()
            end)

            if ok_breed and breed_name then
                local kind = _classify_enemy_from_breed(breed_name)
                if kind then
                    _track_unit(unit, kind, "unit_data_system", {
                        breed_name = breed_name,
                    })
                end
            end
        end
    end
end

local function _prune_units()
    local now = _safe_gameplay_time() or 0

    for unit, data in pairs(mod._tracked_units) do
        if not _safe_unit_alive(unit) then
            mod._tracked_units[unit] = nil
        elseif data.last_seen_t and now - data.last_seen_t > 2.5 then
            mod._tracked_units[unit] = nil
        else
            data.position = _safe_unit_position(unit) or data.position
            if not data.position then
                mod._tracked_units[unit] = nil
            end
        end
    end
end

local function _distance_squared(a, b)
    if not a or not b then
        return math.huge
    end

    local ax, ay, az = a.x, a.y, a.z
    local bx, by, bz = b.x, b.y, b.z

    if not _is_finite_number(ax) or not _is_finite_number(ay) or not _is_finite_number(az) then
        return math.huge
    end

    if not _is_finite_number(bx) or not _is_finite_number(by) or not _is_finite_number(bz) then
        return math.huge
    end

    local dx = ax - bx
    local dy = ay - by
    local dz = az - bz

    return dx * dx + dy * dy + dz * dz
end

local function _collect_radar_targets()
    local player_unit = _player_unit()
    if not _safe_unit_alive(player_unit) then
        return {}
    end

    local player_pos = _safe_unit_position(player_unit)
    if not player_pos then
        return {}
    end

    local targets = {}

    for unit, data in pairs(mod._tracked_units) do
        if _safe_unit_alive(unit) and data.position and data.kind and _kind_enabled(data.kind) then
            targets[#targets + 1] = {
                unit = unit,
                kind = data.kind,
                position = data.position,
                source = data.source,
                meta = data.meta,
                distance_sq = _distance_squared(player_pos, data.position),
            }
        end
    end

    table.sort(targets, function(a, b)
        return (a.distance_sq or math.huge) < (b.distance_sq or math.huge)
    end)

    return targets
end

local function _collect_radar_snapshot()
    local player_unit = _player_unit()
    if not _safe_unit_alive(player_unit) then
        return nil
    end

    local player_pos = _safe_unit_position(player_unit)
    if not player_pos then
        return nil
    end

    return {
        player_unit = player_unit,
        player_position = player_pos,
        player_rotation = _safe_player_rotation(player_unit),
        targets = mod._radar_targets,
    }
end

local function _count_kind(kind)
    local n = 0
    for unit, data in pairs(mod._tracked_units) do
        if _safe_unit_alive(unit) and data.kind == kind then
            n = n + 1
        end
    end
    return n
end

local function _debug_log_scan()
    if mod:get("debug_mode") ~= true then
        return
    end

    local signature = table.concat({
        tostring(_count_kind("pickup_ammo")),
        tostring(_count_kind("pickup_grenade")),
        tostring(_count_kind("pickup_medkit")),
        tostring(_count_kind("pickup_stimm")),
        tostring(_count_kind("pickup_unknown")),
        tostring(_count_kind("crate_unknown")),
        tostring(_count_kind("enemy_monstrosity")),
        tostring(_count_kind("enemy_captain")),
        tostring(_count_kind("enemy_karnak_twin")),
        tostring(_count_kind("player_teammate")),
        tostring(#mod._radar_targets),
        tostring(_safe_mission_name()),
        tostring(_safe_presence_activity()),
        tostring(_safe_mechanism_name()),
    }, "|")

    if signature == mod._last_scan_signature then
        return
    end

    mod._last_scan_signature = signature

    mod:echo(string.format(
        "Radar scan | ammo=%d grenades=%d medkits=%d stimms=%d pickup_unknown=%d crates=%d monstrosities=%d captains=%d twins=%d teammates=%d tracked=%d radar_targets=%d mission=%s activity=%s mechanism=%s",
        _count_kind("pickup_ammo"),
        _count_kind("pickup_grenade"),
        _count_kind("pickup_medkit"),
        _count_kind("pickup_stimm"),
        _count_kind("pickup_unknown"),
        _count_kind("crate_unknown"),
        _count_kind("enemy_monstrosity"),
        _count_kind("enemy_captain"),
        _count_kind("enemy_karnak_twin"),
        _count_kind("player_teammate"),
        _table_size(mod._tracked_units),
        #mod._radar_targets,
        tostring(_safe_mission_name()),
        tostring(_safe_presence_activity()),
        tostring(_safe_mechanism_name())
    ))
end

local function _reset_runtime_state()
    mod._next_scan_t = 0
    mod._tracked_units = {}
    mod._logged_units = {}
    mod._radar_targets = {}
    mod._radar_snapshot = nil
    mod._last_update_t = nil
    mod._last_scan_signature = nil
    mod._last_block_signature = nil
    mod._last_state_gameplay = nil
end

local function _debug_log_block(reason, gameplay_t, mission_name, activity, mechanism_name)
    if mod:get("debug_mode") ~= true then
        return
    end

    local signature = table.concat({
        tostring(reason),
        tostring(mission_name),
        tostring(activity),
        tostring(mechanism_name),
        tostring(gameplay_t),
    }, "|")

    if signature == mod._last_block_signature then
        return
    end

    mod._last_block_signature = signature
    mod:echo(string.format(
        "Radar blocked | reason=%s mission=%s activity=%s mechanism=%s gameplay_t=%s",
        tostring(reason),
        tostring(mission_name),
        tostring(activity),
        tostring(mechanism_name),
        tostring(gameplay_t)
    ))
end

local function _update_internal(dt, t)
    if mod:get("enable_radar") == false then
        mod._radar_targets = {}
        mod._radar_snapshot = nil
        return
    end

    local allowed, reason, gameplay_t, mission_name, activity, mechanism_name, player_unit, player_pos = _get_runtime_state()
    local scan_clock = gameplay_t or t or 0

    if mod._last_update_t and scan_clock and scan_clock == mod._last_update_t then
        return
    end
    mod._last_update_t = scan_clock

    if not allowed then
        mod._radar_targets = {}
        mod._radar_snapshot = nil
        _debug_log_block(reason, gameplay_t, mission_name, activity, mechanism_name)
        return
    end

    mod._radar_snapshot = {
        player_unit = player_unit,
        player_position = player_pos,
        player_rotation = _safe_player_rotation(player_unit),
        targets = mod._radar_targets,
    }

    if scan_clock < (mod._next_scan_t or 0) then
        return
    end

    mod._next_scan_t = scan_clock + SCAN_INTERVAL

    _scan_interactees()
    _scan_chests()
    _scan_minions()
    _refresh_player_units()
    _prune_units()

    mod._radar_targets = _collect_radar_targets()
    mod._radar_snapshot = _collect_radar_snapshot()

    _debug_log_scan()
end

mod.on_game_state_changed = function(status, state_name)
    if status == "enter" and state_name == "GameplayStateRun" then
        mod._gameplay_run = true
        mod._next_scan_t = 0
        mod._last_update_t = nil
        return
    end

    if status == "exit" and state_name == "GameplayStateRun" then
        mod._gameplay_run = false
        _reset_runtime_state()
        return
    end

    if status == "enter" and (
            state_name == "StateLoading" or
            state_name == "StateMainMenu" or
            state_name == "StateTitle" or
            state_name == "StateGameplay" or
            state_name == "GameplayStateInit"
        ) then
        mod._gameplay_run = false
        _reset_runtime_state()
    end
end

mod:register_hud_element({
    class_name = "HudElementRadarDebug",
    filename = "Radar/scripts/mods/Radar/ui/hud_element_radar_debug",
    visibility_groups = { "alive" },
    use_hud_scale = true,
})

_log_once("radar_hook_reg_marker", "Radar registering HudElementWorldMarkers hook")
mod:hook_safe("HudElementWorldMarkers", "event_add_world_marker_unit", function(self, unit, template_name, position, ...)
    if mod:get("enable_radar") == false or not _is_allowed_runtime() then
        return
    end

    local key = _safe_lower_string(template_name)

    if key and string.find(key, "ammo", 1, true) then
        _track_unit(unit, "pickup_ammo", "world_marker", { template_name = template_name })
    elseif key and string.find(key, "grenade", 1, true) then
        _track_unit(unit, "pickup_grenade", "world_marker", { template_name = template_name })
    elseif key and (string.find(key, "medical", 1, true) or string.find(key, "medkit", 1, true) or string.find(key, "health", 1, true)) then
        _track_unit(unit, "pickup_medkit", "world_marker", { template_name = template_name })
    elseif key and (string.find(key, "stim", 1, true) or string.find(key, "syringe", 1, true)) then
        _track_unit(unit, "pickup_stimm", "world_marker", { template_name = template_name })
    end
end)

mod:hook_safe("StateGameplay", "update", function(self, dt, t, ...)
    mod._last_state_gameplay = self
    _update_internal(dt, t)
end)

mod.update = function(dt)
    if not mod._gameplay_run then
        return
    end

    _update_internal(dt, _safe_gameplay_time())
end

function mod:get_radar_snapshot()
    return self._radar_snapshot
end

function mod:should_draw_radar()
    if self:get("enable_radar") == false then
        return false
    end

    return _is_allowed_runtime()
end

function mod:get_radar_size()
    return self:get("radar_size") or 220
end

function mod:get_radar_range()
    return self:get("radar_range") or 35
end

function mod:get_radar_origin(size)
    local x = self:get("radar_pos_x") or 40
    local y = self:get("radar_pos_y") or 220
    local z = 200
    local radius = size / 2
    return x, y, z, radius
end

function mod:project_target_to_radar(player_pos, player_rot, target_pos, max_radius, range)
    if not player_pos or not target_pos then
        return nil, nil
    end

    range = tonumber(range) or 35
    max_radius = tonumber(max_radius) or 0
    if range <= 0 or max_radius <= 0 then
        return nil, nil
    end

    local dx = target_pos.x - player_pos.x
    local dy = target_pos.y - player_pos.y
    if not _is_finite_number(dx) or not _is_finite_number(dy) then
        return nil, nil
    end

    local local_x = dx
    local local_y = dy

    local forward_x, forward_y = _safe_forward_xy(player_rot)

    if forward_x and forward_y then
        -- Derive a flattened right vector from forward instead of relying on
        -- Quaternion.right. This matches the compass math more closely and keeps
        -- the radar in the same 2D basis as the live camera facing.
        local right_x = forward_y
        local right_y = -forward_x

        local_x = dx * right_x + dy * right_y
        local_y = dx * forward_x + dy * forward_y
    end

    local radar_scale = max_radius / range
    local px = local_x * radar_scale
    local py = -local_y * radar_scale
    if not _is_finite_number(px) or not _is_finite_number(py) then
        return nil, nil
    end

    local dist_sq = px * px + py * py
    local max_sq = max_radius * max_radius
    if dist_sq > max_sq then
        local dist = math.sqrt(dist_sq)
        if dist > 0 then
            local clamp = max_radius / dist
            px = px * clamp
            py = py * clamp
        end
    end

    return px, py
end

return mod
