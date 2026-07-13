# 🛡️ Lkey Sentinel

A featherweight guardian for powerful-but-unstable Windows gaming rigs.

Lkey Sentinel sits quietly in the background, sips telemetry on a slow timer, and does three things:

- **Warns before trouble** — watches GPU/CPU temps, RAM, and VRAM, and alerts you *before* a crash when the machine enters the danger zone ("VRAM 94% — save your game").
- **Catches crashes** — the moment a program or game dies, it cross-checks the Windows Event Log, records **why** (the faulting module) and the machine's vital signs in the seconds before death, and pings you.
- **Stays out of the way** — a few MB of footprint, read-only toward the system. It never throttles, kills, or touches your games, launchers, anti-cheat, or anything you're actively using.

It cannot fix hardware faults — it gives you **early warning** and a **black box** so the real cause is visible, even remotely.

## Quick start

1. **Install Python 3.10+** from [python.org](https://www.python.org/downloads/) (tick "Add Python to PATH").
2. **Install dependencies:**
   ```
   pip install psutil pynvml pywin32 pystray pillow
   ```
   (Only `psutil` is strictly required. `pynvml` adds NVIDIA GPU stats, `pywin32` enables crash confirmation from the Event Log, `pystray`+`pillow` enable the system-tray mode.)
3. **Run it:**
   ```
   python lkey_sentinel.py            # console mode
   python lkey_sentinel.py --tray     # quiet system-tray mode
   python lkey_sentinel.py --once     # single snapshot and exit
   ```

Or just double-click **START_SENTINEL.bat**.

## Getting Telegram alerts (optional but recommended)

Remote alerts let you know the instant something goes wrong — even when you're not at the machine.

1. On Telegram, message **@BotFather**, send `/newbot`, and follow the prompts. It gives you a **bot token**.
2. Message your new bot anything, then visit `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` in a browser to find your **chat ID** (the `"id"` number under `"chat"`).
3. Copy `.env.EXAMPLE` to `.env` and fill in:
   ```
   TELEGRAM_BOT_TOKEN=your_token_here
   TELEGRAM_CHAT_ID=your_chat_id_here
   ```

Without these, Sentinel still watches and logs locally — it just won't send remote pings.

## Where the logs live

- `app/data/sentinel_crashes.log` — plain-English crash record ("Cyberpunk2077.exe crashed — faulting module: nvwgf2umx.dll")
- `app/data/sentinel_crash_debug.log` — long-form debug dump with vitals at crash time (share this to diagnose the cause)
- `app/data/sentinel_blackbox.log` — pre-crash vitals when a danger threshold is crossed

## Tuning

Thresholds live in `app/data/sentinel.json` (created on first run). Raise `poll_seconds` for even lighter load; adjust the temp/RAM/VRAM warning levels for your hardware.

## License

MIT — free to use, modify, and share. See [LICENSE](LICENSE).

*Part of the Lkey ecosystem by Rouxster Enterprise.*
