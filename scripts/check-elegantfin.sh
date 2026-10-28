#!/usr/bin/env bash
# ======================== CONFIGURATION ========================
set -euo pipefail

UPSTREAM_URLS=(
    "https://cdn.jsdelivr.net/gh/lscambo13/ElegantFin@main/Theme/ElegantFin-jellyfin-theme-build-latest-minified.css"
    "https://cdn.jsdelivr.net/gh/mihaif7/elegantfin-jf12@main/Theme/ElegantFin-jf12-modern-latest.css"
)
THEME_FILE="${1:-Theme/ElegantSpider-latest.css}"
shift || true
UPSTREAM_FILES=("$@")
# =================================================


# ======================== FONCTIONS ========================
# --------------------- Récupération du CSS d'ElegantFin et du compagnon jf12 ---------------------
fetch_upstream() {
    if (( ${#UPSTREAM_FILES[@]} )); then
        cat "${UPSTREAM_FILES[@]}"
    else
        for url in "${UPSTREAM_URLS[@]}"; do curl -fsSL "$url"; echo; done
    fi
}

# --------------------- Variables redéfinies par ElegantSpider (hors --es-*) ---------------------
theme_variables() {
    grep -oE '^\s*--[A-Za-z0-9-]+:' "$THEME_FILE" | tr -d ' :' | grep -v '^--es-' | sort -u
}
# =================================================


# ======================== VÉRIFICATION ========================
upstream_css="$(fetch_upstream)"
version="$(grep -oE 'ElegantFin v[0-9]+\.[0-9]+\.[0-9]+' <<< "$upstream_css" | head -n 1 || true)"
echo "Version d'ElegantFin : ${version:-inconnue}"
echo "version=${version:-inconnue}" >> "${GITHUB_OUTPUT:-/dev/null}"

missing=()
while read -r var; do
    # Une variable absente des deux fichiers veut dire qu'elle a été renommée ou supprimée
    grep -qE -- "${var}:" <<< "$upstream_css" || missing+=("$var")
done < <(theme_variables)

if (( ${#missing[@]} )); then
    echo "Variables introuvables chez ElegantFin / jf12 :"
    printf '  %s\n' "${missing[@]}"
    printf '%s\n' "${missing[@]}" > missing-variables.txt
    exit 1
fi

echo "Toutes les variables utilisées par ElegantSpider existent toujours."
# =================================================
