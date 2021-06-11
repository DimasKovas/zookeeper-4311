#!/bin/bash

# clear everything from previous run
./clear.sh

# create dirs for zookeeper instances
mkdir zoo1
mkdir zoo2
mkdir zoo3

# dirs for filesystem emulator (cuttlefs)
mkdir zoo1/data_faulty
mkdir zoo1/data_faulty_underlying
# start emulator
cuttlefs --fault-list-file ./fault_list.json ./zoo1/data_faulty_underlying ./zoo1/data_faulty

# start zookeeper cluster
sudo docker-compose -f zookeeper_multi.yml up -d
# just random commands to make zookeeper "non empty"
# it is not nessesary
./zk_cmd zoo1 create /random_node random_data 2> /dev/null

# Ensure that everyting is OK
# Should print 'zookeeper' and 'random_node' 3 times
./zk_cmd zoo1 ls / 2> /dev/null
./zk_cmd zoo2 ls / 2> /dev/null
./zk_cmd zoo3 ls / 2> /dev/null

# all nodes have the same state, node with higher number is prioritized in current leader election alghorithm
# so zoo3 is the leader in epoch 1
sudo docker-compose -f zookeeper_multi.yml kill zoo3
sleep 3

# now zoo2 is the leader in epoch 2

# kill the last follower and send 'create' command simultaneously
# command should persist in zoo2 txn-log only (so, it's not commited)
# to do so, command be sent after zoo1 is killed, but before zoo2 could realize it
# for this purpose, use SLEEP_TIME
# 0.8s works on my PC, but may be you should tune it to reproduce the test by your own
SLEEP_TIME=0.8
sudo docker-compose -f zookeeper_multi.yml kill zoo1 & (sleep $SLEEP_TIME; ./zk_cmd zoo2 create /test_node_1 x)

sudo docker-compose -f zookeeper_multi.yml down

# now all nodes are down
# zoo2 contains 'create /test_node_1' command in its txn-log in epoch 2
# zoo1 and zoo3 do not have any commands from epoch 2 in their log
# zoo3 was killed in epoch 1, so its currentEpoch and acceptedEpoch are 1 as well
# zoo1's currentEpoch and acceptedEpoch files are 1 because of fsync failure

# the highest 'saved' epoch is 1, so new epoch is 2 again
sudo docker-compose -f zookeeper_multi.yml up -d zoo1 zoo3

# now zoo3 is the leader in epoch 2

# create node /test_node_2
# zxid of this command and zxid of 'create /test_node_1' in zoo2 should be the same
# because from some perspectives they are 'the first command in the same epoch'
./zk_cmd zoo1 create /test_node_2 y 2> /dev/null

# return zoo2 back to the cluster
# last zxid in zoo2 and last zxid in the leader should match (but the actual command is diffrent)
sudo docker-compose -f zookeeper_multi.yml up -d zoo2

# zoo1 and zoo3 should observe 'zookeeper', 'random_node' and 'test_node_2' znodes
# zoo2 should observe 'zookeeper', 'random_node' and 'test_node_1' znodes

./zk_cmd zoo1 ls / 2> /dev/null
./zk_cmd zoo2 ls / 2> /dev/null
./zk_cmd zoo3 ls / 2> /dev/null
