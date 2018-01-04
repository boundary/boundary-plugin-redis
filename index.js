var _os = require('os');

var _param  = process.env.TSP_PLUGIN_PARAMS;
if (_param == null || _param == ''){
  _param = require('./param.json');
}else{
  _param = parseJSON(_param); 
} 
var _redis = require('redis');
var _tools = require('graphdat-plugin-tools');

var _client = _redis.createClient(_param.port, _param.host);
_client.auth(_param.password);

_client.on('error', function (err) {
	console.error('Unexpected error: ' + err.toString());
});

var _pollInterval = _param.pollInterval;

var _accum = {};

function accum(vals, name)
{
	var last = _accum[name];
	var cur = vals[name];

	if (last === undefined)
		last = cur;

	var diff = cur - last;

	_accum[name] = cur;

	return diff;
}

function poll()
{
	_client.info(function(err, data)
	{
		if (err)
			return console.error(err);

		// Parse
		var lines = data.split('\n');
		var vals = {};

		lines.forEach(function(line)
		{
			var parts = line.split(':');
			if (parts.length == 2)
			{
				vals[parts[0]] = parts[1];
			}
		});

		// Report
		console.log('REDIS_CONNECTED_CLIENTS %d %s', vals.connected_clients, _param.source);
		console.log('REDIS_KEY_HITS %d %s', accum(vals, 'keyspace_hits'), _param.source);
		console.log('REDIS_KEY_MISSES %d %s', accum(vals, 'keyspace_misses'), _param.source);
		console.log('REDIS_KEYS_EXPIRED %d %s', accum(vals, 'expired_keys'), _param.source);
		console.log('REDIS_KEY_EVICTIONS %d %s', accum(vals, 'evicted_keys'), _param.source);
		console.log('REDIS_COMMANDS_PROCESSED %d %s', accum(vals, 'total_commands_processed'), _param.source);
		console.log('REDIS_CONNECTIONS_RECEIVED %d %s', accum(vals, 'total_connections_received'), _param.source);
		console.log('REDIS_USED_MEMORY %d %s', vals.used_memory_rss / _os.totalmem(), _param.source);
	});

	setTimeout(poll, _pollInterval);
}

poll();
