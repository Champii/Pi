fs = require 'fs'
ccFS = require './ccFS'
Client = require('node-rest-client').Client

client = new Client()

if not process.argv[2]? or not process.argv[3]?
  return console.log 'Usage: coffee worker.coffee login pass'

auth = '?username=' + process.argv[2] + '&password=' + process.argv[3]

client.get 'http://localhost:3000/api/1/fileClusters' + auth, (data, response) ->
  fileCluster = JSON.parse data

  return console.log fileCluster.err if fileCluster.err?

  client.get 'http://localhost:3000/api/1/fileClusters/' + fileCluster.id + '/file' + auth, (data, response) ->
    file = new Buffer data

    return console.log file.err if file.err?

    process.stdout.write '0%'

    ccFS.GetHash file, 3, (err, progress, idx, value) ->
      return console.log err if err?
      console.log err, progress, idx, value

      process.stdout.cursorTo(0)
      process.stdout.write progress + '%'

      client.put 'http://localhost:3000/api/1/fileClusters/' + fileCluster.id + '/found' + auth, {data: idx: idx, value: value}, (data, response) ->
        console.log data

