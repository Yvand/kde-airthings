#!/usr/bin/env bash
# Extracts translatable strings into template.pot and merges them into every <lang>.po file.
# Requires gettext (xgettext, msgmerge).
set -euo pipefail

cd "$(dirname "$0")"
package=../package
widgetId=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' "$package/metadata.json")
version=$(sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' "$package/metadata.json")

# QML and .mjs files are parsed as JavaScript; .mjs is not a known extension, so the language is forced.
find "$package" \( -name '*.qml' -o -name '*.mjs' \) | sort > files.txt
xgettext \
    --from-code=UTF-8 \
    --language=JavaScript \
    --add-comments=i18n \
    --keyword= \
    --keyword=i18n:1 \
    --keyword=i18nc:1c,2 \
    --keyword=i18np:1,2 \
    --keyword=i18ncp:1c,2,3 \
    --keyword=I18N_NOOP:1 \
    --package-name="plasma_applet_$widgetId" \
    --package-version="$version" \
    --files-from=files.txt \
    --output=template.pot
rm files.txt

for po in *.po; do
    [[ -e "$po" ]] || continue
    msgmerge --quiet --update --backup=none "$po" template.pot
    echo "Merged $po"
done
