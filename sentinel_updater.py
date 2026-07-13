#!/usr/bin/env python3
"""🔄 SENTINEL SELF-UPDATER — safe, pull-based, verify-before-swap.

PHILOSOPHY (why it's built this way):
  This code updates itself from a PUBLIC repo. That's a supply chain, so every
  step is a guardrail. It is PULL-based (this machine chooses to check; nobody
  pushes code IN), VERSION-GATED (only strictly-newer versions), VERIFIED
  (downloads to temp, must compile, before anything is swapped), REVERSIBLE
  (backs up the current version), and NON-DISRUPTIVE (never overwrites the
  running file mid-run — stages for next start).

  It will NEVER:
    - downgrade (older remote version is ignored)
    - swap in a download that is empty, truncated, or won't compile
    - delete the old version (it's backed up)
    - touch anything but its own sentinel file

Usage:
    from sentinel_updater import check_for_updates
    check_for_updates(notify=print)          # check + stage if newer
    check_for_updates(notify=print, apply=False)  # check only, report
"""
import re
import os
import shutil
import tempfile
import urllib.request
from datetime import datetime
from pathlib import Path

# --- CONFIG: the PUBLIC source this pulls from (read-only, no auth needed) ---
RAW_BASE = "https://raw.githubusercontent.com/RouxsterEnterprise/Lkey-Sentinel/main"
REMOTE_VERSION_URL = f"{RAW_BASE}/VERSION"
REMOTE_CODE_URL = f"{RAW_BASE}/lkey_sentinel.py"

HERE = Path(__file__).resolve().parent
LOCAL_VERSION_FILE = HERE / "VERSION"
LOCAL_CODE_FILE = HERE / "lkey_sentinel.py"
STAGED_UPDATE = HERE / "lkey_sentinel.py.staged"   # applied on next start


def parse_version(v):
    """'1.2.3' -> (1,2,3). Robust against whitespace/junk; unknown -> (0,)."""
    try:
        nums = re.findall(r"\d+", str(v).strip())
        return tuple(int(n) for n in nums[:3]) or (0,)
    except Exception:
        return (0,)


def _read_local_version():
    try:
        return LOCAL_VERSION_FILE.read_text(encoding="utf-8").strip()
    except Exception:
        return "0.0.0"   # no local version file -> treat as oldest


def _fetch(url, timeout=10):
    """Fetch a URL's text. Returns None on any failure (offline, 404, etc.)."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "LkeySentinel-Updater"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read().decode("utf-8", errors="replace")
    except Exception:
        return None


def _verify_code(content):
    """A downloaded update MUST be non-empty, look like code, and COMPILE.
    (Compile is checked independently so a long-but-broken file is still caught.)"""
    if not content or len(content) < 200:
        return False, "download empty or truncated"
    if "def " not in content or "import " not in content:
        return False, "does not look like the sentinel source"
    try:
        compile(content, "<downloaded_update>", "exec")
    except SyntaxError as e:
        return False, f"downloaded code won't compile: {e}"
    # sanity: the real sentinel has these hallmarks
    if "def watch" not in content or "def sample" not in content:
        return False, "missing expected sentinel functions — refusing"
    return True, "valid"


def check_for_updates(notify=print, apply=True):
    """Check the public repo for a newer version. If found and valid, stage it
    (or report only if apply=False). Returns a short status string."""
    local_v = _read_local_version()

    remote_v = _fetch(REMOTE_VERSION_URL)
    if remote_v is None:
        notify("🔄 Update check skipped (couldn't reach the update server — that's OK, offline is fine).")
        return "offline"
    remote_v = remote_v.strip()

    if parse_version(remote_v) <= parse_version(local_v):
        notify(f"🔄 Sentinel is up to date (v{local_v}).")
        return "current"

    # a newer version exists
    notify(f"🔄 Update available: v{local_v} → v{remote_v}")
    if not apply:
        return f"available:{remote_v}"

    # download the new code to a temp file
    new_code = _fetch(REMOTE_CODE_URL)
    if new_code is None:
        notify("🔄 Couldn't download the update — will try again next time.")
        return "download_failed"

    ok, why = _verify_code(new_code)
    if not ok:
        notify(f"🔄 Update REJECTED for safety: {why}. Keeping current version.")
        return f"rejected:{why}"

    # write to a temp file first, verify it lands intact, then stage
    try:
        fd, tmp = tempfile.mkstemp(suffix=".py", dir=str(HERE))
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(new_code)
        # re-verify the file on disk compiles (belt and suspenders)
        compile(Path(tmp).read_text(encoding="utf-8"), "<staged>", "exec")
        # stage it — applied on next start, NOT mid-run (avoids file locks)
        shutil.move(tmp, STAGED_UPDATE)
        # write the new version marker alongside the staged update
        (HERE / "VERSION.staged").write_text(remote_v, encoding="utf-8")
    except Exception as e:
        notify(f"🔄 Staging failed ({e}) — current version untouched.")
        try:
            if os.path.exists(tmp):
                os.remove(tmp)
        except Exception:
            pass
        return "stage_failed"

    notify(f"🔄 Update v{remote_v} downloaded + verified. It will apply next time "
           "Sentinel starts. (Your current version keeps running until then.)")
    return f"staged:{remote_v}"


def apply_staged_update(notify=print):
    """Called at STARTUP: if a verified update was staged, back up the current
    version and swap the staged one in. Safe because nothing's running from the
    file yet at startup. Returns True if an update was applied."""
    if not STAGED_UPDATE.exists():
        return False
    try:
        # verify the staged file STILL compiles (paranoia — it was verified at
        # download, but disk could have changed)
        staged_code = STAGED_UPDATE.read_text(encoding="utf-8")
        compile(staged_code, "<staged_apply>", "exec")
    except Exception as e:
        notify(f"🔄 Staged update failed final check ({e}) — discarding it, keeping current.")
        try:
            STAGED_UPDATE.unlink()
        except Exception:
            pass
        return False

    # back up current version (reversible!)
    try:
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        if LOCAL_CODE_FILE.exists():
            shutil.copy2(LOCAL_CODE_FILE, HERE / f"lkey_sentinel.py.bak_{stamp}")
        # swap in the staged version
        shutil.move(str(STAGED_UPDATE), str(LOCAL_CODE_FILE))
        # promote the staged version marker
        staged_ver = HERE / "VERSION.staged"
        if staged_ver.exists():
            shutil.move(str(staged_ver), str(LOCAL_VERSION_FILE))
        notify("🔄 Update applied ✅ (previous version backed up — safe to roll back).")
        return True
    except Exception as e:
        notify(f"🔄 Couldn't apply staged update ({e}) — current version intact.")
        return False


if __name__ == "__main__":
    import sys
    if "--apply-staged" in sys.argv:
        applied = apply_staged_update()
        print("applied" if applied else "nothing staged")
    else:
        # check-only by default when run manually, so nothing surprises you
        print(check_for_updates(apply="--go" in sys.argv))
