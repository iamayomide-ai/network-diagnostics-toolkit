
#!/bin/bash
set -euo pipefail
 
# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
 
# --- Helper Functions ---
print_section_header() {
    echo ""
    echo -e "${CYAN}=== $1 ===${NC}"
    echo ""
}
 
print_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
}
 
print_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
}
 
print_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
}
 
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}
 
# --- Dependency Check ---
check_dependencies() {
    local required_cmds=("ping" "dig" "ss" "timeout" "awk" "sed")
    local missing=()
 
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
 
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: missing required command(s): ${missing[*]}${NC}" >&2
        echo "Install them before running netcheck.sh (e.g. 'apt install dnsutils iproute2 iputils-ping coreutils')." >&2
        exit 127
    fi
}
 
# --- Connectivity Check ---
check_connectivity () {
 print_section_header "Connectivity Check (ICMP)"
    local hosts=("8.8.8.8" "1.1.1.1" "192.168.1.1")
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
            print_pass "$host is reachable"
        else
            print_fail "$host is unreachable"
        fi
    done
}
 
# --- Port Scanning ---
check_port() {
    local host="$1"
    local port="$2"
    local exit_code=0
    timeout 2 bash -c "</dev/tcp/$host/$port" 2>/dev/null || exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        print_pass "$host:$port OPEN"
    elif [[ $exit_code -eq 1 ]]; then
        print_fail "$host:$port CLOSED"
    elif [[ $exit_code -eq 124 ]]; then
        print_warn "$host:$port FILTERED (timeout)"
    else
        print_fail "$host:$port ERROR (exit code: $exit_code)"
    fi
}
scan_ports() {
    print_section_header "Port Scan (TCP)"
    local targets=("google.com:443" "google.com:80" "localhost:22" "localhost:9999")
    for target in "${targets[@]}"; do
        local host="${target%%:*}"
        local port="${target##*:}"
        check_port "$host" "$port"
    done
}
 
# --- Report Generation ---
generate_report_header() {
    echo "=========================================="
    echo " Network Diagnostics Report"
    echo " Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo " Hostname: $(hostname)"
    echo " Kernel: $(uname -r)"
    echo " Uptime: $(uptime -p)"
    echo "=========================================="
}
 
 
# --- Connection State Analysis ---
check_connections() {
    print_section_header "Connection Summary"
    echo "  TCP connection states:"
    ss -tan 2>/dev/null | awk 'NR>1 {state[$1]++} END {for (s in state) printf "    %-14s %d\n", s, state[s]}' | sort
    echo ""
}
 
check_listening() {
    echo "  Listening TCP ports:"
    ss -tln 2>/dev/null | awk 'NR>1 {printf "    %s\n", $4}'
    echo ""
}
 
# --- DNS Resolution ---
check_dns() {
    print_section_header "DNS Resolution"
    local domains=("google.com" "github.com" "fakdomain.invalid")
    for domain in "${domains[@]}"; do
        local start_ms
        start_ms=$(date +%s%3N)
        local result
        result=$(dig +short "$domain" 2>/dev/null | head -1)
        local end_ms
        end_ms=$(date +%s%3N)
        local elapsed=$(( end_ms - start_ms ))
        if [[ -n "$result" ]]; then
            print_pass "$domain -> $result (${elapsed}ms)"
        else
            print_fail "$domain -> resolution failed (${elapsed}ms)"
        fi
    done
}
 
print_banner () {
  echo -e "${CYAN}"
    echo "  netcheck.sh - Network Diagnostics Toolkit"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${NC}"
}
 
run_all () {
        check_connectivity
        check_dns
        scan_ports
        check_connections
        check_listening
}
 
main () {
    check_dependencies
 
    local report_mode=false
    local mode="all"
 
    for arg in "$@"; do
        case "$arg" in
            --report)
                report_mode=true
                ;;
            all|ping|dns|ports|connections)
                mode="$arg"
                ;;
            *)
                echo "Usage: $0 [--report] {all|ping|dns|ports|connections}"
                exit 1
                ;;
        esac
    done
 
    if [[ "$report_mode" == true ]]; then
        local report_file="netcheck-$(date '+%Y-%m-%d-%H%M%S').log"
        {
            generate_report_header
            print_banner
            case "$mode" in
                all) run_all ;;
                ping) check_connectivity ;;
                dns) check_dns ;;
                ports) scan_ports ;;
                connections) check_connections; check_listening ;;
            esac
        } | tee >(strip_colors > "$report_file")
        echo ""
        echo -e "${GREEN}Report saved to: ${report_file}${NC}"
    else
        print_banner
        case "$mode" in
            all) run_all ;;
            ping) check_connectivity ;;
            dns) check_dns ;;
            ports) scan_ports ;;
            connections) check_connections; check_listening ;;
        esac
    fi
}
 
main "$@"
