#!/usr/bin/env bash
set -u

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="$project_dir/entry/src/main/ets"

echo "Review fontSize(16+) occurrences:"
rg -n '\.fontSize\((1[6-9]|[2-9][0-9])\)' "$source_dir" || true

echo "Review fixed height(60+) occurrences:"
rg -n '\.height\(([6-9][0-9]|[1-9][0-9]{2,})\)' "$source_dir" || true

echo "Review explicit iconSize 27+ occurrences:"
rg -n 'iconSize:\s*(2[7-9]|[3-9][0-9])' "$source_dir" || true
