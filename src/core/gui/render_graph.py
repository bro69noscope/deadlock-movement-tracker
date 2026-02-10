import sys
import traceback

import matplotlib
import pandas as pd

matplotlib.use("Agg")
import matplotlib.pyplot as plt


# pyright: reportUnknownMemberType=false
def main() -> int:
    if len(sys.argv) < 4:
        return 2

    csv_path = sys.argv[1]
    out_path = sys.argv[2]
    instance_name = sys.argv[3]

    try:
        df = pd.read_csv(csv_path, names=["ts", "instance", "result"])
    except Exception:
        # Let the daemon capture it
        traceback.print_exc()
        df = None

    plt.figure(figsize=(6, 3))

    if df is None or df.empty:
        plt.text(
            0.5,
            0.5,
            "No Data Available",
            ha="center",
            va="center",
            fontsize=16,
            color="gray",
            transform=plt.gca().transAxes,
        )
        plt.ylim(0, 1)
        plt.title(f"Success Over Time — {instance_name}")
    else:
        succ = (
            df["result"].astype(str).str.strip().str.lower().eq("success").astype(int)
        )
        rate = succ.cumsum() / (succ.index + 1)

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
