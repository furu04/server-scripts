#!/bin/bash

# 監視するインターフェース名
INTERFACE="eno1"

# 閾値 (GB単位)
LIMIT_GB=10000

# シャットダウンを実行するかどうかのフラグ
# テスト時は false、本番運用時は true する
DO_SHUTDOWN=false

# 起動後、監視をスキップする時間（分）
GRACE_PERIOD_MIN=10

UPTIME_SECONDS=$(cat /proc/uptime | awk '{print int($1)}')
GRACE_PERIOD_SECONDS=$(($GRACE_PERIOD_MIN * 60))

if [ "$UPTIME_SECONDS" -lt "$GRACE_PERIOD_SECONDS" ]; then
    echo "マシン起動後の経過時間が${GRACE_PERIOD_MIN}分以内のため監視を一時停止しています。"
    exit 0
fi

LIMIT_BYTES=$(($LIMIT_GB * 1024 * 1024 * 1024))

CURRENT_BYTES=$(vnstat -i $INTERFACE --oneline b 2>/dev/null | awk -F';' '{print $11}')

if [ -z "$CURRENT_BYTES" ]; then
    echo "エラー: vnstatから通信量を取得できません"
    exit 1
fi

CURRENT_GB=$(($CURRENT_BYTES / 1024 / 1024 / 1024))
echo "現在の通信量: ${CURRENT_GB} GB / 上限: ${LIMIT_GB} GB"

if [ "$CURRENT_BYTES" -gt "$LIMIT_BYTES" ]; then
    echo "通信量が制限を超過しました。 ($CURRENT_BYTES > $LIMIT_BYTES)"

    if [ "$DO_SHUTDOWN" = true ]; then
        echo "マシンをシャットダウンします。"
        /sbin/shutdown -h now
    else
        echo "(テスト環境のためシャットダウンはスキップしました)"
    fi
else
    echo "通信量は制限内です。"
fi
