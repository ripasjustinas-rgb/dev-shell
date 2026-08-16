local mainMod = "SUPER"
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("qs -c laptopui ipc call laptopui toggleCommandPalette"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs -c laptopui ipc call laptopui toggleControlCenter"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c laptopui ipc call laptopui toggleNotifications"))
-- hyprexpose owns the live Hyprland window thumbnails. It is a persistent
-- user service; Super+Tab only toggles its zero-idle-cost overlay.
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("pkill -SIGUSR1 -x laptopui-hyprex"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("$HOME/.local/bin/laptopui-lock"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
for _, direction in ipairs({"left", "right", "up", "down"}) do
  hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
end
for i = 1, 5 do
  local key = i
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("$HOME/.local/bin/laptopui-screenshot full"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("$HOME/.local/bin/laptopui-screenshot region"))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+; qs -c laptopui ipc call laptopui osd volume"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; qs -c laptopui ipc call laptopui osd volume"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; qs -c laptopui ipc call laptopui osd volume"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; qs -c laptopui ipc call laptopui osd mic"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+; qs -c laptopui ipc call laptopui osd brightness"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-; qs -c laptopui ipc call laptopui osd brightness"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("$HOME/.local/bin/laptopui-lid close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("$HOME/.local/bin/laptopui-lid open"), { locked = true })
