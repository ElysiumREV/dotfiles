----------------------------------
-- Elysium's Hyprland config
----------------------------------

require("modules.autostart")
require("modules.input")
require("modules.keybinds")
require("modules.workspaces")

-- Debug
hl.config({
    debug = {
        disable_logs = false,
        damage_tracking = 2,
    },
})

--------------------
-- MONITORS
--------------------

-- Desktop
hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "0x0", scale = 1 })
-- Fallback
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

--------------------
-- LOOK AND FEEL
--------------------

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in = 4,
        gaps_out = 6,
        border_size = 2,
        resize_on_border = false,
        col = {
            active_border = { colors = { "rgb(d4c5b0)", "rgb(A08EC4)" }, angle = 45 },
            inactive_border = "rgb(2A2D35)",
        },
        allow_tearing = true,
        layout = "dwindle",
    },

    render = {
        cm_auto_hdr = false,
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.8,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 50,
            render_power = 10,
            color = "rgba(13151a88)", -- rgba(19,21,26,136) convertido
        },
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            brightness = 1,
            noise = 0.05,
            contrast = 0.89,
            vibrancy = 0.5,
            vibrancy_darkness = 0.5,
            popups = false,
            popups_ignorealpha = 0.6,
            input_methods = true,
            input_methods_ignorealpha = 0.8,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },

    master = {
        new_status = "slave",
        -- master_ratio = 0.75,
        -- master_side = "left",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty)",
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = true,
        render_unfocused_fps = 30,
    },
})

--------------------
-- ANIMATIONS
--------------------

-- Curves
hl.curve("expressiveFastSpatial", { type = "bezier", points = { { 0.42, 1.67 }, { 0.21, 0.90 } } })
hl.curve("expressiveSlowSpatial", { type = "bezier", points = { { 0.39, 1.29 }, { 0.35, 0.98 } } })
hl.curve("expressiveDefaultSpatial", { type = "bezier", points = { { 0.38, 1.21 }, { 0.22, 1.00 } } })
hl.curve("expressiveOvershoot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("standardDecel", { type = "bezier", points = { { 0, 0 }, { 0, 1 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } })
hl.curve("stall", { type = "bezier", points = { { 1, -0.1 }, { 0.7, 0.85 } } })

-- Animations
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 2.5,
    bezier = "expressiveDefaultSpatial",
    style = "popin 85%",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 2.5,
    bezier = "expressiveDefaultSpatial",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.8,
    bezier = "emphasizedDecel",
    style = "popin 90%",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.8,
    bezier = "menu_decel",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 2.5,
    bezier = "expressiveDefaultSpatial",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 4,
    bezier = "emphasizedDecel",
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 1.5,
    bezier = "menu_decel",
    style = "popin 90%",
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.8,
    bezier = "menu_accel",
    style = "popin 94%",
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 0.4,
    bezier = "menu_decel",
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 2,
    bezier = "stall",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.5,
    bezier = "expressiveDefaultSpatial",
    style = "slide fade",
})
hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 2.2,
    bezier = "expressiveDefaultSpatial",
    style = "slidevert popin 85%",
})
hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 1,
    bezier = "emphasizedAccel",
    style = "slidevert",
})
hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 2.5,
    bezier = "standardDecel",
})
