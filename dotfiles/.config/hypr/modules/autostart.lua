hl.on("hyprland.start", function()
  hl.exec_cmd("pkill waybar; $HOME/.local/bin/laptopui-wallpaper-random; qs --no-duplicate --config laptopui")
end)
