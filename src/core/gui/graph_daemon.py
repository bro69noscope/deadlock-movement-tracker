import contextlib
import io
import json
import os
import runpy
import sys
import time
import traceback
from pathlib import Path

# pyright: reportAny=false


def _run_render(
    render_script: Path, csv_path: str, out_path: str, title: str
) -> tuple[int, str]:
    old_argv = sys.argv[:]
    sys.argv = [str(render_script), csv_path, out_path, title]
    buf = io.StringIO()
    try:
        with contextlib.redirect_stderr(buf):
            runpy.run_path(str(render_script), run_name="__main__")
        return 0, buf.getvalue()
    except SystemExit as e:
        return int(e.code) if isinstance(e.code, int) else 0, buf.getvalue()
    finally:
        sys.argv = old_argv


def process_request(
    req_path: Path,
    res_dir: Path,
    render_script: Path,
) -> None:
    req_id = req_path.stem
    res_path = res_dir / f"{req_id}.json"

    try:
        data = json.loads(req_path.read_text(encoding="utf-8-sig"))
        csv_path = data["csv"]
        out_path = data["png"]
        title = data.get("title", "Unknown")

        code, stderr = _run_render(render_script, csv_path, out_path, title)

        ok = code == 0 and Path(out_path).exists() and Path(out_path).stat().st_size > 0

        res = {"ok": bool(ok), "code": int(code), "stderr": stderr}

    except Exception:
        res = {
            "ok": False,
            "code": 99,
            "error": traceback.format_exc(),
        }

    res_path.write_text(json.dumps(res, ensure_ascii=False), encoding="utf-8")

    try:
        req_path.unlink()
    except Exception:
        pass


def main() -> int:
    if len(sys.argv) < 3:
        return 2

    base_dir = Path(sys.argv[1])
    render_script = Path(sys.argv[2])

    req_dir = base_dir / "req"
    res_dir = base_dir / "res"
    pid_file = base_dir / "daemon.pid"
    stop_file = base_dir / "STOP"

    req_dir.mkdir(parents=True, exist_ok=True)
    res_dir.mkdir(parents=True, exist_ok=True)
    pid_file.write_text(str(os.getpid()), encoding="utf-8")

    try:
        while True:
            if stop_file.exists():
                try:
                    stop_file.unlink()
                except Exception:
                    pass
                break

            reqs = sorted(req_dir.glob("*.json"), key=lambda p: p.stat().st_mtime)
            if not reqs:
                time.sleep(0.05)
                continue

            process_request(reqs[0], res_dir, render_script)

    finally:
        try:
            pid_file.unlink()
        except Exception:
            pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
