local Emitter = require('core').Emitter
local fs = require('fs')
local timer = require('timer')

local redisNative = require('./modules/redis')

local RedisClient = Emitter:extend()

local commands = {
  "append",
  "auth",
  "bgrewriteaof",
  "bgsave",
  "blpop",
  "brpop",
  "brpoplpush",
  "config get",
  "config set",
  "config resetstat",
  "dbsize",
  "debug object",
  "debug segfault",
  "decr",
  "decrby",
  "del",
  "discard",
  "dump",
  "echo",
  "eval",
  "exec",
  "exists",
  "expire",
  "expireat",
  "flushall",
  "flushdb",
  "get",
  "getbit",
  "getrange",
  "getset",
  "hdel",
  "hexists",
  "hget",
  "hgetall",
  "hincrby",
  "hincrbyfloat",
  "hkeys",
  "hlen",
  "hmget",
  "hmset",
  "hset",
  "hsetnx",
  "hvals",
  "incr",
  "incrby",
  "incrbyfloat",
  "info",
  "keys",
  "lastsave",
  "lindex",
  "linsert",
  "llen",
  "lpop",
  "lpush",
  "lpushx",
  "lrange",
  "lrem",
  "lset",
  "ltrim",
  "mget",
  "migrate",
  "monitor",
  "move",
  "mset",
  "msetnx",
  "multi",
  "object",
  "persist",
  "pexpire",
  "pexpireat",
  "ping",
  "psetex",
  "psubscribe",
  "pttl",
  "publish",
  "punsubscribe",
  "quit",
  "randomkey",
  "rename",
  "renamenx",
  "restore",
  "rpop",
  "rpoplpush",
  "rpush",
  "rpushx",
  "sadd",
  "save",
  "scard",
  "script exists",
  "script flush",
  "script kill",
  "script load",
  "sdiff",
  "sdiffstore",
  "select",
  "set",
  "setbit",
  "setex",
  "setnx",
  "setrange",
  "shutdown",
  "sinter",
  "sinterstore",
  "sismember",
  "slaveof",
  "slowlog",
  "smembers",
  "smove",
  "sort",
  "spop",
  "srandmember",
  "srem",
  "strlen",
  "subscribe",
  "sunion",
  "sunionstore",
  "sync",
  "time",
  "ttl",
  "type",
  "unsubscribe",
  "unwatch",
  "watch",
  "zadd",
  "zcard",
  "zcount",
  "zincrby",
  "zinterstore",
  "zrange",
  "zrangebyscore",
  "zrank",
  "zrem",
  "zremrangebyrank",
  "zremrangebyscore",
  "zrevrange",
  "zrevrangebyscore",
  "zrevrank",
  "zscore",
  "zunionstore"
}

-- proxy native client commands
do
  for index = 1, #commands do
    local value = commands[index]:lower()
    RedisClient[value] = function(self, ...)
      self.redisNativeClient:command(value, ...)
    end
    RedisClient[value:upper()] = RedisClient[value]
  end
end

-- client constructor
function RedisClient:initialize(host, port, autoReconnect)

  host = host or '127.0.0.1'
  port = port or 6379
  autoReconnect = autoReconnect == nil and true

  self.hiredisVersion = redisNative.version
  self.redisNativeClient = redisNative.createClient(host, port)

  self.redisNativeClient:onError(function(err)
    if autoReconnect and self.retryTimer == nil then
      -- FIXME: should implement exponential growth of timeout
      --   e.g. 250, 500, 1000, 2000...
      self.retryTimer = timer.setTimeout(250, function()
        self:initialize(host, port, autoReconnect)
        self.retryTimer = nil
      end)
    end
    self:emit('error', err)
  end)

  self.redisNativeClient:onConnect(function()
    self:emit('connect')
  end)

  self.redisNativeClient:onDisconnect(function()
    self:emit('disconnect')
  end)

end

-- register custom command
function RedisClient:registerCommand(
    commandName,
    script,
    numOfKeys,
    callback
  )
  self.redisNativeClient:command('SCRIPT', 'LOAD', script, function(err, sha1)
    if err then callback(err) ; return end
    -- FIXME: Utils.bind?
    RedisClient[commandName] = function(self, ...)
      self.redisNativeClient:command(
          'EVALSHA',
          sha1,
          numOfKeys,
          ...
        )
    end
    callback()
  end)
end

-- register custom command read from a file
-- FIXME: should it be in this lib ever?
function RedisClient:registerCommandFromFile(
    commandName,
    scriptFilePath,
    numOfKeys,
    callback
  )
  fs.readFile(scriptFilePath, function(err, script)
    if err then callback(err) ; return end
    self:registerCommand(commandName, script, numOfKeys, callback)
  end)
end

-- FIXME: shouldn't it reuse RedisClient hash we filled up before?
function RedisClient:command(...)
  self.redisNativeClient:command(...)
end

-- orderly disconnect the client
function RedisClient:disconnect(...)
  self.redisNativeClient:disconnect()
end

-- helpers
RedisClient.print = function(err, reply)
  if err then
    print('Error: ', err)
  else
    print('Reply: ', reply)
  end
end

-- exports
return RedisClient

