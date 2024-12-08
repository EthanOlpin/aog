#!/usr/bin/env bash
set -euo pipefail

AOC_BASE_URL="https://adventofcode.com"
: "${AOC_SESSION_ID:?Need to set AOC_SESSION_ID environment variable}"

if [ $# -ge 2 ]; then
  YEAR="$1"
  DAY="$2"
elif [ $# -eq 1 ]; then
  YEAR="$1"
  TZ="America/New_York" DAY=$(date +%-d)
else
  TZ="America/New_York" YEAR=$(date +%Y)
  TZ="America/New_York" DAY=$(date +%-d)
fi

INPUT_DIR="inputs/${YEAR}"
INPUT_FILE="${INPUT_DIR}/${DAY}"

if [ ! -f "${INPUT_FILE}" ]; then
    echo "Fetching input for ${YEAR}-${DAY} from Advent of Code..."
    mkdir -p "${INPUT_DIR}"
    curl --fail -s -H "Cookie: session=${AOC_SESSION_ID}" "${AOC_BASE_URL}/${YEAR}/day/${DAY}/input" > "${INPUT_FILE}"
fi

echo "Running solution for Day ${DAY} ${YEAR}..."
SOLUTION_PATH="solutions/year${YEAR}/day${DAY}"

gleam run -m "${SOLUTION_PATH}" --no-print-progress -- "${INPUT_FILE}"
