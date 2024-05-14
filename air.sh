#!/bin/bash

# 关闭错误退出
set +e

while true; do
    expect -c '
    spawn junctiond tx staking delegate $validator $amountamf --from $address --chain-id=junction --fees 10000amf --node $junctiond_RPC_PORT  -y
    set password_attempts 0
    expect {
        "Enter keyring passphrase" {
            if {$password_attempts < 3} {
                send "$pwd\r"
                incr password_attempts
                exp_continue
            } else {
                exit 1
            }
        }
        -re {confirm transaction before signing and broadcasting \[y/N\]:\s*$} {
            send "y\r"
            exp_continue
        }
        eof
    }
    '
    if [ $? -ne 0 ]; then
        echo "密码输入错误"
        exit 1
    fi

    echo "将在1~5小时内继续自动质押art"
    current_time=$(TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")
    echo "当前时间（UTC+8）: $current_time"
    
    # 等待3到8小时
    sleep $((10800 + RANDOM % 20000))
done
