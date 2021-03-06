fs = require 'fs'
zlib = require 'zlib'
Nodulator = require 'nodulator'

piFS = require '../storage'
File = require '../resources/File'

module.exports.Init = ->
  Nodulator.bus.on 'calc_hash', (f, srcPath, destPath) ->
    getHash f, srcPath, destPath

  getHash = (f, srcPath, destPath) ->
    if f.maxLevel
      return

    timer = setInterval ->
      piFS.GetPercentage destPath + '_tmp', (err, percentage) ->
        return console.error err if err?

        if percentage.length < 4 and percentage isnt f.percentage
          File.Fetch f.id, (err, f) ->
            return console.error err if err?

            f.percentage = percentage
            f.Save (err) ->
              return console.error err if err?

    , 5000

    error = (e) ->
      clearInterval timer
      console.error e
      File.Fetch f.id, (error, file) ->
        return console.error err if err?

        file.percentage = 100
        file.maxLevel = true
        file.Save (err) ->
          return console.error err if err?
      e

    callback = (err, hash) ->
      File.Fetch f.id, (e, file) ->
        return error e if e?

        if (err? and err is 'Error not found') or file.storeLevel is 3
          # console.log 'err, file', err, file
          if file.piSize is 0
            return error err

          # console.log 'Before compress', file.idxStoreLevel, ', raw size', hash.length * 4
          zlib.gzip fs.readFileSync(destPath), (err, compressed) ->
            # console.log 'Pass', file.idxStoreLevel, ', compressed size', compressed.length, err
            return error err if err?
            if hash? and hash.length * 4 <= compressed.length
              file.maxLevel = true
              file.piSize = hash.length * 4
              file.percentage = 100
              # console.log 'MAX LEVEL', file
              return file.Save ->
            else
              file.storeLevel = 2
              file.percentage = 0
              file.idxStoreLevel++
              file.Save (err) ->
                return error e if e?

            fs.writeFileSync srcPath, compressed
            getHash file, srcPath, destPath

          clearInterval timer
          return
        else if err?
          clearInterval timer
          return console.error err if err?


        # if file.isIndexed
        #   file.idxStoreLevel++
        # else
        file.storeLevel++

        file.percentage = 100
        file.piSize = hash.length * 4

        fs.writeFileSync destPath, piFS.Array32ToBuffer hash

        file.Save (err) ->
          return error err if err?

          clearInterval timer
          # console.log 'On y retourne'
          getHash file, srcPath, destPath

    # if f.isIndexed
    #   piFS.GetHash srcPath, destPath, f.idxStoreLevel + 1, callback
    # else
    piFS.GetHash srcPath, destPath, f.storeLevel + 1, callback
