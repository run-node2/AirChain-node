# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Delegate.sh"



# 安装expect
function install() {
    sudo apt-get update
    sudo apt-get install -y expect
    sudo apt install screen

    echo "==============================模块安装完成=============================="

    read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}

# 委托功能
function delegate_staking() {

  if ! command -v screen &> /dev/null
    then
        sudo apt install screen
  fi

  # 获取密码和钱包名
  local air_pwd air_wallet
  air_pwd=$(grep -oP 'air_pwd=\K.*' ~/.bashrc)
  air_wallet=$(grep -oP 'air_wallet=\K.*' ~/.bashrc)
  air_address=$(grep -oP 'air_address=\K.*' ~/.bashrc)
  air_validator=$(grep -oP 'air_validator=\K.*' ~/.bashrc)
  air_amount=$(grep -oP 'air_amount=\K.*' ~/.bashrc)

  # 获取 air.sh 脚本
  wget -O air.sh https://raw.githubusercontent.com/run-node2/AirChain-node/main/air.sh && chmod +x air.sh

    # 获取密码并替换 air.sh 中的占位符
    sed -i "s|\$pwd|$air_pwd|g" air.sh

    # 获取钱包名并替换 air.sh 中的占位符
    sed -i "s|\$wallet|$air_wallet|g" air.sh

    # 获取质押数量并替换 air.sh 中的占位符
    sed -i "s|\$amount|$air_amount|g" air.sh

    # 获取钱包地址并替换 air.sh 中的占位符
    sed -i "s|\$address|$air_address|g" air.sh

    # 获取验证者地址并替换 air.sh 中的占位符
    sed -i "s|\$validator|$air_validator|g" air.sh

  # 检查并关闭已存在的 screen 会话
  if screen -list | grep -q delegate_airchain; then
    screen -S delegate_airchain -X quit
    echo "正在关闭之前设置的自动质押······"
  fi

  # 创建一个screen会话并运行命令
  screen -dmS delegate_airchain bash -c './air.sh'
  echo "===========自动质押已开启；每隔3~10小时自动质押(保证交互时间不一致)==========="
  echo "执行完后请前往网站查询钱包地址确保有tx记录----https://testnet.airchains.io/validators"
  read -p "按回车键返回主菜单"
  # 返回主菜单
  main_menu
}

# 查询钱包列表功能
function check_wallet() {
    echo "正在查询中，请稍等"
    airelad keys list

    read -p "按回车键返回主菜单"

     # 返回主菜单
    main_menu
}


# 设置密码功能
function set_password() {
    # 检查 ~/.bashrc 是否存在，如果不存在则创建
    if [ ! -f ~/.bashrc ]; then
        touch ~/.bashrc
    fi

    read -p "请输入创建节点时的密码(自动质押需要输入密码,否则无法自动执行): " new_pwd

    # 检查 ~/.bashrc 中是否已存在 air_pwd，如果存在则替换为新密码，如果不存在则追加
    if grep -q '^air_pwd=' ~/.bashrc; then
    sed -i "s|^air_pwd=.*$|air_pwd=$new_pwd|" ~/.bashrc
    else
    echo "air_pwd=$new_pwd" >> ~/.bashrc
    fi

    # 输入钱包名
    read -p "请输入钱包名: " wallet_name

    # 检查 ~/.bashrc 中是否已存在 air_wallet，如果存在则替换为新钱包名，如果不存在则追加
    if grep -q '^air_wallet=' ~/.bashrc; then
    sed -i "s|^air_wallet=.*$|air_wallet=$wallet_name|" ~/.bashrc
    else
    echo "air_wallet=$wallet_name" >> ~/.bashrc
    fi

    echo "正在查询钱包地址"
    # 检查 ~/.bashrc 中是否已存在 air_address，如果存在则替换为新地址，如果不存在则追加
    if grep -q '^air_address=' ~/.bashrc; then
    air_address=$(airelad keys show $wallet_name -a)
    sed -i "s|^air_address=.*$|air_address=$air_address|" ~/.bashrc
    echo "钱包地址为: $air_address"
    else
    air_address=$(airelad keys show $wallet_name -a)
    echo "air_address=$air_address" >> ~/.bashrc
    echo "钱包地址为: $air_address"
    fi
    echo "正在查询验证者地址"
    # 检查 ~/.bashrc 中是否已存在 air_validator，如果存在则替换为新验证器，如果不存在则追加
    if grep -q '^air_validator=' ~/.bashrc; then
    air_validator=$(airelad keys show $wallet_name --bech val -a)
    sed -i "s|^air_validator=.*$|air_validator=$air_validator|" ~/.bashrc
    echo "验证者地址为: $air_validator"
    else
    air_validator=$(airelad keys show $wallet_name --bech val -a)
    echo "air_validator=$air_validator" >> ~/.bashrc
    echo "验证者地址为: $air_validator"
    fi


    # 输入质押数量
  read -p "请输入每次自动质押时的数量: " amount

    # 检查 ~/.bashrc 中是否已存在 air_wallet，如果存在则替换为新钱包名，如果不存在则追加
    if grep -q '^air_amount=' ~/.bashrc; then
    sed -i "s|^air_amount=.*$|air_amount=$amount|" ~/.bashrc
    else
    echo "air_amount=$amount" >> ~/.bashrc
    fi

  echo "参数已设置成功，并写入到 ~/.bashrc 文件中"

  read -p "按回车键返回主菜单"

  # 返回主菜单
  main_menu
}




# 主菜单
function main_menu() {
  clear
  echo "=====================专用脚本 盗者必究==========================="
  echo "需要测试网节点部署托管 技术指导 部署领水质押脚本 请联系Telegram :https://t.me/linzeusasa"
  echo "需要测试网节点部署托管 技术指导 部署领水质押脚本 请联系Wechat :llkkxx001"
  echo "1. 安装基础环境"
  echo "2. 查询AirChain钱包信息"
  echo "3. 配置AirChain节点信息"
  echo "4. 开始自动质押amf代币(如果之前已经配置过AirChain节点信息，直接执行该步骤)"
  read -p "请输入选项（1-4）: " OPTION

  case $OPTION in
  1) install ;;
  2) check_wallet ;;
  3) set_password ;;
  4) delegate_staking ;;

  *) echo "无效选项。" ;;
  esac
}

# 显示主菜单
main_menu
