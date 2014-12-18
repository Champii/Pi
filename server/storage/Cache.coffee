fs = require 'fs'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

redis = require 'redis'
i = 0
class Cache

  constructor: ->
    @client = redis.createClient config.redis.port, config.redis.host

    @client.on "error", (err) ->
        console.log "Error " + err

  GetFromCache: (size, name, done) ->
    console.log 'Ask from cache', size, name, (i += size)
    @client.hget size, name, (err, reply) ->

      console.log 'Got from cache', size, name, i, reply
      done null, reply

  PutInCache: (size, name, index) ->
    @client.hset size, name, index, (err, reply) ->
      return console.error err if err?

      # console.log 'Put in cache', size, name, index, reply, err

  Quit: ->
    @client.quit()

module.exports = new Cache
