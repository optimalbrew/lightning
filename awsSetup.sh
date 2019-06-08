#!/bin/bash

# Setup for Lightning Network (LND) on Ubuntu 18.04 LTS
# Security: in addition to SSH access, etc
# * ports opened: 
# * 10001-10003 (grpc), 10011-10012 (p2p connections), 8001-8003 (REST connections)  

# https://dev.lightning.community/guides/installation/
# https://dev.lightning.community/tutorial/01-lncli/index.html


# git clone  
# cd light
# chmod +x awsSetup.sh

sudo apt-get update

printf '\n\nSet up memory swap\n\n'
# memory swap set up
sudo dd if=/dev/zero of=/swapfile bs=1M count=512
sudo mkswap /swapfile
sudo swapon /swapfile
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile


printf '\n\ninstalling python2 and build-essential (for use in the future)\n\n'

sudo apt install -y build-essential

sudo apt-get install -y python-pip #installs python2 and pip
sudo pip install virtualenv

# install go
sudo snap install --classic go
#set GOPATH
#add to environment
export GOPATH=~/snap/go
export PATH=$PATH:$GOPATH/bin
source ~/.bashrc

# install lnd
go get -d github.com/lightningnetwork/lnd
cd $GOPATH/src/github.com/lightningnetwork/lnd
make && make install

# uncomment if updating lnd
# cd $GOPATH/src/github.com/lightningnetwork/lnd
# git pull
# make clean && make && make install

# install btcd for bitcoin node
make btcd

# Now to run the nodes (just one bitcoin node)

# Create our development space
cd $GOPATH
mkdir dev
cd dev
mkdir alice bob charlie # Create folders for each of our nodes


# set up a tmux session
tmux new -d -s light
# create 4 panels to run 1 btcd node and 3 lnd nodes
tmux select-window -t light:0
tmux rename-window nodes
tmux split-window -h #split into two panes
tmux select-pane -t light:nodes.0 #select left pane
tmux split-window #split vertically
tmux select-pane -t :.+ #select right pane
tmux split-window #split vertically
#set up the terminals to display what we want
tmux send-keys -t light:nodes.0 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:nodes.0 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:nodes.0 'source ~/.bashrc' ENTER
tmux send-keys -t light:nodes.0 'btcd --txindex --simnet --rpcuser=kek --rpcpass=kek' ENTER
#recall that pane numbers = order in which they were created. 
#alice
tmux send-keys -t light:nodes.1 'cd alice' ENTER
tmux send-keys -t light:nodes.1 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:nodes.1 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:nodes.1 'source ~/.bashrc' ENTER
tmux send-keys -t light:nodes.1 'lnd --rpclisten=localhost:10001 --listen=localhost:10011 --restlisten=localhost:8001 --datadir=data --logdir=log --debuglevel=info --bitcoin.simnet --bitcoin.active --bitcoin.node=btcd --btcd.rpcuser=kek --btcd.rpcpass=kek' ENTER
#bob
tmux send-keys -t light:nodes.2 'cd bob' ENTER
tmux send-keys -t light:nodes.2 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:nodes.2 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:nodes.2 'source ~/.bashrc' ENTER
tmux send-keys -t light:nodes.2 'lnd --rpclisten=localhost:10002 --listen=localhost:10012 --restlisten=localhost:8002 --datadir=data --logdir=log --debuglevel=info --bitcoin.simnet --bitcoin.active --bitcoin.node=btcd --btcd.rpcuser=kek --btcd.rpcpass=kek' ENTER
#charlie
tmux send-keys -t light:nodes.3 'cd charlie' ENTER
tmux send-keys -t light:nodes.3 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:nodes.3 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:nodes.3 'source ~/.bashrc' ENTER
tmux send-keys -t light:nodes.3 'lnd --rpclisten=localhost:10003 --listen=localhost:10013 --restlisten=localhost:8003 --datadir=data --logdir=log --debuglevel=info --bitcoin.simnet --bitcoin.active --bitcoin.node=btcd --btcd.rpcuser=kek --btcd.rpcpass=kek' ENTER


#do the same with another window for command line, pything grpc etc
# create new window with 4 panels to run 3 CLIs lncli 
tmux new-window
tmux select-window -t light:1
tmux rename-window CLIs
tmux split-window -h #split into two panes
tmux select-pane -t light:CLIs.0 #select left pane
tmux split-window #split vertically
tmux select-pane -t :.+ #select right pane
tmux split-window #split vertically


# getting the virtualenv setup for python interactions grpc
tmux send-keys -t light:CLIs.0 'virtualenv lnd' ENTER
tmux send-keys -t light:CLIs.0 'source lnd/bin/activate' ENTER
tmux send-keys -t light:CLIs.0 'pip install grpcio grpcio-tools googleapis-common-protos' ENTER
tmux send-keys -t light:CLIs.0 'git clone https://github.com/googleapis/googleapis.git' ENTER
#download lnd.proto
tmux send-keys -t light:CLIs.0 'curl -o rpc.proto -s https://raw.githubusercontent.com/lightningnetwork/lnd/master/lnrpc/rpc.proto' ENTER
#compile the proto file
tmux send-keys -t light:CLIs.0 'python -m grpc_tools.protoc --proto_path=googleapis:. --python_out=. --grpc_python_out=. rpc.proto' ENTER

#setup the CLI
#alice
tmux send-keys -t light:CLIs.1 'cd alice' ENTER
tmux send-keys -t light:CLIs.1 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:CLIs.1 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:CLIs.1 'alias lncli-alice="lncli --rpcserver=localhost:10001 --macaroonpath=data/chain/bitcoin/simnet/admin.macaroon"' ENTER
tmux send-keys -t light:CLIs.1 'source ~/.bashrc' ENTER
tmux send-keys -t light:CLIs.1 'lncli-alice create' ENTER
#bob
tmux send-keys -t light:CLIs.2 'cd bob' ENTER
tmux send-keys -t light:CLIs.2 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:CLIs.2 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:CLIs.2 'alias lncli-bob="lncli --rpcserver=localhost:10002 --macaroonpath=data/chain/bitcoin/simnet/admin.macaroon"' ENTER
tmux send-keys -t light:CLIs.2 'source ~/.bashrc' ENTER
tmux send-keys -t light:CLIs.2 'lncli-bob create' ENTER
#charlie
tmux send-keys -t light:CLIs.3 'cd charlie' ENTER
tmux send-keys -t light:CLIs.3 'export GOPATH=~/snap/go' ENTER
tmux send-keys -t light:CLIs.3 'export PATH=$PATH:$GOPATH/bin' ENTER
tmux send-keys -t light:CLIs.3 'alias lncli-charlie="lncli --rpcserver=localhost:10003 --macaroonpath=data/chain/bitcoin/simnet/admin.macaroon"' ENTER
tmux send-keys -t light:CLIs.3 'source ~/.bashrc' ENTER
tmux send-keys -t light:CLIs.3 'lncli-charlie create' ENTER

#view the session
tmux attach -t light
