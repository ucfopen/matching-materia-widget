Matching = angular.module 'matching'

Matching.controller 'matchingPlayerCtrl', ['$scope', '$timeout', '$sce', ($scope, $timeout, $sce) ->
	materiaCallbacks = {}
	$scope.title = ''

	$scope.items = []
	$scope.pages = []
	$scope.selectedQA = []
	$scope.matches = []
	$scope.prelines = []

	$scope.lines = []
	$scope.questionCircles = []
	$scope.answerCircles = []

	$scope.totalPages = 1
	$scope.currentPage = 0
	$scope.totalItems = 0
	$scope.setCreated = false

	$scope.qset = {}

	$scope.checkEnd = false

	# these are used for animation
	$scope.pageAnimate = false
	$scope.pageNext = false
	ANIMATION_DURATION = 600

	colorNumber = 0

	ITEMS_PER_PAGE = 6
	NUM_OF_COLORS = 7
	CIRCLE_START_X = 20
	CIRCLE_END_X = 220
	CIRCLE_RADIUS = 10
	CIRCLE_SPACING = 69
	CIRCLE_OFFSET = 61
	PROGRESS_BAR_LENGTH = 160

	materiaCallbacks.start = (instance, qset) ->
		$scope.qset = qset
		$scope.title = instance.name
		$scope.totalItems = qset.items[0].items.length
		$scope.totalPages = Math.ceil $scope.totalItems/ITEMS_PER_PAGE

		# set up the pages
		for [1..$scope.totalPages]
			$scope.pages.push {questions:[], answers:[]}
			$scope.selectedQA.push {question:-1, answer:-1}
			$scope.questionCircles.push []
			$scope.answerCircles.push []

		_itemIndex = 0
		_pageIndex = 0
		_indexShift = 0
		# Splits the the last items over the last two pages
		_leftover = $scope.totalItems % ITEMS_PER_PAGE
		_splitPoint = ~~(4 + (_leftover - 1)/2)
		if _leftover == 0
			_splitPoint = -1

		for item in qset.items[0].items
			if _itemIndex == ITEMS_PER_PAGE or (_pageIndex == $scope.totalPages - 2 && _itemIndex == _splitPoint)
				_shuffle $scope.pages[_pageIndex].questions
				_shuffle $scope.pages[_pageIndex].answers
				_itemIndex = 0
				_indexShift = 0
				_pageIndex++

			wrapQuestionUrl = ->
				if item.assets[0] != 0 and item.assets[0] != undefined # for qsets published after this commit, this value will be 0, for older qsets it's undefined
					return $sce.trustAsResourceUrl Materia.Engine.getImageAssetUrl(item.assets[0])

			$scope.pages[_pageIndex].questions.push {
				text: if item.questions[0].text then item.questions[0].text else '[No Text Provided!]'
				id: item.id
				pageId: _pageIndex
				type: 'question'
				asset: wrapQuestionUrl()
			}

			$scope.questionCircles[_pageIndex].push {
				r:CIRCLE_RADIUS
				cx: CIRCLE_START_X
				cy:CIRCLE_SPACING * _itemIndex + CIRCLE_OFFSET
				id:_itemIndex
				isHover: false
				lightHover: false
				type: 'question-circle'
				color: 'c0'
			}

			# Adjust if this is a 'fakeout' answer option
			if item.assets[1] == 0 and not item.answers[0].text.length
				_itemIndex++
				_indexShift++
				$scope.totalItems--
				continue

			wrapAnswerUrl = ->
				if item.assets[1] != 0 and item.assets[1] != undefined # for qsets published after this commit, this value will be 0, for older qsets it's undefined
					return $sce.trustAsResourceUrl Materia.Engine.getImageAssetUrl(item.assets[1])

			$scope.pages[_pageIndex].answers.push {
				text: if item.answers[0].text then item.answers[0].text else '[No Text Provided!]'
				id: item.id
				pageId: _pageIndex
				type: 'answer'
				asset: wrapAnswerUrl()
			}

			$scope.answerCircles[_pageIndex].push {
				r:CIRCLE_RADIUS
				cx: CIRCLE_END_X
				cy:CIRCLE_SPACING * (_itemIndex - _indexShift) + CIRCLE_OFFSET
				id:_itemIndex
				isHover: false
				lightHover: false
				type: 'answer-circle'
				color: 'c0'
			}

			_itemIndex++

		# final shuffling for last page
		_shuffle $scope.pages[_pageIndex].questions
		_shuffle $scope.pages[_pageIndex].answers
		$scope.setCreated = true

		Materia.Engine.setHeight()
		$scope.$apply()

	$scope.changePage = (direction) ->
		return false if $scope.pageAnimate
		_clearSelections()

		# pageAnimate is used by the li elements and the rotating circle, also sets footer onTop
		$scope.pageNext = (direction == 'next')
		$scope.pageAnimate = true
		$timeout ->
			if direction == 'previous'
				$scope.currentPage-- unless $scope.currentPage <= 0
			if direction == 'next'
				$scope.currentPage++ unless $scope.currentPage >= $scope.totalPages - 1
				document.getElementById('column2').focus()
		, ANIMATION_DURATION/3


		$timeout ->
			$scope.pageAnimate = false
		, ANIMATION_DURATION*1.1


	$scope.checkForQuestionAudio = (index) ->
		$scope.pages[$scope.currentPage].questions[index].asset != undefined

	$scope.checkForAnswerAudio = (index) ->
		$scope.pages[$scope.currentPage].answers[index].asset != undefined

	_pushMatch = () ->
		$scope.matches.push {
			questionId: $scope.selectedQuestion.id
			questionIndex: $scope.selectedQA[$scope.currentPage].question
			answerId: $scope.selectedAnswer.id
			answerIndex: $scope.selectedQA[$scope.currentPage].answer
			matchPageId: $scope.currentPage
		}

	_applyCircleColor = () ->
		# find appropriate circle
		$scope.questionCircles[$scope.currentPage][$scope.selectedQA[$scope.currentPage].question].color = _getColor()
		$scope.answerCircles[$scope.currentPage][$scope.selectedQA[$scope.currentPage].answer].color = _getColor()

	_getColor = () ->
		'c' + colorNumber

	_checkForMatches = () ->
		if $scope.selectedQA[$scope.currentPage].question != -1 and $scope.selectedQA[$scope.currentPage].answer != -1
			# check if the id already exists in matches
			clickQuestionId = $scope.selectedQuestion.id
			clickAnswerId = $scope.selectedAnswer.id

			# increment color cycle
			colorNumber = (colorNumber+1)%NUM_OF_COLORS
			if colorNumber == 0
				colorNumber = 1

			# if the id of the question exists in a set of matches, delete that set of matches
			# get the index of the match where the question/answer exists
			indexOfQuestion = $scope.matches.map((element) -> element.questionId).indexOf clickQuestionId
			indexOfAnswer = $scope.matches.map((element) -> element.answerId).indexOf clickAnswerId

			if indexOfQuestion >= 0
				match1_QIndex = $scope.matches[indexOfQuestion].questionIndex
				match1_AIndex = $scope.matches[indexOfQuestion].answerIndex

			if indexOfAnswer >= 0
				match2_QIndex = $scope.matches[indexOfAnswer].questionIndex
				match2_AIndex = $scope.matches[indexOfAnswer].answerIndex

			# if both question and answer are in matches then take out where they exist in matches
			if indexOfQuestion != -1 and indexOfAnswer != -1
				# need to account here for the indexOfQuestion and indexOfAnswer being the same
				$scope.questionCircles[$scope.currentPage][match1_QIndex].color = 'c0'
				$scope.questionCircles[$scope.currentPage][match2_QIndex].color = 'c0'

				$scope.answerCircles[$scope.currentPage][match1_AIndex].color = 'c0'
				$scope.answerCircles[$scope.currentPage][match2_AIndex].color = 'c0'

				$scope.matches.splice indexOfQuestion, 1
				# only proceed to do the following if the index of question and answer
				# are not the same- otherwise an extra pair will be deleted
				if indexOfQuestion != indexOfAnswer
					if indexOfAnswer > indexOfQuestion
						# we have to subtract 1 to account for the previous slice
						$scope.matches.splice indexOfAnswer-1, 1
					else
						# in this case we don't need to subtract to account for splice
						$scope.matches.splice indexOfAnswer, 1
			# only the question exists in a match
			else if indexOfQuestion != -1  and indexOfAnswer == -1
				$scope.questionCircles[$scope.currentPage][match1_QIndex].color = 'c0'
				$scope.answerCircles[$scope.currentPage][match1_AIndex].color = 'c0'
				$scope.matches.splice indexOfQuestion, 1
			# only the answer exists in a match
			else if indexOfQuestion == -1 and indexOfAnswer != -1
				$scope.questionCircles[$scope.currentPage][match2_QIndex].color = 'c0'
				$scope.answerCircles[$scope.currentPage][match2_AIndex].color = 'c0'
				$scope.matches.splice indexOfAnswer, 1

			_pushMatch()

			_applyCircleColor()

			_clearSelections()

			_updateLines()

			$scope.unapplyHoverSelections()

	_clearSelections = () ->
		$scope.selectedQA[$scope.currentPage].question = -1
		$scope.selectedQA[$scope.currentPage].answer = -1

	_updateLines = () ->
		$scope.lines = []
		for [1..$scope.totalPages]
			$scope.lines.push []
		for match in $scope.matches
			targetStartY = $scope.questionCircles[match.matchPageId][match.questionIndex].cy
			targetEndY = $scope.answerCircles[match.matchPageId][match.answerIndex].cy
			$scope.lines[match.matchPageId].push {
				startX:CIRCLE_START_X
				startY:targetStartY
				endX:CIRCLE_END_X
				endY:targetEndY
			}

	$scope.getProgressAmount = () ->
		if $scope.totalItems == 0
			return 0
		return $scope.matches.length / $scope.totalItems * PROGRESS_BAR_LENGTH

	$scope.applyCircleClass = (selectionItem) ->
		# selectionItem.id is the index of circle
		if selectionItem.type == 'question-circle'
			if selectionItem.id == $scope.selectedQA[$scope.currentPage].question
				return true
		if selectionItem.type == 'answer-circle'
			if selectionItem.id == $scope.selectedQA[$scope.currentPage].answer
				return true
		false

	$scope.unapplyHoverSelections = () ->
		$scope.prelines = []
		$scope.questionCircles[$scope.currentPage].forEach (element) ->
			element.isHover = false
			element.lightHover = false
		$scope.answerCircles[$scope.currentPage].forEach (element) ->
			element.isHover = false
			element.lightHover = false

	# truthiness evaluated from function return
	$scope.isInMatch = (item) ->
		if item.type == 'question'
			return $scope.matches.some( (match) -> match.questionId == item.id)

		if item.type == 'answer'
			return $scope.matches.some( (match) -> match.answerId == item.id)

		return false

	$scope.drawPrelineToRight = (hoverItem) ->
		elementId = hoverItem.id
		# get the index of the item in the current page by finding it with its id
		endIndex = $scope.pages[$scope.currentPage].answers.map((element) ->
			if(element != undefined)
				element.id
			).indexOf elementId

		# exit if a question has not been selected
		if $scope.selectedQA[$scope.currentPage].question == -1
			$scope.answerCircles[$scope.currentPage][endIndex].lightHover = true
			return

		startIndex = $scope.selectedQA[$scope.currentPage].question

		if $scope.prelines.length > 0
			$scope.prelines = []

		$scope.prelines.push {
			# left column
			linex1 : $scope.questionCircles[$scope.currentPage][startIndex].cx
			# right column
			linex2 : $scope.answerCircles[$scope.currentPage][endIndex].cx

			# left column
			liney1 : $scope.questionCircles[$scope.currentPage][startIndex].cy
			# right column
			liney2 : $scope.answerCircles[$scope.currentPage][endIndex].cy
		}
		$scope.answerCircles[$scope.currentPage][endIndex].isHover = true

	$scope.drawPrelineToLeft = (hoverItem) ->
		elementId = hoverItem.id
		# get the index of the item in the current page by finding it with its id
		endIndex = $scope.pages[$scope.currentPage].questions.map((element) ->
			if(element != undefined)
				element.id
		).indexOf elementId

		# exit if a question has not been selected
		if $scope.selectedQA[$scope.currentPage].answer == -1
			$scope.questionCircles[$scope.currentPage][endIndex].lightHover = true
			return

		startIndex = $scope.selectedQA[$scope.currentPage].answer

		if $scope.prelines.length > 0
			$scope.prelines = []

		$scope.prelines.push {
			# right column
			linex1 : $scope.answerCircles[$scope.currentPage][startIndex].cx
			# left column
			linex2 : $scope.questionCircles[$scope.currentPage][endIndex].cx

			# right column
			liney1 : $scope.answerCircles[$scope.currentPage][startIndex].cy
			# left column
			liney2 : $scope.questionCircles[$scope.currentPage][endIndex].cy
		}
		$scope.questionCircles[$scope.currentPage][endIndex].isHover = true

	$scope.selectQuestion = (selectionItem) ->
		elementId = selectionItem.id
		# get the index of the item in the current page by finding it with its id
		indexId = $scope.pages[$scope.currentPage].questions.map((element) -> element.id).indexOf elementId
		# selectedQuestion allows us to find the item we want in our initialized question array at the specified index
		# selectedQuestion represents the question [left] column selection
		$scope.selectedQuestion = $scope.pages[$scope.currentPage].questions[indexId]
		# selectedQA stores the index of the current selected answer and question for a particular page
		$scope.selectedQA[$scope.currentPage].question = indexId
		_checkForMatches()

		if $scope.matches.length == $scope.totalItems && $scope.setCreated
			$scope.checkEnd = true
		console.log $scope.checkEnd

	$scope.selectAnswer = (selectionItem) ->
		elementId = selectionItem.id
		# get the index of the item in the current page by finding it with its id
		indexId = $scope.pages[$scope.currentPage].answers.map((element) -> element.id).indexOf elementId
		# selectedAnswer allows us to find the item we want in our initialized question array at the specified index
		# selectedAnswer represents the answer [right] column selection
		$scope.selectedAnswer = $scope.pages[$scope.currentPage].answers[indexId]
		# selectedQA stores the index of the current selected answer and question for a particular page
		$scope.selectedQA[$scope.currentPage].answer = indexId
		_checkForMatches()

		if $scope.matches.length == $scope.totalItems && $scope.setCreated
			$scope.checkEnd = true
		console.log $scope.checkEnd

	$scope.submit = () ->
		qsetItems = $scope.qset.items[0].items

		for i in [0..qsetItems.length-1]
			# get id of the current qset item use that as the 1st argument
			# find the id of that qset item in the matches object array
			matchedItem = $scope.matches.filter( (match) -> match.questionId == qsetItems[i].id)
			if matchedItem?.length
				matchedItemAnswerId = matchedItem[0].answerId
				# get the answer of that match at that question id and use that as the 2nd argument
				mappedQsetItemText = qsetItems.filter( (item) -> item.id == matchedItemAnswerId)[0].answers[0].text
				mappedQsetAudioString = qsetItems.filter( (item) -> item.id == matchedItemAnswerId)[0].assets[2]
			else
				mappedQsetItemText = null
			Materia.Score.submitQuestionForScoring(qsetItems[i].id, mappedQsetItemText, mappedQsetAudioString)
		Materia.Engine.end true

	_shuffle = (qsetItems) ->
		# don't shuffle if less than 2 elements
		return qsetItems unless qsetItems.length >= 2
		for index in [1..qsetItems.length-1]
			randomIndex = Math.floor Math.random() * (index + 1)
			[qsetItems[index], qsetItems[randomIndex]] = [qsetItems[randomIndex], qsetItems[index]]

	Materia.Engine.start materiaCallbacks
]
