hl.on("hyprland.start", function()
  hl.exec_cmd("pkill waybar; $HOME/.local/bin/laptopui-wallpaper-random; qs --no-duplicate --config laptopui")
  hl.exec_cmd("systemctl --user start laptopui-hypridle.service laptopui-lid-inhibit.service laptopui-clipboard.service")
end)

-- A config reload reapplies appearance.lua defaults. Restore the current
-- wallpaper palette immediately so borders and shadows remain dynamic.
hl.on("config.reloaded", function()
  hl.exec_cmd("$HOME/.local/bin/laptopui-apply-hypr-theme")
end)
