-- Rex configuration: keeps the tmux.conf prefix (`Ctrl+s`) and key tables for muscle memory.
-- Rex keys are written unshifted: `H` is shift+h, `@` is shift+2, `$` is shift+4.
-- The default cmd+... shortcuts stay as they are.
--
-- Validate with `rex config check`, apply with `rex config reload`, inspect with `rex keymap`.

local P = "ctrl+s>"

-- Floating panes live in layers of kind "floating" in session.view; the client actions cover
-- creating them but not toggling or resizing, so these helpers drive the server API directly

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
      rex.call("session.set_layer_state",
        { session_id = ctx.session_id, layer_id = layer.layer_id, state = "minimized" })
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

-- vim-like pane switching; `wrap` crosses from one edge to the other, as tmux select-pane does.
-- tmux `;` (last-pane) waits for pane.focus_recent.in_tab, documented but not in this build
local focus = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(focus) do
  rex.bind(P .. key, "pane.focus", { direction = dir, wrap = true })
end
rex.bind(P .. "o", "pane.focus_next")

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

-- Panes: zoom (stock `z`), float toggle (stock `@`), kill (`x`; Rex closes without a confirm)
rex.bind(P .. "z", "pane.zoom")
rex.bind(P .. "shift+2", "pane.float")
rex.bind(P .. "x", "pane.close")
rex.bind(P .. "shift+1", "pane.move_to_new_tab") -- tmux `!` break-pane

-- Floating panes: `f` shows/hides one (float_toggle, top of file; a hidden pane keeps running),
-- `F` always opens another, `M` hides them all. `o` cycles through them; h/j/k/l do not reach
-- them
rex.bind(P .. "f", "float_toggle")
rex.bind(P .. "shift+f", "pane.new_floating")
rex.bind(P .. "shift+m", "pane.minimize_all_floating")

-- Sessions (stock `s` chooser and `$` rename)
rex.bind(P .. "s", "session.switch")
rex.bind(P .. "shift+4", "session.rename")
rex.bind(P .. "shift+9", "session.previous") -- tmux `(`
rex.bind(P .. "shift+0", "session.next")     -- tmux `)`

-- Rex has no status line; `e` toggles the sidebar, the closest chrome to hide
rex.bind(P .. "e", "client.sidebar.toggle")

-- Rex has no copy mode (no keyboard selection); `/` opens its scrollback search
rex.bind(P .. "/", "client.find.open")

-- Scroll mode (closest to tmux `[` copy mode): `[`/`]` jump between shell prompts, ctrl+u/d and
-- PageUp/PageDown page through scrollback, `/` searches, n/N step through matches,
-- Escape/Enter/^M/q leave. Exclusive, like resize mode
rex.mode("scroll", { exclusive = true })
rex.bind(P .. "[BracketLeft]", "client.mode.enter", { name = "scroll" })

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
