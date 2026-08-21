#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
omarchy plugin validate "$plugin_dir"
qmllint -I "$OMARCHY_PATH/shell" \
  "$plugin_dir/VpnState.qml" \
  "$plugin_dir/ExpressVpnIcon.qml" \
  "$plugin_dir/BarWidget.qml" \
  "$plugin_dir/Panel.qml"
