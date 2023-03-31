#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export DYMENSION_CHAIN_ID=35-C" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

# install go
if ! [ -x "$(command -v go)" ]; then
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.19.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
fi

# download binary
cd $HOME
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v0.2.0-beta
make install

# config
dymd config chain-id $DYMENSION_CHAIN_ID
dymd config keyring-backend test

# init
dymd init $NODENAME --chain-id $DYMENSION_CHAIN_ID

# download genesis and addrbook
curl -s https://raw.githubusercontent.com/dymensionxyz/testnets/main/dymension-hub/35-C/genesis.json > $HOME/.dymension/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/dymension-testnet/addrbook.json > $HOME/.dymension/config/addrbook.json

# set minimum gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0001udym\"/" $HOME/.dymension/config/app.toml

# set peers and seeds
SEEDS="f97a75fb69d3a5fe893dca7c8d238ccc0bd66a8f@dymension-testnet.seed.brocha.in:30584,ebc272824924ea1a27ea3183dd0b9ba713494f83@dymension-testnet-seed.autostake.net:27086,b78dd0e25e28ec0b43412205f7c6780be8775b43@dym.seed.takeshi.team:10356,babc3f3f7804933265ec9c40ad94f4da8e9e0017@testnet-seed.rhinostake.com:20556,c6cdcc7f8e1a33f864956a8201c304741411f219@3.214.163.125:26656"
PEERS="76fb074cb54791afa399979ca863da211404bad6@dymension-testnet.nodejumper.io:27656,7fc44e2651006fb2ddb4a56132e738da2845715f@65.108.6.45:61256,8f84d324a2d266e612d06db4a793b0d001ee62a0@38.146.3.200:20556,6204710a0d089566b6df85ae4aee595afdd23cbb@146.190.40.115:26656,e374d21e689d4e1832ef72e0dae2a9bca435ba36@95.217.114.220:46656,f2d185a19f27e8290163d63a28846601662b50f1@138.201.204.5:40656,6cf94ed068c7401ba8e6f9a49143fd90df415e83@195.201.237.198:46656,54160abe97cd71abb3a83516fd8e4a47cb509fba@188.34.178.103:46656,4d2ec1e61d61550fc5bfacc57e971ff9b6181152@135.181.180.29:26656,47921c153041fb2f048c1e174b6d02ac0efab7a9@38.242.207.16:26656,015c628c6975befaaec912a88f19c0566f37173e@95.217.133.45:46656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.dymension/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.dymension/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.dymension/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.dymension/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.dymension/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.dymension/config/config.toml

# create service
sudo tee /etc/systemd/system/dymd.service > /dev/null << EOF
[Unit]
Description=Dymension testnet Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which dymd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

dymd tendermint unsafe-reset-all --home $HOME/.dymension --keep-addr-book 
curl https://snapshots2-testnet.nodejumper.io/dymension-testnet/35-C_2023-03-31.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.dymension

# start service
sudo systemctl daemon-reload
sudo systemctl enable dymd
sudo systemctl start dymd

break
;;

"Create Wallet")
dymd keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
DYMENSION_WALLET_ADDRESS=$(dymd keys show $WALLET -a)
DYMENSION_VALOPER_ADDRESS=$(dymd keys show $WALLET --bech val -a)
echo 'export DYMENSION_WALLET_ADDRESS='${DYMENSION_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export DYMENSION_VALOPER_ADDRESS='${DYMENSION_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
dymd tx staking create-validator \
--amount=1000000udym \
--pubkey=$(dymd tendermint show-validator) \
--moniker="$NODENAME" \
--chain-id=35-C \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=1000udym \
--from=wallet \
-y
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
