@echo off
title Lkey Sentinel
cd /d "%~dp0"
start "" pythonw lkey_sentinel.py --tray
exit
