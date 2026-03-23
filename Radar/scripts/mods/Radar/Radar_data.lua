local mod = get_mod("Radar")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "general_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_radar",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "radar_size",
                        type = "numeric",
                        default_value = 180,
                        range = { 100, 350 },
                    },
                    {
                        setting_id = "radar_range",
                        type = "numeric",
                        default_value = 40,
                        range = { 25, 100 },
                    },
                    {
                        setting_id = "highlight_distance",
                        type = "numeric",
                        default_value = 15,
                        range = { 5, 50 },
                    },
                    {
                        setting_id = "debug_mode",
                        type = "checkbox",
                        default_value = false,
                    },
                },
            },
            {
                setting_id = "other_pickups_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_ammo_small",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_ammo_big",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_grenades",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_medkits",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_stimms",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_unknown_pickups",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_crates",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "pocketables_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_pocketable_ammo_crate",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_breach_charge",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_medical_crate",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_corrupted_auspex_scanner",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_grimoire",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_scripture",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_expedition_loot_crate",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_syringe_ability",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_syringe_corruption",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_syringe_power",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_syringe_speed",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_landmine_explosive",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_landmine_fire",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_landmine_shock",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_void_shield",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_airstrike",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_artillery_strike",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_big_grenade",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_valkyrie_hover",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "materials_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_diamantine",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_plasteel",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_expeditions_currency",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_expeditions_loot",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "enemies_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_monstrosities",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_captains",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_karnak_twins",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "players_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_teammates",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
        },
    },
}
