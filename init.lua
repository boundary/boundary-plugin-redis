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
local gsplit = framework.string.gsplit
local split = framework.string.split

local params = framework.params
params.port = params.port or 6379
params.host = params.host or 'localhost'

local acc = Accumulator:new()

local parseLine = function (line)
  return split(line, ':')
end

local function parse(data)
  local response, message = data:match('^-(%u+)%s(.*)\r\n')
  if response == 'ERR' or response == 'NOAUTH' then
    return nil, message
  end
  p(data)
  local result = {}
  for v in gsplit(data, '\r\n') do
    local parts = parseLine(v) 
    result[parts[1]] = parts[2]   
  end
  return true, result 
end

--local ds = RedisDataSource:new(params)

local ds = NetDataSource:new(params.host, params.port)
function ds:onFetch(socket)
  socket:write('INFO\r\n')
end

local plugin = Plugin:new(params, ds)
function plugin:onParseValues(data)
  local success, parsed = parse(data) 
  if not success then
    self:emitEvent('error', parsed)
    return
  end
  local result = {}
  result['REDIS_CONNECTED_CLIENTS'] = parsed.connected_clients
  result['REDIS_KEY_HITS'] = acc:accumulate('REDIS_KEY_HITS', parsed.keyspace_hits)
  result['REDIS_KEY_MISSES'] = acc:accumulate('REDIS_KEY_MISSES', parsed.keyspace_misses)
  result['REDIS_KEYS_EXPIRED'] = acc:accumulate('REDIS_KEYS_EXPIRED', parsed.expired_keys)
  result['REDIS_KEY_EVICTIONS'] = acc:accumulate('REDIS_KEY_EVICTIONS', parsed.evicted_keys)
  result['REDIS_COMMANDS_PROCESSED'] = acc:accumulate('REDIS_COMMANDS_PROCESSED', parsed.total_commands_processed)
  result['REDIS_CONNECTIONS_RECEIVED'] = acc:accumulate('REDIS_CONNECTIONS_RECEIVED', parsed.total_connections_received)
  result['REDIS_USED_MEMORY'] = parsed.used_memory_rss / uv_native.getTotalMemory()
  return result
end

plugin:run()
