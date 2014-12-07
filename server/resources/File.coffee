bus = require '../bus'

Modulator = require '../../Modulator'
multipart = require('connect-multiparty');
multipartMiddleware = multipart();

class FileRoute extends Modulator.Route
  Config: ->
    #FIXME: HIDEOUS HACK TO MAKE MIDDLEWARE TO WORK
    # @Add 'post', '', multipartMiddleware, (req, res) ->
    #FIXME: HIDEOUS HACK TO MAKE MIDDLEWARE TO WORK
    # super()
    #FIXME: HIDEOUS HACK TO MAKE MIDDLEWARE TO WORK
    @Add 'post', '', multipartMiddleware, (req, res) ->
      console.log 'lol2'
      console.log req.files
      # for file in req.files
      bus.emit 'newFile', req.user.id, req.files.file
      res.status(200).end()


    @Add 'get', '', (req, res) ->
      console.log 'lol1'
      flow.get req, (status, filename, original_filename, identifier) ->
        console.log('GET', status, filename, original_filename, identifier);
        res.status(status == 'found' ? 200 : 404).end()


class File extends Modulator.Resource 'file', FileRoute

File.Init()

module.exports = File
