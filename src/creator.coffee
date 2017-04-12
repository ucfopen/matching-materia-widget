###

Materia
It's a thing

Widget  : Matching, Creator
Authors : Jonathan Warner, Micheal Parks
Updated : 2/16
###

# Create an angular module to import the animation module and house our controller.
MatchingCreator = angular.module( 'matchingCreator', ['ngAnimate'] )

MatchingCreator.directive('ngEnter', ->
	return (scope, element, attrs) ->
		element.bind("keydown keypress", (event) ->
			if(event.which == 13)
				scope.$apply ->
					scope.$eval(attrs.ngEnter)
				event.preventDefault()
		)
)
MatchingCreator.directive('focusMe', ['$timeout', '$parse', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout ->
					element[0].focus()
			value
])

# Set the controller for the scope of the document body.
MatchingCreator.controller 'matchingCreatorCtrl', ['$scope', '$sce', ($scope, $sce) ->
	_qset = {}
	# Stores data to be gathered on save.
	$scope.widget =
		title     : "My Matching widget"
		wordPairs : []

	$scope.acceptedMediaTypes = ['mp3']
	audioRef = []

	# Adds and removes a pair of textareas for users to input a word pair.
	$scope.addWordPair = (q=null, a=null, media=[0,0], id='') ->
		$scope.widget.wordPairs.push {question:q, answer:a, media:media, id:id}

	$scope.removeWordPair = (index) -> $scope.widget.wordPairs.splice(index, 1)

	# Public methods
	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items

		# wrapInitMedia used to avoid interpolation error
		wrapInitMedia = (counter) ->
			try
				return [$sce.trustAsResourceUrl(_items[counter].assets[0]), $sce.trustAsResourceUrl(_items[counter].assets[1])]
			try
				return [0, $sce.trustAsResourceUrl(_items[counter].assets[1])]
			try
				return [$sce.trustAsResourceUrl(_items[counter].assets[0]), 0]
			catch error
				return 0

		$scope.$apply ->
			$scope.widget.title     = title
			$scope.widget.wordPairs = []
			$scope.addWordPair( _items[i].questions[0].text, _items[i].answers[0].text, wrapInitMedia(i), _items[i].id ) for i in [0.._items.length-1]

	$scope.onSaveClicked = ->
		if _buildSaveData()
			Materia.CreatorCore.save $scope.widget.title, _qset
		else Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	$scope.onQuestionImportComplete = (questions) ->
		$scope.$apply -> $scope.addWordPair(question.questions[0].text, question.answers[0].text, question.id) for question in questions

	$scope.beginMediaImport = (index, which) ->
		Materia.CreatorCore.showMediaImporter($scope.acceptedMediaTypes)

		audioRef[0] = index
		audioRef[1] = which

	$scope.onMediaImportComplete = (media) ->
		# use $sce.trustAsResourceUrl to avoid interpolation error
		url = $sce.trustAsResourceUrl(Materia.CreatorCore.getMediaUrl media[0].id + ".mp3")

		$scope.widget.wordPairs[audioRef[0]].media.splice(audioRef[1], 1, url)
		$scope.$apply -> true

		# load all audio tags
		audioTags = document.getElementsByTagName("audio")
		audioAmount = audioTags.length
		count = 0

		for count in [0..audioAmount]
			# if statement used here to only load the audio tags that have a src
			if audioTags[count] != undefined
				audioTags[count].load()

	$scope.checkMedia = (index, which) ->
		if $scope.widget.wordPairs[index].media == 0
			return false
		else
			return $scope.widget.wordPairs[index].media[which] != 0

	# View actions
	$scope.setTitle = ->
		$scope.widget.title = $scope.introTitle or $scope.widget.title
		$scope.step = 1
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.autoSize = (pair) ->
		question = pair.question or ''
		answer = pair.answer or ''
		len = if question.length > answer.length then question.length else answer.length
		size = if len > 15 then 30 + len * 1.1 else 25
		height: size + 'px'

	unwrapQuestionValue = (counter) ->
		try
			return $scope.widget.wordPairs[counter].media[0].$$unwrapTrustedValue()
		catch error
			return 0

	unwrapAnswerValue = (counter) ->
		try
			return $scope.widget.wordPairs[counter].media[1].$$unwrapTrustedValue()
		catch error
			return 0

	# Private methods
	_buildSaveData = ->
		okToSave = true
		_qset.items      = []
		_qset.items[0] =
			name: "null"
			items: []
		wordPairs  = $scope.widget.wordPairs
		_qset.items[0].items.push( _process wordPairs[i],unwrapQuestionValue(i),unwrapAnswerValue(i) ) for i in [0..wordPairs.length-1]
		okToSave = false if $scope.widget.title is ''
		okToSave

	# Get each pair's data from the controller and organize it into Qset form.
	_process = (wordPair, questionMedia, answerMedia) ->
		questions: [
			text: wordPair.question
		]
		answers: [
			text: wordPair.answer
			value: '100',
			id: ''
		]
		type: 'QA'
		id: wordPair.id
		assets: [questionMedia,answerMedia]

	Materia.CreatorCore.start $scope
]

