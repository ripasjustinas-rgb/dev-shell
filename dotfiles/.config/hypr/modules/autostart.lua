hl.on("hyprland.start", function()
  hl.exec_cmd("pkill waybar; qs --no-duplicate --config laptopui")
end)
