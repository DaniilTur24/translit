#!/bin/bash
# Compiles the converter with the tests and runs them. Touches nothing outside a temp dir.
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
swiftc -swift-version 5 -o "$tmp/tests" Sources/Translit.swift Sources/Fixes.swift Tests/main.swift
"$tmp/tests"
