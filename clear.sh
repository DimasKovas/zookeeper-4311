#!/bin/bash

# clear everything from previous run

# kill zookeeper instances if any
sudo docker-compose -f zookeeper_multi.yml down
# kill filesystem emulator
killall -SIGKILL -w cuttlefs
# killing emulator does not unmount dir for some reason
# unmount it explicitly
fusermount -u zoo1/data_faulty
# remove emulator's files
rm block_manager
rm block_manager.meta
rm -rf to_be_deleted
# remove all data-dirs
sudo rm -rf zoo1
sudo rm -rf zoo2
sudo rm -rf zoo3