#!/usr/bin/env bash
# Compiles every <lang>.po file into package/contents/locale/<lang>/LC_MESSAGES/plasma_applet_<id>.mo.
# Requires gettext (msgfmt).
set -euo pipefail

cd "$(dirname "$0")"
package=../package
widgetId=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' "$package/metadata.json")

rm -rf "$package/contents/locale"
for po in *.po; do
    [[ -e "$po" ]] || continue
    lang=${po%.po}
    dir="$package/contents/locale/$lang/LC_MESSAGES"
    mkdir -p "$dir"
    msgfmt --check --output-file="$dir/plasma_applet_$widgetId.mo" "$po"
    echo "Built $lang"
done
