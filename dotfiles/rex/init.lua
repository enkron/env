-- Rex configuration: keeps the tmux.conf prefix (`Ctrl+s`) and key tables for muscle memory.
-- Rex keys are written unshifted: `|` is shift+\, `_` is shift+-, `"` is shift+', `%` is shift+5.
-- The default cmd+... shortcuts stay as they are.
--
-- Validate with `rex config check`, apply with `rex config reload`, inspect with `rex keymap`.

local P = "ctrl+s>"

-- Legacy control keys for readline/zle emacs bindings (as ghostty.conf does for ^M/^I). Rex sends
-- nothing for these four; every other ctrl+letter, ctrl+space, ctrl+/ and alt+key already sends
-- its usual byte. Bracketed physical-key names keep `[` and `-` unambiguous
rex.bind("ctrl+m", "pane.send_key", { key = "enter" })                -- ^M, CR
rex.bind("ctrl+i", "pane.send_key", { key = "tab" })                  -- ^I, HT
rex.bind("ctrl+[BracketLeft]", "pane.send_key", { key = "escape" })   -- ^[, ESC
rex.bind("ctrl+shift+[Minus]", "pane.send_key", { key = "ctrl+/" })   -- ^_, undo

-- Send the prefix through to the program (tmux `bind C-s send-prefix`); also drives a remote
-- tmux running this repo's tmux.conf. A stock remote tmux gets `Ctrl+b` directly, as Rex leaves
-- it unbound, so the tmux F12 passthrough is not needed
rex.bind(P .. "ctrl+s", "pane.send_key", { key = "ctrl+s" })

-- Splits: `"`/`_` below, `%`/`|` right. Rex has no full-width (`-f`) split, so both pairs match
rex.bind(P .. "shift+'", "pane.split", { direction = "down" })
rex.bind(P .. "shift+-", "pane.split", { direction = "down" })
rex.bind(P .. "shift+5", "pane.split", { direction = "right" })
rex.bind(P .. "shift+\\", "pane.split", { direction = "right" })

-- Windows are Rex tabs, numbered from 1 like tmux `base-index 1`
rex.bind(P .. "c", "client.tab.new")
rex.bind(P .. "n", "client.tab.next")
rex.bind(P .. "p", "client.tab.previous")
rex.bind(P .. ",", "client.tab.rename")
for i = 1, 9 do
  rex.bind(P .. i, "client.tab.goto", { index = i })
end

-- vim-like pane switching
rex.bind(P .. "h", "pane.focus.left")
rex.bind(P .. "j", "pane.focus.down")
rex.bind(P .. "k", "pane.focus.up")
rex.bind(P .. "l", "pane.focus.right")
rex.bind(P .. "o", "pane.focus_next")

-- One-shot resize (tmux C-h/j/k/l); `amount` units are undocumented, values mirror tmux.conf
rex.bind(P .. "ctrl+h", "pane.resize", { direction = "left", amount = 1 })
rex.bind(P .. "ctrl+j", "pane.resize", { direction = "down", amount = 2 })
rex.bind(P .. "ctrl+k", "pane.resize", { direction = "up", amount = 2 })
rex.bind(P .. "ctrl+l", "pane.resize", { direction = "right", amount = 1 })

-- Resize mode (tmux `-T resize`): h/j/k/l and arrows step, H/J/K/L take a coarse step, M-h/j/k/l
-- move the pane, `=` balances, Escape/Enter/q leave. Exclusive: stray keys never reach the shell
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
    rex.bind("resize/" .. key, "pane.resize", { direction = r.dir, amount = r.step })
  end
  rex.bind("resize/shift+" .. r.keys[1], "pane.resize", { direction = r.dir, amount = 5 })
  rex.bind("resize/alt+" .. r.keys[1], "pane.move." .. r.dir)
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/escape", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/q", "client.mode.exit")

-- Panes: zoom (stock `z`), float toggle (stock `@`), kill (`x`; Rex closes without a confirm)
rex.bind(P .. "z", "pane.zoom")
rex.bind(P .. "shift+2", "pane.float")
rex.bind(P .. "x", "pane.close")

-- Sessions (stock `s` chooser and `$` rename)
rex.bind(P .. "s", "session.switch")
rex.bind(P .. "shift+4", "session.rename")

-- Rex has no status line; `e` toggles the sidebar, the closest chrome to hide
rex.bind(P .. "e", "client.sidebar.toggle")

-- Rex has no copy mode; `/` opens its scrollback search
rex.bind(P .. "/", "client.find.open")

-- Reload configuration file (tmux `R`)
rex.bind(P .. "shift+r", "client.config.reload")
