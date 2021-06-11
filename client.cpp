#include <stdio.h>
#include <errno.h>
#include <cstring>

#include <bits/stdc++.h>

#include <zookeeper.h>

using namespace std;

// Keeping track of the connection state
volatile int connected = 0;
volatile int expired   = 0;

// watcher function would process events
void watcher(zhandle_t *zkH, int type, int state, const char *path, void *watcherCtx)
{
    if (type == ZOO_SESSION_EVENT) {

        // state refers to states of zookeeper connection.
        // To keep it simple, we would demonstrate these 3: ZOO_EXPIRED_SESSION_STATE, ZOO_CONNECTED_STATE, ZOO_NOTCONNECTED_STATE
        // If you are using ACL, you should be aware of an authentication failure state - ZOO_AUTH_FAILED_STATE
        if (state == ZOO_CONNECTED_STATE) {
            connected = 1;
        } else if (state == ZOO_NOTCONNECTED_STATE ) {
            connected = 0;
        } else if (state == ZOO_EXPIRED_SESSION_STATE) {
            expired = 1;
            connected = 0;
            zookeeper_close(zkH);
        }
    }
}

void waitConnected()
{
    int connectedTime = 0;
    while (!connected && !expired) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        ++connectedTime;
    }
    std::cerr << "Connected in " + std::to_string(connectedTime) << "ms" << std::endl;
}

void print(const std::string& s)
{
    std::cout << s << std::endl;
}


const std::map<std::string, std::string> hostToAddress = {
    {"zoo1", "localhost:2181"},
    {"zoo2", "localhost:2182"},
    {"zoo3", "localhost:2183"},
};

zhandle_t * connect(const std::string& host)
{
    assert(hostToAddress.find(host) != hostToAddress.end());
    std::string address = hostToAddress.find(host)->second;

    zhandle_t * handler = zookeeper_init(
        address.c_str(),
        watcher,
        /* timeout */ 10000, 
        /* client_id */ NULL,
        /* context */ NULL,
        /* flags */ 0);

    if (!handler) {
        print("Failed to create zookeeper connection");
        abort();
    }

    waitConnected();

    return handler;
}

void cmdCreate(zhandle_t * handler, const std::string& path, const std::string& data)
{
    std::cerr << "Starting create command...\n";
    // std::this_thread::sleep_for(std::chrono::milliseconds(750));

    int err = zoo_create(
        handler,
        path.c_str(),
        data.c_str(),
        data.size(),
        &ZOO_OPEN_ACL_UNSAFE,
        ZOO_PERSISTENT,
        NULL,
        0);
    
    if (err != ZOK) {
        print("Failed to create node " + path + ", code: " + std::to_string(err));
        abort();
    }

    print("Node " + path + " created");
}

void cmdLs(zhandle_t * handler, const std::string& path)
{
    struct String_vector result;

    int err = zoo_get_children(handler, path.c_str(), 0, &result);

    if (err != ZOK) {
        print("Failed to list node " + path + ", code: " + std::to_string(err));
        return;
    }

    for (int i = 0; i < result.count; ++i) {
        std::cout << result.data[i] << std::endl;
    }
    std::cout << std::endl;

    // TODO: deallocate String_vector?
}

int main(int argc, char ** argv) {
    // bin-path, host, cmd, path [, data]
    assert(argc >= 4);

    std::string host(argv[1]), cmd(argv[2]), path(argv[3]), data;

    if (cmd == "create") {
        assert(argc == 5);
        data = argv[4];
    } else if (cmd == "ls") {
        assert(argc == 4);
    } else {
        abort();
    }

    zhandle_t * handler = connect(host);

    if (cmd == "create") {
        cmdCreate(handler, path, data);
    } else if (cmd == "ls") {
        cmdLs(handler, path);
    }

    return 0;
}
