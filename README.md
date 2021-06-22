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
* Install zookeeper client c-bindings. I had some problems with [the oficial instruction](https://github.com/apache/zookeeper/blob/master/zookeeper-client/zookeeper-client-c/README), so the exact steps I did during installing may help you:
  * Make sure that dir `zookeeper-client/zookeeper-client-c/generated` with `jute` files exists. If it's not, try to [build zookeeper](https://github.com/apache/zookeeper/blob/master/README_packaging.md) with `-Pfull-build`. Files are generated on early stage of the build, so as soon as dir is created, you can stop the build. I did not find a better way to generate all these files (steps from the instruction did not work for me).  
  * go to `zookeeper-client/zookeeper-client-c` dir
  * run `autoreconf -if`
  * run `./configure --disable-shared --enable-static --without-openssl --without-sasl`
  * run `make`
  * run `sudo make install`
* Compile the client with the following command:
  * `g++ client.cpp -lzookeeper_mt -DTHREADED -pthread -o zk_cmd`
* Clone CuttleFS from [GH repository](https://github.com/WiscADSL/cuttlefs). In order to allow access to a mounted fuse dir from docker, you should add the line `allow_other=True,` [here](https://github.com/WiscADSL/cuttlefs/blob/8ddc684d4fc9167778bfe1cddfbbae8a3eabe15e/cuttlefs/cli.py#L135). Then, install CuttleFS with the instruction from the repository.
* Run ./test.sh
* Run ./clear.sh to stop zookeeper cluster and clear all temporary files.