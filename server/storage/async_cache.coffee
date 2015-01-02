cache = require './Cache'
fs = require 'fs'

# cache.PutInCache process.argv[2], process.argv[3], process.argv[4]

module.exports = (storeLevel, chunk, index)->
  cache.PutInCache storeLevel, chunk, index
