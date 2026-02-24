import sys
import textwrap
import traceback
from pathlib import Path

import matplotlib
from matplotlib.axes import Axes
import pandas as pd

matplotlib.use("Agg")
import matplotlib.pyplot as plt

# pyright: reportUnknownMemberType=false


def wrap_title(title: str, width: int) -> str:
    return "\n".join(textwrap.wrap(title, width=width))


def _succ_series(df: pd.DataFrame) -> pd.Series:
    # 1 for success, 0 otherwise
    return df["result"].astype(str).str.strip().str.lower().eq("success").astype(int)


def _plot_panel(
    ax: Axes, succ: pd.Series, label: str, color: str | None = None
) -> None:
    ax.set_ylim(0, 1)
    ax.grid(alpha=0.3)
    ax.set_ylabel("Rate")

    if succ.empty:
        ax.text(
            0.5,
            0.5,
            "No Data",
            ha="center",
            va="center",
            fontsize=11,
            color="gray",
            transform=ax.transAxes,
        )
        ax.set_title(label)
        ax.set_xlabel("Attempt")
        return

    succ2 = succ.reset_index(drop=True)
    rate = succ2.cumsum() / (succ2.index + 1)

    if color:
        ax.plot(succ2.index + 1, rate, linewidth=2.2, color=color)
    else:
        ax.plot(succ2.index + 1, rate, linewidth=2.2)

    ax.set_title(f"{label} — N={len(succ2)}")
    ax.set_xlabel("Attempt")


def main() -> int:
    if len(sys.argv) < 4:
        return 2

    csv_path = sys.argv[1]
    out_path = sys.argv[2]
    instance_name = sys.argv[3]
    df = None

    try:
        if not Path(csv_path).exists():
            raise FileNotFoundError(f"CSV file not found: {csv_path}")
        df = pd.read_csv(csv_path, names=["ts", "instance", "result"])
    except Exception:
        traceback.print_exc()
        df = None

    fig = plt.figure(figsize=(6, 8))
    wrapped = wrap_title(f"Success Over Time — {instance_name}", 60)
    fig.suptitle(wrapped)

    ax1 = fig.add_subplot(3, 1, 1)
    ax2 = fig.add_subplot(3, 1, 2)
    ax3 = fig.add_subplot(3, 1, 3)

    if df is None or df.empty:
        for ax, title in [(ax1, "Overall"), (ax2, "Last 50"), (ax3, "Last 20")]:
            _plot_panel(ax, pd.Series(dtype=int), title)
        fig.tight_layout()
        fig.savefig(out_path, dpi=120)
        plt.close(fig)
        return 0

    succ = _succ_series(df)

    _plot_panel(ax1, succ, "Overall")
    _plot_panel(ax2, succ.tail(50), "Last 50", color="orange")
    _plot_panel(ax3, succ.tail(20), "Last 20", color="green")

    fig.tight_layout()
    fig.savefig(out_path, dpi=120)
    plt.close(fig)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
