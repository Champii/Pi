async = require 'async'

Modulator = require '../../Modulator'

Directory = require './Directory'

config =
  account:
    fields:
      usernameField: 'login'
      passwordField: 'pass'

class ClientRoute extends Modulator.Route.DefaultRoute
  Config: ->
    super()

    @Add 'post', (req, res) ->
      async.auto
        checkUser: (done) ->
          Client.FetchBy 'login', req.body.login, (err, client) ->
            return done() if err?
            done({})
        deserialize: ['checkUser', (done, results) ->
          Client.Deserialize req.body, done]

        user: ['deserialize', (done, results) ->
          results.deserialize.Save done]

        rootDir: ['user', (done, results) ->
          toSave =
            client_id: results.user.id
            name: '/'
          Directory.Deserialize toSave, (err, dir) ->
            return done err if err?

            dir.Save done]

        userRootDir: ['rootDir', (done, results) ->
          results.user.root_id = results.rootDir.id
          results.user.Save done]

      , (err, results) ->
        return res.locals.sendError err if err?

        res.status(200).end()

class Client extends Modulator.Resource 'client', ClientRoute, config

Client.Init()

module.exports = Client
