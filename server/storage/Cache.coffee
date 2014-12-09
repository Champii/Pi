fs = require 'fs'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

redis = require 'redis'
class Cache

  constructor: ->
    @client = redis.createClient()
    @client.on "error", (err) ->
        console.log "Error " + err

  GetFromCache: (size, buffer, done) ->
    @client.hget size, buffer.toJSON(), (err, reply) ->

      # console.log 'Get from cache', buffer.toJSON(), reply
      done null, reply

  PutInCache: (size, buffer, index) ->
    @client.hset size, buffer.toJSON(), index, (err, reply) ->
      return console.error err if err?

      # console.log 'Put in cache', reply, buffer.toJSON(), index

  Quit: ->
    @client.quit()

module.exports = new Cache
