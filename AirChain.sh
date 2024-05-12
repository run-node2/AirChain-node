#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 检查Go环境
function check_go_installation() {
    if command -v go > /dev/null 2>&1; then
        echo "Go 环境已安装"
        return 0
    else
        echo "Go 环境未安装，正在安装..."
        return 1
    fi
}

# 节点安装功能
function install_node() {
    install_nodejs_and_npm
        install_pm2

        # 更新和安装必要的软件
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

        # 安装 Go
        if ! check_go_installation; then
            sudo rm -rf /usr/local/go
            curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
            source $HOME/.bash_profile
            go version
        fi

        # 安装所有二进制文件
        wget https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond
        chmod +x junctiond
        sudo mv junctiond /usr/local/go/bin

        # 配置junctiond
        junctiond config chain-id junction
        junctiond init "Moniker" --chain-id junction
        junctiond config node tcp://localhost:43457

        # 获取初始文件和地址簿
        wget -O $HOME/.junction/config/genesis.json https://github.com/airchains-network/junction/releases/download/v0.1.0/genesis.json
        wget https://smeby.fun/airchains-addrbook.json -O $HOME/.junction/config/addrbook.json
        sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025amf\"/;" ~/.junction/config/app.toml

        # 配置节点
        SEEDS=""
        PEERS="de2e7251667dee5de5eed98e54a58749fadd23d8@34.22.237.85:26656,1918bd71bc764c71456d10483f754884223959a5@35.240.206.208:26656,48887cbb310bb854d7f9da8d5687cbfca02b9968@35.200.245.190:26656,de2e7251667dee5de5eed98e54a58749fadd23d8@34.22.237.85:26656,8b72b2f2e027f8a736e36b2350f6897a5e9bfeaa@131.153.232.69:26656,e09fa8cc6b06b99d07560b6c33443023e6a3b9c6@65.21.131.187:26656,5c5989b5dee8cff0b379c4f7273eac3091c3137b@57.128.74.22:56256,086d19f4d7542666c8b0cac703f78d4a8d4ec528@135.148.232.105:26656,0305205b9c2c76557381ed71ac23244558a51099@162.55.65.162:26656,3e5f3247d41d2c3ceeef0987f836e9b29068a3e9@168.119.31.198:56256,6a2f6a5cd2050f72704d6a9c8917a5bf0ed63b53@93.115.25.41:26656,eb4d2c546be8d2dc62d41ff5e98ef4ee96d2ff29@46.250.233.5:26656,7d6694fb464a9c9761992f695e6ba1d334403986@164.90.228.66:26656,b2e9bebc16bc35e16573269beba67ffea5932e13@95.111.239.250:26656,23152e91e3bd642bef6508c8d6bd1dbedccf9e56@95.111.237.24:26656,c1e9d12d80ec74b8ddbabdec9e0dad71337ba43f@135.181.82.176:26656,3b429f2c994fa76f9443e517fd8b72dcf60e6590@37.27.11.132:26656,84b6ccf69680c9459b3b78ca4ba80313fa9b315a@159.69.208.30:26656"
        sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.junction/config/config.toml


        # 配置端口
        node_address="tcp://localhost:43457"
        sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:43458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:43457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:43460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:43456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":43466\"%" $HOME/.junction/config/config.toml
        sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:43417\"%; s%^address = \":8080\"%address = \":43480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:43490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:43491\"%; s%:8545%:43445%; s%:8546%:43446%; s%:6065%:43465%" $HOME/.junction/config/app.toml
        echo "export junctiond_RPC_PORT=$node_address" >> $HOME/.bash_profile
        source $HOME/.bash_profile

        pm2 start junctiond -- start && pm2 save && pm2 startup

        curl -L http://148.113.6.240/airchains_snapshots.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.junction --strip-components 2
        mv $HOME/.junction/priv_validator_state.json.backup $HOME/.junction/data/priv_validator_state.json

        # 使用 PM2 启动节点进程

        pm2 restart junctiond

    echo '====================== 安装完成 ==========================='

}

# 查看junction 服务状态
function check_service_status() {
    pm2 list
}

# 查看junction 节点日志查询
function view_logs() {
    pm2 logs junctiond
}

function restart() {
    pm2 restart junctiond
}

