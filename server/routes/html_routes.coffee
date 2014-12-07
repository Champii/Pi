bus = require '../bus'

exports.mount = (app) ->

  app.get '/favicon.ico', (req, res) ->
    res.status(200).end()

  app.get '*', (req, res) ->

    u =
      user: {}
    if req.user?
      u.user = req.user
    # console.log 'Userid', req.user
    res.render 'index', u


    # user = {}
    # if req.user?
    #   user = req.user

    # res.render 'index',
    #   user: user

