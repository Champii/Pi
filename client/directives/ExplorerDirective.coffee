class ExplorerDirective extends Nodulator.Directive 'explorer', '$http', 'directoryService', 'userService', 'FileUploader'

  Pre: ->
    @uploader = new @FileUploader
      url: 'api/1/files'

  Post: ->
    @newDirName = ''

    @path = '/'

    @createDir = =>
      if @newDirName.length < 1
        return

      @$http.post '/api/1/directorys/', {name: @newDirName, parent_id: @directoryService.current.id, client_id: userService.current.id}
        .success (data) =>
          @directoryService.Refresh()
          @newDirName = ''

    @enter = (id) =>
      @directoryService.Fetch id, (dir) =>
        @path += dir.name + '/'

    @parent = (id) =>
      @directoryService.Fetch id, (dir) =>
        @path =  @path.split('/')[...-2].join('/') + '/'

    @upgrade = (file) =>
      if file.percentage < 100
        return
      $http.put '/api/1/files/' + file.id , {storeLevel: file.storeLevel + 1}
        .success ->
          @directoryService.Refresh()

    @uploader.onAfterAddingFile = (fileItem) ->
      console.info "onAfterAddingFile", fileItem
      fileItem.upload()
      return

    @uploader.onCompleteItem = (fileItem, response, status, headers) =>
      @directoryService.Refresh()
      return

ExplorerDirective.Init()
