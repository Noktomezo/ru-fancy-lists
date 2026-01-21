#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUCCESS_SYM="✓"
WARNING_SYM="⚠"
ERROR_SYM="✗"

NC=$(tput sgr0)
FG_RED=$(tput setaf 1)
FG_GREEN=$(tput setaf 2)
FG_YELLOW=$(tput setaf 3)
FG_BLUE=$(tput setaf 4)
BOLD=$(tput bold)
UNBOLD="\033[22m"

check_tool_availaibility() {
  local input_tool=$1

  if ! command -v $1 &> /dev/null; then
    echo -e "[${RED}✗${NC}]: ${RED}\"${input_tool}\" is not installed. Install it first.${NC}"
    exit 1
  fi
}

check_file_availability() {
  local input_file=$1

  if [[ ! -f "$input_file" ]]; then
      echo -e "[${RED}${ERROR_SYM}${NC}] ${RED} File \"$input_file\" not found!"
      exit 1
  fi
}

check_files_by_pattern() {
  local glob_pattern=$1

  if ! compgen -G "${glob_pattern}" > /dev/null; then
      echo "[${YELLOW}${WARNING_SYM}${NC}] No files matching \"${glob_pattern}\" pattern found." >&2
      return 1
  else
      return 0
  fi
}

spinner() {
    local pid=$1
    local wait_msg=$2
    local success_msg="${3:-$wait_msg successfully completed}"
    local error_msg="${4:-$wait_msg failed}"

    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local delay=0.1
    local i=0

    # Hide cursor
    printf "\033[?25l" > /dev/tty

    while kill -0 "$pid" 2>/dev/null; do
        local frame="${spinstr:$i:1}"
        printf "\r[${YELLOW}%s${NC}] ${YELLOW}%s${NC}" "${frame}" "${wait_msg}" > /dev/tty
        ((i = (i + 1) % ${#spinstr}))
        sleep "$delay"
    done

    wait "$pid"
    local exit_status=$?

    printf "\r\033[K" > /dev/tty

    if [ $exit_status -eq 0 ]; then
        printf "[${GREEN}%s${NC}] ${GREEN}%s${NC}\n" "$SUCCESS_SYM" "${success_msg}" > /dev/tty
    else
        printf "[${RED}%s${NC}] ${RED}%s (exit code: %s)${NC}\n" "${ERROR_SYM}" "${error_msg}" "${exit_status}" > /dev/tty
    fi

    # Restore cursor
    printf "\033[?25h" > /dev/tty

    return $exit_status
}

download() {
    local url="$1"
    local output_file="$2"

    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL -o "$output_file" "$url"
}

process_hostlist() {
    local input_file=$1
    local filter_pattern=$2
    local whitelist_file="${ROOT_DIR}/filters/whitelist.txt"

    cat "$input_file" | tr -d '\r' | \
    {
        if [[ -n "$filter_pattern" ]]; then
            grep -ivE "$filter_pattern"
        else
            cat
        fi
    } | \
    {
        if [[ -f "$whitelist_file" ]]; then
            grep -Fvx -f "$whitelist_file"
        else
            cat
        fi
    } | \

    grep -vE "^#|^$" | \
    awk -F. '{if (NF >= 2) print $(NF-1)"."$NF; else print $0}' | \
    sort -u
}

cleanup_hostlist() {
  local input_file="$1"
  local output_file="$2"
  local filter_dir="${3:-${ROOT_DIR}/filters}"
  local whitelist="${4:-${ROOT_DIR}/filters/whitelist.txt}"

  local all_filters_regex=""

  check_file_availability "${input_file}"
  touch "${whitelist}"

  if [[ -d "$filter_dir" ]]; then
    check_files_by_pattern "${filter_dir}/*.json"

    for json_file in "$filter_dir"/*.json; do
        [[ -e "$json_file" ]] || continue

        filter_name=$(basename "$json_file" .json)

        current_pattern=$(jq -r '.[]' "$json_file" | tr -d '\r' | paste -sd "|" -)

        if [[ -n "${current_pattern}" ]]; then
            if [[ -z "${all_filters_regex}" ]]; then
                all_filters_regex="${current_pattern}"
            else
                all_filters_regex="${all_filters_regex}|${current_pattern}"
            fi
        fi
    done
  fi

  if [[ -n "$all_filters_regex" ]]; then
    process_hostlist "${input_file}" "${all_filters_regex}" > "${output_file}"
  else
    process_hostlist "${input_file}" > "${output_file}"
  fi
}

# trims domain sub-domains
# sub.example.com -> example.com
trim_sub_domains() {
  local input_file=$1
  local output_file=$2

  grep -v '^#' "${input_file}" | grep -v '^$' | \
  awk -F. '{
    if (NF >= 2) {
        print $(NF-1)"."$NF
    } else {
        print $0
    }
  }' | sort -u > "${output_file}"
}

# merges all .* hostlists into single file
merge_hostlists() {
    local input_dir=$1
    local output_file=$2
    local output_dir=$(dirname "$output_file")

    mkdir -p "$output_dir"

    check_files_by_pattern "${input_dir}/*.lst"
    cat "${input_dir}/"*.lst | sort -u > "$output_file"
}

# resolves alive hosts by A dns-record
# returns list with following content: example.com [A] 192.0.0.1
resolve_hostlist() {
  local input_file=$1
  local output_file=$2
  local dns_resolver_file="${ROOT_DIR}/resolvers.txt"

  check_tool_availaibility "dnsx"

  dnsx -l "${input_file}" -r "${dns_resolver_file}" -o "${output_file}" -silent -t 100000 -nc -re >/dev/null
}

parse_resolved_results() {
  local input_file="$1"
  local ipset_output="$2"
  local hostlist_output="$3"

  awk -v host_out="$hostlist_output" -v ip_out="$ipset_output" '
  {
    print $1 >> host_out

    # Remove brackets [1.2.3.4] -> 1.2.3.4
    gsub(/[\[\]]/, "", $3)

    # IP deduplication
    if (!seen[$3]++) {
      print $3 >> ip_out
    }
  }' "$input_file"
}

optimize_hostlist() {
  local input_file=$1
  local output_file=$2

  trim_sub_domains "${input_file}" "${output_file}"
}

optimize_ipset() {
  local input_file=$1
  local output_file=$2

  check_tool_availaibility "iprange"

  grep -vE '^(127\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' "${input_file}" | iprange --optimize - > "${output_file}"
}
