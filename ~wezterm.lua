local wezterm = require("wezterm")
local mux = wezterm.mux
local action = wezterm.action
wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

local config = wezterm.config_builder()

local function is_vim(pane)
	local process_info = pane:get_foreground_process_info()
	local process_name = process_info and process_info.name
  
	return process_name == "nvim" or process_name == "vim"
  end
-- local function is_vim(pane)
-- 	-- This gsub is equivalent to POSIX basename(3)
-- 	-- Given "/foo/bar" returns "bar"
-- 	-- Given "c:\\foo\\bar" returns "bar"
-- 	local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
-- 	return process_name == "nvim" or process_name == "vim"
-- end

-- Spawn a PowerShell in login mode
config.default_prog = { "C:/Program Files/PowerShell/7/pwsh.exe" }

local direction_keys = {
	Left = "h",
	Down = "j",
	Up = "k",
	Right = "l",
	-- reverse lookup
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
  }

config.font = wezterm.font("JetBrains Mono")

local function split_nav(resize_or_move, key)
	return {
	  key = key,
	  mods = resize_or_move == "resize" and "META" or "CTRL",
	  action = wezterm.action_callback(function(win, pane)
		if is_vim(pane) then
		  -- pass the keys through to vim/nvim
		  win:perform_action({
			SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
		  }, pane)
		else
		  if resize_or_move == "resize" then
			win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
		  else
			win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
		  end
		end
	  end),
	}
  end

config.font_size = 18
config.window_decorations = "RESIZE"
config.window_frame = {
	font_size = 13.0,
}
-- config.enable_tab_bar = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.show_new_tab_button_in_tab_bar = false
config.window_padding = {
	bottom = 0,
	left = 0,
	right = 0,
}

config.color_scheme = "Catppuccin Mocha" -- or Macchiato, Frappe, Latte

-- config.window_background_opacity = 0.8
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.warn_about_missing_glyphs = false

config.keys = {

	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },
	{
		key = "\\",
		mods = "LEADER",
		action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = "LEADER",
		action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "m",
		mods = "LEADER",
		action = action.TogglePaneZoomState,
	},
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},

	{
		key = "p",
		mods = "LEADER",
		action = action.ActivateTabRelative(-1),
	},
	{
		key = "n",
		mods = "LEADER",
		action = action.ActivateTabRelative(1),
	},
	-- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
	{
		key = "a",
		mods = "LEADER|CTRL",
		action = action.SendKey({ key = "a", mods = "CTRL" }),
	},
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	{
		key = "9",
		mods = "ALT",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }),
	},
	{
		key = "W",
		mods = "CTRL|SHIFT",
		action = action.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						action.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},
}
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = action.ActivateTab(i - 1),
	})
end

config.status_update_interval = 10000

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

-- tmux status
wezterm.on("update-right-status", function(window, _)
	local SOLID_LEFT_ARROW = ""
	local ARROW_FOREGROUND = { Foreground = { Color = "#c6a0f6" } }
	local prefix = ""

	if window:leader_is_active() then
		prefix = " " .. utf8.char(0x1f30a) -- ocean wave
		SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	end

	if window:active_tab():tab_id() ~= 0 then
		ARROW_FOREGROUND = { Foreground = { Color = "#1e2030" } }
	end -- arrow color based on if tab is first pane

	window:set_left_status(wezterm.format({
		{ Background = { Color = "#cba6f7" } },
		{ Text = prefix },
		ARROW_FOREGROUND,
		{ Text = SOLID_LEFT_ARROW },
	}))
end)


return config
