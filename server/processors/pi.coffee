Decimal = require 'decimal.js'

bus = require '../bus'
piFS = require '../storage'

module.exports.init = ->

  bus.on 'newFile', (userId, file) ->
    console.log 'newFile', userId, file
    hash = piFS.GetHash file
    console.log hash
