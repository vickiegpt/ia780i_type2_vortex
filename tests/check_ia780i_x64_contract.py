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
ECC_REQ = ROOT / "hardware_test_design/common/mc_top/mc_single_chan_ecc_req.sv"
ECC_RSP = ROOT / "hardware_test_design/common/mc_top/mc_single_chan_ecc_rsp.sv"
AVMM_FSM = ROOT / "hardware_test_design/common/mc_top/mc_single_chan_avmm_fsm.sv"
MC_TOP = ROOT / "hardware_test_design/common/mc_top/mc_top.sv"
WRAPPER = ROOT / "hardware_test_design/ed_top_wrapper_typ2.sv"


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
    active_altecc = [line for line in qsf if "altecc_" in line]
    if active_altecc:
        errors.append(f"ALTECC IP must not be active for IA780I: {active_altecc}")

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

    require_regex(
        errors,
        mc_pkg,
        r"typedef\s+struct\s+packed\s*\{[^}]*logic\s+write_poison\s*;[^}]*"
        r"\}\s*t_reqfifo_data_post_ecc_avmm\s*;",
        "AVMM post-ECC request must carry write_poison with its data",
    )

    ecc_req = ECC_REQ.read_text(encoding="utf-8")
    require_regex(
        errors,
        ecc_req,
        r"`ifdef\s+IA780I.*?to_fsm_avmm_new_req_emifclk\.write_poison",
        "IA780I no-ECC request path must pipeline write_poison",
    )

    ecc_rsp = ECC_RSP.read_text(encoding="utf-8")
    require_regex(
        errors,
        ecc_rsp,
        r"input\s+logic\s+sidecar_read_poison_emifclk",
        "IA780I no-ECC response path must accept sidecar poison",
    )
    require_regex(
        errors,
        ecc_rsp,
        r"`ifdef\s+IA780I.*?read_poison\s*<=?\s*sidecar_read_poison_emifclk",
        "IA780I no-ECC response path must return sidecar poison",
    )

    avmm_fsm = AVMM_FSM.read_text(encoding="utf-8")
    require_regex(
        errors,
        avmm_fsm,
        r"output\s+logic\s+to_emif_avmm_write_poison_emifclk",
        "AVMM FSM must export write_poison aligned to the write request",
    )
    require_regex(
        errors,
        avmm_fsm,
        r"to_emif_avmm_write_poison_emifclk\s*=\s*"
        r"from_mceccreq_new_req_emifclk\.write_poison",
        "AVMM FSM must forward request write_poison",
    )

    mc_top = MC_TOP.read_text(encoding="utf-8")
    wrapper = WRAPPER.read_text(encoding="utf-8")
    for text, location in ((mc_top, "mc_top"), (wrapper, "top wrapper")):
        require_regex(
            errors,
            text,
            r"hdm2emif_avmm_write_poison_emifclk",
            f"{location} must carry per-channel AVMM write poison",
        )
        require_regex(
            errors,
            text,
            r"emif2hdm_avmm_read_poison_emifclk",
            f"{location} must carry per-channel AVMM read poison",
        )
    require_regex(
        errors,
        mc_top,
        r"mc_single_chan_ecc_rsp.*?inst_mc_ecc_rsp_block.*?"
        r"\.sidecar_read_poison_emifclk\s*\(\s*"
        r"emif2hdm_avmm_read_poison_emifclk\[genvarChanCount\]",
        "mc_top must connect sidecar read poison to the ECC response stage",
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
