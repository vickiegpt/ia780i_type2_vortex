#!/usr/bin/env python3
"""Fail-closed checks for the active IA-780I x64/no-ECC Quartus contract."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
QSF = ROOT / "hardware_test_design/cxltyp2_ed.qsf"
PINOUT = ROOT / "hardware_test_design/constraints/ia780i_pinout.tcl"
DEFINES = ROOT / "hardware_test_design/common/cxl_ed_defines.svh.iv"
TOP_PKG = ROOT / "hardware_test_design/common/ed_cxlip_top_pkg.sv"
MC_PKG = ROOT / "hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv"
EMIF_IP = ROOT / "hardware_test_design/common/mc_top/emif_ip/emif.ip"
EMIF_RTL = ROOT / "hardware_test_design/common/mc_top/emif_ip/emif/emif.v"


def active_tcl_lines(path: Path) -> list[str]:
    return [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def require_regex(errors: list[str], text: str, pattern: str, message: str) -> None:
    if re.search(pattern, text, flags=re.MULTILINE | re.DOTALL) is None:
        errors.append(message)


def ip_parameter_value(text: str, parameter_id: str) -> str | None:
    pattern = (
        rf'<ipxact:parameter\s+parameterId="{re.escape(parameter_id)}"[^>]*>'
        rf'.*?<ipxact:value>(.*?)</ipxact:value>.*?</ipxact:parameter>'
    )
    match = re.search(pattern, text, flags=re.DOTALL)
    return match.group(1).strip() if match else None


def main() -> int:
    errors: list[str] = []
    qsf = active_tcl_lines(QSF)
    pinout = active_tcl_lines(PINOUT)

    if qsf.count("source ./constraints/ia780i_pinout.tcl") != 1:
        errors.append("IA780I pinout must be sourced exactly once")
    if "set_global_assignment -name VERILOG_MACRO IA780I" not in qsf:
        errors.append("IA780I macro is not active")

    device_lines = [
        line for line in qsf + pinout if re.search(r"-name\s+DEVICE\s+", line)
    ]
    expected_device = "set_global_assignment -name DEVICE AGIB023R18A1E1V"
    if device_lines != [expected_device]:
        errors.append(f"unexpected active DEVICE assignments: {device_lines}")

    for forbidden in (
        "qsf_device_pinout.tcl",
        "AGIB027R29A1E2VR2",
        "concordia_qwen",
    ):
        if any(forbidden in line for line in qsf):
            errors.append(f"forbidden active IA780I binding: {forbidden}")

    def count_pin(prefix: str) -> int:
        pattern = re.compile(
            rf"-to\s+{re.escape(prefix)}\[[01]\]\[\d+\](?:\s|$)"
        )
        return sum(pattern.search(line) is not None for line in pinout)

    expected_pins = {
        "mem_dq": 128,
        "mem_dqs": 16,
        "mem_dqs_n": 16,
        "mem_dbi_n": 16,
    }
    for signal, expected_count in expected_pins.items():
        actual_count = count_pin(signal)
        if actual_count != expected_count:
            errors.append(
                f"{signal}: expected {expected_count} active pins, got {actual_count}"
            )

    ecc_dq = re.compile(r"-to\s+mem_dq\[[01]\]\[(?:6[4-9]|7[01])\](?:\s|$)")
    if any(ecc_dq.search(line) for line in pinout):
        errors.append("ECC DQ[71:64] must not be active")

    defines = DEFINES.read_text(encoding="utf-8")
    require_regex(
        errors,
        defines,
        r"`ifdef\s+IA780I.*?`define\s+DDR_MEM_DQS_W\s+8.*?"
        r"`define\s+DDR_MEM_DQ_W\s+64",
        "IA780I top-level DDR width must be DQS=8 and DQ=64",
    )

    top_pkg = TOP_PKG.read_text(encoding="utf-8")
    mc_pkg = MC_PKG.read_text(encoding="utf-8")
    require_regex(
        errors,
        top_pkg,
        r"EMIF_AMM_DATA_WIDTH\s*=\s*512\s*;",
        "ed_cxlip_top_pkg EMIF data width must be 512",
    )
    require_regex(
        errors,
        top_pkg,
        r"EMIF_AMM_BE_WIDTH\s*=\s*64\s*;",
        "ed_cxlip_top_pkg EMIF byte-enable width must be 64",
    )
    require_regex(
        errors,
        mc_pkg,
        r"MCTOP_EMIF_AMM_DATA_WIDTH\s*=\s*512\s*;",
        "MC EMIF data width must be 512",
    )
    require_regex(
        errors,
        mc_pkg,
        r"MCTOP_EMIF_AMM_BE_WIDTH\s*=\s*(?:64|"
        r"\(MCTOP_EMIF_AMM_DATA_WIDTH/8\))\s*;",
        "MC EMIF byte-enable width must resolve to 64",
    )

    emif_ip = EMIF_IP.read_text(encoding="utf-8")
    dq_width = ip_parameter_value(emif_ip, "MEM_DDR4_DQ_WIDTH")
    if dq_width != "64":
        errors.append(f"EMIF MEM_DDR4_DQ_WIDTH must be 64, got {dq_width!r}")
    for parameter_id in (
        "CTRL_DDR4_ECC_EN",
        "CTRL_DDR4_ECC_AUTO_CORRECTION_EN",
        "CTRL_DDR4_ECC_READDATAERROR_EN",
        "CTRL_DDR4_ECC_STATUS_EN",
    ):
        value = ip_parameter_value(emif_ip, parameter_id)
        if value != "false":
            errors.append(f"EMIF {parameter_id} must be false, got {value!r}")

    if EMIF_RTL.exists():
        emif_rtl = EMIF_RTL.read_text(encoding="utf-8", errors="replace")
        if re.search(r"\bmem_dq\s*\[[^]]*71\s*:\s*0[^]]*\]", emif_rtl):
            errors.append("generated EMIF RTL still exposes mem_dq[71:0]")
        if re.search(r"\bamm_(?:write|read)data_0\s*\[[^]]*575\s*:\s*0[^]]*\]", emif_rtl):
            errors.append("generated EMIF RTL still exposes 576-bit AVMM data")

    if errors:
        print("IA780I_X64_CONTRACT: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print("IA780I_X64_CONTRACT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
