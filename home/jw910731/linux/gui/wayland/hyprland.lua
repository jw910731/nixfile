-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


-----------------------
---- LID DETECTION ----
-----------------------

local function readFile(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

local function readCommand(cmd)
    local p = io.popen("{ " .. cmd .. "; } 2>/dev/null")
    if not p then
        return nil
    end
    local output = p:read("*a")
    p:close()
    return output
end

-- Lid state sources, tried in order until one gives an answer. Each returns
-- true (closed), false (open) or nil (cannot tell on this machine).
-- To support a new machine, add a source here.
local lidProviders = {
    -- ACPI laptops. Absent on Apple Silicon and other device-tree machines.
    function()
        local state = readCommand("cat /proc/acpi/button/lid/*/state") or ""
        if state:match("closed") then
            return true
        elseif state:match("open") then
            return false
        end
    end,

    -- UPower is the only source that reports whether a lid exists at all.
    function()
        local output = readCommand("busctl --timeout=1 get-property org.freedesktop.UPower"
            .. " /org/freedesktop/UPower org.freedesktop.UPower LidIsPresent LidIsClosed") or ""
        local present, closed = output:match("b (%a+)%s+b (%a+)")
        if present == "true" then
            return closed == "true"
        end
    end,

    -- logind reads false both for an open lid and for no lid. Either way the
    -- panel stays on, so the ambiguity is harmless.
    function()
        local output = readCommand("busctl --timeout=1 get-property org.freedesktop.login1"
            .. " /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed") or ""
        local closed = output:match("b (%a+)")
        if closed then
            return closed == "true"
        end
    end,
}

-- true / false from the first source that knows, nil if none does. Callers
-- must compare with `== true` so that unknown keeps the panel online.
local function lidClosed()
    for _, provider in ipairs(lidProviders) do
        local ok, closed = pcall(provider)
        if ok and closed ~= nil then
            return closed
        end
    end
    return nil
end

local function isBuiltinConnector(connector)
    return connector:match("^eDP") or connector:match("^LVDS") or connector:match("^DSI")
end

-- Reads sysfs rather than hl.get_monitors(), which is still empty while the
-- config is evaluated at startup.
local function connectedConnectors()
    local connected = readCommand("grep -l '^connected' /sys/class/drm/card*-*/status") or ""
    local connectors = {}
    for connector in connected:gmatch("card%d+%-([^/]+)/status") do
        table.insert(connectors, connector)
    end
    return connectors
end

local function externalDisplayConnected()
    for _, connector in ipairs(connectedConnectors()) do
        if not isBuiltinConnector(connector) then
            return true
        end
    end
    return false
end

-- nil on a machine with no builtin panel.
local function detectBuiltinConnector()
    for _, connector in ipairs(connectedConnectors()) do
        if isBuiltinConnector(connector) then
            return connector
        end
    end
    return nil
end

-- Device names of every input device advertising SW_LID (bit 0 of the SW
-- capability mask, whose last hex digit holds the low bits). Hyprland binds
-- switches by name, and the name varies by machine.
local function lidSwitchNames()
    local names = { ["Lid Switch"] = true } -- common ACPI name, if the read fails
    local devices = readFile("/proc/bus/input/devices") or ""
    for block in (devices .. "\n\n"):gmatch("(.-)\n\n") do
        local name = block:match('N: Name="(.-)"')
        local lowDigit = block:match("B: SW=[%x ]-(%x)\n") or block:match("B: SW=[%x ]-(%x)$")
        if name and lowDigit and tonumber(lowDigit, 16) % 2 == 1 then
            names[name] = true
        end
    end
    return names
end

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Main monitor
-- Safe defaults for a machine with no panel spec yet. `builtin_monitor` is
-- injected from jw.hyprland.builtinMonitor (see builtin-monitor.nix), and any
-- field it sets wins.
local laptopMonitor = {
    output   = detectBuiltinConnector(),
    mode   = "preferred",
    scale  = "auto",
    position = "0x0",
    vrr = 0,
}
for key, value in pairs(builtin_monitor) do
    laptopMonitor[key] = value
end

if laptopMonitor.output then
    if lidClosed() == true and externalDisplayConnected() then
        hl.monitor({
            output = laptopMonitor.output,
            disabled = true,
        })
    else
        hl.monitor(laptopMonitor)
    end
end

-- Any active monitor besides the builtin panel? (docked / clamshell mode)
local function externalMonitorActive()
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name ~= laptopMonitor.output then
            return true
        end
    end
    return false
end

function disableLaptopMonitor()
    -- Clamshell mode only. Never disable the last active monitor: lid close
    -- is followed by suspend ~1s later, and Noctalia locks the session on
    -- PrepareForSleep — if eDP-1 is already gone at that moment, the lock
    -- screen has no output to attach to and comes back blank after wake.
    if externalMonitorActive() then
        hl.monitor({
            output = laptopMonitor.output,
            disabled = true,
        })
    end
end

function enableLaptopMonitor()
    hl.monitor(laptopMonitor)
    if externalMonitorActive() then
        -- Docked only: recompute the externals' auto-* positions around the
        -- re-enabled panel. Skipped when undocked so the reload never churns
        -- outputs while the session lock is up.
        hl.exec_cmd("hyprctl reload")
    end
end
if laptopMonitor.output then
    for name in pairs(lidSwitchNames()) do
        hl.bind("switch:on:" .. name, disableLaptopMonitor, { locked = true })
        hl.bind("switch:off:" .. name, enableLaptopMonitor, { locked = true })
    end
end

-- Home monitor
hl.monitor({
    output   = "desc:Microstep MPG 274URF QD 0x00000001",
    mode   = "3840x2160@160",
    position = "auto-center-up",
    scale = 2,
    vrr = 2,
})
-- Other monitor
hl.monitor({ output = "", mode = "preferred", scale = "auto", position = "auto" })


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
-- Open windows via D-Bus so the background systemd instance (needed for the quick terminal) stays primary
local terminal    = "ghostty +new-window"
local fileManager = "dolphin"
local menu        = "vicinae toggle"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd(pam_init)
    hl.exec_cmd("1password --silent")
end)

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = true,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.85,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 2,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.75,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
    xwayland = {
        force_zero_scaling = true
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        accel_profile = "adaptive",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            drag_lock = 1,
            clickfinger_behavior = true,
            scroll_factor = 0.7
        },
        touchdevice = {
            output = laptopMonitor.output,
        },
    },
})

