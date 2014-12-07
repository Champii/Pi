fs = require 'fs'

class PiFS

  @CHUNK_SIZE: 1

  constructor: ->
    @pi = fs.readFileSync './server/storage/pi2'

  GetFile: (hash) ->
    file = new Buffer hash.idx.length * hash.chunkSize
    for v, i in hash.idx
      @pi.copy file, i * hash.chunkSize, v, v + hash.chunkSize
    file

  IsEqual: (a, b) ->
    # return undefined if not Buffer.isBuffer a
    # return undefined if not Buffer.isBuffer b
    # return a.equals(b) if typeof a.equals is 'function'
    # return false if a.length isnt b.length

    for v, i in a
      # console.log i, v, b, b[i]
      if v isnt b[i]
        return false

    true

  GetHash: (file) ->
    fileBuffer = fs.readFileSync file.path
    hash = {name: file.name, chunkSize: PiFS.CHUNK_SIZE, idx: []}
    percent = 0
    for i in [0...fileBuffer.length] by PiFS.CHUNK_SIZE
      chunk = new Buffer PiFS.CHUNK_SIZE
      fileBuffer.copy chunk, 0, i, i + PiFS.CHUNK_SIZE

      j = 0
      buffer = new Buffer PiFS.CHUNK_SIZE
      while (@pi.copy(buffer, 0, j, j + PiFS.CHUNK_SIZE) or true) and not @IsEqual(chunk, buffer) and j + PiFS.CHUNK_SIZE < @pi.length
        j++

      if not @IsEqual(chunk, buffer) and j >= @pi.length
        console.error 'Error not found', chunk, buffer
        return

      old = percent
      percent = ((i / fileBuffer.length) * 100).toFixed 2
      process.stdout.write percent + "%\r" if percent isnt old


      hash.idx.push j

    hash

module.exports = new PiFS

