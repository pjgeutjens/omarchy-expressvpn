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
