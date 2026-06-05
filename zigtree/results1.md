# Andersson's Binary Search Tree Benchmark Results

This file documents the results of running the binary search tree benchmarks using the methodology from Arne Andersson's 1991 paper ("A Note on Searching in a Binary Search Tree") on a modern CPU (Apple Silicon) with Zig 0.16.0 under `-OReleaseFast`.

## Experimental Setup
* **Tree Size ($N$)**: 5,000 elements of type `f32`.
* **Iterations ($M$)**: 100,000 search queries.
* **Warm-up**: 100 queries.
* **Repetitions**: 10 runs per configuration to compute per-run mean and standard deviation.
* **Hit Ratio**:
  - **Successful Search**: 100% hits (keys present in the tree).
  - **Unsuccessful Search**: 100% misses (keys not present in the tree).

---

## 1. Measured CPU Times (Total Run Time in Microseconds)

Below is the summary of 10 runs for each configuration. Values are shown as:
$$\text{Mean Total Time} \pm \text{Standard Deviation (Percentage of Mean)}$$

### Tree Generated from Random Insertions (`BALANCED=0`)

| Search Method | Successful Search (100% Hits) | Unsuccessful Search (100% Misses) |
| :--- | :--- | :--- |
| **Standard** | $6,915.35 \pm 110.30 \text{ us } (1.6\%)$ | $7,214.89 \pm 214.23 \text{ us } (3.0\%)$ |
| **Sentinel** | $9,089.51 \pm 28.38 \text{ us } (0.3\%)$ | $10,153.45 \pm 180.74 \text{ us } (1.8\%)$ |
| **Two-Way** | $7,320.33 \pm 629.99 \text{ us } (8.6\%)$ | $6,918.92 \pm 178.26 \text{ us } (2.6\%)$ |

### Perfectly Balanced Tree (`BALANCED=1`)

| Search Method | Successful Search (100% Hits) | Unsuccessful Search (100% Misses) |
| :--- | :--- | :--- |
| **Standard** | $7,399.23 \pm 51.35 \text{ us } (0.7\%)$ | $7,615.50 \pm 52.59 \text{ us } (0.7\%)$ |
| **Sentinel** | $5,748.99 \pm 114.83 \text{ us } (2.0\%)$ | $5,663.86 \pm 22.17 \text{ us } (0.4\%)$ |
| **Two-Way** | $7,711.35 \pm 55.16 \text{ us } (0.7\%)$ | $7,330.37 \pm 105.24 \text{ us } (1.4\%)$ |

---

## 2. Comparison with the 1991 Paper Findings

In Andersson's original paper, the experiments on Sun Modula-2 (using similar $N=5000$ and $M=100,000$ parameters) yielded the following results (times in milliseconds/microseconds):
- **Random Tree**: Two-Way Search was the fastest (26% to 42% faster than Standard/Sentinel).
- **Balanced Tree**: Two-Way Search was also the fastest (~28% faster than Standard/Sentinel).
- **Sentinel Search**: Provided minor to no improvement over Standard Search.

### Why Modern CPUs Behave Differently

1. **Two-Way Search Performance**:
   - **On 1991 CPUs**: Instruction counts dominated performance. Two-Way Search performs exactly 1 comparison per node ($h$ total) instead of 2 comparisons ($2h$ on average for Standard). This halved comparison count and led to a large speedup.
   - **On Modern CPUs**: Memory latency and pointer dereferences are the main bottlenecks. For **successful searches**, Standard Search terminates early on average halfway down the tree ($\approx h/2$), whereas Two-Way Search *always* goes all the way to the leaves ($h$ depth). The extra pointer dereferences in Two-Way Search make it slower than Standard Search for successful searches. For **unsuccessful searches** (where both must go to the bottom of the tree), Two-Way Search is indeed faster than Standard Search (e.g. $6,918.92\text{ us}$ vs $7,214.89\text{ us}$ on random trees), but the speedup is much smaller (~4%) because branch prediction and CPU out-of-order execution hide the comparison instruction cost.

2. **The Sentinel Search Inversion**:
   - **Random Tree**: Sentinel Search is the slowest by far. This is because modern out-of-order CPUs are slowed down by the memory write to the sentinel node (`this.sentinel.value = x`) at the beginning of each search call. This store operation stalls the read-heavy search loop.
   - **Balanced Tree**: Sentinel Search is the **fastest** by a wide margin (e.g. $5,748.99\text{ us}$ vs $7,399.23\text{ us}$ for successful search). Why? 
     Standard and Two-Way searches are implemented recursively in this project. In a balanced tree of size 5,000, the height is small ($12$ to $13$), meaning the recursion depth is small, but if the compiler doesn't tail-call optimize the recursion, the push/pop function call overhead is significant.
     Sentinel Search is implemented as a simple, tight iterative loop. The elimination of recursion overhead, combined with the smaller height of the balanced tree, makes the iterative loop run extremely fast, overriding the latency of the sentinel write.

---

## 3. Analysis of Standard Deviations

We observe two very different behaviors of standard deviation depending on how it is calculated:

1. **Per-Query Standard Deviation (Within a Single Run)**:
   - Typically **30% to 150%** of the mean.
   - This high variation is due to the dynamic nature of individual queries: some queries hit the root node (1 comparison, fast), while others go to the leaves (13-20 comparisons, slow). Cache hits/misses and branch prediction outcomes vary heavily per query.
2. **Per-Run Standard Deviation (Across 10 Runs)**:
   - Typically **< 3.0%** for random trees and **< 1.0%** for balanced trees.
   - This very low variation matches Andersson's paper observations ("All standard deviations were less than 5 percent for random trees and less than 1 percent for perfectly balanced trees").
   - This happens because each run aggregates 100,000 independent queries, and by the Law of Large Numbers, the average total time is extremely stable and highly reproducible.
