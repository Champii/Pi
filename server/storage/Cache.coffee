fs = require 'fs'

Settings = require 'settings'
config = new Settings(require '../../settings/config')

class Cache

  constructor: ->
    @file = fs.readFileSync config.cacheFile
    @cache = JSON.parse @file.toString()

  GetFromCache: (buffer) ->

