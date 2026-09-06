local monitors = require("monitors")

-- ── Environment variables ─────────────────────────────────────────────────────

local local_bin = os.getenv("HOME") .. "/.local/bin"
local path = os.getenv("PATH") or ""

if not path:find(local_bin, 1, true) then
	path = local_bin .. ":" .. path
end

hl.env("PATH", path)
hl.env("SSH_AUTH_SOCK", os.getenv("HOME") .. "/.1password/agent.sock")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "default")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ── Autostart ─────────────────────────────────────────────────────────────────

hl.on("hyprland.start", function()
	hl.exec_cmd("quickshell -c shell")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("wl-clip-persist --clipboard regular")
	hl.exec_cmd("udiskie --no-tray")
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
			natural_scroll = true,
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

local terminal = "kitty"
local fileManager = "thunar"
local menu = "fuzzel"
local mainMod = "SUPER"

-- Core
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { desc = "Apps: Open terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { desc = "Windows: Close focused window" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "Apps: Open file manager" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Windows: Toggle floating" })
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu), { desc = "Apps: Open launcher" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { desc = "Windows: Toggle pseudotile" })
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"), { desc = "Windows: Toggle split direction" })

-- Session
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("hyprlock"), { desc = "Session: Lock screen" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("qs -c shell ipc call powermenu toggle"), { desc = "Session: Power menu" })
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("qs -c shell ipc call powertuning toggle"), { desc = "Session: Power tuning" })

-- Night light — toggle wlsunset at 3500K
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("nightlight toggle"), { desc = "Display: Toggle night light" })

-- Shell panels
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("qs -c shell ipc call audio toggle"), { desc = "Panels: Audio" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("qs -c shell ipc call bluetooth toggle"), { desc = "Panels: Bluetooth" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs -c shell ipc call network toggle"), { desc = "Panels: Network" })
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("qs -c shell ipc call display toggle"), { desc = "Panels: Display" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("qs -c shell ipc call notifications toggle"), { desc = "Panels: Notifications" })
hl.bind(mainMod .. " + SLASH", hl.dsp.exec_cmd("qs -c shell ipc call keybinds toggle"), { desc = "Panels: Keybinds cheat sheet" })

-- Fullscreen / maximize
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { desc = "Windows: Toggle fullscreen" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { desc = "Windows: Toggle maximize" })

-- Clipboard history picker
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"), { desc = "Apps: Clipboard history" })

-- Focus — arrow keys and vim keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }), { desc = "Focus: Focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), { desc = "Focus: Focus right" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }), { desc = "Focus: Focus up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }), { desc = "Focus: Focus down" })
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Move window — arrow keys and vim keys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }), { desc = "Windows: Move window left" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }), { desc = "Windows: Move window right" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }), { desc = "Windows: Move window up" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }), { desc = "Windows: Move window down" })
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- Resize window — repeatable
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true, desc = "Windows: Resize wider" })
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true, desc = "Windows: Resize narrower" })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true, desc = "Windows: Resize shorter" })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true, desc = "Windows: Resize taller" })

-- Focus and move windows between monitors
hl.bind(mainMod .. " + comma", hl.dsp.focus({ monitor = "-1" }), { desc = "Monitors: Focus previous monitor" })
hl.bind(mainMod .. " + period", hl.dsp.focus({ monitor = "+1" }), { desc = "Monitors: Focus next monitor" })
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.window.move({ monitor = "-1" }), { desc = "Monitors: Move window to previous monitor" })
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.window.move({ monitor = "+1" }), { desc = "Monitors: Move window to next monitor" })

-- Workspaces — switch (1–9 via loop, 10 via 0 key)
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }), i == 1 and { desc = "Workspaces: Focus workspace (1–9, 0 = 10)" } or nil)
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), i == 1 and { desc = "Workspaces: Move window to workspace (1–9, 0 = 10)" } or nil)
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { desc = "Workspaces: Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { desc = "Workspaces: Move window to scratchpad" })

-- btop scratchpad — launch if not running, toggle visibility
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pgrep -x btop > /dev/null || kitty --class=floating-btop -e btop"))
hl.bind(mainMod .. " + B", hl.dsp.workspace.toggle_special("btop"), { desc = "Apps: Toggle btop scratchpad" })

-- Updates panel
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("qs -c shell ipc call updates toggle"), { desc = "Apps: Toggle updates panel" })

-- Scroll through workspaces with Super+scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Workspaces: Cycle workspaces (scroll)" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Windows: Drag to move" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Windows: Drag to resize" })

-- Volume — repeatable + locked
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true, desc = "Media: Volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, desc = "Media: Volume down" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true, desc = "Media: Toggle mute" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true, desc = "Media: Toggle mic mute" }
)

-- Brightness — repeatable + locked
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightness up"), { locked = true, repeating = true, desc = "Media: Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness down"), { locked = true, repeating = true, desc = "Media: Brightness down" })

-- Media — locked
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, desc = "Media: Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Media: Play/pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Media: Play/pause" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, desc = "Media: Previous track" })

-- Screenshots — Print key
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename -]]), { desc = "Screenshots: Select area" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim - | satty --filename -"), { desc = "Screenshots: Full screen" })
hl.bind(
	mainMod .. " + SHIFT + Print",
	hl.dsp.exec_cmd(
		[[grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | satty --filename -]]
	),
	{ desc = "Screenshots: Active window" }
)

-- Screen recording
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("record screen"), { desc = "Recording: Record screen" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("record region"), { desc = "Recording: Record region" })

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
	{ locked = true, desc = "System: Lock or disable laptop screen on lid close" }
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
	{ locked = true, desc = "System: Re-enable laptop screen on lid open" }
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
	match = { class = "^(floating-btop)$" },
	workspace = "special:btop",
})
hl.window_rule({
	match = { class = "^(floating-btop)$" },
	float = true,
	center = true,
	size = "1200 800",
})

-- nmtui, launched from the network panel
hl.window_rule({
	match = { class = "^(floating-tui)$" },
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
