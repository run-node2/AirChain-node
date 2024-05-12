#!/bin/bash

# 关闭错误退出
set +e

while true; do
    expect -c '
    spawn junctiond tx staking delegate $validator $amountamf --from $address --chain-id=junction --gas 10000amf --node $junctiond_RPC_PORT  -y
    expect "Enter keyring passphrase (attempt 1/3):"
    send "$pwd\r"
    expect {
        -re {confirm transaction before signing and broadcasting \[y/N\]:\s*$} {
            send "y\r"
            exp_continue
        }
        eof
    }
    '
    echo "将在1~5小时内继续自动质押art"
    current_time=$(TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")
    echo "当前时间（UTC+8）: $current_time"
    
    # 等待3到8小时
    sleep $((10800 + RANDOM % 25200))
done
