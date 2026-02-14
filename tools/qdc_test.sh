#!/usr/bin/env bash
# QDC Test Script — LiveCaptionsXR validation logging
# Usage: ./tools/qdc_test.sh [device_serial]
#
# Captures structured logs from QDC device during LiveCaptionsXR testing.
# Saves timestamped log files for post-mortem analysis.

set -euo pipefail

DEVICE="${1:-}"
ADB_ARGS=""
if [ -n "$DEVICE" ]; then
  ADB_ARGS="-s $DEVICE"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$(dirname "$0")/../logs/qdc"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/qdc_${TIMESTAMP}.log"
DEVICE_INFO="$LOG_DIR/qdc_${TIMESTAMP}_device.txt"
MODEL_STATUS="$LOG_DIR/qdc_${TIMESTAMP}_models.txt"

PKG="com.livecaptionsxr.app"

echo "=== QDC LiveCaptionsXR Test — $(date) ===" | tee "$LOG_FILE"
echo "Log: $LOG_FILE"
echo ""

# ─── Step 1: Device Info ───
echo "━━━ Step 1: Device Info ━━━" | tee -a "$LOG_FILE"
{
  echo "--- Build Properties ---"
  adb $ADB_ARGS shell getprop ro.build.display.id
  adb $ADB_ARGS shell getprop ro.product.model
  adb $ADB_ARGS shell getprop ro.product.device
  adb $ADB_ARGS shell getprop ro.hardware
  adb $ADB_ARGS shell getprop ro.hardware.chipname 2>/dev/null || echo "(no chipname)"
  adb $ADB_ARGS shell getprop ro.board.platform
  adb $ADB_ARGS shell "cat /proc/meminfo | head -3"
  echo ""
  echo "--- Build.SOC_MODEL (API 31+) ---"
  adb $ADB_ARGS shell getprop ro.soc.model 2>/dev/null || echo "(unavailable)"
  echo ""
  echo "--- NPU/DSP devices ---"
  adb $ADB_ARGS shell "ls -la /dev/fastrpc* 2>/dev/null || echo 'No fastrpc devices'"
  adb $ADB_ARGS shell "ls -la /dev/adsprpc* 2>/dev/null || echo 'No adsprpc devices'"
  echo ""
  echo "--- SELinux ---"
  adb $ADB_ARGS shell getenforce
} 2>&1 | tee "$DEVICE_INFO" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ─── Step 2: Network check ───
echo "━━━ Step 2: Network (WiFi needed for model downloads) ━━━" | tee -a "$LOG_FILE"
{
  adb $ADB_ARGS shell "dumpsys wifi | grep 'Wi-Fi is' | head -1"
  adb $ADB_ARGS shell "ping -c 1 -W 2 nexa-model-hub-bucket.s3.us-west-1.amazonaws.com 2>&1 | tail -1" || echo "Cannot reach Nexa S3"
} 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ─── Step 3: App version check ───
echo "━━━ Step 3: App Version ━━━" | tee -a "$LOG_FILE"
{
  adb $ADB_ARGS shell "dumpsys package $PKG | grep -E 'versionName|versionCode'" || echo "App not installed"
} 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ─── Step 4: Check existing model files ───
echo "━━━ Step 4: Model Files on Device ━━━" | tee -a "$LOG_FILE"
{
  echo "--- App files/models/ ---"
  adb $ADB_ARGS shell "run-as $PKG ls -laR files/models/ 2>/dev/null" || echo "No models directory or no access"
  echo ""
  echo "--- SharedPreferences (download status) ---"
  adb $ADB_ARGS shell "run-as $PKG cat shared_prefs/nexa_model_downloads.xml 2>/dev/null" || echo "No download prefs found"
  adb $ADB_ARGS shell "run-as $PKG cat shared_prefs/FlutterSharedPreferences.xml 2>/dev/null | grep -i model" || echo "No Flutter model prefs"
} 2>&1 | tee "$MODEL_STATUS" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ─── Step 5: Clear old logs, start capture ───
echo "━━━ Step 5: Starting logcat capture ━━━" | tee -a "$LOG_FILE"
echo "Clearing logcat buffer..." | tee -a "$LOG_FILE"
adb $ADB_ARGS logcat -c

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Now open LiveCaptionsXR on QDC and tap 'Start Captions'   ║"
echo "║  Press Ctrl+C when done testing to save the log            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Capture flutter + nexa + system logs
# Filter for our app's tags + any crash/ANR
adb $ADB_ARGS logcat \
  -v threadtime \
  flutter:V \
  NexaAsrPlugin:V \
  NexaSdk:V \
  NexaModelDownloader:V \
  ModelDownloader:V \
  ActivityManager:I \
  AndroidRuntime:E \
  System.err:W \
  LiveCaptionsXR:V \
  '*:S' \
  2>&1 | while IFS= read -r line; do
    echo "$line" | tee -a "$LOG_FILE"
done

echo ""
echo "━━━ Test Complete ━━━"
echo "Full log:     $LOG_FILE"
echo "Device info:  $DEVICE_INFO"
echo "Model status: $MODEL_STATUS"
echo ""
echo "To analyze, look for:"
echo "  grep -E '✅|❌|⚠️|ERROR|FATAL|Exception' $LOG_FILE"
echo "  grep -i 'parakeet\|omnineural\|download\|model' $LOG_FILE"
echo "  grep -i 'asr.*create\|llm.*create\|vlm.*create' $LOG_FILE"
