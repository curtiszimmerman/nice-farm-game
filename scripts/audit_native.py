#!/usr/bin/env python3
"""Run native checks with separate logs so one failure cannot hide later failures."""
import argparse
import json
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tests", nargs="*", help="Native test names, without .gd; defaults to check.sh's suite")
    parser.add_argument("--failed-from", type=Path, help="Rerun checks with errors in this previous log directory")
    parser.add_argument("--output", default="internal/verification/native-audit", type=Path, help="Directory for logs and summary.json, inside this project")
    args = parser.parse_args()
    project = Path(__file__).resolve().parent.parent
    output = (project / args.output).resolve()
    if not output.is_relative_to(project):
        parser.error("Logs must stay inside the project")
    errors = re.compile(r"SCRIPT ERROR:|^ERROR:|^WARNING:|FAIL:", re.MULTILINE)
    names = args.tests
    if args.failed_from:
        names += [file.stem for file in sorted(args.failed_from.glob("*.log")) if errors.search(file.read_text())]
    if not names:
        source = (project / "scripts/check.sh").read_text()
        for line in source.splitlines():
            if line.startswith("for test_file in "):
                names += line.split(" in ", 1)[1].split(";", 1)[0].split()
        names += re.findall(r"tests/native/(\w+_test)\.gd", source)
    output.mkdir(parents=True, exist_ok=True)
    results = {}
    for name in dict.fromkeys(names):
        if not re.fullmatch(r"\w+_test", name) or not (project / "tests/native" / (name + ".gd")).is_file():
            parser.error("Unknown native test: " + name)
        try:
            run = subprocess.run(["bash", "scripts/play.sh", "--headless", "--script", "../../tests/native/" + name + ".gd"], cwd=project, capture_output=True, text=True, timeout=30)
            log = run.stdout + run.stderr
            passed = run.returncode == 0 and not errors.search(log)
        except subprocess.TimeoutExpired as error:
            log = (error.stdout or b"").decode() + (error.stderr or b"").decode() + "\nERROR: Native check timed out\n"
            passed = False
        (output / (name + ".log")).write_text(log)
        results[name] = {"passed": passed, "assertions": len(re.findall(r"^PASS:", log, re.MULTILINE))}
        failures = [line for line in log.splitlines() if errors.search(line)]
        print(name + ": " + ("PASS" if passed else "FAIL " + " | ".join(failures[:3])), flush=True)
        (output / "summary.json").write_text(json.dumps(results, indent=2) + "\n")
    print(f"{sum(result['passed'] for result in results.values())}/{len(results)} native programs passed", flush=True)
    return 0 if all(result["passed"] for result in results.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
