Matching = angular.module 'matching', ['ngAnimate']

Matching.controller 'matchingCreatorCtrl', ['$scope', '$sce', ($scope, $sce) ->
	_qset = {}
	# Stores data to be gathered on save.
	$scope.widget =
		title     : "My Matching widget"
		wordPairs : []
		uniqueIds : []

	$scope.acceptedMediaTypes = ['mp3']
	audioRef = []

	# Adds and removes a pair of textareas for users to input a word pair.
	$scope.addWordPair = (q=null, a=null, media=[0,0], id='') ->
		$scope.widget.wordPairs.push {question:q, answer:a, media:media, id:id}

	$scope.removeWordPair = (index) -> $scope.widget.wordPairs.splice(index, 1)

	$scope.removeAudio = (index, which) -> $scope.widget.wordPairs[index].media.splice(which, 1, 0)

	# Public methods
	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items

		$scope.$apply ->
			$scope.widget.title = title
			$scope.widget.wordPairs = []
			$scope.addWordPair( _items[i].questions[0].text, _items[i].answers[0].text, _checkAssets(_items[i]), _items[i].id ) for i in [0.._items.length-1]

	$scope.onSaveClicked = ->
		# don't allow empty sets to be saved.
		if _buildSaveData()
			Materia.CreatorCore.save $scope.widget.title, _qset
		else Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	$scope.onQuestionImportComplete = (questions) ->
		$scope.$apply ->
			for question in questions
				assets = _checkAssets question

				$scope.addWordPair(
					question.questions[0].text,
					question.answers[0].text,
					assets,
					question.id
				)

	$scope.beginMediaImport = (index, which) ->
		Materia.CreatorCore.showMediaImporter($scope.acceptedMediaTypes)
		audioRef[0] = index
		audioRef[1] = which

	$scope.onMediaImportComplete = (media) ->
		# $scope.widget.wordPairs[audioRef[0]].media.splice(audioRef[1], 1, media[0].id)
		$scope.widget.wordPairs[audioRef[0]].media.splice(audioRef[1], 1, media[0].id)
		$scope.$apply -> true

	$scope.checkMedia = (index, which) ->
		return $scope.widget.wordPairs[index].media[which] != 0

	# View actions
	$scope.setTitle = ->
		$scope.widget.title = $scope.introTitle or $scope.widget.title
		$scope.step = 1
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.autoSize = (pair, audio) ->
		question = pair.question or ''
		answer = pair.answer or ''
		len = if question.length > answer.length then question.length else answer.length
		if audio == true
			size = if len > 15 then 85 + len * 1.1 else 85
		else
			size = if len > 15 then 25 + len * 1.1 else 25
		height: size + 'px'

	$scope.audioUrl = (assetId) ->
		# use $sce.trustAsResourceUrl to avoid interpolation error
		$sce.trustAsResourceUrl Materia.CreatorCore.getMediaUrl(assetId + ".mp3")

	checkIds = (currentId, idList) ->
		# prevents duplicate ids
		intCheck = $scope.widget.uniqueIds.indexOf(uniqueId)
		while(intCheck > -1)
			uniqueId = Math.floor(Math.random() * 10000)
			intCheck = $scope.widget.uniqueIds.indexOf(uniqueId)
		$scope.widget.uniqueIds.push(uniqueId)

		if(uniqueId == undefined)
			return currentId.toString()
		else
			return uniqueId.toString()

	assignString = (counter) ->
		answer = $scope.widget.wordPairs[counter].answer
		question = $scope.widget.wordPairs[counter].question
		questionAudio = $scope.widget.wordPairs[counter].media[0]
		answerAudio = $scope.widget.wordPairs[counter].media[1]

		# create unique id
		uniqueId = Math.floor(Math.random() * 10000)

		# checks if there are wordpairs with audio that don't have a description
		# if any exist the description placeholder is set to Audio
		if questionAudio != 0 && (question == null || question == '')
			$scope.widget.wordPairs[counter].question = 'Audio'
		if answerAudio != 0 && (answer == null || answer == '')
			$scope.widget.wordPairs[counter].answer = 'Audio'

		return checkIds(uniqueId, $scope.widget.uniqueIds) if answerAudio

	# Private methods

	# _used to set defaults if media is unset on either side
	_checkAssets = (object) ->
		try
			return [object.assets[0],object.assets[1]]
		try
			return [0,object.assets[1]]
		try
			return [object.assets[0],0]
		catch error
			return [0,0]

	_buildSaveData = ->
		_qset.items = []
		_qset.items[0] =
			name: "null"
			items: []
		wordPairs = $scope.widget.wordPairs

		return false if not wordPairs.length

		toRemove = []
		for i in [0..wordPairs.length-1]
			pair = wordPairs[i]
			# Don't allow any with blank questions (left side)
			if (not pair.question? or pair.question.trim() == '') and not wordPairs[i].media[0]
				toRemove.push(i)
				continue

			# Blank answers (right side) are allowed, they just won't show up when playing
			if not pair.answer?
				pair.answer = ''

			pairData = _process wordPairs[i], wordPairs[i].media[0], wordPairs[i].media[1], assignString(i)
			_qset.items[0].items.push(pairData)

		for i, index in toRemove
			$scope.removeWordPair(i - index)
		$scope.$apply()

		return $scope.widget.wordPairs.length > 0

	# Get each pair's data from the controller and organize it into Qset form.
	_process = (wordPair, questionMediaId, answerMediaId, audioString) ->
		questions: [
			text: wordPair.question
		]
		answers: [
			text: wordPair.answer.trim()
			value: '100',
			id: ''
		]
		type: 'QA'
		id: wordPair.id
		assets: [questionMediaId,answerMediaId,audioString]
	Materia.CreatorCore.start $scope
]