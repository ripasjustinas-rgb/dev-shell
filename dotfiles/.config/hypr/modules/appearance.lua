hl.config({
  general = {
    gaps_in = 5, gaps_out = 20, border_size = 2,
    col = {
      -- Material fallback used only until the runtime matugen palette is
      -- applied. Avoid Hyprland's cyan/green sample colors on first frame.
      active_border = { colors = {"rgba(dabaf9ff)", "rgba(d0c1daff)"}, angle = 45 },
      inactive_border = "rgba(968e98aa)",
    },
    resize_on_border = false, allow_tearing = false, layout = "dwindle",
  },
  decoration = {
    rounding = 20, rounding_power = 2, active_opacity = 1.0, inactive_opacity = 0.85,
    shadow = { enabled = true, range = 12, render_power = 4, color = 0xea151218 },
    blur = { enabled = true, size = 7, passes = 2, vibrancy = 0.22 },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  master = { new_status = "master" },
  scrolling = { fullscreen_on_one_column = true },
  -- Hyprpaper owns the background. Do not reveal Hyprland's branded fallback
  -- for the short time a wallpaper is being decoded.
  misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = {{0.23, 1}, {0.32, 1}} })
hl.curve("easeInOutCubic", { type = "bezier", points = {{0.65, 0.05}, {0.36, 1}} })
hl.curve("linear", { type = "bezier", points = {{0, 0}, {1, 1}} })
hl.curve("almostLinear", { type = "bezier", points = {{0.5, 0.5}, {0.75, 1}} })
hl.curve("quick", { type = "bezier", points = {{0.15, 0}, {0.1, 1}} })
hl.curve("riceHighSnap", { type = "spring", mass = 1.0, stiffness = 145.0, dampening = 18.0 })
hl.curve("riceHighFloat", { type = "spring", mass = 1.0, stiffness = 90.0, dampening = 16.0 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.3, spring = "riceHighSnap" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.9, spring = "riceHighSnap", style = "slide bottom" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.0, spring = "riceHighFloat", style = "popin 85%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.9, spring = "riceHighSnap" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, spring = "riceHighFloat" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.6, spring = "riceHighSnap", style = "slidefade 24%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.3, spring = "riceHighSnap", style = "slide left" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.1, spring = "riceHighFloat", style = "slide right" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
