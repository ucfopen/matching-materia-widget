angular.module 'matching'
# Directive that watches question/answer inputs and manages error states
.directive 'inputStateManager', () ->
	restrict: 'A',
	link: ($scope, $element, $attrs) ->
		$scope.FOCUS = "focus"
		$scope.BLUR = "blur"

		$scope.hasQuestionProblem = false
		$scope.hasAnswerProblem = false

		# Fired on focus/blur
		$scope.updateInputState = (type, evt) ->
			el = angular.element evt.target
			switch type
				when $scope.FOCUS
					el.addClass 'focused'
				when $scope.BLUR
					el.removeClass 'focused'
					# If question is empty AND there is no media, apply error visuals
					if el[0].classList.contains('question-text')
						$scope.hasQuestionProblem = !($scope.widget.wordPairs[$attrs.index].question or $scope.checkMedia($attrs.index, 0))

					# If answer is empty AND there is no media, apply error visuals
					if el[0].classList.contains('answer-text')
						$scope.hasAnswerProblem = !($scope.widget.wordPairs[$attrs.index].answer or $scope.checkMedia($attrs.index, 1))

		# Hide error highlight as soon as question length > 0, as opposed to when blur happens
		$scope.$watch "pair.question", (newVal, oldVal) ->
			if (oldVal is null or oldVal.length < 1) and newVal isnt oldVal then $scope.hasQuestionProblem = false

		# Hide error highlight as soon as answer length > 0, as opposed to when blur happens
		$scope.$watch "pair.answer", (newVal, oldVal) ->
			if (oldVal is null or oldVal.length < 1) and newVal isnt oldVal then $scope.hasAnswerProblem = false

		$scope.$watch "pair.media", (newVal, oldVal) ->
			if newVal[0] isnt 0 then $scope.hasQuestionProblem = false
			if newVal[1] isnt 0 then $scope.hasAnswerProblem = false
