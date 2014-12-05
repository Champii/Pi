pi.directive 'piApp', [
  () ->
    return {

      restrict: 'E'

      templateUrl: 'app-tpl'

      link: (scope, element, attrs) ->

    }

]
