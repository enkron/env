-- Rex configuration: keeps the tmux.conf prefix (`Ctrl+s`) and key tables for muscle memory.
-- Rex keys are written unshifted: `H` is shift+h, `@` is shift+2, `$` is shift+4.
-- The default cmd+... shortcuts stay as they are.
--
-- Validate with `rex config check`, apply with `rex config reload`, inspect with `rex keymap`.

local P = "ctrl+s>"

-- Floating panes live in layers of kind "floating" in session.view; the client actions cover
-- creating and minimizing them but not restoring or resizing, so these helpers drive the server
-- API directly

-- The window holding `block_id` (else the active one), and the layer `block_id` sits in
local function locate(session_id, block_id)
  local view = rex.call("session.view", { session_id = session_id })
  local active
  for _, win in ipairs(view.windows or {}) do
    if win.window_id == view.active_window_id then active = win end
    for _, layer in ipairs(win.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        if b.block_id == block_id then return win, layer end
      end
    end
  end
  return active, nil
end

-- Show/hide toggle (tmux display-popup): minimize the focused floating pane; otherwise raise and
-- focus the frontmost floating pane, minimized or not; with none in the window, open one
rex.action{
  name = "float_toggle",
  title = "Toggle Floating Pane",
  category = "Pane",
  run = function(ctx)
    local win, layer = locate(ctx.session_id, ctx.block_id)
    if layer and layer.kind == "floating" then
      rex.client.queue("pane.minimize_floating")
      return
    end
    local front
    for _, l in ipairs(win and win.layers or {}) do
      if l.kind == "floating" and #(l.blocks or {}) > 0 then front = l end
    end
    if front then
      rex.call("session.set_layer_state",
        { session_id = ctx.session_id, layer_id = front.layer_id, state = "normal", focus = true })
    else
      rex.client.queue("pane.new_floating")
    end
  end,
}

-- pane.resize ignores floating panes, so resize their layer instead: right/down grow the pane
-- from its right/bottom edge, left/up shrink it. `amount` is in percent of the window, as layer
-- bounds are fractions; tiled panes fall through to pane.resize unchanged. `repeats` lets a held
-- key keep resizing, as it does for the built-in pane.resize; actions default to one press
local MIN_FLOAT = 0.1
rex.action{
  name = "pane_resize",
  title = "Resize Pane (Tiled or Floating)",
  category = "Pane",
  repeats = true,
  run = function(ctx, args)
    local _, layer = locate(ctx.session_id, ctx.block_id)
    if not (layer and layer.kind == "floating") then
      rex.client.queue("pane.resize", { direction = args.direction, amount = args.amount })
      return
    end
    local x, y, w, h = layer.bounds[1], layer.bounds[2], layer.bounds[3], layer.bounds[4]
    local d = (args.amount or 1) / 100
    if args.direction == "right" then w = w + d
    elseif args.direction == "left" then w = w - d
    elseif args.direction == "down" then h = h + d
    elseif args.direction == "up" then h = h - d
    end
    -- Keep the layer inside the window: shift it back when it outgrows an edge
    w = math.max(MIN_FLOAT, math.min(w, 1))
    h = math.max(MIN_FLOAT, math.min(h, 1))
    x = math.max(0, math.min(x, 1 - w))
    y = math.max(0, math.min(y, 1 - h))
    rex.call("session.resize_layer",
      { session_id = ctx.session_id, layer_id = layer.layer_id, bounds = { x, y, w, h } })
  end,
}

-- Legacy control keys for readline/zle emacs bindings (as ghostty.conf does for ^M/^I). Rex sends
-- nothing for these four; every other ctrl+letter, ctrl+space, ctrl+/ and alt+key already sends
-- its usual byte. Bracketed physical-key names keep `[` and `-` unambiguous. Rex also applies
-- these in its own text fields (e.g. tab rename), where ^M closes the field and sends Enter to the
-- terminal; DefaultKeyBinding.dict alone fixes the fields but leaves terminals without ^M
rex.bind("ctrl+m", "pane.send_key", { key = "enter" })                -- ^M, CR
rex.bind("ctrl+i", "pane.send_key", { key = "tab" })                  -- ^I, HT
rex.bind("ctrl+[BracketLeft]", "pane.send_key", { key = "escape" })   -- ^[, ESC
rex.bind("ctrl+shift+[Minus]", "pane.send_key", { key = "ctrl+/" })   -- ^_, undo

-- Send the prefix through to the program (tmux `bind C-s send-prefix`); also drives a remote
-- tmux running this repo's tmux.conf. A stock remote tmux gets `Ctrl+b` directly, as Rex leaves
-- it unbound, so the tmux F12 passthrough is not needed
rex.bind(P .. "ctrl+s", "pane.send_key", { key = "ctrl+s" })

-- Splits: Shift+h/j/k/l split towards that side, like the native cmd+shift+arrows. The tmux
-- full-width `"`/`%` splits are left out, as Rex has no `-f` split
rex.bind(P .. "shift+h", "pane.split", { direction = "left" })
rex.bind(P .. "shift+j", "pane.split", { direction = "down" })
rex.bind(P .. "shift+k", "pane.split", { direction = "up" })
rex.bind(P .. "shift+l", "pane.split", { direction = "right" })

-- Windows are Rex tabs, numbered from 1 like tmux `base-index 1`
rex.bind(P .. "c", "client.tab.new")
rex.bind(P .. "n", "client.tab.next")
rex.bind(P .. "p", "client.tab.previous")
rex.bind(P .. ",", "client.tab.rename")
for i = 1, 9 do
  rex.bind(P .. i, "client.tab.goto", { index = i })
end

-- Move the tab left/right (tmux `swap-window -t -1`/`+1` on `<`/`>`)
rex.bind(P .. "shift+,", "client.tab.move.backward")
rex.bind(P .. "shift+.", "client.tab.move.forward")

-- Pick any session, tab or pane from a tree (tmux `'` select-window by index or name, and
-- choose-tree)
rex.bind(P .. "'", "pane.go_to")

-- vim-like pane switching; `wrap` crosses from one edge to the other, as tmux select-pane does
local focus = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(focus) do
  rex.bind(P .. key, "pane.focus", { direction = dir, wrap = true })
end
rex.bind(P .. "o", "pane.focus_next")

-- tmux `;` last-pane. Rex has no in-tab last pane; navigate.back walks a jump list of panes
-- across tabs and sessions, so it also returns to a pane in another tab
rex.bind(P .. ";", "client.navigate.back")

-- One-shot resize (tmux C-h/j/k/l); `amount` units are undocumented, values mirror tmux.conf.
-- pane_resize (top of file) also handles floating panes
rex.bind(P .. "ctrl+h", "pane_resize", { direction = "left", amount = 1 })
rex.bind(P .. "ctrl+j", "pane_resize", { direction = "down", amount = 2 })
rex.bind(P .. "ctrl+k", "pane_resize", { direction = "up", amount = 2 })
rex.bind(P .. "ctrl+l", "pane_resize", { direction = "right", amount = 1 })

-- Resize mode (tmux `-T resize`): h/j/k/l and arrows step, H/J/K/L take a coarse step,
-- M-h/j/k/l move the pane, `=` balances, Escape/Enter/^M/q leave. Exclusive: stray keys never
-- reach the shell
rex.mode("resize", { exclusive = true })
rex.bind(P .. "r", "client.mode.enter", { name = "resize" })

local resize = {
  { keys = { "h", "left" }, dir = "left", step = 1 },
  { keys = { "j", "down" }, dir = "down", step = 2 },
  { keys = { "k", "up" }, dir = "up", step = 2 },
  { keys = { "l", "right" }, dir = "right", step = 1 },
}
for _, r in ipairs(resize) do
  for _, key in ipairs(r.keys) do
    rex.bind("resize/" .. key, "pane_resize", { direction = r.dir, amount = r.step })
  end
  rex.bind("resize/shift+" .. r.keys[1], "pane_resize", { direction = r.dir, amount = 5 })
  rex.bind("resize/alt+" .. r.keys[1], "pane.move." .. r.dir)
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/escape", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/q", "client.mode.exit")
rex.bind("resize/ctrl+m", "client.mode.exit")

-- Navigate mode: h/j/k/l and arrows keep moving focus, `o` cycles to the next pane,
-- Escape/Enter/^M/q leave. Exclusive, like resize mode
rex.mode("navigate", { exclusive = true })
rex.bind(P .. "w", "client.mode.enter", { name = "navigate" })

local navigate = {
  { keys = { "h", "left" }, dir = "left" },
  { keys = { "j", "down" }, dir = "down" },
  { keys = { "k", "up" }, dir = "up" },
  { keys = { "l", "right" }, dir = "right" },
}
for _, n in ipairs(navigate) do
  for _, key in ipairs(n.keys) do
    rex.bind("navigate/" .. key, "pane.focus", { direction = n.dir, wrap = true })
  end
end
rex.bind("navigate/o", "pane.focus_next")
rex.bind("navigate/escape", "client.mode.exit")
rex.bind("navigate/enter", "client.mode.exit")
rex.bind("navigate/q", "client.mode.exit")
rex.bind("navigate/ctrl+m", "client.mode.exit")

-- Panes: zoom (stock `z`), float toggle (stock `@`), kill (`x`). Rex closes without the tmux
-- confirm; `u` reopens the last closed pane instead, repeat for the one before
rex.bind(P .. "z", "pane.zoom")
rex.bind(P .. "shift+2", "pane.float")
rex.bind(P .. "x", "pane.close")
rex.bind(P .. "u", "session.undo_close")
rex.bind(P .. "shift+1", "pane.move_to_new_tab") -- tmux `!` break-pane
-- tmux join-pane, with a tab picker; does nothing while the session has only one tab
rex.bind(P .. "m", "pane.move_to_tab")
rex.bind(P .. "shift+t", "pane.rename")          -- tmux select-pane -T

-- Floating panes: `f` shows/hides one (float_toggle, top of file; a hidden pane keeps running),
-- `F` always opens another, `M` hides them all. `o` cycles through them; h/j/k/l do not reach
-- them
rex.bind(P .. "f", "float_toggle")
rex.bind(P .. "shift+f", "pane.new_floating")
rex.bind(P .. "shift+m", "pane.minimize_all_floating")

-- Place the focused floating pane, keeping its size: corner 1-4 (top-left, top-right,
-- bottom-left, bottom-right) or "fill"; with `direction`, nudge it by `amount` percent of the
-- window instead. Tiled panes are left alone
rex.action{
  name = "float_place",
  title = "Place Floating Pane",
  category = "Pane",
  repeats = true,
  run = function(ctx, args)
    local _, layer = locate(ctx.session_id, ctx.block_id)
    if not (layer and layer.kind == "floating") then return end
    local x, y, w, h = layer.bounds[1], layer.bounds[2], layer.bounds[3], layer.bounds[4]
    local d = (args.amount or 5) / 100
    if args.corner == "fill" then x, y, w, h = 0, 0, 1, 1
    elseif args.corner then
      x = (args.corner == 2 or args.corner == 4) and 1 - w or 0
      y = (args.corner == 3 or args.corner == 4) and 1 - h or 0
    elseif args.direction == "left" then x = x - d
    elseif args.direction == "right" then x = x + d
    elseif args.direction == "up" then y = y - d
    elseif args.direction == "down" then y = y + d
    end
    x = math.max(0, math.min(x, 1 - w))
    y = math.max(0, math.min(y, 1 - h))
    rex.call("session.resize_layer",
      { session_id = ctx.session_id, layer_id = layer.layer_id, bounds = { x, y, w, h } })
  end,
}

-- Move mode (tmux 3.8 stock `g` table): one key, then back to normal, as a tmux key table does.
-- 1-4 snap to a corner, 0 fills the window, h/j/k/l nudge. Resize mode (`r`) resizes
rex.mode("move", { exclusive = true })
rex.bind(P .. "g", "client.mode.enter", { name = "move", once = true })
for corner = 1, 4 do
  rex.bind("move/" .. corner, "float_place", { corner = corner })
end
rex.bind("move/0", "float_place", { corner = "fill" })
for key, dir in pairs(focus) do
  rex.bind("move/" .. key, "float_place", { direction = dir, amount = 5 })
end
rex.bind("move/escape", "client.mode.exit")

-- Sessions (stock `s` chooser and `$` rename)
rex.bind(P .. "s", "session.switch")
rex.bind(P .. "shift+4", "session.rename")
rex.bind(P .. "shift+9", "session.previous") -- tmux `(`
rex.bind(P .. "shift+0", "session.next")     -- tmux `)`

-- Rex has no status line; `e` toggles the sidebar, the closest chrome to hide
rex.bind(P .. "e", "client.sidebar.toggle")

-- `/` opens the scrollback search outside copy mode
rex.bind(P .. "/", "client.find.open")

-- Copy mode (tmux `[` with mode-keys vi). The app supplies the keys inside it, as tmux
-- copy-mode-vi does: vi motions, v/V/ctrl+v select, y yanks, / and ? search, f/t find
rex.bind(P .. "[BracketLeft]", "pane.copy_mode.enter")

-- Scroll mode on `{`, kept for what copy mode lacks: `[`/`]` jump between shell prompts,
-- ctrl+u/d and PageUp/PageDown page through scrollback, `/` searches, n/N step through matches,
-- Escape/Enter/^M/q leave. Exclusive, like resize mode
rex.mode("scroll", { exclusive = true })
rex.bind(P .. "shift+[BracketLeft]", "client.mode.enter", { name = "scroll" })

rex.bind("scroll/[BracketLeft]", "client.prompt.previous")
rex.bind("scroll/[BracketRight]", "client.prompt.next")
rex.bind("scroll/ctrl+u", "client.scroll.page_up")
rex.bind("scroll/ctrl+d", "client.scroll.page_down")
rex.bind("scroll/pageup", "client.scroll.page_up")
rex.bind("scroll/pagedown", "client.scroll.page_down")
rex.bind("scroll//", "client.find.open")
rex.bind("scroll/n", "client.find.next")
rex.bind("scroll/shift+n", "client.find.previous")
rex.bind("scroll/escape", "client.mode.exit")
rex.bind("scroll/enter", "client.mode.exit")
rex.bind("scroll/q", "client.mode.exit")
rex.bind("scroll/ctrl+m", "client.mode.exit")

-- Reload configuration file (tmux `R`)
rex.bind(P .. "shift+r", "client.config.reload")

-- Command palette (tmux `:` command-prompt): every action, including the ones defined here
rex.bind(P .. "shift+;", "client.palette.toggle")

-- List keys (tmux `?` list-keys): `rex keymap` in a floating pane, closed by quitting less. It
-- shows this file's bindings and modes, not the app's built-in cmd+... shortcuts
rex.action{
  name = "list_keys",
  title = "List Key Bindings",
  category = "Help",
  run = function(ctx)
    rex.call("session.new_layer", {
      session_id = ctx.session_id,
      bounds = { 0.1, 0.05, 0.8, 0.9 },
      focus = true,
      layout = { block = {
        flavor = "com.superlogical.terminal.shell",
        label = "keys",
        options = { command = { "sh", "-c", "rex keymap --color=always | less -RS" } },
      } },
    })
  end,
}
rex.bind(P .. "shift+/", "list_keys")

-- App settings. Rex keeps them in the app, not in this file, and each client.setting.* action
-- sets one, so this action pins them: run "Apply App Settings" from the command palette
-- (prefix+:) after a fresh install or after changing a value here. `rex do app_settings` works
-- only with Remote Control on (Settings > General). Settings left out stay at the app's default
-- or as set in Settings; `rex actions -C <client>` lists them all.
-- Not pinned: the themes (ecs_theme below imports and selects the dark one), and settings
-- whose stored value has no unambiguous action value (active border opacity, interface style,
-- tab icon tint, inactive window fade, cursor blink)
local APP_SETTINGS = {
  -- Interface
  { "interface.toolbar.layout", "left" },                -- vertical tabs in a left sidebar
  { "interface.toolbar.auto_hide_toolbar", "always_show" },
  { "interface.appearance.glass", false },
  { "interface.panes.density", "comfortable" },
  -- tmux pane-border-status top-floating: Rex headers cover every pane, so on hover only
  { "interface.panes.headers", "on_hover" },
  -- tmux pane-active-border-style fg=#3972a8: the theme's blue
  { "interface.active_panes.active_border", true },
  { "interface.active_panes.active_border_color", "blue" },
  { "interface.active_panes.fade", "both" },             -- dim inactive panes
  { "interface.splits_focus.autobalance", false },
  { "interface.splits_focus.focus_follows_mouse", true },
  { "interface.animation.style", "natural" },
  { "interface.app_icon.selection", "default" },
  { "notifications.overview.position", "bottom_right" },
  -- Terminal
  { "terminal.typography.font", "Hack" },
  { "terminal.typography.size", 14 },
  { "terminal.advanced_fonts.smoothing", false },
  { "terminal.cursor.shaders", true },
  { "terminal.keyboard.option", "sends_alt" },          -- Option is Meta, as in Ghostty
  -- Which-key popup after the prefix, beside prefix+? (list_keys)
  { "terminal.keyboard.sequence_hints", true },
  { "terminal.scrolling.smooth", true },
  -- tmux copy-pipe on mouse selection
  { "terminal.selection.copy_on_select", true },
  -- Selected text keeps its colours, as the bg-only copy-mode-selection-style
  { "terminal.selection.foreground", "cell_foreground" },
  { "terminal.selection.background", "theme" },
  { "terminal.titles.prefer_generated", false },
  -- Developer
  { "developer.mode.enabled", true },
  { "developer.experimental.new_quick_switcher", true },
}

rex.action{
  name = "app_settings",
  title = "Apply App Settings",
  category = "Settings",
  run = function()
    for _, s in ipairs(APP_SETTINGS) do
      rex.client.queue("client.setting." .. s[1], { value = s[2] })
    end
  end,
}

-- ecs colour theme (themes/ecs, from ecs.vim). Rex has no colour options in this file; this
-- action imports the Ghostty-format theme and selects it. Rex keeps its own copy, so run it from
-- the command palette after editing the theme
rex.action{
  name = "ecs_theme",
  title = "Import ecs Theme",
  category = "Themes",
  run = function()
    rex.client.queue("client.theme.import", {
      path = os.getenv("HOME") .. "/rps/github.com/enkron/env/dotfiles/rex/themes/ecs",
    })
  end,
}
