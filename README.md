# Reproduction of bug ZOOKEEPER-4311

This repository contains configuration files and scripts for demonstration of the possible impact of bug ZOOKEEPER-4311.

The scenario leads to broken consistency-guarantees. Durting the script two instances are elected in the same epoch, and then diffrent commands are writen on diffrent instances under the same zxid. Clients see diffrent state of the system depending on the connected instance.

Filesystem emulator [CuttleFS](https://github.com/WiscADSL/cuttlefs) is used to simulate fsync failures.

The test scenario is described in comments in [test.sh](./test.sh).

If you only want to see the result after running the script and don't want to compile/run anything, you can look at the result of running on my PC in [output_example.txt](./output_example.txt).

## Prerequisite
* Zookeeper instances are configured with `localSessionsEnabled=true` to prevent unwanted session messages in the tx-log.
* CuttleFS is configured to throw en error on 3-rd fsync() call to currentEpoch.tmp and acceptedEpoch.tmp. In test, 3-rd call happens during leader election in epoch 2 (zoo2 is the winner).

## Running the scenario
There are a few steps to run the scenario:
* Install docker and docker-compose
* Install zookeeper client c-bindings
* Compile the client with the following command:
`g++ -Iinclude client.cpp  libzookeeper.a libhashtable.a -o zk_cmd -pthread -DTHREADED`
* Install CuttleFS from [GH repository](https://github.com/WiscADSL/cuttlefs). In order to allow access to mounted dir from docker, you should add the line `allow_other=True,` [here](https://github.com/WiscADSL/cuttlefs/blob/8ddc684d4fc9167778bfe1cddfbbae8a3eabe15e/cuttlefs/cli.py#L135) before installing it.
* Run ./test.sh
* Run ./clear.sh to stop zookeeper cluster and clear all temporary files.