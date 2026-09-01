#!/usr/bin/env python3
"""Fail-closed validation for the IA-780I x64/no-ECC Quartus result."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import sys
import tempfile
import time


EXPECTED_DEVICE = "AGIB023R18A1E1V"
EXPECTED_DQ_WIDTH = 64
EXPECTED_AVMM_WIDTH = 512
SLACK_CLASSES = ("Setup", "Hold", "Recovery", "Removal")
NUMBER_RE = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)"


class ValidationError(RuntimeError):
    """A required build artifact or proof is absent or invalid."""


def require_file(path: Path, description: str) -> Path:
    if not path.is_file():
        raise ValidationError(f"missing {description}: {path}")
    return path


def read_text(path: Path, description: str) -> str:
    require_file(path, description)
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        raise ValidationError(f"cannot read {description}: {path}: {exc}") from exc


def parse_device(fit_summary: str) -> str:
    matches = re.findall(r"(?m)^Device\s*:\s*(\S+)\s*$", fit_summary)
    if len(matches) != 1:
        raise ValidationError("fitter summary must contain exactly one Device field")
    device = matches[0]
    if device != EXPECTED_DEVICE:
        raise ValidationError(
            f"wrong device: expected {EXPECTED_DEVICE}, found {device}"
        )
    if not re.search(r"(?m)^Fitter Status\s*:\s*Successful\b", fit_summary):
        raise ValidationError("fitter summary does not report Successful")
    return device


def packed_width(verilog: str, port: str) -> int:
    match = re.search(
        rf"\b(?:input|output|inout)\s+(?:wire|logic)?\s*"
        rf"\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*{re.escape(port)}\b",
        verilog,
    )
    if not match:
        raise ValidationError(f"generated EMIF top has no packed port {port}")
    high, low = (int(value) for value in match.groups())
    return abs(high - low) + 1


def parse_emif_widths(emif_top: str) -> tuple[int, int]:
    dq_width = packed_width(emif_top, "mem_dq")
    avmm_write_width = packed_width(emif_top, "amm_writedata_0")
    avmm_read_width = packed_width(emif_top, "amm_readdata_0")
    byteenable_width = packed_width(emif_top, "amm_byteenable_0")

    if dq_width != EXPECTED_DQ_WIDTH:
        raise ValidationError(
            f"wrong EMIF DQ width: expected {EXPECTED_DQ_WIDTH}, found {dq_width}"
        )
    if avmm_write_width != EXPECTED_AVMM_WIDTH:
        raise ValidationError(
            "wrong EMIF AVMM write width: "
            f"expected {EXPECTED_AVMM_WIDTH}, found {avmm_write_width}"
        )
    if avmm_read_width != EXPECTED_AVMM_WIDTH:
        raise ValidationError(
            "wrong EMIF AVMM read width: "
            f"expected {EXPECTED_AVMM_WIDTH}, found {avmm_read_width}"
        )
    if byteenable_width != EXPECTED_AVMM_WIDTH // 8:
        raise ValidationError(
            "wrong EMIF AVMM byte-enable width: "
            f"expected {EXPECTED_AVMM_WIDTH // 8}, found {byteenable_width}"
        )
    return dq_width, avmm_write_width


def parse_slacks(sta_summary: str) -> dict[str, float]:
    values: dict[str, list[float]] = {name: [] for name in SLACK_CLASSES}
    entry_re = re.compile(
        rf"(?m)^Type\s*:\s*(Setup|Hold|Recovery|Removal)\b[^\n]*\n"
        rf"Slack\s*:\s*({NUMBER_RE})\s*$"
    )
    for match in entry_re.finditer(sta_summary):
        values[match.group(1)].append(float(match.group(2)))

    missing = [name for name, class_values in values.items() if not class_values]
    if missing:
        raise ValidationError("missing timing slack class(es): " + ", ".join(missing))

    minima = {name: min(class_values) for name, class_values in values.items()}
    negative = [f"{name}={value:.3f}" for name, value in minima.items() if value < 0]
    if negative:
        raise ValidationError("negative timing slack: " + ", ".join(negative))
    return minima


def parse_unconstrained_paths(sta_report: str) -> int:
    summaries: list[int] = []
    lines = sta_report.splitlines()
    for index, line in enumerate(lines):
        if not re.search(r";\s*Unconstrained Paths Summary\s*;", line):
            continue
        total = 0
        rows = 0
        for row in lines[index + 1 : index + 20]:
            match = re.match(
                r";\s*(Illegal Clocks|Unconstrained Clocks|"
                r"Unconstrained Input Ports|"
                r"Paths from Unconstrained Input Ports \(Pairs-Only\)|"
                r"Unconstrained Output Ports|"
                r"Paths to Unconstrained Output Ports \(Pairs-Only\))\s*;"
                r"\s*(\d+)\s*;\s*(\d+)\s*;",
                row,
            )
            if match:
                rows += 1
                total += max(int(match.group(2)), int(match.group(3)))
        if rows:
            summaries.append(total)

    if not summaries:
        raise ValidationError("missing Unconstrained Paths Summary table")
    unconstrained = max(summaries)
    if unconstrained != 0:
        raise ValidationError(f"unconstrained paths are nonzero: {unconstrained}")
    return unconstrained


def validate_fresh_artifacts(
    sof: Path,
    report_paths: tuple[Path, ...],
    max_sof_age_seconds: int,
    now: float | None = None,
) -> str:
    require_file(sof, "SOF")
    if max_sof_age_seconds <= 0:
        raise ValidationError("max SOF age must be positive")
    now = time.time() if now is None else now
    sof_mtime = sof.stat().st_mtime
    age = now - sof_mtime
    if age < -5:
        raise ValidationError(f"SOF timestamp is in the future by {-age:.1f} seconds")
    if age > max_sof_age_seconds:
        raise ValidationError(
            f"stale SOF: age {age:.1f}s exceeds {max_sof_age_seconds}s"
        )
    for report in report_paths:
        require_file(report, "Quartus report")
        report_age = now - report.stat().st_mtime
        if report_age > max_sof_age_seconds:
            raise ValidationError(f"stale Quartus report: {report}")
        if report.stat().st_mtime > sof_mtime + 5:
            raise ValidationError(f"SOF predates Quartus report: {report}")

    digest = hashlib.sha256()
    with sof.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_project(project_dir: Path, max_sof_age_seconds: int) -> dict[str, object]:
    project_dir = project_dir.resolve()
    fit_path = project_dir / "output_files" / "cxltyp2_ed.fit.summary"
    sta_summary_path = project_dir / "output_files" / "cxltyp2_ed.sta.summary"
    sta_report_path = project_dir / "output_files" / "cxltyp2_ed.sta.rpt"
    sof_path = project_dir / "output_files" / "cxltyp2_ed.sof"
    emif_top_path = (
        project_dir
        / "common"
        / "mc_top"
        / "emif_ip"
        / "emif"
        / "synth"
        / "emif.v"
    )

    fit_summary = read_text(fit_path, "fitter summary")
    sta_summary = read_text(sta_summary_path, "TimeQuest summary")
    sta_report = read_text(sta_report_path, "TimeQuest report")
    emif_top = read_text(emif_top_path, "generated EMIF top")

    device = parse_device(fit_summary)
    dq_width, avmm_width = parse_emif_widths(emif_top)
    slacks = parse_slacks(sta_summary)
    unconstrained = parse_unconstrained_paths(sta_report)
    sof_sha256 = validate_fresh_artifacts(
        sof_path,
        (fit_path, sta_summary_path, sta_report_path),
        max_sof_age_seconds,
    )
    return {
        "device": device,
        "dq_width": dq_width,
        "avmm_width": avmm_width,
        "slacks": slacks,
        "unconstrained": unconstrained,
        "sof_sha256": sof_sha256,
    }


def write_fixture(
    root: Path,
    *,
    device: str = EXPECTED_DEVICE,
    dq_width: int = EXPECTED_DQ_WIDTH,
    avmm_width: int = EXPECTED_AVMM_WIDTH,
    slacks: dict[str, float] | None = None,
    unconstrained: int = 0,
    sof_age: int = 0,
) -> None:
    slacks = slacks or {name: 0.125 for name in SLACK_CLASSES}
    output = root / "output_files"
    emif = root / "common" / "mc_top" / "emif_ip" / "emif" / "synth"
    output.mkdir(parents=True)
    emif.mkdir(parents=True)
    fit = output / "cxltyp2_ed.fit.summary"
    sta_summary = output / "cxltyp2_ed.sta.summary"
    sta_report = output / "cxltyp2_ed.sta.rpt"
    sof = output / "cxltyp2_ed.sof"
    fit.write_text(
        f"Fitter Status : Successful - fixture\nDevice : {device}\n",
        encoding="utf-8",
    )
    sta_summary.write_text(
        "\n".join(
            f"Type  : {name} 'fixture_clock'\nSlack : {value:.3f}\n"
            for name, value in slacks.items()
        ),
        encoding="utf-8",
    )
    sta_report.write_text(
        "+--+\n"
        "; Unconstrained Paths Summary ;\n"
        "; Property ; Setup ; Hold ;\n"
        f"; Unconstrained Clocks ; {unconstrained} ; {unconstrained} ;\n"
        "; Unconstrained Input Ports ; 0 ; 0 ;\n"
        "; Paths from Unconstrained Input Ports (Pairs-Only) ; 0 ; 0 ;\n"
        "; Unconstrained Output Ports ; 0 ; 0 ;\n"
        "; Paths to Unconstrained Output Ports (Pairs-Only) ; 0 ; 0 ;\n",
        encoding="utf-8",
    )
    emif.joinpath("emif.v").write_text(
        "module emif (\n"
        f"  inout wire [{dq_width - 1}:0] mem_dq,\n"
        f"  input wire [{avmm_width - 1}:0] amm_writedata_0,\n"
        f"  output wire [{avmm_width - 1}:0] amm_readdata_0,\n"
        f"  input wire [{avmm_width // 8 - 1}:0] amm_byteenable_0\n"
        "); endmodule\n",
        encoding="utf-8",
    )
    sof.write_bytes(b"IA780I fixture SOF\n")
    timestamp = time.time() - sof_age
    for path in (fit, sta_summary, sta_report, sof):
        os.utime(path, (timestamp, timestamp))


def run_self_tests() -> None:
    cases = 0

    def expect_pass(**kwargs: object) -> None:
        nonlocal cases
        with tempfile.TemporaryDirectory(prefix="ia780i-quartus-good-") as temp:
            root = Path(temp)
            write_fixture(root, **kwargs)
            validate_project(root, 60)
        cases += 1

    def expect_reject(description: str, **kwargs: object) -> None:
        nonlocal cases
        with tempfile.TemporaryDirectory(prefix="ia780i-quartus-bad-") as temp:
            root = Path(temp)
            write_fixture(root, **kwargs)
            try:
                validate_project(root, 60)
            except ValidationError:
                cases += 1
                return
        raise AssertionError(f"self-test accepted {description}")

    expect_pass()
    expect_reject("wrong device", device="AGIB023R18A1E2V")
    expect_reject("72-bit DQ", dq_width=72)
    expect_reject("576-bit AVMM", avmm_width=576)
    for slack_class in SLACK_CLASSES:
        bad_slacks = {name: 0.125 for name in SLACK_CLASSES}
        bad_slacks[slack_class] = -0.001
        expect_reject(f"negative {slack_class} slack", slacks=bad_slacks)
    missing_slacks = {name: 0.125 for name in SLACK_CLASSES if name != "Removal"}
    expect_reject("missing Removal slack", slacks=missing_slacks)
    expect_reject("nonzero unconstrained paths", unconstrained=1)
    expect_reject("stale SOF", sof_age=61)

    with tempfile.TemporaryDirectory(prefix="ia780i-quartus-missing-sof-") as temp:
        root = Path(temp)
        write_fixture(root)
        root.joinpath("output_files", "cxltyp2_ed.sof").unlink()
        try:
            validate_project(root, 60)
        except ValidationError:
            cases += 1
        else:
            raise AssertionError("self-test accepted missing SOF")

    print(f"IA780I_QUARTUS_RESULT_SELF_TEST: PASS ({cases} cases)")


def print_result(result: dict[str, object]) -> None:
    slacks = result["slacks"]
    assert isinstance(slacks, dict)
    print(f"DEVICE={result['device']}")
    print(f"EMIF_DQ_PER_CHANNEL={result['dq_width']}")
    print(f"EMIF_AVMM_WIDTH={result['avmm_width']}")
    for name in SLACK_CLASSES:
        print(f"{name.upper()}_WNS={slacks[name]:.3f}")
    print(f"UNCONSTRAINED_PATHS={result['unconstrained']}")
    print(f"SOF_SHA256={result['sof_sha256']}")
    print("IA780I_QUARTUS_RESULT=PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-dir", type=Path)
    parser.add_argument("--max-sof-age-seconds", type=int, default=86400)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    try:
        if args.self_test:
            run_self_tests()
            return 0
        if args.project_dir is None:
            parser.error("--project-dir is required unless --self-test is used")
        result = validate_project(args.project_dir, args.max_sof_age_seconds)
        print_result(result)
        return 0
    except (ValidationError, AssertionError) as exc:
        print(f"IA780I_QUARTUS_RESULT=FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
