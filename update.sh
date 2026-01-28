#!/usr/bin/env bash

source ./utils.sh

TEMP_FOLDER="${ROOT_DIR}/temp"
LIST_FOLDER="${ROOT_DIR}/lists"

ANTIFILTER_HOSTLIST="https://antifilter.download/list/domains.lst"
ANTIFILTER_COMMUNITY_HOSTLIST="https://community.antifilter.download/list/domains.lst"
RE_FILTER_HOSTLIST="https://raw.githubusercontent.com/1andrevich/Re-filter-lists/refs/heads/main/domains_all.lst"

ANTIFILTER_IPSET="https://antifilter.download/list/allyouneed.lst"
ANTIFILTER_EXTRA_IPSET="https://antifilter.download/list/ipresolve.lst"
ANTIFILTER_COMMUNITY_IPSET="https://community.antifilter.download/list/community.lst"
RE_FILTER_IPSET="https://github.com/1andrevich/Re-filter-lists/raw/refs/heads/main/ipsum.lst"

setup() {
  rm -rf "${LIST_FOLDER}"
}

cleanup() {
  rm -f "${ROOT_DIR}/resume.cfg"
  rm -rf "${TEMP_FOLDER}"
}

main() {
  setup

  # --- Hostlists ---
  download "${ANTIFILTER_HOSTLIST}" "${TEMP_FOLDER}/hostlists/antifilter.lst" &
  spinner $! "Antifilter domain list downloading"

  download "${ANTIFILTER_COMMUNITY_HOSTLIST}" "${TEMP_FOLDER}/hostlists/antifilter-community.lst" &
  spinner $! "Antifilter Community domain list downloading"

  download "${RE_FILTER_HOSTLIST}" "${TEMP_FOLDER}/hostlists/re-filter.lst" &
  spinner $! "Re:filter domain list downloading"

  merge_lists "${TEMP_FOLDER}/hostlists" "${LIST_FOLDER}/hostlists/full.txt" &
  spinner $! "Hostlist merging"

  # --- IPSets ---
  download "${ANTIFILTER_IPSET}" "${TEMP_FOLDER}/ipsets/antifilter.lst" &
  spinner $! "Antifilter IPSet downloading"

  download "${ANTIFILTER_COMMUNITY_IPSET}" "${TEMP_FOLDER}/ipsets/antifilter-community.lst" &
  spinner $! "Antifilter Community IPSet downloading"

  download "${ANTIFILTER_EXTRA_IPSET}" "${TEMP_FOLDER}/ipsets/antifilter-extra.lst" &
  spinner $! "Antifilter Extra IPSet downloading"

  download "${RE_FILTER_IPSET}" "${TEMP_FOLDER}/ipsets/re-filter.lst" &
  spinner $! "Re:filter IPSet downloading"

  merge_lists "${TEMP_FOLDER}/ipsets" "${LIST_FOLDER}/ipsets/full.txt" &
  spinner $! "IPSets merging"

  # --- Post-Processing ---
  cleanup_hostlist "${LIST_FOLDER}/hostlists/full.txt" "${LIST_FOLDER}/hostlists/filtered.txt" &
  spinner $! "Hostlist filtering"

  optimize_hostlist "${LIST_FOLDER}/hostlists/filtered.txt" "${LIST_FOLDER}/hostlists/smart.txt" &
  spinner $! "Hostlist optimization"

  optimize_ipset "${LIST_FOLDER}/ipsets/full.txt" "${LIST_FOLDER}/ipsets/smart.txt" &
  spinner $! "IPSet optimization"

  echo -e "[${GREEN}${SUCCESS_SYM}${NC}] ${BOLD}${GREEN}Process completed!${NC}"

  cleanup
}

main
