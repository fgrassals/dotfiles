local monitors = require("monitors")

-- ── Environment variables ─────────────────────────────────────────────────────

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "default")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ── Autostart ─────────────────────────────────────────────────────────────────

hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("mako")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("udiskie --no-tray")
	hl.exec_cmd("~/.local/bin/battery-notify.sh")
	hl.exec_cmd("1password --silent --ozone-platform=wayland")
end)

-- ── Look and feel ─────────────────────────────────────────────────────────────

hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 6,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 0.85,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			vibrancy = 0.1696,
		},
	},
	dwindle = {
		-- pseudotile removed in 0.55; SUPER+P still toggles pseudo on the active window
		preserve_split = true,
	},
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
	input = {
		kb_layout = "us",
		kb_variant = "altgr-intl",
		kb_model = "",
		kb_options = "terminate:ctrl_alt_bksp",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = false,
			tap_to_click = true,
			tap_and_drag = true,
			drag_lock = true,
			disable_while_typing = true,
		},
	},
})

-- ── Animations ────────────────────────────────────────────────────────────────

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 5.0, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.0, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 0.8, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.0, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 0.8, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 2.0, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.0, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 0.8, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.0, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 0.8, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.0, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 0.8, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.0, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3.5, bezier = "quick" })

-- ── Input gestures ────────────────────────────────────────────────────────────

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ── Workspace-to-monitor binding ──────────────────────────────────────────────
-- Workspaces 1-5 on external, 6-10 on laptop.
-- When external is unplugged, workspaces 1-5 migrate to laptop automatically.

hl.workspace_rule({ workspace = "1", monitor = monitors.external, default = true })
hl.workspace_rule({ workspace = "2", monitor = monitors.external })
hl.workspace_rule({ workspace = "3", monitor = monitors.external })
hl.workspace_rule({ workspace = "4", monitor = monitors.external })
hl.workspace_rule({ workspace = "5", monitor = monitors.external })
hl.workspace_rule({ workspace = "6", monitor = monitors.laptop, default = true })
hl.workspace_rule({ workspace = "7", monitor = monitors.laptop })
hl.workspace_rule({ workspace = "8", monitor = monitors.laptop })
hl.workspace_rule({ workspace = "9", monitor = monitors.laptop })
hl.workspace_rule({ workspace = "10", monitor = monitors.laptop })

-- ── Keybindings ───────────────────────────────────────────────────────────────

local terminal = "foot -e tmux new-session"
local fileManager = "thunar"
local menu = "rofi -show drun"
local mainMod = "SUPER"

-- Core
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))

-- Session
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.local/bin/waybar-power-menu.sh"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/waybar-battery-threshold.sh"))

-- Night light — toggle hyprsunset at 3500K
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("pgrep -x hyprsunset && killall hyprsunset || hyprsunset -t 3500"))

-- TUI tools
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("foot --title gazelle gazelle"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("foot --title wiremix wiremix"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("foot --title bluetui bluetui"))

-- Fullscreen / maximize
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Clipboard history picker
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

-- Calculator
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("rofi -show calc -modi calc -no-show-match -no-sort"))

-- Focus — arrow keys and vim keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Move window — arrow keys and vim keys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- Resize window — repeatable
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Focus and move windows between monitors
hl.bind(mainMod .. " + comma", hl.dsp.focus({ monitor = "-1" }))
hl.bind(mainMod .. " + period", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.window.move({ monitor = "-1" }))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.window.move({ monitor = "+1" }))

-- Workspaces — switch (1–9 via loop, 10 via 0 key)
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- btop scratchpad — launch if not running, then toggle visibility
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pgrep -x btop || foot -T btop -e btop"))
hl.bind(mainMod .. " + B", hl.dsp.workspace.toggle_special("btop"))

-- Scroll through workspaces with Super+scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume — repeatable + locked
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),
	{ locked = true, repeating = true }
)

-- Brightness — repeatable + locked
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("swayosd-client --brightness raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("swayosd-client --brightness lower"),
	{ locked = true, repeating = true }
)

-- Media — locked
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots — Print key
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename -]]))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim - | satty --filename -"))
hl.bind(
	mainMod .. " + SHIFT + Print",
	hl.dsp.exec_cmd(
		[[grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | satty --filename -]]
	)
)

-- Screen recording
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("~/.local/bin/record.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.local/bin/record.sh region"))

-- Screenshots — Z binds for Q11 keyboard (no Print key)
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename -]]))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("grim - | satty --filename -"))
hl.bind(
	mainMod .. " + CTRL + Z",
	hl.dsp.exec_cmd(
		[[grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | satty --filename -]]
	)
)

-- Lid close: clamshell if external connected, otherwise lock
hl.bind(
	"switch:on:Lid Switch",
	hl.dsp.exec_cmd(
		'[ "$(hyprctl monitors -j | jq length)" -gt 1 ] && hyprctl keyword monitor "'
			.. monitors.laptop
			.. ',disable" || loginctl lock-session'
	),
	{ locked = true }
)

-- Lid open: re-enable laptop display if it was disabled
hl.bind(
	"switch:off:Lid Switch",
	hl.dsp.exec_cmd(
		'hyprctl monitors | grep -q "^Monitor '
			.. monitors.laptop
			.. '" || hyprctl keyword monitor "'
			.. monitors.laptop
			.. ',1920x1200@60,auto-right,1.25"'
	),
	{ locked = true }
)

-- ── Window rules ──────────────────────────────────────────────────────────────

-- Prevent apps from maximising themselves
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix XWayland drag bug — ghost windows stealing focus mid-drag
hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- pavucontrol
hl.window_rule({
	match = { class = "^(pavucontrol)$" },
	float = true,
	size = "900 600",
	center = true,
})

-- blueman-manager
hl.window_rule({
	match = { class = "^(blueman-manager)$" },
	float = true,
	size = "700 500",
	center = true,
})

-- 1Password — floating prompt and tiling main window are separate rules
hl.window_rule({
	match = { class = "^(1password)$", float = true },
	float = true,
	min_size = "420 400",
	center = true,
})
hl.window_rule({
	match = { class = "^(1password)$", float = false },
	min_size = "800 600",
})

-- satty
hl.window_rule({
	match = { class = "^(com.gabm.satty)$" },
	float = true,
	size = "1200 800",
	center = true,
})

-- Picture-in-picture
hl.window_rule({
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	pin = true,
})

-- btop scratchpad
hl.window_rule({
	match = { title = "^(btop)$" },
	workspace = "special:btop",
})
hl.window_rule({
	match = { title = "^(btop)$" },
	float = true,
	center = true,
	size = "1200 800",
})

-- Floating TUI tools
hl.window_rule({
	match = { title = "^(bluetui)$" },
	float = true,
	center = true,
	size = "800 500",
})
hl.window_rule({
	match = { title = "^(gazelle)$" },
	float = true,
	center = true,
	size = "900 550",
})
hl.window_rule({
	match = { title = "^(wiremix)$" },
	float = true,
	center = true,
	size = "900 550",
})

-- Thunar file operation dialogs
hl.window_rule({
	match = { title = "^(File Operation Progress)$" },
	float = true,
	center = true,
})

-- xdg-desktop-portal-gtk file picker
hl.window_rule({
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
	center = true,
	size = "900 600",
})
