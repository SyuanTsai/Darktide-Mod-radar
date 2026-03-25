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
                        setting_id = "max_radar_markers",
                        type = "numeric",
                        default_value = 64,
                        range = { 10, 100 },
                    },
                    {
                        setting_id = "scale_icons_with_radar_size",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "radar_style",
                        type = "dropdown",
                        default_value = "square",
                        options = {
                            {
                                text = "radar_style_square",
                                value = "square",
                            },
                            {
                                text = "radar_style_circle",
                                value = "circle",
                            },
                        },
                    },
                    {
                        setting_id = "enemy_display_style",
                        type = "dropdown",
                        default_value = "marked_icon",
                        options = {
                            {
                                text = "display_style_icon_only",
                                value = "icon_only",
                            },
                            {
                                text = "display_style_marked_icon",
                                value = "marked_icon",
                            },
                        },
                    },
                    {
                        setting_id = "player_display_style",
                        type = "dropdown",
                        default_value = "marked_icon",
                        options = {
                            {
                                text = "display_style_icon_only",
                                value = "icon_only",
                            },
                            {
                                text = "display_style_marked_icon",
                                value = "marked_icon",
                            },
                        },
                    },
                    {
                        setting_id = "highlight_distance",
                        type = "numeric",
                        default_value = 15,
                        range = { 5, 50 },
                    },
                },
            },
            {
                setting_id = "common_pickups_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_crates",
                        type = "checkbox",
                        default_value = true,
                    },
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
                        setting_id = "show_pocketable_ammo_crate",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_medical_crate",
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
                },
            },
            {
                setting_id = "primary_objective_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_power_cell_teal",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_cryonic_rod",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_moebian_pox_zetaphyte_13_sample",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_vacuum_capsule",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_special_issue_ammo",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_prismata_crystal_repository",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_mortis_relic",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_coordinates_paper",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "secondary_objective_group",
                type = "group",
                sub_widgets = {
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
                },
            },
            {
                setting_id = "expeditions_specific_group",
                type = "group",
                sub_widgets = {
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
                    {
                        setting_id = "show_expeditions_dropped_loot",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_data_reliquaries",
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
                    {
                        setting_id = "show_promethium_barrel",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_large_ammunition_crate",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_anti_rad_stimm",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "martyr_s_skull_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_martyr_skull",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_power_cell_orange",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "deployables_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_ammo_crate_deployable",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_medical_crate_deployable",
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
            {
                setting_id = "event_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_tainted_skull",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_pocketable_corrupted_auspex_scanner",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_saints",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "show_stolen_rations",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "debug_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "debug_mode",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "show_unknown_pickups",
                        type = "checkbox",
                        default_value = false,
                    },
                },
            },
        },
    },
}
