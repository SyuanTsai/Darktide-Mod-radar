local mod = get_mod("Radar")

return {
    name = "Radar",
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
                        range = { 10, 100 },
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
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "pickups_group",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "show_ammo",
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
