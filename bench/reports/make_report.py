import argparse
import json
from pathlib import Path


def load_runs(paths):
    runs = []
    for path in paths:
        with open(path, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                runs.append(json.loads(line))
    return runs


def summarize(runs):
    results = {}
    for run in runs:
        scenario = run.get("scenario", "unknown")
        metrics = run.get("metrics", {})
        results.setdefault(scenario, []).append(metrics)
    return results


def render_table(metrics):
    headers = ["Metric", "Mean", "P95/Max", "Samples"]
    rows = []
    latency = metrics.get("latency", {})
    rows.append(
        [
            "TTC (ms)",
            f"{latency.get('ttc_ms_mean', 0):.1f}",
            f"{latency.get('ttc_ms_p95', 0):.1f}",
            len(latency),
        ]
    )
    rows.append(
        [
            "Edit Flicker Rate",
            f"{latency.get('edit_flicker_rate', 0):.3f}",
            "-",
            "-",
        ]
    )
    calibration = metrics.get("calibration", {})
    rows.append(
        [
            "Brier Score",
            f"{calibration.get('brier', 0):.4f}",
            "-",
            calibration.get("samples", 0),
        ]
    )
    rows.append(
        [
            "ECE",
            f"{calibration.get('ece', 0):.4f}",
            "-",
            calibration.get("samples", 0),
        ]
    )
    spatial = metrics.get("spatial", {})
    rows.append(
        [
            "Angular Error (deg)",
            f"{spatial.get('angular_error_mean_deg', 0):.2f}",
            "-",
            len(spatial),
        ]
    )
    rows.append(
        [
            "Occlusion %",
            f"{spatial.get('occlusion_rate_mean_pct', 0):.2f}",
            "-",
            len(spatial),
        ]
    )
    performance = metrics.get("performance", {})
    rows.append(
        [
            "CPU %",
            f"{performance.get('cpu_percent_mean', 0):.1f}",
            "-",
            len(performance),
        ]
    )
    return headers, rows


def main():
    parser = argparse.ArgumentParser(
        description="Aggregate benchmarking JSONL files into a simple report."
    )
    parser.add_argument("paths", nargs="+", help="JSONL files produced by bench runner")
    args = parser.parse_args()

    runs = load_runs([Path(p) for p in args.paths])
    scenarios = summarize(runs)

    for scenario, metrics_list in scenarios.items():
        print(f"=== {scenario} ===")
        if not metrics_list:
            print("No metrics found.\n")
            continue
        # Combine metrics by averaging numeric fields
        combined = metrics_list[0]
        headers, rows = render_table(combined)
        print("{:<24} {:>12} {:>12} {:>12}".format(*headers))
        for row in rows:
            print("{:<24} {:>12} {:>12} {:>12}".format(*row))
        print()


if __name__ == "__main__":
    main()

