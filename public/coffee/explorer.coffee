pi.service 'dirService', [
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
          done data if done?

    socket.on 'updateFile', (f) =>
      console.log 'Update file percentage !', f
      file = _(@current.child).findWhere {id: f.id, file: true}

      if file?
        file = _(file).extend(f)

    @refresh = ->
      @fetch @current.id

    if userService.current
      @fetch userService.current.root_id

    @
]

pi.directive 'piExplorer', [
  '$http'
  'dirService'
  'userService'
  'FileUploader'
  ($http, dirService, userService, FileUploader) ->
    return {

      restrict: 'E'

      templateUrl: 'explorer-tpl'
      compile: ->
        return {
          pre: (scope, element, attrs) ->
            scope.uploader = new FileUploader
              url: 'api/1/files'

          post: (scope, element, attrs) ->
            console.log scope.uploader

            scope.dirService = dirService
            scope.userService = userService

            scope.newDirName = ''

            scope.path = '/'

            scope.createDir = ->
              if scope.newDirName.length < 1
                return

              $http.post '/api/1/directorys/', {name: scope.newDirName, parent_id: scope.dirService.current.id, client_id: userService.current.id}
                .success (data) ->
                  dirService.refresh()
                  scope.newDirName = ''

            scope.enter = (id) ->
              dirService.fetch id, (dir) ->
                scope.path += dir.name + '/'

            scope.parent = (id) ->
              dirService.fetch id, (dir) ->
                scope.path =  scope.path.split('/')[...-2].join('/') + '/'

            scope.upgrade = (file) ->
              if file.percentage < 100
                return
              $http.put '/api/1/files/' + file.id , {storeLevel: file.storeLevel + 1}
                .success ->
                  dirService.refresh()


            scope.uploader.onAfterAddingFile = (fileItem) ->
              console.info "onAfterAddingFile", fileItem
              fileItem.upload()
              return

            scope.uploader.onCompleteItem = (fileItem, response, status, headers) ->
              dirService.refresh()
              return

        }

      }

]
