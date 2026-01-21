#!/usr/bin/env bash

source ./utils.sh

TEMP_FOLDER="${ROOT_DIR}/temp"
LIST_FOLDER="${ROOT_DIR}/lists"

ANTIFILTER="https://antifilter.download/list/domains.lst"
ANTIFILTER_COMMUNITY="https://community.antifilter.download/list/domains.lst"
RE_FILTER="https://raw.githubusercontent.com/1andrevich/Re-filter-lists/refs/heads/main/domains_all.lst"

setup() {
  rm -rf "${LIST_FOLDER}"
  rm -f "${ROOT_DIR}/resume.cfg"

  mkdir -p "${TEMP_FOLDER}"
  mkdir -p "${LIST_FOLDER}"
}

cleanup() {
  rm -f "${ROOT_DIR}/resume.cfg"
  rm -rf "${TEMP_FOLDER}"
}

main() {
  setup

  download "${ANTIFILTER}" "${TEMP_FOLDER}/antifilter.lst" &
  spinner $! "${BOLD}Antifilter domain list downloading${SLIM}"

  download "${ANTIFILTER_COMMUNITY}" "${TEMP_FOLDER}/antifilter-community.lst" &
  spinner $! "${BOLD}Antifilter Community domain list downloading${SLIM}"

  download "${RE_FILTER}" "${TEMP_FOLDER}/re-filter.lst" &
  spinner $! "${BOLD}Re:filter domain list downloading${SLIM}"

  merge_hostlists "${TEMP_FOLDER}" "${LIST_FOLDER}/hostlist-full.txt" &
  spinner $! "${BOLD}Domain list merging${SLIM}"

  cleanup_hostlist "${LIST_FOLDER}/hostlist-full.txt" "${LIST_FOLDER}/hostlist-filtered.txt" &
  spinner $! "${BOLD}Domain list filtering${SLIM}"

  resolve_hostlist "${LIST_FOLDER}/hostlist-filtered.txt" "${LIST_FOLDER}/data-resolvable.txt" &
  spinner $! "${BOLD}Domain list resolving${SLIM}"

  parse_resolved_results "${LIST_FOLDER}/data-resolvable.txt" "${LIST_FOLDER}/ipset-resolvable.txt" "${LIST_FOLDER}/hostlist-resolvable.txt" &
  spinner $! "${BOLD}Hostlist and ipset parsing${SLIM}"

  optimize_hostlist "${LIST_FOLDER}/hostlist-resolvable.txt" "${LIST_FOLDER}/hostlist-smart.txt" &
  spinner $! "${BOLD}Hostlist optimization${SLIM}"

  optimize_ipset "${LIST_FOLDER}/ipset-resolvable.txt" "${LIST_FOLDER}/ipset-smart.txt" &
  spinner $! "${BOLD}IPSet optimization${SLIM}"

  echo -e "[${GREEN}${SUCCESS_SYM}${NC}] ${GREEN}Process completed!${NC}"

  cleanup
}

main
