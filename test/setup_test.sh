#!/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/brew" <<'EOF'
#!/bin/bash
if [[ "$1" == shellenv ]]; then
  echo "export PATH=\"$(dirname "$0"):\$PATH\""
  exit 0
fi
echo "brew($0) $*" >> "$LOG"
EOF

cat > "$TMP/claude" <<'EOF'
#!/bin/bash
EOF

mkdir -p "$TMP/fakebin"
cat > "$TMP/fakebin/curl" <<'EOF'
#!/bin/bash
url="${*: -1}"
echo "curl $url" >> "$LOG"
case "$url" in
  *Homebrew/install*) echo "mkdir -p '$HOMEBREW_PREFIX/bin' && cp '$FAKE_BREW' '$HOMEBREW_PREFIX/bin/brew'" ;;
  *claude.ai/install.sh) echo "true" ;;
esac
EOF
chmod +x "$TMP/brew" "$TMP/claude" "$TMP/fakebin/curl"

failures=0
pass() { echo "ok - $1"; }
fail() { echo "not ok - $1"; failures=$((failures + 1)); }

run() {
  : > "$TMP/log"
  env PATH="$TMP/fakebin:${EXTRA_PATH:-}/usr/bin:/bin" LOG="$TMP/log" FAKE_BREW="$TMP/brew" \
    HOMEBREW_PREFIX="$PREFIX" "$ROOT/setup.sh" "$@" > "$TMP/out" 2>&1
}

PREFIX="$TMP/none"
run invalid
[[ $? -ne 0 ]] && pass "fails with invalid profile" || fail "fails with invalid profile"
[[ ! -s "$TMP/log" ]] && pass "does nothing with invalid profile" || fail "does nothing with invalid profile"

PREFIX="$TMP/fresh"
run private
status=$?
[[ $status -eq 0 ]] && pass "fresh install succeeds" || { fail "fresh install succeeds (status=$status)"; cat "$TMP/out"; }
grep -q "curl .*Homebrew/install" "$TMP/log" && pass "installs Homebrew when missing" || fail "installs Homebrew when missing"
grep -qx "brew($PREFIX/bin/brew) bundle install --file=$ROOT/Brewfile.private" "$TMP/log" \
  && pass "uses newly installed brew for bundle" || { fail "uses newly installed brew for bundle"; cat "$TMP/log"; }

PREFIX="$TMP/existing"
mkdir -p "$PREFIX/bin" && cp "$TMP/brew" "$PREFIX/bin/brew"
run work
[[ $? -eq 0 ]] && pass "succeeds when brew exists but is not on PATH" || fail "succeeds when brew exists but is not on PATH"
! grep -q "Homebrew/install" "$TMP/log" && pass "does not reinstall existing brew" || fail "does not reinstall existing brew"
grep -qx "brew($PREFIX/bin/brew) bundle install --file=$ROOT/Brewfile.work" "$TMP/log" \
  && pass "uses existing brew under prefix" || fail "uses existing brew under prefix"

mkdir -p "$TMP/onpath"
cp "$TMP/brew" "$TMP/onpath/brew" && cp "$TMP/claude" "$TMP/onpath/claude"
PREFIX="$TMP/none" EXTRA_PATH="$TMP/onpath:" run private
[[ $? -eq 0 ]] && pass "succeeds when brew is on PATH" || fail "succeeds when brew is on PATH"
grep -qx "brew($TMP/onpath/brew) bundle install --file=$ROOT/Brewfile.private" "$TMP/log" \
  && pass "uses brew on PATH" || fail "uses brew on PATH"
! grep -q "curl" "$TMP/log" && pass "skips installers when already installed" || fail "skips installers when already installed"

[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
