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

            scope.uploader.onWhenAddingFileFailed = (item, filter, options) -> #{File|FileLikeObject}
              console.info "onWhenAddingFileFailed", item, filter, options
              return

            scope.uploader.onAfterAddingFile = (fileItem) ->
              console.info "onAfterAddingFile", fileItem
              fileItem.upload()
              return

            scope.uploader.onAfterAddingAll = (addedFileItems) ->
              console.info "onAfterAddingAll", addedFileItems
              return

            scope.uploader.onBeforeUploadItem = (item) ->
              console.info "onBeforeUploadItem", item
              return

            scope.uploader.onProgressItem = (fileItem, progress) ->
              console.info "onProgressItem", fileItem, progress
              return

            scope.uploader.onProgressAll = (progress) ->
              console.info "onProgressAll", progress
              return

            scope.uploader.onSuccessItem = (fileItem, response, status, headers) ->
              console.info "onSuccessItem", fileItem, response, status, headers
              return

            scope.uploader.onErrorItem = (fileItem, response, status, headers) ->
              console.info "onErrorItem", fileItem, response, status, headers
              return

            scope.uploader.onCancelItem = (fileItem, response, status, headers) ->
              console.info "onCancelItem", fileItem, response, status, headers
              return

            scope.uploader.onCompleteItem = (fileItem, response, status, headers) ->
              console.info "onCompleteItem", fileItem, response, status, headers
              return

            scope.uploader.onCompleteAll = ->
              console.info "onCompleteAll"
              return
        }

      }

]
