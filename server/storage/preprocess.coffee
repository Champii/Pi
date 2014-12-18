fs = require 'fs'

cache = require './Cache'
piFS = require __dirname
require('buffertools').extend()

console.log 'Big buffer Generation for 4'

num = Math.pow(15, 4)
res = new Buffer num * 4
chunk = new Buffer 4

console.log num
for i in [0...num]
  res.writeUInt32BE i, i * 4

fs.writeFileSync '/tmp/tmp', res

piFS.GetHash '/tmp/tmp', '/tmp/tmp2', 4, (err, hash) ->
  console.log err, hash
