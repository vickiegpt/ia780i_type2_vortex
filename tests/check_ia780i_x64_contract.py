#!/usr/bin/env python3
"""Fail-closed checks for the active IA-780I x64/no-ECC Quartus contract."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
QSF = ROOT / "hardware_test_design/cxltyp2_ed.qsf"
PINOUT = ROOT / "hardware_test_design/constraints/ia780i_pinout.tcl"
TOP_SDC = ROOT / "hardware_test_design/constraints/cxltyp2_ed.sdc"
QUARTUS_CONSTRAINTS = (
    ROOT / "hardware_test_design/constraints/cxltyp2_quartus_constraints_ed_en.tcl"
)
DEFINES = ROOT / "hardware_test_design/common/cxl_ed_defines.svh.iv"
TOP_PKG = ROOT / "hardware_test_design/common/ed_cxlip_top_pkg.sv"
MC_PKG = ROOT / "hardware_test_design/common/mc_top/ddr_mc_top_common_pkg.sv"
EMIF_IP = ROOT / "hardware_test_design/common/mc_top/emif_ip/emif.ip"
EMIF_CAL_IP = ROOT / "hardware_test_design/common/mc_top/emif_ip/emif_cal_two_ch.ip"
EMIF_RTL = ROOT / "hardware_test_design/common/mc_top/emif_ip/emif/synth/emif.v"
ECC_REQ = ROOT / "hardware_test_design/common/mc_top/mc_single_chan_ecc_req.sv"
ECC_RSP = ROOT / "hardware_test_design/common/mc_top/mc_single_chan_ecc_rsp.sv"
AVMM_FSM = ROOT / "hardware_test_design/common/mc_top/mc_single_chan_avmm_fsm.sv"
MC_TOP = ROOT / "hardware_test_design/common/mc_top/mc_top.sv"
WRAPPER = ROOT / "hardware_test_design/ed_top_wrapper_typ2.sv"
MC_EMIF = ROOT / "hardware_test_design/common/mc_top/mc_emif_avmm.sv"
POISON_SIDECAR = ROOT / "hardware_test_design/common/mc_top/mc_poison_sidecar.sv"
VORTEX_MSHR = (
    ROOT / "hardware_test_design/common/rv64/vortex/cache/VX_cache_mshr.sv"
)
VORTEX_AXI = ROOT / "hardware_test_design/common/rv64/vortex/Vortex_axi.sv"
VORTEX_AXI_ADAPTER = (
    ROOT / "hardware_test_design/common/rv64/vortex/libs/VX_axi_adapter.sv"
)
VORTEX_DP_RAM = (
    ROOT / "hardware_test_design/common/rv64/vortex/libs/VX_dp_ram.sv"
)
VORTEX_PLATFORM = ROOT / "hardware_test_design/common/rv64/vortex/VX_platform.vh"
BUNDLED_CDC = ROOT / "hardware_test_design/common/rv64/cxl_bundled_toggle_cdc.sv"
AFU_TOP = ROOT / "hardware_test_design/common/afu/afu_top.sv"
CXL_QIP = (
    ROOT
    / "hardware_test_design/intel_rtile_cxl_top_cxltyp2_ed"
    / "intel_rtile_cxl_top_cxltyp2_ed.qip"
)


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
    top_sdc = TOP_SDC.read_text(encoding="utf-8")
    quartus_constraints = QUARTUS_CONSTRAINTS.read_text(encoding="utf-8")

    if qsf.count("source ./constraints/ia780i_pinout.tcl") != 1:
        errors.append("IA780I pinout must be sourced exactly once")
    if "set_global_assignment -name VERILOG_MACRO IA780I" not in qsf:
        errors.append("IA780I macro is not active")

    dcache_repl_macros = [
        line for line in qsf if "VERILOG_MACRO" in line and "DCACHE_REPL_POLICY" in line
    ]
    expected_dcache_repl = (
        'set_global_assignment -name VERILOG_MACRO "DCACHE_REPL_POLICY=0"'
    )
    if dcache_repl_macros != [expected_dcache_repl]:
        errors.append(
            "timing-closed Vortex D-cache must use the registered RANDOM "
            f"replacement policy: {dcache_repl_macros}"
        )

    vortex_mshr = VORTEX_MSHR.read_text(encoding="utf-8")
    require_regex(
        errors,
        vortex_mshr,
        r"`DISABLE_BRAM\s+reg\s+\[`CS_LINE_ADDR_WIDTH-1:0\]\s+"
        r"addr_table\s*\[0:MSHR_SIZE-1\]\s*;",
        "Vortex MSHR addr_table must use logic registers to break the RAM "
        "output-to-address timing loop",
    )

    for channel in (0, 1):
        require_regex(
            errors,
            top_sdc,
            rf"set\s+emif_usr_clk_{channel}\s+\[get_clocks\s+"
            rf"ed_top_wrapper_typ2_inst\|inst_emif_avmm\|emif_inst_{channel}"
            rf"\|emif_core_usr_clk\]",
            f"top SDC must bind IA780I EMIF channel {channel} user clock",
        )
    if "GEN_CHAN_COUNT_EMIF_NOT_REVB" in top_sdc:
        errors.append("top SDC still uses the inactive legacy EMIF hierarchy")
    require_regex(
        errors,
        quartus_constraints,
        r"set_global_assignment\s+-name\s+SEED\s+2(?:\s|$)",
        "timing-closure fitter seed must be reproducibly fixed to 2",
    )

    expected_cxl_qip = (
        "set_global_assignment -name QIP_FILE "
        "./intel_rtile_cxl_top_cxltyp2_ed/intel_rtile_cxl_top_cxltyp2_ed.qip"
    )
    active_cxl_qips = [line for line in qsf if "intel_rtile_cxl_top" in line and "QIP_FILE" in line]
    if active_cxl_qips != [expected_cxl_qip]:
        errors.append(f"unexpected active CXL QIP assignments: {active_cxl_qips}")
    if not CXL_QIP.is_file():
        errors.append(f"active CXL QIP does not exist: {CXL_QIP}")
    if any("./../intel_rtile_cxl_top_cxltyp2_ed" in line for line in qsf):
        errors.append("active CXL IP paths must remain inside hardware_test_design")

    expected_bundled_cdc = (
        "set_global_assignment -name SYSTEMVERILOG_FILE "
        "./common/rv64/cxl_bundled_toggle_cdc.sv"
    )
    active_bundled_cdc = [
        line for line in qsf if "cxl_bundled_toggle_cdc.sv" in line
    ]
    if active_bundled_cdc != [expected_bundled_cdc]:
        errors.append(
            "bundled CDC primitive must be compiled exactly once: "
            f"{active_bundled_cdc}"
        )

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

    reset_termination = (
        'set_instance_assignment -name OUTPUT_TERMINATION '
        '"SERIES 40 OHM WITHOUT CALIBRATION" -to mem_reset_n[*]'
    )
    if pinout.count(reset_termination) != 1:
        errors.append(
            "DDR4 RESET_N must explicitly use the fitter-selected series 40 ohm "
            "output termination"
        )

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
    afu_top = AFU_TOP.read_text(encoding="utf-8")
    bundled_cdc = BUNDLED_CDC.read_text(encoding="utf-8")
    mc_emif = MC_EMIF.read_text(encoding="utf-8")
    poison_sidecar = POISON_SIDECAR.read_text(encoding="utf-8")
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
    for absent_module in ("dram0_ddr2666_32gb", "dram1_ddr2666_32gb"):
        if absent_module in mc_emif:
            errors.append(f"IA780I references absent EMIF module: {absent_module}")
    for instance in ("emif_inst_0", "emif_inst_1"):
        require_regex(
            errors,
            mc_emif,
            rf"\bemif\s+{instance}\b",
            f"IA780I channel must instantiate generated emif as {instance}",
        )
    require_regex(
        errors,
        mc_emif,
        r"input\s+logic\s+\[[^]]*MCTOP_MC_CHANNEL[^]]*\]\s*"
        r"emif_amm_write_poison",
        "mc_emif_avmm must accept per-channel write poison",
    )
    require_regex(
        errors,
        mc_emif,
        r"output\s+logic\s+\[[^]]*MCTOP_MC_CHANNEL[^]]*\]\s*"
        r"emif_amm_read_poison",
        "mc_emif_avmm must return per-channel read poison",
    )
    require_regex(
        errors,
        mc_emif,
        r"mc_poison_sidecar\s+sidecar.*?\.phy_address\s*\(\s*"
        r"phy_amm_address\[chanCount\]",
        "mc_emif_avmm must instantiate a poison sidecar per channel",
    )
    summary_write_sites = re.findall(
        r"summary_ram\s*\[[^]]+\]\s*<=", poison_sidecar
    )
    if len(summary_write_sites) != 1:
        errors.append(
            "poison summary RAM must have exactly one HDL write site; "
            f"found {len(summary_write_sites)}"
        )
    require_regex(
        errors,
        poison_sidecar,
        r"if\s*\(summary_write_enable\)\s*"
        r"summary_ram\s*\[summary_write_address\]\s*<=\s*"
        r"summary_write_data",
        "poison summary RAM must use one explicit synchronous write port",
    )
    require_regex(
        errors,
        mc_emif,
        r"\.amm_address_0\s*\(\s*phy_amm_address\s*\[0\]",
        "IA780I channel 0 EMIF must use the sidecar physical address",
    )
    require_regex(
        errors,
        mc_emif,
        r"\.amm_address_0\s*\(\s*phy_amm_address\s*\[1\]",
        "IA780I channel 1 EMIF must use the sidecar physical address",
    )
    if re.search(
        r"assign\s+emif2hdm_avmm_read_poison_emifclk\s*=\s*'0", wrapper
    ):
        errors.append("top wrapper still ties sidecar read poison to zero")
    require_regex(
        errors,
        wrapper,
        r"\.emif_amm_write_poison\s*\(\s*"
        r"hdm2emif_avmm_write_poison_emifclk\s*\)",
        "top wrapper must connect merged write poison into mc_emif_avmm",
    )
    require_regex(
        errors,
        wrapper,
        r"\.emif_amm_read_poison\s*\(\s*"
        r"emif2hdm_avmm_read_poison_emifclk\s*\)",
        "top wrapper must connect sidecar read poison from mc_emif_avmm",
    )
    require_regex(
        errors,
        wrapper,
        r"`ifdef\s+IA780I.*?assign\s+hdm_size_256mb\s*=\s*"
        r"mc_poison_sidecar_pkg::HDM_SIZE_256MB",
        "IA780I HDM advertisement must exclude the poison arena",
    )
    require_regex(
        errors,
        wrapper,
        r"`ifdef\s+IA780I.*?assign\s+mc_chan_memsize\[chanCount\]\s*=\s*"
        r"mc_poison_sidecar_pkg::VISIBLE_BYTES_PER_CHANNEL",
        "IA780I per-channel capacity must exclude the poison arena",
    )

    for instance, width in (("vx_launch_cdc_inst", "128"),
                            ("vx_result_cdc_inst", "136")):
        require_regex(
            errors,
            wrapper,
            rf"cxl_bundled_toggle_cdc\s*#\s*\(\s*\.WIDTH\s*\(\s*{width}\s*\)\s*\)"
            rf"\s*{instance}",
            f"top wrapper must instantiate {instance} with WIDTH={width}",
        )
        require_regex(
            errors,
            top_sdc,
            rf"constrain_cxl_bundled_toggle_cdc\s+.*{instance}",
            f"top SDC must constrain {instance} as a bundled CDC path",
        )
    for constraint in ("set_max_skew", "set_net_delay", "set_max_delay", "set_min_delay"):
        if constraint not in top_sdc:
            errors.append(f"bundled CDC SDC is missing {constraint}")
    require_regex(
        errors,
        top_sdc,
        r"set\s+src_token\s+.*src_toggle.*?"
        r"set\s+dst_token\s+.*dst_toggle_meta.*?"
        r"set\s+skew_from_nodes\s+\[add_to_collection\s+\$from_nodes\s+\$src_token\].*?"
        r"set\s+skew_to_nodes\s+\[add_to_collection\s+\$to_nodes\s+\$dst_token\].*?"
        r"set_max_skew\s+-from\s+\$skew_from_nodes\s+-to\s+\$skew_to_nodes",
        "bundled CDC max-skew constraint must cover both payload and event token",
    )
    require_regex(
        errors,
        afu_top,
        r"input\s+logic\s+ext_vx_launch_valid",
        "AFU must consume the destination-domain launch-valid pulse",
    )
    if "ext_toggle_s1" in afu_top or "ext_vx_launch_toggle" in afu_top:
        errors.append("AFU still contains the obsolete second launch-toggle synchronizer")
    if "gpu_cycles_sync1" in wrapper or "gpu_instrs_sync1" in wrapper:
        errors.append("top wrapper still samples running multi-bit counters bitwise")

    vortex_axi = VORTEX_AXI.read_text(encoding="utf-8")
    vortex_axi_adapter = VORTEX_AXI_ADAPTER.read_text(encoding="utf-8")
    vortex_dp_ram = VORTEX_DP_RAM.read_text(encoding="utf-8")
    vortex_platform = VORTEX_PLATFORM.read_text(encoding="utf-8")
    require_regex(
        errors,
        vortex_axi_adapter,
        r"parameter\s+TAG_BUFFER_LUTRAM\s*=\s*0.*?"
        r"VX_index_buffer\s*#\s*\(.*?\.LUTRAM\s*\(TAG_BUFFER_LUTRAM\)",
        "AXI adapter must expose and forward the tag-buffer LUTRAM selection",
    )
    require_regex(
        errors,
        vortex_axi,
        r"VX_axi_adapter\s*#\s*\(.*?\.TAG_BUFFER_LUTRAM\s*\(1\)",
        "IA780I Vortex AXI tag buffer must use LUTRAM to avoid the BRAM read-to-response timing path",
    )
    require_regex(
        errors,
        vortex_dp_ram,
        r"end\s+else\s+begin\s*:\s*g_auto.*?"
        r"`USE_FAST_BRAM\s+(?:`RAM_ARRAY_WREN|reg\s+\[DATAW-1:0\]\s+ram)",
        "VX_dp_ram LUTRAM branch must explicitly select MLAB instead of AUTO RAM mapping",
    )
    if vortex_dp_ram.count("`USE_FAST_BRAM") != 8:
        errors.append("all VX_dp_ram LUTRAM declarations must carry USE_FAST_BRAM")
    require_regex(
        errors,
        vortex_platform,
        r"`ifdef\s+QUARTUS.*?`define\s+USE_FAST_BRAM\s+"
        r"\(\*\s*ramstyle\s*=\s*\"MLAB, no_rw_check\"\s*\*\)",
        "Quartus USE_FAST_BRAM must resolve to explicit MLAB ramstyle",
    )
    require_regex(
        errors,
        bundled_cdc,
        r"src_data_hold\s*<=\s*src_data.*?src_toggle\s*<=\s*~src_toggle",
        "bundled CDC source must snapshot payload before toggling the event",
    )
    require_regex(
        errors,
        bundled_cdc,
        r"if\s*\(dst_toggle_sync\s*!=\s*dst_toggle_seen\).*?"
        r"dst_data_hold\s*<=\s*src_data_hold",
        "bundled CDC destination must capture the held payload on toggle",
    )

    emif_ip = EMIF_IP.read_text(encoding="utf-8")
    emif_cal_ip = EMIF_CAL_IP.read_text(encoding="utf-8")
    expected_ip_device = "AGIB023R18A1E1V"
    for ip_text, ip_name in ((emif_ip, "EMIF"), (emif_cal_ip, "EMIF calibration")):
        device = ip_parameter_value(ip_text, "device")
        if device != expected_ip_device:
            errors.append(
                f"{ip_name} source device must be {expected_ip_device}, got {device!r}"
            )
        if "AGIB027R29A1E2VR3" in ip_text:
            errors.append(f"{ip_name} source still contains the old VR3 device")

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

    if not EMIF_RTL.exists():
        errors.append(f"generated EMIF RTL is missing: {EMIF_RTL}")
    else:
        emif_rtl = EMIF_RTL.read_text(encoding="utf-8", errors="replace")
        require_regex(
            errors,
            emif_rtl,
            r"\[\s*63\s*:\s*0\s*\]\s+mem_dq\b",
            "generated EMIF RTL must expose mem_dq[63:0]",
        )
        require_regex(
            errors,
            emif_rtl,
            r"\[\s*511\s*:\s*0\s*\]\s+amm_writedata_0\b",
            "generated EMIF RTL must expose 512-bit AVMM write data",
        )
        require_regex(
            errors,
            emif_rtl,
            r"\[\s*63\s*:\s*0\s*\]\s+amm_byteenable_0\b",
            "generated EMIF RTL must expose 64-bit AVMM byte enable",
        )
        if re.search(r"\[\s*71\s*:\s*0\s*\]\s+mem_dq\b", emif_rtl):
            errors.append("generated EMIF RTL still exposes mem_dq[71:0]")
        if re.search(
            r"\[\s*575\s*:\s*0\s*\]\s+amm_(?:write|read)data_0\b", emif_rtl
        ):
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