-- 3-finger horizontal swipe: the native workspace swipe everywhere, except on
-- scrolling-layout workspaces, where each swipe steps one column and only
-- switches workspace once the edge column is focused.
-- Hyprland rejects overlapping gestures ("overshadowed"), so the two variants
-- are swapped whenever the active workspace changes.
local function active_workspace(monitor)
    return hl.get_active_special_workspace(monitor) or hl.get_active_workspace(monitor)
end

-- Nearest existing workspace on the same monitor in direction `step`, like the
-- native swipe's m+1 / m-1 (but without wrapping around).
local function neighbour_workspace(ws, step)
    if ws.special or not ws.monitor then
        return nil
    end
    local best
    for _, w in ipairs(hl.get_workspaces()) do
        if not w.special and w.monitor and w.monitor.id == ws.monitor.id then
            local d = (w.id - ws.id) * step
            if d > 0 and (best == nil or d < (best.id - ws.id) * step) then
                best = w
            end
        end
    end
    return best
end

-- step = 1: next column / workspace, step = -1: previous
local function scrolling_swipe(step)
    return function()
        local ws = active_workspace()
        if not ws then
            return
        end

        local win = hl.get_active_window()
        if win and not win.floating and win.workspace and win.workspace.id == ws.id then
            -- Columns are laid out along x; any tiled window further in the
            -- swipe direction means we are not at the edge yet.
            local x = win.at.x
            for _, w in ipairs(hl.get_workspace_windows(ws)) do
                if not w.floating and (w.at.x - x) * step > 0 then
                    hl.dispatch(hl.dsp.layout(step > 0 and "focus r" or "focus l"))
                    return
                end
            end
        end

        local target = neighbour_workspace(ws, step)
        if target then
            hl.dispatch(hl.dsp.focus({ workspace = tostring(target.id) }))
        end
    end
end

-- gestures:workspace_swipe_invert (default on): fingers moving left go forward
local swipeForward  = scrolling_swipe(1)
local swipeBackward = scrolling_swipe(-1)
local swipeMode = nil

