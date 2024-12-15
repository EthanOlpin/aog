#!/usr/bin/env bash
set -euo pipefail

AOC_BASE_URL="https://adventofcode.com"
: "${ADVENT_OF_CODE_SESSION_ID:?Need to set ADVENT_OF_CODE_SESSION_ID environment variable}"

export TZ="America/New_York"
if [ $# -ge 2 ]; then
  YEAR="$1"
  DAY="$2"
elif [ $# -eq 1 ]; then
  YEAR="$1"
  DAY=$(date +%-d)
else
  YEAR=$(date +%Y)
  DAY=$(date +%-d)
fi
unset TZ

INPUT_DIR="inputs/${YEAR}"
INPUT_FILE="${INPUT_DIR}/${DAY}"

if [ ! -f "${INPUT_FILE}" ]; then
    echo "Fetching input for ${YEAR}-${DAY} from Advent of Code..."
    mkdir -p "${INPUT_DIR}"
    curl --fail -s -H "Cookie: session=${ADVENT_OF_CODE_SESSION_ID}" "${AOC_BASE_URL}/${YEAR}/day/${DAY}/input" > "${INPUT_FILE}"
fi

echo "Running solution for Day ${DAY} ${YEAR}..."
SOLUTION_PATH="solutions/year${YEAR}/day${DAY}"

gleam run -m "${SOLUTION_PATH}" --no-print-progress -- "${INPUT_FILE}"
