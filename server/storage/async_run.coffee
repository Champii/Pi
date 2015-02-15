fs = require 'fs'
ccFS = require './ccFS'


ccFS._GetHash process.argv[2], process.argv[3], parseInt(process.argv[4], 10)

# piFS.GetHash process.argv[2], process.argv[3], parseInt(process.argv[4], 10), (err, hash) ->

#   console.log 'Level', (level = parseInt(process.argv[4], 10))
#   console.log 'Source file', (src = fs.readFileSync process.argv[2])
#   console.log 'Hash for source', hash
#   console.log 'Extracted from Hash', piFS.GetFile JSON.parse(hash), level
