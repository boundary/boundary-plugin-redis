-- Copyright 2015 Boundary, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local framework = require('framework')
local uv_native = require('uv_native')
local Plugin = framework.Plugin
local Accumulator = framework.Accumulator
local NetDataSource = framework.NetDataSource
local PollerCollection = framework.PollerCollection
local DataSourcePoller = framework.DataSourcePoller
local gsplit = framework.string.gsplit
local split = framework.string.split
local notEmpty = framework.string.notEmpty
local ipack = framework.util.ipack
local Cache = framework.Cache
local json = require('json')
local env = require('env')
 
local params = env.get("TSP_PLUGIN_PARAMS")
if(params == nil or  params == '') then
   params = framework.params
else
   params = json.parse(params)
end
params.items = params.items or {}

local cache = Cache:new(function () return Accumulator:new() end)

local parseLine = function (line)
  return split(line, ':')
end

local function parseError(data)
  local response, message = data:match('^-(%u+)%s(.*)\r\n')
  if response == 'ERR' or response == 'NOAUTH' then
    return message
  end
  return nil
end

local function parse(data)
  local error = parseError(data)
  if error then
    return nil, error
  end

  local result = {}
  for v in gsplit(data, '\r\n') do
    local parts = parseLine(v) 
    result[parts[1]] = parts[2]   
  end
  return true, result 
end

local RedisDataSource = NetDataSource:extend()

function RedisDataSource:initialize(params)
  self.password = notEmpty(params.password)
  self.source = params.source
  NetDataSource.initialize(self, params.host, params.port)
end

function RedisDataSource:fetch(context, callback)
  if notEmpty(self.password) and not self.authenticated then
    local function parseAuth(data)
      if data:match('+OK\r\n') then
        self.authenticated = true
        NetDataSource.fetch(self, context, callback)
      else
        local error = parseError(data)
        if error then
          self:emit('error', error) 
        end
      end
    end
    NetDataSource.fetch(self, context, parseAuth)
  else
    NetDataSource.fetch(self, context, callback)
  end
end

function RedisDataSource:onFetch(socket)
  if notEmpty(self.password) and not self.authenticated then
    socket:write('AUTH ' .. self.password .. '\r\n')
  else
    socket:write('INFO\r\n')
  end
end

local function poller(item)
  item.pollInterval = notEmpty(item.pollInterval, 1000)
  item.port = notEmpty(item.port, 6379)
  item.host = notEmpty(item.host, '127.0.0.1')
  item.source = notEmpty(item.source, '')
  local ds = RedisDataSource:new(item)
  local p = DataSourcePoller:new(item.pollInterval, ds)
  return p 
end

local function createPollers(items)
  local pollers = PollerCollection:new() 
  for _, i in pairs(items) do
    pollers:add(poller(i))
  end
  return pollers
end

local pollers = createPollers(params.items)

local plugin = Plugin:new({pollInterval = 1000}, pollers)
function plugin:onParseValues(data, extra)
  local success, parsed = parse(data) 
  if not success then
    self:emitEvent('error', parsed, self.source, extra.context.source)
    return
  end
  local result = {}
  local metric = function (...)
   ipack(result, ...)
  end
  local acc = cache:get(extra.context.source)

  --local source = self.source .. '.' .. extra.context.source 
  local source = extra.context.source
  metric('REDIS_CONNECTED_CLIENTS', parsed.connected_clients, nil, source)
  metric('REDIS_KEY_HITS', acc('REDIS_KEY_HITS', parsed.keyspace_hits), nil, source)
  metric('REDIS_KEY_MISSES', acc('REDIS_KEY_MISSES', parsed.keyspace_misses), nil, source)
  metric('REDIS_KEYS_EXPIRED', acc('REDIS_KEYS_EXPIRED', parsed.expired_keys), nil, source)
  metric('REDIS_KEY_EVICTIONS', acc('REDIS_KEY_EVICTIONS', parsed.evicted_keys), nil, source)
  metric('REDIS_COMMANDS_PROCESSED', acc('REDIS_COMMANDS_PROCESSED', parsed.total_commands_processed), nil, source)
  metric('REDIS_CONNECTIONS_RECEIVED', acc('REDIS_CONNECTIONS_RECEIVED', parsed.total_connections_received), nil, source)
  metric('REDIS_USED_MEMORY', parsed.used_memory_rss / uv_native.getTotalMemory(), nil, source)
  return result
end

plugin:run()
