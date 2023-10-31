angular.module 'matching', ['ngAnimate']
.controller 'matchingCreatorCtrl', ['$scope', '$sce', ($scope, $sce) ->
	_qset = {}
	materiaCallbacks = {}
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
	materiaCallbacks.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.showIntroDialog = true

	materiaCallbacks.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items

		$scope.$apply ->
			$scope.widget.title = title
			$scope.widget.wordPairs = []
			for item in _items
				$scope.addWordPair(item.questions[0].text, item.answers[0].text, _checkAssets(item), item.id)

	materiaCallbacks.onSaveClicked = ->
		# don't allow empty sets to be saved.
		if _buildSaveData()
			Materia.CreatorCore.save $scope.widget.title, _qset
		else
			$scope.showErrorDialog = true
			$scope.$apply()
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	materiaCallbacks.onSaveComplete = (title, widget, qset, version) -> true

	materiaCallbacks.onQuestionImportComplete = (questions) ->
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

	materiaCallbacks.onMediaImportComplete = (media) ->
		$scope.widget.wordPairs[audioRef[0]].media.splice(audioRef[1], 1, media[0].id)
		$scope.$apply -> true

	$scope.checkMedia = (index, which) ->
		return false if !$scope.widget.wordPairs[index]?
		return $scope.widget.wordPairs[index].media[which] != 0 && $scope.widget.wordPairs[index].media[which] != undefined # value is undefined for older qsets

	# View actions
	$scope.setTitle = ->
		$scope.widget.title = $scope.introTitle or $scope.widget.title
		$scope.step = 1
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = $scope.showErrorDialog = false

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

	# prevents duplicate ids
	createUniqueAudioAnswerId = () ->
		uniqueId = 0
		intCheck = 0
		while(intCheck > -1)
			uniqueId = Math.floor(Math.random() * 10000)
			intCheck = $scope.widget.uniqueIds.indexOf(uniqueId)
		$scope.widget.uniqueIds.push(uniqueId)

		uniqueId.toString()

	# Private methods

	# _used to set defaults if media is unset on either side
	_checkAssets = (object) ->
		assets = [0,0]
		if object.assets?
			assets[0] = object.assets[0] if object.assets[0]?
			assets[1] = object.assets[1] if object.assets[1]?
		assets

	_buildSaveData = ->
		_qset.items = []
		_qset.items[0] =
			name: "null"
			items: []
		wordPairs = $scope.widget.wordPairs

		return false if not wordPairs.length

		toRemove = []
		for pair, i in wordPairs
			# Don't allow any with blank questions (left side)
			if (not pair.question? or pair.question.trim() == '') and not pair.media[0]
				toRemove.push(i)
				continue
			# Don't allow any with blank answers (right side)
			if (not pair.answer? or pair.answer.trim() == '') and not pair.media[1]
				toRemove.push(i)
				continue
			###
			BRING THIS BACK WHEN WE'RE READY FOR FAKEOUT OPTIONS
			# Blank answers (right side) are allowed, they just won't show up when playing
			if not pair.answer?
				pair.answer = ''
			###

			# checks if there are wordpairs with audio that don't have a description
			# if any exist the description placeholder is set to Audio
			if pair.media[0] != 0 && (pair.question == null || pair.question == '')
				pair.question = 'Audio'
			if pair.media[1] != 0 && (pair.answer == null || pair.answer == '')
				pair.answer = 'Audio'

			pairData = _process pair, pair.media[0], pair.media[1], createUniqueAudioAnswerId()
			_qset.items[0].items.push(pairData)

		###
		MAYBE DO THIS LATER, WITH AN EXTRA 'ARE YOU SURE?' STEP BEFORE MASS DELETING
		for i, index in toRemove
			$scope.removeWordPair(i - index)
		$scope.$apply()

		return $scope.widget.wordPairs.length > 0
		###
		toRemove.length is 0 and !($scope.widget.title is '' or $scope.widget.wordPairs.length < 1)

	# Get each pair's data from the controller and organize it into Qset form.
	_process = (wordPair, questionMediaId, answerMediaId, answerAudioId) ->
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
		assets: [questionMediaId, answerMediaId, answerAudioId]

	Materia.CreatorCore.start materiaCallbacks
]
