fs = require 'fs'
exec = require('child_process').exec

Settings = require 'settings'
config = new Settings(require '../../settings/config')
require('buffertools').extend()

class PiFS

  constructor: ->
    # @pi = fs.readFileSync config.piPath
    # @pi = fs.readFileSync './server/storage/pi'

  GetFile: (hash, storeLevel) ->
    pi = []
    file = new Buffer(hash.length * storeLevel)
    for v, i in hash
      filePart = Math.floor(v / config.piPartSize)
      if not pi[filePart]?
        pi[filePart] = fs.openSync config.piPath + filePart, 'r'
      fs.readSync pi[filePart], file, i * storeLevel, storeLevel, v
      # @pi.copy file, i * storeLevel, v, v + storeLevel
    file

  GetHash: (srcPath, destPath, storeLevel, done) ->
    exec 'coffee ./server/storage/async_run.coffee ' + srcPath + ' ' +  destPath + ' ' + storeLevel, (err, stdout, stderr) =>
      return done err if err?

      err = fs.readFileSync destPath + '_tmp'
      fs.unlinkSync destPath + '_tmp'


      if err.toString() is 'Error not found'
        return done 'Error not found'

      res = fs.readFileSync destPath
      done null, @BufferToArray32 res

  _GetHash: (srcPath, destPath, storeLevel, piFile = 0) ->
    tmpPath = destPath + '_tmp'

    fs.readFile config.piPath + piFile, (err, pi) =>
      fs.writeFileSync tmpPath, 'Error not found'
      return console.error err if err

      fs.writeFileSync tmpPath, 0 + ''

      srcBuffer = fs.readFileSync srcPath

      hash = []
      percent = 0
      for i in [0...srcBuffer.length] by storeLevel
        chunk = new Buffer(storeLevel)
        srcBuffer.copy(chunk, 0, i, i + storeLevel)

        j = 0
        if (j = pi.indexOf(chunk)) is -1
          @_GetHash srcPath, destPath, storeLevel, piFile + 1
          return console.error 'Error not found'

        old = percent
        percent = Math.floor((i / srcBuffer.length) * 100)

        hash.push j

        fs.writeFileSync tmpPath, percent + '' if percent isnt old

      fs.writeFileSync destPath, @Array32ToBuffer hash

  GetPercentage: (destPath, done) ->
    fs.readFile destPath, (err, file) ->
      return done err if err?

      done null, file.toString()

  Array32ToBuffer: (arr) ->
    arrBuff = new ArrayBuffer arr.length * 4
    view = new Uint32Array arrBuff
    for v, i in arr
      view[i] = v
    new Buffer new Uint8Array arrBuff

  BufferToArray32: (buffer) ->
    ab = new ArrayBuffer buffer.length
    view = new Uint8Array ab
    for v, i in buffer
        view[i] = v
    Array.prototype.slice.call new Uint32Array ab

module.exports = new PiFS

