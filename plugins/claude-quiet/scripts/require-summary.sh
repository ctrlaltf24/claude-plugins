#!/usr/bin/env bash
# Stop hook: ask for condensed copy when a response runs long.
# Exit 2 blocks the stop and feeds stderr back for revision.
#
# Reads last_assistant_message from the payload, never the transcript: the
# transcript is written asynchronously and lags the current turn, so a
# "newest assistant record" read returns the PREVIOUS response and blocks the
# wrong message with its word count.
set -euo pipefail

MAX_WORDS=40

input="$(cat)"

msg="$(jq -er '.last_assistant_message // empty' <<<"$input")" || exit 0
[[ -n "$msg" ]] || exit 0

# Fenced code blocks are quoted material, not prose — exclude from the count.
prose="$(awk '/^[[:space:]]*```/ { f = !f; next } !f' <<<"$msg")"

# Count only tokens containing an alphanumeric, so em-dashes, bullets and bare
# punctuation don't inflate the number the response is asked to cut to.
words="$(tr -s '[:space:]' '\n' <<<"$prose" | grep -cE '[[:alnum:]]' || true)"

(( words <= MAX_WORDS )) && exit 0

cat >&2 <<EOF
Your response is too long. Condense your response. Keep the core essence. Re-send it as short copy.
If your response has much out context it is permitted to trim twice.
The detail is above — say what's critical for the reader to know.

Trim as much as you can - but $MAX_WORDS words is a hard ceiling.
EOF
exit 2
