## 📄 **Description**

This script (`scanURL.sh`) automates recon and reflection testing against given URLs or URL lists. It integrates crawlers (`hakrawler`, `waymore`), filters out irrelevant file extensions (archives, binaries, etc.), and separates discovered resources into:

- **Dynamic URLs** → Possible backend/API/processing endpoints  
- **Static URLs** → Likely just static assets (HTML, CSS, images, etc.)  
- **JS/JSON files** → Separated into `js.txt` and `json.txt` for deeper analysis  

It also detects simple **reflections** by probing with a unique payload, tracks tested URLs to avoid duplicates, and maintains a list of all discovered subdomains.  

In short: it's a **recon → classify → reflect test** pipeline for bug bounty and pentesting workflows.  

---

## 📘 **README.md**

```markdown
# 🛡️ Automated Recon + Reflection Tester (scanURL.sh)

A Bash script that automates recon, URL classification, and reflection testing for bug bounty & pentesting workflows.

---

## 🚀 Features

- Crawls targets with **hakrawler** + **waymore**
- Filters URLs (removes common static file extensions)
- Separates and saves:
  - JavaScript files → `js.txt`
  - JSON files → `json.txt`
  - Dynamic URLs → `dynamic_urls.txt`
  - Static URLs → `static_urls.txt`
- Detects **simple reflections** using payload injection
- Tracks tested targets in `testedUrls.txt` (avoids re-testing)
- Maintains subdomain inventory (`allSubs.txt`)
- Sends unrelated-domain URLs to a `pendingURLs.txt` queue

---

## 📦 Requirements

Make sure the following tools are installed and available in `$PATH`:

- [hakrawler](https://github.com/hakluke/hakrawler)
- [waymore](https://github.com/xnl-h4ck3r/waymore)
- `curl`, `grep`, `awk`, `sed`, `sort`

---

## ⚙️ Usage

```bash
./scanURL.sh <url|file>
```

### Examples:
```bash
# Scan a single target
./scanURL.sh https://example.com

# Scan a list of targets from file
./scanURL.sh urls_list.txt
```

---

## 📂 Output Files

| File               | Description |
|--------------------|-------------|
| `testedUrls.txt`   | List of URLs already tested (avoids duplicates) |
| `urls.txt`         | Cleaned & filtered URLs from crawling |
| `js.txt`           | Extracted JavaScript file URLs |
| `json.txt`         | Extracted JSON file URLs |
| `dynamic_urls.txt` | URLs classified as dynamic (backend/API indicators) |
| `static_urls.txt`  | URLs classified as static |
| `pendingURLs.txt`  | Discovered URLs outside the target domain |
| `allSubs.txt`      | Subdomain inventory |

---

## 🧪 Reflection Detection

The script tests each target with a payload appended (e.g., `https://example.com/hahawtofaha`) and checks if the reflection appears in the response.

---

## 🧹 Cleanup

Temporary files created during scanning are auto-removed at the end of execution.

---

## ⚠️ Notes

- Run with `bash`, not `sh`:
  ```bash
  bash scanURL.sh <target>
  ```
- First run may take time since it crawls multiple sources.
- Reflection detection is **basic** — for deeper testing, integrate with fuzzers.

---

## 🏴‍☠️ Disclaimer

This tool is for **educational and authorized security testing only**.  
Unauthorized usage against systems you don’t own is **illegal**.
```

---

Do you want me to also add an **example run (with fake sample output)** in the README so someone skimming it gets the vibe of what the tool does?
