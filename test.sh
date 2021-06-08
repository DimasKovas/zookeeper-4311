cuttlefs --fault-list-file ~/diplom/cuttle_meta/fault_list.json ~/diplom/zoo1/data_faulty_underlying ~/diplom/zoo1/data_faulty

sudo docker-compose -f zookeeper_multi.yml up -d
sleep 3
# zoo3 is the leader
sudo docker-compose -f zookeeper_multi.yml kill zoo3
sleep 3
# now zoo2 is the leader
sudo docker-compose -f zookeeper_multi.yml kill zoo1
./a.out --to zoo2 --cmd 'set test_node X'

sudo docker-compose -f zookeeper_multi.yml down

sudo docker-compose -f zookeeper_multi.yml up -d zoo1 zoo3

sleep 3

./a.out --to zoo3 --cmd 'set test_node Y'

sudo docker-compose -f zookeeper_multi.yml up -d zoo2

sleep 3

./a.out --to zoo1 --cmd 'get test_node'
./a.out --to zoo2 --cmd 'get test_node'
./a.out --to zoo3 --cmd 'get test_node'