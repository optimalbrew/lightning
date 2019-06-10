# Lightning
Working with [lightning network](https://lightning.network/), specifically the [LND](https://github.com/lightningnetwork/lnd) implementation and associated [gRPC API](https://api.lightning.community/?python). Starting with simple deployment on EC2 and simnet to get doc examples working.

## Linux setup
The shell script `awsSetp.sh` has been tested on Ubuntu 18.04 LTS on an AWS t2 micro instance. 
* installs `go`, `lnd`,`btcd`, `protoc`.   
* starts a `tmux` session with two windows and 8 panes
  * window 0: *"node" panes* -> 1 bitcoin node (btcd not bitcoind) and 3 LND nodes (for alice, bob and charlie). 
  * window 1: *"interaction" panes* -> 3 panes for LND's command line interface `lncli` (one each for alice, bob and charlie) and 1 pane for gRPC API with python.

## Running
Once the tmux session is attached, enter a password for each user (no need to select a passphrase). The python program `pyAPI0.py` provides one illustration of interactions. Naturally, all balances are initially 0 (need to mine some) as shown in [docs](https://dev.lightning.community/tutorial/01-lncli/index.html).

Example:
Generate a new address (pay 2 witness key hash, but *nested* inside a P2SH)
    alice$ lncli-alice newaddress np2wkh

Stop the `btcd` process and restart giving alice mining rights using the address generated above
    btcd --simnet --txindex --rpcuser=kek --rpcpass=kek --miningaddr=<ALICE_ADDRESS>

Generate 400 blocks (100 to make the *coinbase* funds spendable, and 400 blocks to activate **segwit**)

    alice$ btcctl --simnet --rpcuser=kek --rpcpass=kek generate 400

Check *segwit* status

    alice$ btcctl --simnet --rpcuser=kek --rpcpass=kek getblockchaininfo | grep -A 1 segwit

Check alice's balance 
    
    alice$ lncli-alice walletbalance


