-- RTX 2080 Ti desktop profile. These are the two NVIDIA variables currently
-- recommended by Hyprland; legacy WLR_NO_HARDWARE_CURSORS is intentionally not
-- used.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Fill exact outputs after running scripts/desktop-preflight on the desktop.
-- Keep the generic preferred/auto rule from modules/monitors.lua as a safe
-- fallback until then. Example:
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = "1" })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "2560x0", scale = "1" })
