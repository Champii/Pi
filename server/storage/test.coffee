_ = require 'underscore'
fs = require 'fs'
ccFS = require './ccFS'
Client = require('node-rest-client').Client

client = new Client()

if not process.argv[2]? or not process.argv[3]?
  return console.log 'Usage: coffee worker.coffee login pass'

auth = '?username=' + process.argv[2] + '&password=' + process.argv[3]

host = 'http://localhost:3000'

fileCluster = null

mainLoop = ->
  console.log 'Get new file part'
  client.get host + '/api/1/fileClusters/' + fileCluster.id + '/file' + auth, (data, response) ->
    # return console.log data.err, data.status if data.err? or data.status?

    parsed = JSON.parse data
    console.log 'Parsed', parsed
    if parsed.err? or parsed.status?
      return getFile()# if parsed.err? or parsed.status?

    file = new Buffer parsed.fileBuffer
    console.log 'Got new part. Size =', file.length

    process.stdout.write '0%'

    ccFS.GetHash file, 3, parsed.piIdx, (err, idxs) ->
      return console.log err if err?

      console.log '\nFinished working for that part ! Found:', _(idxs).reject((item) -> not item?).length, '/', idxs.length

      client.put host + '/api/1/fileClusters/' + fileCluster.id + '/found' + auth, {data: {idxs: idxs}, headers:{"Content-Type": "application/json"}}, (data, response) ->
        if data.err? or data.status?
          data.err = data.status if data.status?
          console.log data.err
          return getFile()

        mainLoop()


getFile = ->
  console.log 'Get new FileCluster'
  client.get host + '/api/1/fileClusters' + auth, (data, response) ->
    fileCluster = JSON.parse data

    if fileCluster.err?
      if fileCluster.err is 'no clusters'
        console.log fileCluster.err, ', trying again in 10 seconds'
        return setTimeout ->
          getFile()
        , 10000

      return console.log fileCluster.err

    console.log 'Got FileCluster', fileCluster.id
    mainLoop()

getFile()
