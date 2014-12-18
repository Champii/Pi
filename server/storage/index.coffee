fs = require 'fs'
async = require 'async'
exec = require('child_process').exec
_ = require 'underscore'
Settings = require 'settings'
config = new Settings(require '../../settings/config')
require('buffertools').extend()
cache = require './Cache'

class PiFS

  constructor: ->

  GetFile: (hash, storeLevel) ->
    pi = []
    file = new Buffer(hash.length * storeLevel)

    for v, i in hash
      filePart = Math.floor(v / config.piPartSize)

      if not pi[filePart]?
        pi[filePart] = fs.openSync config.piPath + filePart, 'r'

      fs.readSync pi[filePart], file, i * storeLevel, storeLevel, v

    file

  GetHash: (srcPath, destPath, storeLevel, done) ->
    exec 'coffee ./server/storage/async_run.coffee ' + srcPath + ' ' +  destPath + ' ' + storeLevel, (err, stdout, stderr) =>
      return done err if err?

      fs.open destPath + '_tmp', 'r', (err, fd) ->
        if not err?
          errMess = fs.readFileSync destPath + '_tmp'
          fs.closeSync fd
          fs.unlinkSync destPath + '_tmp'

          if errMess.toString() is 'Error not found'
            return done 'Error not found'

        fs.readFile destPath, (err, res) =>
          return done err if err?

          done null, @BufferToArray32 res

  _GetHash: (srcPath, destPath, storeLevel) ->
    srcBuffer = fs.readFileSync srcPath

    tmpPath = destPath + '_tmp'
    fs.writeFileSync tmpPath, 0 + ''

    arr = []
    # cachePercent = 0
    chunk = new Buffer(storeLevel)
    for i in [0...srcBuffer.length] by storeLevel
      srcBuffer.copy(chunk, 0, i, i + storeLevel)
      arr.push chunk.toJSON()
      # old = percent
      # cachePercent = Math.floor((i / srcBuffer.length) * 100)

    async.map arr, ((item, done) -> parseInt(cache.GetFromCache(storeLevel, item, done), 10)), (err, hash) =>
      console.log 'Prepached hash = ', hash, err
      @__GetHash srcPath, destPath, storeLevel, tmpPath, 0, srcBuffer, 0, hash, _(hash).reject((item) -> not item?).length

  __GetHash: (srcPath, destPath, storeLevel, tmpPath, piFile, srcBuffer, oldI, hash, cacheSize = 0) ->
    fs.open config.piPath + piFile, 'r', (err, piFd) =>
      if err?
        fs.writeFileSync tmpPath, 'Error not found'
        cache.Quit()
        return console.error err

      pi = new Buffer config.piFileSlice

      found = false

      percent = 0
      chunk = new Buffer(storeLevel)
      for i in [oldI...srcBuffer.length] by storeLevel
        if hash[i]?
          continue


        srcBuffer.copy(chunk, 0, i, i + storeLevel)

        sliceCount = 0
        while config.piFileSlice * sliceCount < config.piPartSize
          fs.readSync piFd, pi, 0, config.piFileSlice, sliceCount * config.piFileSlice

          j = 0
          if (j = pi.indexOf(chunk)) is -1
            found = false
            sliceCount++
            continue

          found = true
          old = percent
          percent = Math.floor((cacheSize / srcBuffer.length) * 100) + Math.floor((i / srcBuffer.length) * (100 - cacheSize))

          j = j + (piFile * config.piPartSize) + (sliceCount * config.piFileSlice)
          hash[Math.floor(i / storeLevel)] = j

          # console.log 'lol', i, chunk, j, storeLevel
          cache.PutInCache storeLevel, chunk.toJSON(), j.toString()

          sliceCount = 0

          fs.writeFileSync tmpPath, percent + '' if percent isnt old
          break

        if not found
          return @__GetHash srcPath, destPath, storeLevel, tmpPath, piFile + 1, srcBuffer, i, hash, cacheSize

      fs.writeFileSync destPath, @Array32ToBuffer hash
      cache.Quit()
      return

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