local function sync_swipe_gesture(ws)
    local mode = (ws and ws.tiled_layout == "scrolling") and "scrolling" or "workspace"
    if mode == swipeMode then
        return
    end

    if swipeMode == "scrolling" then
        hl.gesture({ fingers = 3, direction = "left",  action = "unset" })
        hl.gesture({ fingers = 3, direction = "right", action = "unset" })
    elseif swipeMode == "workspace" then
        hl.gesture({ fingers = 3, direction = "horizontal", action = "unset" })
    end

    if mode == "scrolling" then
        hl.gesture({ fingers = 3, direction = "left",  action = swipeForward })
        hl.gesture({ fingers = 3, direction = "right", action = swipeBackward })
    else
        hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    end
    swipeMode = mode
end

sync_swipe_gesture(active_workspace())
hl.on("workspace.active", function() sync_swipe_gesture(active_workspace()) end)
hl.on("monitor.focused", function(m) sync_swipe_gesture(active_workspace(m)) end)

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
-- Framework keyboard swap
hl.device({
    name = "at-translated-set-2-keyboard",
    kb_options = "ctrl:nocaps,altwin:swap_lalt_lwin",
})
-- MacBook (Asahi) built-in keyboard
hl.device({
    name = "apple-mtp-keyboard",
    kb_options = "ctrl:nocaps",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local ipc = "noctalia msg " -- noctalia IPC command prefix

local function layout_bind(bind_table)
    return function()
        local workspace = hl.get_active_special_workspace() or
                          hl.get_active_workspace()

        if not workspace then
            return
        end

        local layout = workspace.tiled_layout

        if bind_table[layout] then
            if type(bind_table[layout]) == "function" then
                bind_table[layout]()
            else
                hl.dispatch(bind_table[layout])
            end
        end
    end
end

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(terminal))
-- Ghostty registers its global keybind via the portal with the trigger as the shortcut id.
-- The app id is "com.mitchellh.ghostty" under the systemd service and "ghostty" when
-- launched directly; only one instance is alive, so dispatching both is safe.
hl.bind(mainMod .. " + grave", function()
    hl.dispatch(hl.dsp.global("com.mitchellh.ghostty:LOGO+grave"))
    hl.dispatch(hl.dsp.global("ghostty:LOGO+grave"))
end)
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + SHIFT + ALT + Q", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + G", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + E", layout_bind({
    dwindle = hl.dsp.layout("togglesplit"),
    scrolling = hl.dsp.layout("promote"),
}))

-- Noctalia
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))
hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exec_cmd(ipc .. "session lock"))


-- Move focus with mainMod + arrow keys
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end
hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ workspace = "r-1", on_current_monitor = true }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({workspace = "r+1", on_current_monitor = true,}))


-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
local WS_PER_MONITOR = 10

local function workspace_id(monitor, local_ws)
    return monitor.id * WS_PER_MONITOR + local_ws
end

for i = 1, WS_PER_MONITOR do
    local key = tostring(i % 10) -- 10 => key 0

    hl.bind("SUPER + " .. key, function()
        local m = hl.get_active_monitor()
        if m == nil then
            return
        end

        hl.dispatch(
            hl.dsp.focus({
                workspace = tostring(workspace_id(m, i)),
                on_current_monitor = true,
            })
        )
    end)

    hl.bind("SUPER + SHIFT + " .. key, function()
        local m = hl.get_active_monitor()
        local w = hl.get_active_window()

        if m == nil or w == nil then
            return
        end

        local dst = workspace_id(m, i)

        hl.dispatch(
            hl.dsp.window.move({
                workspace = tostring(dst),
                window = w,
                follow = false,
            })
        )
    end)
end

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(ipc .. "media next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. "media toggle"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(ipc .. "media toggle"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(ipc .. "media previous"),   { locked = true })
-- Power button: lock and suspend (logind ignores it outside a DE)
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(ipc .. "session lock"), { locked = true })

-- Screen capture
hl.bind("Print", hl.dsp.exec_cmd(grim .. ' -g "$(' .. slurp .. ')" - | ' .. swappy .. ' -f -'))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(grim .. ' -g "$(' .. slurp .. ' -d)" - | '.. wl_copy))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- For all monitor, the last workspace is scroll layout for dumping unused windows
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i*10), layout = "scrolling" })
end

-- Example window rules that are useful

-- local suppressMaximizeRule = hl.window_rule({
--     -- Ignore maximize requests from all apps. You'll probably like this.
--     name  = "suppress-maximize-events",
--     match = { class = ".*" },

--     suppress_event = "maximize",
-- })
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Noctalia settings
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
})
