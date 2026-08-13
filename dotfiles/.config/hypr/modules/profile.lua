local profile = "laptop"
local home = os.getenv("HOME") or ""
local state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
local marker = io.open(state_home .. "/dev-shell/active-profile", "r")

if marker then
  local selected = marker:read("*l")
  marker:close()
  if selected == "laptop" or selected == "desktop" then
    profile = selected
  end
end

require("modules.profiles." .. profile)
