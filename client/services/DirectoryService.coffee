app.service 'dirService', [
  '$http'
  '$window'
  'socket'
  'userService'
  ($http, $window, socket, userService) ->

    @current = null

    @fetch = (id, done) ->
      $http.get '/api/1/directorys/' + id
        .success (data) =>
          @current = data
          @totalSize = _(data.child).reduce (memo, item) ->
            memo + item.size
          , 0
          @piSize = _(data.child).reduce (memo, item) ->
            memo + item.piSize
          , 0
          done data if done?

    socket.on 'update_file', (f) =>
      console.log 'Update file percentage !', f
      file = _(@current.child).findWhere {id: f.id, file: true}

      if file?
        file = _(file).extend(f)

      @refresh()

    @refresh = ->
      @fetch @current.id

    if userService.current
      @fetch userService.current.root_id

    @
]
