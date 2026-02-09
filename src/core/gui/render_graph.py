import sys

import pandas as pd
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main() -> int:
    if len(sys.argv) < 3:
        return 2

    csv_path = sys.argv[1]
    out_path = sys.argv[2]

    df = pd.read_csv(csv_path, names=["ts", "instance", "result"])

    instance_name = "Unknown"
    if len(sys.argv) >= 4:
        instance_name = sys.argv[3]
    elif not df.empty:
        instance_name = str(df["instance"].iloc[0])
    if df.empty:
        succ = pd.Series(dtype=int)
    else:
        succ = (
            df["result"].astype(str).str.strip().str.lower().eq("success").astype(int)
        )

    rate = succ.cumsum() / (succ.index + 1)

    plt.figure(figsize=(6, 3))
    plt.plot(rate, linewidth=2)
    plt.ylim(0, 1)
    plt.xlabel("Attempt")
    plt.ylabel("Success rate")
    plt.title(f"Success Over Time — {instance_name}")
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(out_path, dpi=120)
    plt.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
