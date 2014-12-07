bus = require '../bus'

exports.mount = (app) ->

  app.get '/favicon.ico', (req, res) ->
    res.status(200).end()

  app.get '*', (req, res) ->

    u =
      user: {}
    rend = 'auth'
    if req.user?
      u.user = req.user
      rend = 'index'
    # console.log 'Userid', req.user
    res.render rend, u


    # user = {}
    # if req.user?
    #   user = req.user

    # res.render 'index',
    #   user: user

