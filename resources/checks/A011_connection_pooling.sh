# Detect pgbouncer presence and status
if [[ "${SSH_SUPPORT}" = "false" ]]; then
  echo "SSH is not supported, skipping..." >&2
  exit 1
fi

installed=$(${CHECK_HOST_CMD} "command -v pgbouncer >/dev/null && echo yes || echo no")
running=$(${CHECK_HOST_CMD} "pgrep -x pgbouncer >/dev/null && echo yes || echo no")

json="{\"pgbouncer_installed\": \"$installed\", \"pgbouncer_running\": \"$running\"}"
json=$(jq -n "$json")
echo "$json"
