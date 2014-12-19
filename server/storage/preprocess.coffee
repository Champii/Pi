_ = require 'underscore'
fs = require 'fs'
async = require 'async'
require('buffertools').extend()

cache = require './Cache'
piFS = require __dirname

Settings = require 'settings'

config = new Settings(require '../../settings/config')


storeLevel = 4

console.log 'Big buffer Generation for ' + storeLevel

num = Math.pow(15, storeLevel)
res = new Buffer num * storeLevel
chunk = new Buffer storeLevel

arr = []
for i in [0...num]
  chunk.writeUInt32BE i, 0
  arr.push chunk.toJSON()

srcPath = '/tmp/tmp'
destPath = '/tmp/tmp2'
tmpPath = '/tmp/tmp2_tmp'

console.log 'Get existing from cache'
async.map arr, ((item, done) -> parseInt(cache.GetFromCache(storeLevel, item, done), 10)), (err, hash) =>
  console.log 'Got : ', hash, hash.length, 'done at ', Math.floor((_(hash).filter((item) -> item?).length / hash.length) * 100) + '%'
  fs.writeFileSync tmpPath, Math.floor((_(hash).filter((item) -> item?).length / hash.length) * 100) + ''
  __GetHash srcPath, destPath, storeLevel, tmpPath, 0, res, 0, hash, _(hash).reject((item) -> not item?).length


# fs.writeFileSync srcPath, res

# piFS.GetHash srcPath, destPath, storeLevel, (err, hash) ->
#   console.log err, hash

# __GetHash srcPath, destPath, storeLevel, tmpPath, 0, res, 0, []

__GetHash = (srcPath, destPath, storeLevel, tmpPath, piFile, srcBuffer, oldI, hash) ->
  console.log 'Pifile', piFile
  fs.open config.piPath + piFile, 'r', (err, piFd) =>
    if err?
      fs.writeFileSync tmpPath, 'Error not found'
      cache.Quit()
      return console.error err

    pi = new Buffer config.piFileSlice

    found = false

    percent = 0
    chunk = new Buffer(storeLevel)

    sliceCount = 0

    while config.piFileSlice * sliceCount < config.piPartSize
      console.log 'Pislice', sliceCount, arr
      fs.readSync piFd, pi, 0, config.piFileSlice, sliceCount * config.piFileSlice

      for i in [0...config.piFileSlice]
        pi.copy(chunk, 0, i, i + storeLevel)
        console.log 'i', i

        if (j = arr.indexOf(chunk.toJSON()) is -1)
          found = false
          sliceCount++
          continue

        found = true
        # old = percent
        # percent = Math.floor((_(hash).filter((item) -> item?).length / hash.length) * 100)

        j = j + (piFile * config.piPartSize) + (sliceCount * config.piFileSlice)
        hash[Math.floor(i / storeLevel)] = j

        console.log 'Found !', chunk.toJSON(), j.toString()
        require('./async_cache')(storeLevel, chunk.toJSON(), j.toString())

        sliceCount = 0

        fs.writeFileSync tmpPath, percent + '' if percent isnt old
        break

      if not found
        return __GetHash srcPath, destPath, storeLevel, tmpPath, piFile + 1, srcBuffer, i, hash

    fs.writeFileSync destPath, piFS.Array32ToBuffer hash
    cache.Quit()
    return
