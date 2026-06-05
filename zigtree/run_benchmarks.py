import os
import re
import subprocess
import statistics

# Configuration
num_runs = 10
combinations = [
    {"balanced": 0, "success": 100, "label": "Random Tree, Successful Search"},
    {"balanced": 0, "success": 0, "label": "Random Tree, Unsuccessful Search"},
    {"balanced": 1, "success": 100, "label": "Balanced Tree, Successful Search"},
    {"balanced": 1, "success": 0, "label": "Balanced Tree, Unsuccessful Search"},
]

# Use the script's directory as the working directory
script_dir = os.path.dirname(os.path.abspath(__file__))

results = {}

for combo in combinations:
    label = combo["label"]
    results[label] = {
        "Standard": [],
        "Sentinel": [],
        "Two-Way": []
    }
    
    print(f"Running: {label}...")
    for run in range(num_runs):
        env = os.environ.copy()
        env["BALANCED"] = str(combo["balanced"])
        env["SUCCESSFUL_SEARCH"] = str(combo["success"])
        env["NUM_ELEMENTS"] = "5000"
        env["NUM_ITERATIONS"] = "100000"
        
        # Run the compiled Zig binary
        res = subprocess.run(
            ["zig", "build", "-Doptimize=ReleaseFast", "run"],
            cwd=script_dir,
            capture_output=True,
            text=True,
            env=env
        )
        
        output_text = res.stdout + res.stderr
        # Match ns/op average timing using regex
        std_match = re.search(r"Standard Search:\s*([\d.]+)\s*ns/op", output_text)
        sentinel_match = re.search(r"Sentinel Search:\s*([\d.]+)\s*ns/op", output_text)
        twoway_match = re.search(r"Two-Way Search:\s*([\d.]+)\s*ns/op", output_text)
        
        if std_match and sentinel_match and twoway_match:
            results[label]["Standard"].append(float(std_match.group(1)))
            results[label]["Sentinel"].append(float(sentinel_match.group(1)))
            results[label]["Two-Way"].append(float(twoway_match.group(1)))
        else:
            print(f"Failed to parse run {run+1} for {label}: {output_text}")

# Print summary
print("\n=== BENCHMARK SUMMARY (10 runs, N=5000, M=100000) ===\n")
for label, data in results.items():
    print(f"--- {label} ---")
    for method, times in data.items():
        if times:
            mean = statistics.mean(times)
            stddev = statistics.stdev(times) if len(times) > 1 else 0.0
            pct_stddev = (stddev / mean) * 100.0 if mean > 0 else 0.0
            print(f"  {method:8} Search: Mean = {mean:8.2f} ns/op, StdDev = {stddev:6.2f} ns/op ({pct_stddev:.1f}%)")
        else:
            print(f"  {method:8} Search: No data")
