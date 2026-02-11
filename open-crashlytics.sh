#!/usr/bin/env bash
set -euo pipefail

TIME_WINDOW="${1:-7d}"

BASE_URL="https://console.firebase.google.com/project"
QUERY_PARAMS="state=open&time=${TIME_WINDOW}&types=crash&tag=all&sort=eventCount"

BROWSER="/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox"
BROWSER_PROFILE="Google Enterprise"
FIREFOX_DIR="${HOME}/Library/Application Support/Firefox"

ENTRIES=(
    "project|ios|bundle-id"
)

# Resolve full profile path from profiles.ini (robust to field ordering)
PROFILE_REL=$(awk -v name="$BROWSER_PROFILE" '
    /^\[/ {
        if (found_name && path != "") { print path; exit }
        found_name=0; path=""
    }
    /^Name=/ && substr($0,6) == name { found_name=1 }
    /^Path=/ { path=substr($0,6) }
    END { if (found_name && path != "") print path }
' "${FIREFOX_DIR}/profiles.ini")

if [[ -z "$PROFILE_REL" ]]; then
    echo "Error: profile '${BROWSER_PROFILE}' not found in profiles.ini" >&2
    exit 1
fi

PROFILE_PATH="${FIREFOX_DIR}/${PROFILE_REL}"

if [[ ! -d "$PROFILE_PATH" ]]; then
    echo "Error: profile directory does not exist: ${PROFILE_PATH}" >&2
    exit 1
fi

# Collect all URLs first
urls=()
for entry in "${ENTRIES[@]}"; do
    IFS='|' read -r project platform app_id <<< "$entry"
    firebase_app_id="${platform}:${app_id}"
    url="${BASE_URL}/${project}/crashlytics/app/${firebase_app_id}/issues?${QUERY_PARAMS}"
    urls+=("$url")
    echo "→ ${project} / ${firebase_app_id}"
done

# Check if this specific Firefox profile is already running via its profile lock
is_running=false
if [[ -e "${PROFILE_PATH}/lock" ]]; then
    is_running=true
fi

if $is_running; then
    # Profile instance exists — just add tabs to it
    for url in "${urls[@]}"; do
        "$BROWSER" -profile "$PROFILE_PATH" -new-tab "$url"
        sleep 0.3
    done
else
    # Launch new instance with the profile, passing all URLs
    "$BROWSER" -no-remote -profile "$PROFILE_PATH" "${urls[@]}" &
    sleep 2
fi
