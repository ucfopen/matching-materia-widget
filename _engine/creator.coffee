###

Materia
It's a thing

Widget  : Matching, Creator
Authors : Jonathan Warner, Micheal Parks
Updated : 4/14

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

# Set the controller for the scope of the document body.
MatchingCreator.controller 'matchingCreatorCtrl', ['$scope', ($scope) ->

	# Stores data to be gathered on save.
	$scope.widget =
		title     : "My Matching widget"
		wordPairs : []

	# Adds and removes a pair of textareas for users to input a word pair.
	$scope.addWordPair = (q=null, a=null) ->
		$scope.widget.wordPairs.push {question:q,answer:a}
		setTimeout ->
			$('#qt_' + ($scope.widget.wordPairs.length - 1)).focus()
		, 10
	$scope.removeWordPair = (index) -> $scope.widget.wordPairs.splice(index, 1)

	$scope.changeTitle = ->
		setTimeout ->
			$scope.$apply ->
				$('#backgroundcover, .title').addClass 'show'
				$('.title input[type=text]').focus()
		,1
	$scope.setTitle = ->
		setTimeout ->
			$scope.$apply ->
				$scope.widget.title = $('.intro input[type=text]').val() or $scope.widget.title
				$scope.step = 1
				$scope.hideCover()
		,1
	$scope.hideCover = ->
		setTimeout ->
			$('#backgroundcover, .title, .intro').removeClass 'show'
		,1
	
	$scope.autoSize = (pair) ->
		question = pair.question or ''
		answer = pair.answer or ''
		len = if question.length > answer.length then question.length else answer.length
		size = if len > 15 then 30 + len else 30

		pair.style = height: size + 'px'

]

Namespace('Matching').Creator = do ->
	_title = _qset = $scope = null

	# Define the angular scope within this namespace to gather data before saving.
	initNewWidget = (widget, baseUrl) ->
		$scope = angular.element($('body')).scope()

		$('#backgroundcover, .intro').addClass 'show'

		if not Modernizr.input.placeholder then _polyfill()

	# Apply existing data to the angular scope and angular will update the document accordingly.
	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items
		$scope = angular.element($('body')).scope()
		$scope.$apply ->
			$scope.widget.title     = title
			$scope.widget.wordPairs = []
			$scope.addWordPair( _items[i].questions[0].text, _items[i].answers[0].text ) for i in [0.._items.length-1]

		if not Modernizr.input.placeholder then _polyfill()

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData() then Materia.CreatorCore.save _title, _qset
		else Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		$scope.$apply -> $scope.addWordPair(question.questions[0].text, question.answers[0].text) for question in questions

	# Matching does not support media
	onMediaImportComplete = (media) -> null

	_buildSaveData = ->
		if !_qset? then _qset = {}
		_qset.options = {}
		_qset.assets  = []
		_qset.rand    = false
		_qset.name    = ''
		_title        = $scope.widget.title
		_okToSave     = if _title? && _title != '' then true else false

		_items      = []
		_wordPairs  = $scope.widget.wordPairs
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

	_polyfill = () ->
		$('[placeholder]')
		.focus ->
			input = $(this)
			if input.val() is input.attr 'placeholder'
				input.val ''
				input.removeClass 'placeholder'
		.blur ->
			input = $(this)
			if input.val() is '' or input.val() is input.attr 'placeholder'
				input.addClass 'placeholder'
				input.val input.attr 'placeholder'
		.blur()

		$('[placeholder]').parents('form').submit ->
			$(this).find('[placeholder]').each ->
				input = $(this)
				if input.val() is input.attr 'placeholder' then input.val ''

	_trace = -> if console? && console.log? then console.log.apply console, arguments

	# Public
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete

