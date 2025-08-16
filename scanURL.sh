#!/bin/bash
set -euo pipefail

# ================================================
# 🛡️ Automated Recon + Reflection Tester (scan.sh)
# ================================================

# ======== CONFIG ========
tested_file="testedUrls.txt"
urls_file="urls.txt"
pending_file="../pendingURLs.txt"
dynamic_urls="dynamic_urls.txt"
static_urls="static_urls.txt"
all_subs="../allSubs.txt"
tmp_dir="$(mktemp -d)" # temp dir for intermediate files
extensions="zip|fwpkg|cab|pdf|iso|gz|txt|doc|exe|rpm|tar|bin|vib|deb|xml|compsig|flash|msi|tgz|sig|scexe|pmc"

> $urls_file

# ======== HELP / ARG CHECK ========
if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "\nUsage: $0 <url|file>\n"
    echo "Example:"
    echo "  $0 https://example.com"
    echo "  $0 urls_list.txt"
    exit 1
fi

# ======== DETERMINE INPUT TYPE ========
input="$1"
urls_to_scan=()

if [[ -f "$input" ]]; then
    mapfile -t urls_to_scan < <(grep -Eo 'https?://[^ ]+' "$input")
else
    urls_to_scan+=("$input")
fi

# ======== ENSURE FILES EXIST ========
touch "$tested_file" "$urls_file" "$pending_file" "$dynamic_urls" "$static_urls"

# ======== PROCESS EACH URL ========
for url in "${urls_to_scan[@]}"; do
    normalized_url="${url%/}"
    subdomain=$(awk -F[/:] '{print $4}' <<< "$url")
    echo "$subdomain" >> "$all_subs"
    sort -u "$all_subs" -o "$all_subs"

    # Skip if already tested
    if grep -Fxq "$normalized_url" "$tested_file"; then
        echo "[+] $url already tested. Skipping."
        continue
    fi

    # ======== RECON (Hakrawler + Waymore) ========
    echo "[+] Crawling $url ..."
    echo "$url" | hakrawler > "$tmp_dir/hakrawler.txt"
    waymore -i "$url" -mode U -oU "$tmp_dir/waymore.txt"

    # ======== MERGE + CLEAN URL LIST ========
    > $urls_file
    cat "$tmp_dir"/*.txt |
      sort -u |
      sed -E "/\.(${extensions})([?#].*)?$/I d" > temp.txt
      mv temp.txt $urls_file


    echo "[+] URLs deduplicated & filtered into $urls_file"

    # ======== REFLECTION TEST ========
    test_url="${normalized_url}/hahawtofaha"
    if curl -s --max-time 10 "$test_url" | grep -q "hahawtofaha"; then
        echo "[!] Reflection detected: $test_url"
    else
        echo "[-] No reflection detected."
    fi

    # ======== LOG TESTED URL ========
    echo "$normalized_url" >> "$tested_file"
    sort -u "$tested_file" -o "$tested_file"
    echo "[+] Logged $url in $tested_file"

    # ======== FILTER BY DOMAIN ========
    > tmp_urls
    awk -v domain="$subdomain" '
      $0 ~ domain { print > "tmp_urls" }
      $0 !~ domain { print >> "'"$pending_file"'" }
    ' "$urls_file"

    mv tmp_urls "$urls_file"
    sort -u "$pending_file" -o "$pending_file"

    grep -iE "\.js(\?|$)" "$urls_file" > js.txt
    grep -iE "\.json(\?|$)" "$urls_file" > json.txt

    # ======== DYNAMIC / STATIC URL DETECTION ========
    while IFS= read -r target_url; do
        echo "[*] Checking $target_url"

        headers=$(curl -sI --max-time 10 "$target_url")
        html=$(curl -sL --max-time 10 "$target_url")
        reason=""

        # Backend in headers
        if grep -qiE "PHP|ASP\.NET|Express|Django|Ruby|Servlet" <<< "$headers"; then
            reason="Backend detected via headers"
        fi

        # Backend/API hints in HTML
        if [[ -z "$reason" ]] && grep -qiE '\.php|\.asp|\.jsp|/api/|fetch\(|XMLHttpRequest|\.json|name="email"|search' <<< "$html"; then
            reason="Found backend/API endpoint in HTML"
        fi

        # HTML forms
        if [[ -z "$reason" ]] && grep -qi "<form" <<< "$html"; then
            reason="Contains form (possible server processing)"
        fi

        if [[ -n "$reason" ]]; then
            echo "[+] $target_url --> $reason"
            echo "$target_url | $reason" >> "$dynamic_urls"
        else
            echo "[-] $target_url --> Looks static"
            echo "$target_url" >> "$static_urls"
        fi

    done < "$urls_file"
done

# ======== REMOVE DUPLICATES & CLEAN TESTED URLs FROM LISTS ========
sort -u "$dynamic_urls" -o "$dynamic_urls"
sort -u "$static_urls" -o "$static_urls"

grep -vxFf "$tested_file" "$dynamic_urls" > "${dynamic_urls}.tmp" && mv "${dynamic_urls}.tmp" "$dynamic_urls"
sort -u "$dynamic_urls" -o "$dynamic_urls"
grep -vxFf "$tested_file" "$static_urls" > "${static_urls}.tmp" && mv "${static_urls}.tmp" "$static_urls"
sort -u "$static_urls" -o "$static_urls"

echo "[*] Dynamic URLs saved in $dynamic_urls"
echo "[*] Static URLs saved in $static_urls"
echo "[+] Done ✅"

# Cleanup
rm -rf "$tmp_dir"
rm "$urls_file"
