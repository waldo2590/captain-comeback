#!/bin/bash
HOG_CONTAINER_NAME="captain-comeback-hog"
CAPTAIN_PID="0"
CAPTAIN_TERMINATED="1"

HOG_ALLOC_LIMIT=0


want_root() {
  if [ "$(id -u)" != "0" ]; then
    echo "You need to be root to run this test"
    exit 1
  fi
}

want_noswap() {
  local swap_total="$(grep "SwapTotal" /proc/meminfo)"
  if [[ ! "$swap_total" =~ SwapTotal:.+0\ kB ]]; then
    echo "You must disable swap to run this test"
    exit 1
  fi
}

want_hog() {
  gcc hog.c -Wl,--no-export-dynamic -static -o hog
}


_run_hog_internal() {
  local opts=("--memory" "$HOG_MEMORY_LIMIT"
        "--name" "$HOG_CONTAINER_NAME"
        "-v" "$(pwd):/hog"
        "tianon/true" "/hog/hog")

  if [[ "$HOG_ALLOC_LIMIT" -gt 0 ]]; then
    opts+=("$HOG_ALLOC_LIMIT")
  fi

  docker run "$@" "${opts[@]}"
}

run_hog_fg() {
  _run_hog_internal "--rm"
}

run_hog_bg() {
  _run_hog_internal "-d"
}

hog_log() {
  docker logs "$HOG_CONTAINER_NAME"
}

clean_hog() {
  docker rm -f "$HOG_CONTAINER_NAME" >/dev/null 2>&1 || true
}


terminate_captain() {
  if [[ "$CAPTAIN_TERMINATED" -eq 1 ]]; then
    return
  fi
  kill -TERM "$CAPTAIN_PID"
  CAPTAIN_TERMINATED=1
}

terminate_captain_at_exit() {
  trap terminate_captain EXIT
}

run_captain_bg() {
  captain-comeback "$@" &
  CAPTAIN_PID="$!"
  CAPTAIN_TERMINATED=0
  terminate_captain_at_exit
}
