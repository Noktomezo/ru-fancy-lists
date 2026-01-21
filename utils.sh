#!/usr/bin/env bash

export LC_ALL=C
export LANG=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUCCESS_SYM="✓"
WARNING_SYM="⚠"
ERROR_SYM="✗"

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')
BOLD=$(printf '\033[1m')
BLUE=$(printf '\033[34m')
UNBOLD=$(printf '\033[22m')

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

cleanup_spinner() {
    printf "\033[?25h" # Restore cursor
    exit 1
}

spinner() {
    local pid=$1
    local wait_msg=$2
    local success_msg="${3:-$wait_msg successfully completed}"
    local error_msg="${4:-$wait_msg failed}"
    
    # Check if stdout is a terminal (TTY)
    if [[ ! -t 1 ]]; then
        # Non-interactive mode (CI/Logs)
        printf "[RUNNING] %s...\n" "$wait_msg"
        
        wait "$pid"
        local exit_status=$?
        
        if [ $exit_status -eq 0 ]; then
            printf "[%s] %s\n" "$SUCCESS_SYM" "$success_msg"
        else
            printf "[%s] %s (exit code: %s)\n" "$ERROR_SYM" "$error_msg" "$exit_status"
        fi
        return $exit_status
    fi

    # Interactive mode logic
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local delay=0.1
    local i=0

    # Hide cursor and setup trap for unexpected exits
    printf "\033[?25l"
    trap cleanup_spinner SIGINT SIGTERM

    while kill -0 "$pid" 2>/dev/null; do
        local frame="${spinstr:$i:1}"
        # Use \r to return to line start, \033[K to clear line
        printf "\r[%b%s%b] %b%s%b" "${YELLOW}" "${frame}" "${NC}" "${YELLOW}" "${wait_msg}" "${NC}"
        ((i = (i + 1) % ${#spinstr}))
        sleep "$delay"
    done

    wait "$pid"
    local exit_status=$?

    # Clear the spinner line and restore cursor
    printf "\r\033[K"
    printf "\033[?25h"
    trap - SIGINT SIGTERM # Reset trap

    if [ $exit_status -eq 0 ]; then
        printf "[%b%s%b] %b%s%b\n" "${GREEN}" "$SUCCESS_SYM" "${NC}" "${GREEN}" "${success_msg}" "${NC}"
    else
        printf "[%b%s%b] %b%s%b (exit code: %s)\n" "${RED}" "$ERROR_SYM" "${NC}" "${RED}" "${error_msg}" "${NC}" "$exit_status"
    fi

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

    cat "$input_file" | tr -d '\r' | {
        if [[ -n "$filter_pattern" ]]; then
            grep -ivE "$filter_pattern"
        else
            cat
        fi
    } | {
        if [[ -f "$whitelist_file" ]]; then
            grep -Fvx -f "$whitelist_file"
        else
            cat
        fi
    } | grep -vE "^#|^$" | \
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
    local output_dir

    output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    shopt -s nullglob
    local files=("${input_dir}"/*.lst)
    if [ ${#files[@]} -gt 0 ]; then
        cat "${files[@]}" | sort -u > "$output_file"
    else
        echo "[${YELLOW}${WARNING_SYM}${NC}] No .lst files found in ${input_dir}" >&2
    fi
    shopt -u nullglob
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

  check_file_availability "${input_file}"
  trim_sub_domains "${input_file}" "${output_file}"
}

optimize_ipset() {
  local input_file=$1
  local output_file=$2

  check_file_availability "${input_file}"
  check_tool_availaibility "iprange"

  grep -vE '^(127\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' "${input_file}" | iprange --optimize - > "${output_file}"
}
