class DirectoryService extends Nodulator.ResourceService 'directory', 'userService'

  current: null

  Init: ->
    if @userService.current
      @Fetch @userService.current.root_id
    @_lName = 'file'
    super()

  Fetch: (id, done) ->
    super id, (err, data) =>
      return done err if err? and done?
      return console.error err if err?

      @current = data
      @totalSize = _(data.child).reduce (memo, item) ->
        memo + item.size
      , 0
      @piSize = _(data.child).reduce (memo, item) ->
        memo + item.piSize
      , 0
      done data if done?

  OnUpdate: (f) ->
    file = _(@current.child).findWhere {id: f.id, file: true}

    if file?
      file = _(file).extend(f)

    @Refresh()

  Refresh: ->
    @Fetch @current.id

DirectoryService.Init()
