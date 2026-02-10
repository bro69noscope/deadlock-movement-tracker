import json
import os
import runpy
import sys
import time
import traceback
from pathlib import Path


def _run_render(
    render_script: Path, csv_path: str, out_path: str, title: str, err_path: str
) -> int:
    old_argv = sys.argv[:]
    sys.argv = [str(render_script), csv_path, out_path, title, err_path]
    try:
        runpy.run_path(str(render_script), run_name="__main__")
        return 0
    except SystemExit as e:
        if isinstance(e.code, int):
            return int(e.code)
        return 0
    except Exception:
        Path(err_path).write_text(traceback.format_exc(), encoding="utf-8")
        raise
    finally:
        sys.argv = old_argv


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

            req_path = reqs[0]
            req_id = req_path.stem
            res_path = res_dir / f"{req_id}.json"

            try:
                data = json.loads(req_path.read_text(encoding="utf-8-sig"))
                csv_path = data["csv"]
                out_path = data["png"]
                err_path = data["err"]
                title = data.get("title", "Unknown")

                try:
                    Path(err_path).unlink()
                except Exception:
                    pass

                code = _run_render(render_script, csv_path, out_path, title, err_path)

                ok = (
                    code == 0
                    and Path(out_path).exists()
                    and Path(out_path).stat().st_size > 0
                )

                res = {"ok": bool(ok), "code": int(code)}
            except Exception:
                res = {"ok": False, "code": 99, "error": traceback.format_exc()}

            res_path.write_text(json.dumps(res, ensure_ascii=False), encoding="utf-8")

            try:
                req_path.unlink()
            except Exception:
                pass

    finally:
        try:
            pid_file.unlink()
        except Exception:
            pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
