# Reproduction of bug ZOOKEEPER-4311

This repository contains configs and scripts for reproduction of with filesystem emulator.
The scenario leads to broken zookeeper-guarantees. From diffrent zookeeper nodes observe diffrent state.

The output of the script is providen in file output_example.txt

# Installing
There are a few things to be installed
* Install docker and docker-compose
* Install zookeeper client c-bindings
* Compile the client with the following command:
`g++ -Iinclude client.cpp  libzookeeper.a libhashtable.a -o zk_cmd -pthread -DTHREADED`
* Install CuttleFS
* Run ./test.sh