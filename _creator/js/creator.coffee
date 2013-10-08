###

Materia
It's a thing

Widget  : Matching, Creator
Authors : Jonathan Warner, Micheal Parks
Updated : 10/13

###

# Create an angular module to import the animation module and house our controller.
MatchingCreator = angular.module( 'matchingCreator', ['ngAnimate'] )

# Set the controller for the scope of the document body.
MatchingCreator.controller 'matchingController', ($scope) ->

	# Stores data to be gathered on save.
	$scope.widget =
		title     : ""
		wordPairs : [{question:null,answer:null}]

	# Adds and removes a pair of textareas for users to input a word pair.
	$scope.addWordPair = (q=null, a=null) -> $scope.widget.wordPairs.push {question:q,answer:a}
	$scope.removeWordPair = (index) -> $scope.widget.wordPairs.splice(index, 1)

Namespace('Matching').Creator = do ->
	_title = _qset = _scope = null

	# Define the angular scope within this namespace to gather data before saving.
	initNewWidget = (widget, baseUrl) -> 
		_scope = angular.element($('body')).scope()

	# Apply existing data to the angular scope and angular will update the document accordingly.
	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items
		_scope = angular.element($('body')).scope()
		_scope.$apply ->
			_scope.widget.title     = title
			_scope.widget.wordPairs = []
			_scope.addWordPair( _items[i].questions[0].text, _items[i].answers[0].text ) for i in [0.._items.length-1]

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData() then Materia.CreatorCore.save _title, _qset
		else Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		_scope.$apply -> _scope.addWordPair(question.questions[0].text, question.answers[0].text) for question in questions

	# Matching does not support media
	onMediaImportComplete = (media) -> null

	_buildSaveData = ->
		if !_qset? then _qset = {}
		_qset.options = {}
		_qset.assets  = []
		_qset.rand    = false
		_qset.name    = ''
		_title        = _scope.widget.title
		_okToSave     = if _title? && _title != '' then true else false

		_items      = []
		_wordPairs  = _scope.widget.wordPairs
		_items.push( _process _wordPairs[i] ) for i in [0.._wordPairs.length-1]
		_qset.items = [{ items: _items }]
		
		_okToSave

	# Get each pair's data from the controller and organize it into Qset form.
	_process = (wordPair) ->
		questionObj =
			text  : wordPair.question
		answerObj =
			text  : wordPair.answer
			value : '100',
			id    : ''

		qsetItem           = {}
		qsetItem.questions = [questionObj]
		qsetItem.answers   = [answerObj]
		qsetItem.type      = 'QA'
		qsetItem.id        = ''
		qsetItem.assets    = []

		qsetItem

	_trace = -> if console? && console.log? then console.log.apply console, arguments

	# Public
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete

# Bootstrap the document and define it as the matching creator module.
# This will allow angular to add directives to every "ng" HTML attribute.
angular.bootstrap document, ["matchingCreator"]



