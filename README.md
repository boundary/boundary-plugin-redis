Boundary Redis Plugin
---------------------

Collects metrics from an instance of a Redis database.

### Prerequisites

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |         |         |      |


|  Runtime | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |    +    |        |      |

- [How to install node.js?](https://help.boundary.com/hc/articles/202360701)

### Plugin Setup

None

#### Plugin Configuration Fields

|Field Name|Description                                          |
|:-------|:------------------------------------------------------|
|Source  |The source to display in the legend for the REDIS data.|
|Port    |The redis port.                                        |
|Host    |The redis hostname.                                    |
|Password|Password to the redis server.                          |

### Metrics Collected
|Metric Name               |Description|
|:-------------------------|:|
|Redis Connected Clients   ||
|Redis Key Hits            ||
|Redis Key Misses          ||
|Redis Keys Expired        ||
|Redis Key Evictions       ||
|Redis Connections Received||
|Redis Commands Processed  ||
|Redis Used Memory         ||
