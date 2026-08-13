-- RTX 2080 Ti desktop profile. These are the two NVIDIA variables currently
-- recommended by Hyprland; legacy WLR_NO_HARDWARE_CURSORS is intentionally not
-- used.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Xiaomi Mi Monitor: use the highest refresh mode reported by Hyprland.
-- The generic preferred/auto rule in modules/monitors.lua remains a fallback
-- for newly connected outputs.
hl.monitor({ output = "DP-3", mode = "2560x1440@180", position = "0x0", scale = "1" })
