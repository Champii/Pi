fs = require 'fs'
exec = require('child_process').exec
require('buffertools').extend()

class PiFS

  constructor: ->
    @pi = fs.readFileSync './server/storage/pi2'

  GetFile: (hash) ->
    file = new Buffer hash.idx.length * hash.storeLevel
    for v, i in hash.idx
      @pi.copy file, i * hash.storeLevel, v, v + hash.storeLevel
    file

  GetHash: (file, path, done) ->
    exec 'coffee ./server/storage/async_run.coffee ' + path + ' ' +  file.id + ' ' + file.storeLevel, (err, stdout, stderr) ->
      return done err if err?

      res = fs.readFileSync '/tmp/' + file.id

      if res.toString() is 'Error not found'
        return done 'Error not found'

      done null, res

  _GetHash: (path, id, storeLevel) ->
    fs.writeFileSync '/tmp/' + id, 0 + ''

    fileBuffer = fs.readFileSync path
    hash = {id: id, storeLevel: storeLevel, idx: [], percent: 0}
    for i in [0...fileBuffer.length] by hash.storeLevel
      chunk = new Buffer hash.storeLevel + 1
      fileBuffer.copy chunk, 0, i, i + hash.storeLevel

      j = 0
      if (j = @pi.indexOf(chunk)) is -1
        fs.writeFileSync '/tmp/' + id, 'Error not found'
        return console.error 'Error not found'

      old = hash.percent
      hash.percent = Math.floor((i / fileBuffer.length) * 100)

      hash.idx.push j

      fs.writeFileSync '/tmp/' + id, hash.percent + '' if hash.percent isnt old
    fs.writeFileSync '/tmp/' + id, JSON.stringify hash

  GetPercentage: (id, done) ->
    fs.readFile '/tmp/' + id, (err, file) ->
      return done err if err?

      done null, file.toString()

module.exports = new PiFS

