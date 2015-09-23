# Boundary Redis Plugin

Collects metrics from one or more instances of Redis databases.

### Prerequisites

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |         |         |      |

This plugin is compatible with Redis 2.6.X or later.

#### For Boundary Meter v4.2 or later

- To install new meter go to Settings->Installation or [see instructions](https://help.boundary.com/hc/en-us/sections/200634331-Installation).
- To upgrade the meter to the latest version - [see instructions](https://help.boundary.com/hc/en-us/articles/201573102-Upgrading-the-Boundary-Meter). 

#### For Boundary Meter earlier than v4.2

|  Runtime | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |    v    |        |      |

- [How to install node.js?](https://help.boundary.com/hc/articles/202360701)

### Plugin Setup

None

### Plugin Configuration Fields

|Field Name  |Description                                            |
|:-----------|:------------------------------------------------------|
|Host        |The redis hostname.                                    |
|Port        |The redis port.                                        |
|Password    |Password to the redis server.                          |
|PollInterval|Interval (in milliseconds) to query the redis server.  |
|Source      |The source to display in the legend for the REDIS data.|

### Metrics Collected

|Metric Name               |Description|
|:-------------------------|:---------------------------------------------------------------|
|Redis Connected Clients   |Number of client connections (excluding connections from slaves)|
|Redis Key Hits            |Number of successful lookup of keys in the main dictionary      |
|Redis Key Misses          |Number of failed lookup of keys in the main dictionary          |
|Redis Keys Expired        |Total number of key expiration events                           |
|Redis Key Evictions       |Number of evicted keys due to maxmemory limit                   |
|Redis Connections Received|Total number of connections accepted by the server              |
|Redis Commands Processed  |Total number of commands processed by the server                |
|Redis Used Memory         |Percentage of server memory used for the Redis instance         |

### Dashboards

- Redis

### References

See information on Redis `INFO` command [here](http://redis.io/commands/info)
