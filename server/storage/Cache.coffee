fs = require 'fs'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

redis = require 'redis'
class Cache

  constructor: ->
    @client = redis.createClient()
    @client.on "error", (err) ->
        console.log "Error " + err

  GetFromCache: (size, name, done) ->
    @client.hget size, name, (err, reply) ->

      # console.log 'Get from cache', name, reply
      done null, reply

  PutInCache: (size, name, index) ->
    @client.hset size, name, index, (err, reply) ->
      return console.error err if err?

      # console.log 'Put in cache', reply, name, index

  Quit: ->
    @client.quit()

module.exports = new Cache
