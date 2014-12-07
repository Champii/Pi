Decimal = require 'decimal.js'

bus = require '../bus'
piFS = require '../storage'

File = require '../resources/File'

module.exports.init = ->

  # bus.on 'newFile', (file, fileId) ->
  #   piFS.GetHash file, (err, hash) ->
  #     return console.error err if err?

  #     File.Fetch fileId, (err, file) ->
  #       return console.error err if err?

  #       file.hash = JSON.stringify hash

  #       file.Save (err) ->
  #         return console.error err if err?

