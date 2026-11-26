#!/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
cat > "$TMP/bin/brew" <<'EOF'
#!/bin/bash
echo "$*" >> "$BREW_LOG"
[[ "$*" == bundle\ check* ]] && exit "${BREW_CHECK_STATUS:-0}"
[[ "$*" == bundle\ cleanup* ]] && exit "${BREW_CLEANUP_STATUS:-0}"
[[ "$*" == outdated* ]] && printf '%b' "${BREW_OUTDATED:-}"
exit 0
EOF
cat > "$TMP/bin/killall" <<'EOF'
#!/bin/bash
echo "killall $*" >> "$BREW_LOG"
exit 1
EOF
chmod +x "$TMP/bin/brew" "$TMP/bin/killall"

failures=0
pass() { echo "ok - $1"; }
fail() { echo "not ok - $1"; failures=$((failures + 1)); }

run() {
  : > "$TMP/log"
  PATH="$TMP/bin:$PATH" BREW_LOG="$TMP/log" "$ROOT/maintenance.sh" "$@" > "$TMP/out" 2>&1
}

run
[[ $? -ne 0 ]] && pass "fails without profile" || fail "fails without profile"
[[ ! -s "$TMP/log" ]] && pass "no brew calls without profile" || fail "no brew calls without profile"

run invalid
[[ $? -ne 0 ]] && pass "fails with invalid profile" || fail "fails with invalid profile"

run private
status=$?
[[ $status -eq 0 ]] && pass "succeeds with private" || fail "succeeds with private (status=$status)"
expected="update
outdated --verbose
upgrade --yes
autoremove
cleanup
bundle check --file=$ROOT/Brewfile.private
bundle cleanup --file=$ROOT/Brewfile.private"
[[ "$(cat "$TMP/log")" == "$expected" ]] && pass "runs commands in order" \
  || { fail "runs commands in order"; diff <(echo "$expected") "$TMP/log"; }
! grep -q -- "--force" "$TMP/log" && pass "never forces bundle cleanup" || fail "never forces bundle cleanup"

BREW_CHECK_STATUS=1 BREW_CLEANUP_STATUS=1 run work
[[ $? -eq 0 ]] && pass "tolerates bundle check/cleanup diffs" || fail "tolerates bundle check/cleanup diffs"
grep -q "Brewfile.work" "$TMP/log" && pass "uses work profile" || fail "uses work profile"
grep -q "brew bundle install" "$TMP/out" && pass "hints install on missing packages" || fail "hints install on missing packages"
grep -q "cleanup --force" "$TMP/out" && pass "hints forced cleanup on extras" || fail "hints forced cleanup on extras"

! grep -q killall "$TMP/log" && pass "keeps IME running when not upgraded" || fail "keeps IME running when not upgraded"

BREW_OUTDATED="google-japanese-ime (3.33) != 3.34\ngit (2.0) < 2.1\n" run private
[[ $? -eq 0 ]] && pass "succeeds even if IME is not running" || fail "succeeds even if IME is not running"
grep -A1 -x "upgrade --yes" "$TMP/log" | grep -qx "killall GoogleJapaneseInput GoogleJapaneseInputConverter GoogleJapaneseInputRenderer" \
  && pass "restarts IME right after upgrade" || { fail "restarts IME right after upgrade"; cat "$TMP/log"; }

BREW_OUTDATED="google-japanese-ime-dev (1) != 2\n" run private
! grep -q killall "$TMP/log" && pass "matches IME cask name exactly" || fail "matches IME cask name exactly"

[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
