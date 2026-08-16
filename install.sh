#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
home_dir=${HOME:?HOME must be set}
state_dir="${XDG_STATE_HOME:-$home_dir/.local/state}/dev-shell"
backup_root="$state_dir/backups"
active_profile_file="$state_dir/active-profile"
profile=""
dry_run=0

usage() {
  printf '%s\n' \
    'Usage: ./install.sh <check|install|packages|status|restore> [--profile laptop|desktop] [--dry-run] [backup-id]' \
    'Commands:' \
    '  check     Validate repository, profile and system prerequisites.' \
    '  install   Link tracked dotfiles; conflicting paths are backed up.' \
    '  packages  Install manifest packages with pacman (requires sudo).' \
    '  status    Show managed-path and prerequisite status.' \
    '  restore   Restore paths from one backup id.'
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }

run() {
  if (( dry_run )); then
    printf 'dry-run:'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

require_profile() {
  [[ -n "$profile" ]] || die '--profile laptop or --profile desktop is required'
  [[ -f "$repo_dir/profiles/$profile/profile.env" ]] || die "unknown profile: $profile"
}

load_profile() {
  require_profile
  # profile.env is tracked in this repository and contains declarative values
  # only. Export them so validation helpers and child commands see one profile.
  set -a
  # shellcheck disable=SC1090
  source "$repo_dir/profiles/$profile/profile.env"
  set +a
  [[ "${PROFILE_NAME:-}" == "$profile" ]] || die "PROFILE_NAME does not match directory: $profile"
}

emit_package_list() {
  local file line
  local -A seen=()
  for file in "$repo_dir/packages/arch-common.txt" "$repo_dir/packages/arch-$profile.txt"; do
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" == \#* || -n "${seen[$line]:-}" ]] && continue
      seen[$line]=1
      printf '%s\n' "$line"
    done < "$file"
  done
}

manifest() {
  printf '%s\t%s\n' \
    "$repo_dir/dotfiles/.config/hypr" "$home_dir/.config/hypr" \
    "$repo_dir/dotfiles/.config/btop" "$home_dir/.config/btop" \
    "$repo_dir/dotfiles/.config/kitty" "$home_dir/.config/kitty" \
    "$repo_dir/dotfiles/.config/quickshell/laptopui" "$home_dir/.config/quickshell/laptopui" \
    "$repo_dir/dotfiles/.config/starship.toml" "$home_dir/.config/starship.toml" \
    "$repo_dir/dotfiles/.config/systemd/user/laptopui-hypridle.service" "$home_dir/.config/systemd/user/laptopui-hypridle.service" \
    "$repo_dir/dotfiles/.config/systemd/user/laptopui-lid-inhibit.service" "$home_dir/.config/systemd/user/laptopui-lid-inhibit.service" \
    "$repo_dir/dotfiles/.config/systemd/user/laptopui-clipboard.service" "$home_dir/.config/systemd/user/laptopui-clipboard.service" \
    "$repo_dir/dotfiles/.config/waybar" "$home_dir/.config/waybar" \
    "$repo_dir/dotfiles/.zprofile" "$home_dir/.zprofile" \
    "$repo_dir/dotfiles/.zshrc" "$home_dir/.zshrc" \
    "$repo_dir/dotfiles/.local/bin/launcher" "$home_dir/.local/bin/launcher" \
    "$repo_dir/dotfiles/.local/bin/power-menu" "$home_dir/.local/bin/power-menu" \
    "$repo_dir/dotfiles/.local/bin/power-profile-menu" "$home_dir/.local/bin/power-profile-menu" \
    "$repo_dir/dotfiles/.local/bin/power-profile-status" "$home_dir/.local/bin/power-profile-status" \
    "$repo_dir/dotfiles/.local/bin/laptopui-update-count" "$home_dir/.local/bin/laptopui-update-count" \
    "$repo_dir/dotfiles/.local/bin/laptopui-update" "$home_dir/.local/bin/laptopui-update" \
    "$repo_dir/dotfiles/.local/bin/laptopui-weather" "$home_dir/.local/bin/laptopui-weather" \
    "$repo_dir/dotfiles/.local/bin/laptopui-audio-spectrum" "$home_dir/.local/bin/laptopui-audio-spectrum" \
    "$repo_dir/dotfiles/.local/bin/laptopui-visualizer-daemon" "$home_dir/.local/bin/laptopui-visualizer-daemon" \
    "$repo_dir/dotfiles/.local/bin/laptopui-theme-generate" "$home_dir/.local/bin/laptopui-theme-generate" \
    "$repo_dir/dotfiles/.local/bin/laptopui-apply-hypr-theme" "$home_dir/.local/bin/laptopui-apply-hypr-theme" \
    "$repo_dir/dotfiles/.local/bin/laptopui-launcher-pin" "$home_dir/.local/bin/laptopui-launcher-pin" \
    "$repo_dir/dotfiles/.local/bin/laptopui-clipboard-watch" "$home_dir/.local/bin/laptopui-clipboard-watch" \
    "$repo_dir/dotfiles/.local/bin/laptopui-clipboard-preview" "$home_dir/.local/bin/laptopui-clipboard-preview" \
    "$repo_dir/dotfiles/.local/bin/laptopui-screenshot" "$home_dir/.local/bin/laptopui-screenshot" \
    "$repo_dir/dotfiles/.local/bin/laptopui-lock" "$home_dir/.local/bin/laptopui-lock" \
    "$repo_dir/dotfiles/.local/bin/laptopui-reload" "$home_dir/.local/bin/laptopui-reload" \
    "$repo_dir/dotfiles/.local/bin/laptopui-lid" "$home_dir/.local/bin/laptopui-lid" \
    "$repo_dir/dotfiles/.local/bin/laptopui-wallpaper-next" "$home_dir/.local/bin/laptopui-wallpaper-next" \
    "$repo_dir/dotfiles/.local/bin/laptopui-wallpaper-random" "$home_dir/.local/bin/laptopui-wallpaper-random" \
    "$repo_dir/dotfiles/.local/bin/laptopui-wallpaper-restore" "$home_dir/.local/bin/laptopui-wallpaper-restore"
}

link_is_current() {
  local source=$1 target=$2
  [[ -L "$target" && "$(readlink -f -- "$target")" == "$(readlink -f -- "$source")" ]]
}

check() {
  load_profile
  local failed=0 source target package
  [[ -f "$repo_dir/PLAN.md" ]] || { note 'missing PLAN.md'; failed=1; }
  while IFS=$'\t' read -r source target; do
    [[ -e "$source" || -L "$source" ]] || { note "missing source: $source"; failed=1; }
  done < <(manifest)
  command -v hyprctl >/dev/null || { note 'missing command: hyprctl'; failed=1; }
  command -v pacman >/dev/null || { note 'missing command: pacman'; failed=1; }
  while IFS= read -r package; do
    pacman -Q "$package" >/dev/null 2>&1 || { note "missing package: $package (run: ./install.sh packages --profile $profile)"; failed=1; }
  done < <(emit_package_list)
  if [[ "$profile" == laptop ]] && [[ ! -d /sys/class/power_supply/BAT0 ]]; then
    note 'warning: laptop profile selected but BAT0 is not present'
  fi
  if [[ "$profile" == desktop ]]; then
    [[ "${CPU_PROFILE_BACKEND:-}" == "power-profiles-daemon" ]] || {
      note "unsupported desktop CPU_PROFILE_BACKEND: ${CPU_PROFILE_BACKEND:-unset}"
      failed=1
    }
    [[ "${DESKTOP_PORT_READY:-0}" == 1 ]] || note 'warning: desktop inventory is not marked ready; run scripts/desktop-preflight on that host'
    if [[ -r /sys/module/nvidia_drm/parameters/modeset ]]; then
      [[ "$(< /sys/module/nvidia_drm/parameters/modeset)" == Y ]] || { note 'NVIDIA DRM modeset is not enabled'; failed=1; }
    else
      note 'warning: nvidia_drm is not loaded; verify after reboot on the desktop'
    fi
  fi
  (( failed == 0 )) && note "check passed for profile: $profile"
  return "$failed"
}

install() {
  load_profile
  if [[ "$profile" == desktop && "${DESKTOP_PORT_READY:-0}" != 1 && $dry_run -eq 0 ]]; then
    die 'desktop profile is not ready; run scripts/desktop-preflight and set DESKTOP_PORT_READY=1 first'
  fi
  check
  local backup_id backup_dir source target relative
  backup_id=$(date -u +%Y%m%dT%H%M%SZ)
  backup_dir="$backup_root/$backup_id"
  while IFS=$'\t' read -r source target; do
    if link_is_current "$source" "$target"; then
      note "unchanged: $target"
      continue
    fi
    run mkdir -p -- "$(dirname -- "$target")"
    if [[ -e "$target" || -L "$target" ]]; then
      relative=${target#"$home_dir"/}
      run mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
      run mv -- "$target" "$backup_dir/$relative"
      if (( ! dry_run )); then printf '%s\t%s\n' "$target" "$relative" >> "$backup_dir/backed.tsv"; fi
    fi
    run ln -s -- "$source" "$target"
    if (( ! dry_run )); then
      mkdir -p -- "$backup_dir"
      printf '%s\n' "$target" >> "$backup_dir/managed.txt"
    fi
    note "linked: $target"
  done < <(manifest)
  if (( ! dry_run )); then
    mkdir -p -- "$backup_dir"
    touch "$backup_dir/managed.txt"
    if [[ -f "$active_profile_file" ]]; then
      cp -- "$active_profile_file" "$backup_dir/active-profile.before"
    else
      : > "$backup_dir/active-profile.absent"
    fi
    mkdir -p -- "$state_dir"
    printf '%s\n' "$profile" > "$active_profile_file"
    printf '%s\n' "$profile" > "$backup_dir/profile"
    refresh_clipboard_watcher
    note "backup id: $backup_id"
    note "active profile: $profile"
  else
    note "dry-run: write active profile '$profile' to $active_profile_file"
  fi
}

packages() {
  load_profile
  local -a packages_to_install=()
  mapfile -t packages_to_install < <(emit_package_list)
  run sudo pacman --needed -S "${packages_to_install[@]}"
}

refresh_clipboard_watcher() {
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl --user daemon-reload >/dev/null 2>&1 || {
    note 'warning: could not reload user systemd; clipboard watcher starts with the next Hyprland session'
    return 0
  }
  systemctl --user restart laptopui-clipboard.service >/dev/null 2>&1 || \
    note 'warning: could not start clipboard watcher; it starts with the next Hyprland session'
}

status() {
  local source target state
  while IFS=$'\t' read -r source target; do
    if link_is_current "$source" "$target"; then state='linked';
    elif [[ -e "$target" || -L "$target" ]]; then state='unmanaged';
    else state='missing'; fi
    printf '%-10s %s\n' "$state" "$target"
  done < <(manifest)
  printf 'quickshell: '; command -v qs >/dev/null && qs --version || printf 'not installed\n'
  printf 'btop: '; command -v btop >/dev/null && printf 'available\n' || printf 'not installed (run packages)\n'
  printf 'weather forecast helper: '
  if [[ -x "$home_dir/.local/bin/laptopui-weather" ]] && command -v curl >/dev/null && command -v jq >/dev/null; then
    printf 'ready (requires internet when opened)\n'
  else
    printf 'missing helper, curl, or jq (run install and packages)\n'
  fi
  printf 'clipboard watcher: '
  if command -v systemctl >/dev/null && clipboard_state=$(systemctl --user is-active laptopui-clipboard.service 2>/dev/null); then
    printf '%s\n' "$clipboard_state"
  else
    printf 'inactive or unavailable\n'
  fi
  printf 'screenshot helpers: '
  if [[ -x "$home_dir/.local/bin/laptopui-screenshot" && -x "$home_dir/.local/bin/laptopui-clipboard-preview" ]]; then
    printf 'ready\n'
  else
    printf 'missing (run install)\n'
  fi
  printf 'active profile: '; [[ -f "$active_profile_file" ]] && sed -n '1p' "$active_profile_file" || printf 'not selected\n'
  printf 'backups: '; [[ -d "$backup_root" ]] && find "$backup_root" -mindepth 1 -maxdepth 1 -type d -printf '%f ' | sort || true; printf '\n'
}

restore() {
  local backup_id=${1:-}
  [[ "$backup_id" =~ ^[0-9]{8}T[0-9]{6}Z$ ]] || die 'restore needs a valid backup id from status'
  local backup_dir="$backup_root/$backup_id" target relative
  [[ -d "$backup_dir" && -f "$backup_dir/managed.txt" ]] || die "backup not found: $backup_id"
  while IFS= read -r target; do
    [[ "$target" == "$home_dir"/* ]] || die "unsafe target in backup: $target"
    if [[ -L "$target" ]]; then run rm -- "$target"; fi
  done < "$backup_dir/managed.txt"
  if [[ -f "$backup_dir/backed.tsv" ]]; then
    while IFS=$'\t' read -r target relative; do
      [[ "$target" == "$home_dir"/* && "$relative" != /* && "$relative" != *..* ]] || die 'unsafe backup record'
      run mkdir -p -- "$(dirname -- "$target")"
      run mv -- "$backup_dir/$relative" "$target"
    done < "$backup_dir/backed.tsv"
  fi
  if [[ -f "$backup_dir/active-profile.before" ]]; then
    run mkdir -p -- "$state_dir"
    run cp -- "$backup_dir/active-profile.before" "$active_profile_file"
  elif [[ -f "$backup_dir/active-profile.absent" && -f "$active_profile_file" ]]; then
    run rm -- "$active_profile_file"
  fi
  note "restored: $backup_id"
}

command=${1:-}
[[ -n "$command" ]] || { usage; exit 2; }
shift || true
restore_arg=""
while (( $# )); do
  case "$1" in
    --profile) profile=${2:-}; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) [[ -z "$restore_arg" ]] || die "unexpected argument: $1"; restore_arg=$1; shift ;;
  esac
done

case "$command" in
  check) check ;;
  install) install ;;
  packages) packages ;;
  status) status ;;
  restore) restore "$restore_arg" ;;
  *) usage; exit 2 ;;
esac
