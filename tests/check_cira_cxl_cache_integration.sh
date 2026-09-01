#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
afu_top="$repo_root/hardware_test_design/common/afu/afu_top.sv"
ed_top="$repo_root/hardware_test_design/ed_top_wrapper_typ2.sv"
qsf="$repo_root/hardware_test_design/cxltyp2_ed.qsf"

require() {
    local text=$1 file=$2 description=$3
    if rg -Fq -- "$text" "$file"; then
        printf '  [ ok ] %s\n' "$description"
    else
        printf '  [FAIL] %s\n' "$description"
        return 1
    fi
}

forbid() {
    local text=$1 file=$2 description=$3
    if rg -Fq -- "$text" "$file"; then
        printf '  [FAIL] %s\n' "$description"
        return 1
    fi
    printf '  [ ok ] %s\n' "$description"
}

printf '%s\n' '=== CIRA CXL.cache integration checks ==='
require "localparam logic CIRA_WB_ENABLE = 1'b1;" "$afu_top" \
    "afu_top enables completion writer requests"
require ".wb_done            (cira_cache_req_done)" "$afu_top" \
    "dispatcher waits for real writer completion"
require ".wb_error           (cira_cache_req_error)" "$afu_top" \
    "dispatcher receives writer failure"
forbid ".wb_done            (1'b1)" "$afu_top" \
    "no constant writeback completion remains"
require "cira_cxl_cache_completion_writer cira_cache_completion_writer_inst" "$ed_top" \
    "writer is instantiated in AXI1/CXL.cache clock domain"
require "cira_axi_write_arbiter cira_axi1_write_arbiter_inst" "$ed_top" \
    "writer and legacy master are serialized onto AXI1"
require ".cira_cache_req_valid      (cira_cache_req_valid)" "$ed_top" \
    "afu_top request is exported to the writer"
require "./common/rv64/cira_cxl_cache_completion_writer.sv" "$qsf" \
    "writer RTL is in the Quartus source set"
require "./common/rv64/cira_axi_write_arbiter.sv" "$qsf" \
    "arbiter RTL is in the Quartus source set"

printf '%s\n' 'All CIRA CXL.cache integration checks passed'
