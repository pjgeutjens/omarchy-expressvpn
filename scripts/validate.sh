#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
omarchy plugin validate "$plugin_dir"
qmllint -I "$OMARCHY_PATH/shell" \
  "$plugin_dir/VpnState.qml" \
  "$plugin_dir/ExpressVpnIcon.qml" \
  "$plugin_dir/BarWidget.qml" \
  "$plugin_dir/Panel.qml"

if rg -n --glob '*.qml' '(^|[[:space:]])(TextField|TextInput|TextEdit)[[:space:]]*[{]' "$plugin_dir"; then
  echo "Writable native text inputs are forbidden: they can receive unbounded clipboard offers." >&2
  exit 1
fi

cli_start_guards=$(rg -c 'onRunningChanged: if \(!running && !launchConfirmed\) root\.handleCliStartFailure\(' \
  "$plugin_dir/VpnState.qml" || true)
if [[ "$cli_start_guards" -ne 5 ]]; then
  echo "Every ExpressVPN CLI process must invalidate stale state when launch fails." >&2
  exit 1
fi

cli_epoch_guards=$(rg -c 'if \(launchEpoch !== root\.cliEpoch\) return' \
  "$plugin_dir/VpnState.qml" || true)
if [[ "$cli_epoch_guards" -ne 4 ]]; then
  echo "In-flight ExpressVPN CLI results must not revive invalidated state." >&2
  exit 1
fi
