# Boundary Redis Plugin

Collects metrics from an instance of a Redis database.

### Prerequisites

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |         |         |      |

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
|Source      |The source to display in the legend for the REDIS data.|
|Port        |The redis port.                                        |
|Host        |The redis hostname.                                    |
|Password    |Password to the redis server.                          |
|PollInterval|Interval (in milliseconds) to query the redis server.  |

### Metrics Collected

|Metric Name               |Description|
|:-------------------------|:----------|
|Redis Connected Clients   |           |
|Redis Key Hits            |           |
|Redis Key Misses          |           |
|Redis Keys Expired        |           |
|Redis Key Evictions       |           |
|Redis Connections Received|           |
|Redis Commands Processed  |           |
|Redis Used Memory         |           |

### Dashboards

- Redis

### References

None
