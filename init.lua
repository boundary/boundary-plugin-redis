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
local notEmpty = framework.string.notEmpty

local params = framework.params
params.port = notEmpty(params.port, 6379)
params.host = notEmpty(params.host, 'localhost')

local acc = Accumulator:new()

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

local ds = RedisDataSource:new(params)

function ds:onFetch(socket)
  if notEmpty(self.password) and not self.authenticated then
    socket:write('AUTH ' .. self.password .. '\r\n')
  else
    socket:write('INFO\r\n')
  end
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