# 卸载节点功能
function uninstall_node() {
            echo "开始卸载junction节点..."
            pm2 stop junctiond && pm2 delete junctiond
            rm -rf $HOME/.junctiond && rm -rf $HOME/junction $(which junctiond) && rm -rf $HOME/.junction
            cho "junction节点卸载完成"
}

# 创建钱包
function add_wallet() {
    junctiond keys add wallet
}

# 导入钱包
function import_wallet() {
    junctiond keys add wallet --recover
}

# 查询余额
function check_balances() {
    read -p "请输入钱包地址: " wallet_address
    junctiond query bank balances "$wallet_address" --node $junctiond_RPC_PORT
}

function walletlist() {
    junctiond keys list
}

# 查看节点同步状态
function check_sync_status() {
    junctiond status 2>&1 --node $junctiond_RPC_PORT | jq .SyncInfo
}

# 创建验证者
function add_validator() {
    read -p "请设置验证者的名字: " validator_name
    sudo tee ~/validator.json > /dev/null <<EOF
    {
      "pubkey": $(junctiond tendermint show-validator),
      "amount": "1000000amf",
      "moniker": "$validator_name",
      "details": "run-node",
      "commission-rate": "0.10",
      "commission-max-rate": "0.20",
      "commission-max-change-rate": "0.01",
      "min-self-delegation": "1"
    }

    EOF
        junctiond tx staking create-validator $HOME/validator.json --node $junctiond_RPC_PORT \
        --from=wallet \
        --chain-id=junction \
        --fees 10000amf
    }

# 给自己地址验证者质押
function manual_delegate() {
read -p "请输入质押代币数量,(例如1个amf,请输入1000000): " math
read -p "请输入钱包名称: " wallet_name
junctiond tx staking delegate $(junctiond keys show $wallet_name --bech val -a)  ${math}amf --from $wallet_name --chain-id=junction --fees 10000amf --node $junctiond_RPC_PORT  -y

}

function Delegate(){
    wget -O Delegate.sh https://raw.githubusercontent.com/run-node2/AirChain-node/main/Delegate.sh && chmod +x Delegate.sh && ./Delegate.sh
}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "============================自用脚本============================="
    echo "需要测试网节点部署托管 技术指导 部署领水质押脚本 请联系Telegram :https://t.me/linzeusasa"
    echo "需要测试网节点部署托管 技术指导 部署领水质押脚本 请联系Wechat :llkkxx001"
        echo "===================AirChain最新测试网节点一键部署===================="
        echo "网址为https://testnet.airchains.io/validators 请前往网站输入钱包地址 查询验证者信息"
        echo "请选择要执行的功能:"
        echo "1. 安装节点"
        echo "2. 钱包管理"
        echo "3. 查询信息"
        echo "4. 创建验证者(请确保同步状态为false并且钱包有1amf再执行)"
        echo "5. 重启节点"
        echo "6. 卸载节点"
        echo "7. 手动质押"
        echo "8. 自动质押(暂未实现)"
        read -p "请输入选项（1-8）: " OPTION

        case $OPTION in
        1) install_node ;;
        2)
            echo "=========================钱包管理菜单============================"
            echo "请选择要执行的操作:"
            echo "1. 创建钱包"
            echo "2. 导入钱包"
            echo "3. 钱包列表"
            read -p "请输入选项（1-2）: " WALLET_OPTION
            case $WALLET_OPTION in
            1) add_wallet ;;
            2) import_wallet ;;
            3) walletlist ;;
            *) echo "无效选项。" ;;
            esac
            ;;
        3)
            echo "=========================查询信息菜单============================"
            echo "请选择要执行的操作:"
            echo "1. 查看钱包地址余额(请先前往dc-faucet领水)"
            echo "2. 查看节点同步状态"
            echo "3. 查看节点运行状态"
            echo "4. 查看节点运行日志"
            read -p "请输入选项（1-4）: " INFO_OPTION
            case $INFO_OPTION in
            1) check_balances ;;
            2) check_sync_status ;;
            3) check_service_status ;;
            4) view_logs ;;
            *) echo "无效选项。" ;;
            esac
            ;;
        4) add_validator ;;
        5) restart ;;
        6) uninstall_node ;;
        7) manual_delegate ;;
        8) Delegate ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done

}

# 显示主菜单
main_menu
