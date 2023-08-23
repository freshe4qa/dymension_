<p align="center">
  <img height="100" height="auto" src="https://github.com/freshe4qa/dymension_/assets/85982863/6c378fc8-d050-4c0d-92de-93442f145bf3">
</p>

# Dymension Testnet — froopyland_100-1

Official documentation:
>- [Validator setup instructions](https://docs.dymension.xyz)

Explorer:
>- [https://dymension.explorers.guru](https://dymension.explorers.guru)

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)

## Set up your dymension fullnode
```
wget https://raw.githubusercontent.com/freshe4qa/dymension_/main/dymension.sh && chmod +x dymension.sh && ./dymension.sh
```

## Post installation

When installation is finished please load variables into system
```
source $HOME/.bash_profile
```

Synchronization status:
```
dymd status 2>&1 | jq .SyncInfo
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```
dymd keys add $WALLET
```

Recover your wallet using seed phrase
```
dymd keys add $WALLET --recover
```

To get current list of wallets
```
dymd keys list
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu dymd -o cat
```

Start service
```
sudo systemctl start dymd
```

Stop service
```
sudo systemctl stop dymd
```

Restart service
```
sudo systemctl restart dymd
```

### Node info
Synchronization info
```
dymd status 2>&1 | jq .SyncInfo
```

Validator info
```
dymd status 2>&1 | jq .ValidatorInfo
```

Node info
```
dymd status 2>&1 | jq .NodeInfo
```

Show node id
```
dymd tendermint show-node-id
```

### Wallet operations
List of wallets
```
dymd keys list
```

Recover wallet
```
dymd keys add $WALLET --recover
```

Delete wallet
```
dymd keys delete $WALLET
```

Get wallet balance
```
dymd query bank balances $DYMENSION_WALLET_ADDRESS
```

Transfer funds
```
dymd tx bank send $DYMENSION_WALLET_ADDRESS <TO_DYMENSION_WALLET_ADDRESS> 10000000udym
```

### Voting
```
dymd tx gov vote 1 yes --from $WALLET --chain-id=$DYMENSION_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```
dymd tx staking delegate $DYMENSION_VALOPER_ADDRESS 10000000udym --from=$WALLET --chain-id=$DYMENSION_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```
dymd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000udym --from=$WALLET --chain-id=$DYMENSION_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
dymd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$DYMENSION_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
dymd tx distribution withdraw-rewards $DYMENSION_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$DYMENSION_CHAIN_ID
```

Unjail validator
```
dymd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$DYMENSION_CHAIN_ID \
  --gas=auto
```
