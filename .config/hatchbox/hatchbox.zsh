# Add this to your ~/.zshrc or source it from there:
#   source ~./config/hatchbox/hatchbox.zsh

hatchbox() {
  # ----------------------------
  # App configs: "app_name" "ssh_app_name|ssh_target"
  #
  # ssh_target can be:
  #   - An SSH config alias (e.g. my-server)
  #   - A hostname (prefixed with deploy@ automatically if no @ present)
  # ----------------------------
  typeset -A APPS
  APPS=(
    # "app name"       "app name|host alias or host ip"

    # ex.
    # "acme"       "acme|123.45.67.8"
    # "blogger"    "blogger|bloggerserverhostalias"
  )

  local usage="Usage: hatchbox <app> [command] [options]

Apps:
  ${(kj:\n  :)APPS:-  (none configured — edit the APPS map in hatchbox.zsh)}

Commands:
  (none)        Open a plain SSH session
  console       Start a Rails console on the server
  current       Open a shell in the current release directory
  logs <name>   Tail systemd journal logs for <app>-<name>

Options:
  --help        Show this help message

Examples:
  hatchbox myapp                        # SSH session
  hatchbox myapp console                # Rails console
  hatchbox myapp logs server            # Tail server logs
  hatchbox myapp logs solid_queue       # Tail queue worker logs"

  # ----------------------------
  # Parse app name
  # ----------------------------
  if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    echo "$usage"
    return 0
  fi

  local app_key="$1"
  shift

  if [[ -z "${APPS[$app_key]:-}" ]]; then
    echo "❌ Error: unknown app '$app_key'"
    echo ""
    echo "Available apps: ${(kj:, :)APPS:-none configured}"
    return 1
  fi

  local config="${APPS[$app_key]}"
  local ssh_app_name="${config%%|*}"
  local ssh_target="${config##*|}"

  # If target has no @, assume deploy@ user
  if [[ "$ssh_target" != *@* ]]; then
    # Check if it looks like a hostname (contains a dot) vs an alias
    # For aliases, don't prepend user — SSH config handles it
    # For bare hostnames, prepend deploy@
    if [[ "$ssh_target" == *.* ]]; then
      ssh_target="deploy@$ssh_target"
    fi
  fi

  # ----------------------------
  # Parse command
  # ----------------------------
  local cmd=""
  local arg=""

  if [[ $# -gt 0 ]]; then
    case "$1" in
      --help|-h)
        echo "$usage"
        return 0
        ;;
      console|current|logs)
        cmd="$1"
        shift
        ;;
      *)
        echo "❌ Error: unknown command '$1'"
        echo "Run 'hatchbox --help' for usage."
        return 1
        ;;
    esac
  fi

  if [[ $# -gt 0 ]]; then
    arg="$1"
    shift
  fi

  if [[ $# -gt 0 ]]; then
    echo "❌ Error: unexpected argument '$1'"
    return 1
  fi

  # ----------------------------
  # Execute
  # ----------------------------
  echo ""
  echo "🌐 Connecting to $ssh_target ($app_key)"

  case "$cmd" in
    console)
      echo "🟢 Booting Rails console in $ssh_app_name/current..."
      echo ""
      ssh -t "$ssh_target" "cd \$HOME/$ssh_app_name/current && bundle exec rails c"
      ;;

    current)
      echo "🟢 Opening shell in $ssh_app_name/current..."
      echo ""
      ssh -t "$ssh_target" "cd \$HOME/$ssh_app_name/current && exec \$SHELL"
      ;;

    logs)
      if [[ -z "$arg" ]]; then
        echo ""
        echo "❌ Error: logs command requires a process name, e.g. hatchbox $app_key logs server"
        return 1
      fi
      local logs_unit="${ssh_app_name}-${arg}"
      echo ""
      echo "📜 Checking unit $logs_unit..."
      echo ""
      if ! ssh "$ssh_target" "systemctl --user list-units --full --no-legend | grep -q '$logs_unit'"; then
        echo "❌ Error: unit '$logs_unit' not found on $ssh_target"
        return 1
      fi
      echo "📜 Tailing logs for unit $logs_unit..."
      echo ""
      ssh -t "$ssh_target" "journalctl --user --unit=$logs_unit --follow"
      ;;

    "")
      echo ""
      echo "🔑 Opening default SSH session..."
      echo ""
      ssh "$ssh_target"
      ;;
  esac
}
