local wezterm = require("wezterm")
local mux = wezterm.mux
local action = wezterm.action

-- Maximize window on startup
wezterm.on("gui-startup", function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

local config = wezterm.config_builder()

-- Improved vim detection function
local function is_vim(pane)
    local process_info = pane:get_foreground_process_info()
    local process_name = process_info and process_info.name
    return process_name == "nvim" or process_name == "vim"
end

-- Enhanced split navigation function
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

-- General appearance
config.color_scheme = "Catppuccin Mocha" -- Match your LazyVim Catppuccin theme
config.font = wezterm.font("JetBrains Mono")
config.font_size = 14
config.line_height = 1.1
config.cell_width = 1.0

-- Window decorations (keeping your existing settings)
config.window_decorations = "RESIZE"
config.window_frame = {
    font_size = 13.0,
}
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.show_new_tab_button_in_tab_bar = false
config.window_padding = {
    bottom = 0,
    left = 0,
    right = 0,
}

-- Terminal behavior
config.scrollback_lines = 10000
config.default_cursor_style = 'SteadyBlock'
config.warn_about_missing_glyphs = false
config.status_update_interval = 10000

-- Keep your PowerShell default program
config.default_prog = { "C:/Program Files/PowerShell/7/pwsh.exe" }

-- Keep your existing leader key
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

-- Combine your existing keys with enhanced LaTeX and Neovim integration
config.keys = {
    -- Your existing keys
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
    
    -- Your split navigation keys
    split_nav("move", "h"),
    split_nav("move", "j"),
    split_nav("move", "k"),
    split_nav("move", "l"),
    split_nav("resize", "h"),
    split_nav("resize", "j"),
    split_nav("resize", "k"),
    split_nav("resize", "l"),
    
    -- Fuzzy finder
    {
        key = "9",
        mods = "ALT",
        action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }),
    },
    
    -- Workspace prompt
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
    
    -- New LaTeX integration keys
    { 
        key = ",", 
        mods = "LEADER", 
        action = action.SpawnCommandInNewTab {
            args = { "nvim", wezterm.config_dir .. "/.wezterm.lua" },
        }
    },
    
    -- Font size adjustments
    { key = "=", mods = "CTRL", action = action.IncreaseFontSize },
    { key = "-", mods = "CTRL", action = action.DecreaseFontSize },
    { key = "0", mods = "CTRL", action = action.ResetFontSize },
    
    -- Copy/Paste
    { key = "c", mods = "CTRL|SHIFT", action = action.CopyTo("Clipboard") },
    { key = "v", mods = "CTRL|SHIFT", action = action.PasteFrom("Clipboard") },
}

-- Add tab number keys (1-9)
for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = action.ActivateTab(i - 1),
    })
end

-- Set environment variables to improve Neovim and terminal integration
config.set_environment_variables = {
    -- Tell Neovim that we have a truecolor terminal
    COLORTERM = "truecolor",
    -- Set terminal type for better colors and compatibility
    TERM = "wezterm",
    -- For better LaTeX support
    TEXTEDITOR = "nvim",
}

-- Keep your tabline plugin
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

-- Keep your tmux-style status
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

-- Add Neovim window detection for cursor styling
wezterm.on("window-config-reloaded", function(window, pane)
    if is_vim(pane) then
        window:set_config_overrides({
            -- Special settings when Neovim is detected
            cursor_blink_rate = 0, -- Disable cursor blinking in Neovim
        })
    end
end)

return config
