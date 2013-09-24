Namespace('Matching').Creator = do ->
	_widget  = null # holds widget data
	_qset    = null # Keep tack of the current qset
	_title   = null # hold on to this instance's title
	_version = null # holds the qset version, allows you to change your widget to support old versions of your own code
	
	# variables to contain templates for various page elements
	_qTemplate = null
	_qWindowTemplate = null
	_aTemplate = null

	initNewWidget = (widget, baseUrl) ->
		_buildDisplay 'New Matching Widget', widget

	initExistingWidget = (title, widget, qset, version, baseUrl) -> _buildDisplay title, widget, qset, version

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save _title, _qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		_addQuestion question for question in questions

	# Matching does not support media
	onMediaImportComplete = (media) -> null

	_buildDisplay = (title = 'Default test Title', widget, qset, version) ->
		_version = version
		_qset    = qset
		_widget  = widget
		_title   = title

		$('#title').val _title

		# enable the question area so that categories can be drag-sorted
		$('#question_container').sortable {
			containment: 'parent',
			distance: 5,
			helper: 'clone',
		}

		# fill the template objects
		unless _qTemplate
			_qTemplate = $('.template.question')
			$('.template.question').remove()
			_qTemplate.removeClass('template')
		unless _aTemplate
			_aTemplate = $('.template.answer')
			$('.template.answer').remove()
			_aTemplate.removeClass('template')

		$('#add_question_button').click ->
			_addQuestion()

		$('#import_hide').click -> $('#import_area').hide()

		if _qset?
			console.log _qset
			questions = _qset.items[0].items
			console.log questions
			_addQuestion question for question in questions

	_buildSaveData = ->
		okToSave = false

		# create new qset object if we don't already have one, set default values regardless
		if !_qset?
			_qset = {}
		_qset.options = {}
		_qset.assets = []
		_qset.rand = false
		_qset.name = ''

		# update our values
		_title = $('#title').val()
		#_qset.options.randomize = $('#randomize').prop 'checked'
		okToSave = true if _title? && _title!= ''

		items = []

		questions = $('.question')

		qid = 0
		for c in questions
			console.log c
			items.push(_process c)

		console.log(items)

		_qset.items = [{ items: items }]
		okToSave

	# get each category's data from the appropriate page elements
	_process = (c) ->
		c = $(c)
		question = {}
		question.questions = [{text: c.find('.question_text').val()}]
		question.answers = [{text: c.find('.answer_text').val(), value: "100", id: ''}]
		question.type = "QA"
		question.id = ''
		question.assets = []


		question

	_addQuestion = (question=null) ->
		console.log question
		# create a new question element and default its pertinent data
		newQ = _qTemplate.clone()

		newQ.find('.delete').click () ->
			$(this).parent().remove()
		newQ.click () ->
			_changeQuestion this unless $(this).hasClass('dim') or $(this).closest('#import_question_area').length > 0 or $(this).hasClass('dragging')
		if question?
			newQ.find('.question_text').text question.questions[0].text
			newQ.find('.answer_text').text question.answers[0].text
			$.data(newQ[0], 'question', [{text: question.questions[0].text}])
			$.data(newQ[0], 'answer', [{text: question.answers[0].text}])
		else
			$(newQ).click()
		$('#question_container').append newQ

	# open the question edit window, populate it with info based on the clicked question's data
	_changeQuestion = (q) ->
		$('.selected').removeClass 'selected'
		$(q).addClass 'selected'
		$('.question:not(.selected)').addClass 'dim'

	_trace = ->
		if console? && console.log?
			console.log.apply console, arguments

	#public
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked:onSaveClicked
	onMediaImportComplete:onMediaImportComplete
	onQuestionImportComplete:onQuestionImportComplete
	onSaveComplete:onSaveComplete
