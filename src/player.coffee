###

Materia
It's a thing

Widget  : Matching, Engine
Authors : Ian Turgeon, Micheal Parks

###

Namespace('Matching').Engine = do ->
	_regexNonDigit = /[^0-9\.]+/g
	_draw = null
	_data = null
	_dom  = null

	start = (instance, qset, version = '1') ->
		if not _browserSupportsSvg()
			$('.error-notice-container').show()
			return

		# Setup model and view
		_data = Matching.Data
		_data.init(qset)
		_draw = Matching.Draw
		_draw.init(_data)
		_dom = _draw.getDom()

		if instance.name is undefined or null
			instance.name = "Widget Title Goes Here"
		# Setup the game
		_draw.drawTitle(instance.name)
		_draw.drawBoards(_dom.boardTemplate, _data.getGame().numGameboards)
		_assignQuestionsToPages()
		_drawWords()
		_setEventListeners()

	# Attaches event listeners to the document.
	_setEventListeners = ->
		# Environmental conditions.
		msNoPrefix = window.navigator.pointerEnabled
		ms     = window.navigator.msPointerEnabled and not msNoPrefix
		mobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/

		# Event types will adapt to different input types.
		downEventType = switch
			when msNoPrefix then "pointerdown"
			when ms     then "MSPointerDown"
			when mobile then "touchstart"
			else              "mousedown"
		upEventType = switch
			when msNoPrefix then "pointerup"
			when ms     then "MSPointerUp"
			when mobile then "touchend"
			else             "mouseup"

		# Next/Prev/Done buttons
		$(_dom.prev).on downEventType, _onPrevButton
		$(_dom.next).on downEventType, _onNextButton
		$(_dom.submit).on downEventType, _onSubmitButton
		$("#pendingItems").on downEventType, -> $(this).removeClass 'visible'

		# Word Up
		$('.word').on upEventType, (event) -> _onWordUp this

		if mobile
			# Prevents scrolling.
			document.addEventListener 'touchmove', (event) -> event.preventDefault()
		else
			$('.word').on 'mouseenter', (event) -> _onWordOver this
			$('.word').on 'mouseleave', (event) -> _onWordOut this

	_browserSupportsSvg = ->
		document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.0") || document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.1")

	_drawBoards = ->
		# clone board templates
		for i in [0..._data.getGame().numGameboards]
			$board = _dom.boardTemplate.clone()
			_dom.main.append $board
			$board.addClass 'hidden no-transition' if i > 0 # hide all but first board
			_dom.boards.push $board[0]                      # cache for lookup

		# show next button if needed
		_dom.next.className = 'button shown' if i > 1

	_assignQuestionsToPages = () ->
		game  = _data.getGame()
		numGB = game.numGameboards
		top   = game.totalItems-1  							# Store a reference to the top of the array of total word pairs.
		$('#numPages').html(numGB)							# Set the number of boards for the wheel on each page.

		for i in [0...numGB]                                # Iterate through the expected number of gameboards.
			_bottom = top-5                                 # By default 6 word pairs are put on a single page.
			if i is numGB-2 then _bottom = Math.ceil(top/2) # If we're at the second to last gameboard, split the remaining items and use half.
			if i is numGB-1 then _bottom = 0                # If we're at the last gameboard, use the remaining items.

			# Stash the number of items on the current gameboard.
			game.questionsOnBoard[i] = (top-_bottom)+1

			_shuffleSection top, _bottom, game.qIndices
			_shuffleSection top, _bottom, game.ansIndices

			top = _bottom-1

		# Since the arrays were shuffled top to bottom, we need to reverse them.
		game.qIndices.reverse()
		game.ansIndices.reverse()

	# Shuffles a section of an array.
	_shuffleSection = (top, bottom, array, j=-1) ->
		for i in [top..bottom]
			j = Math.floor(Math.random()*(top-bottom+1))+bottom # J will represent a random index within the current chunk.
			[array[i], array[j]] = [array[j], array[i]]         # Fast swap.

	_drawWords = () ->
		game                 = _data.getGame()
		boards               = Matching.Draw.getDom().boards
		questionId           = 0 # ID's used for matching and drawing.
		answerId             = 1 # ID's used for matching and drawing.
		questions            = _data.getQset().items[0].items
		suffledQuestionIndex = 0 # keep track of the index of the question being used

		# EACH BOARD
		for bIndex in [0..._data.getGame().numGameboards]
			$leftColumn  = $(_dom.boards[bIndex]).find('.column1') # Cache the current board's left column.
			$rightColumn = $(_dom.boards[bIndex]).find('.column2') # Cache the current board's right column.

			# EACH QUESTION ON THIS BOARD
			for qOnBIndex in [0...game.questionsOnBoard[bIndex]]

				questionText = questions[game.qIndices[suffledQuestionIndex]].questions[0].text
				answerText   = questions[game.ansIndices[suffledQuestionIndex]].answers[0].text

				word1        = _data.addWord(questionId, boards[bIndex], qOnBIndex, questionText)
				word2        = _data.addWord(answerId, boards[bIndex], qOnBIndex, answerText)

				questionDom  = _draw.drawWord(word1, $leftColumn, 'question', questionText, 'w'+questionId)
				answerDom    = _draw.drawWord(word2, $rightColumn, 'answer', answerText, 'w'+answerId)

				questionId += 2 # Question IDs will be even.
				answerId   += 2 # Answer IDs will be odd.
				suffledQuestionIndex++

	# Submit matched words for scoring.
	_submitAnswers = ->
		game = _data.getGame()
		if game.remainingItems isnt 0
			$('#pendingItems').addClass 'visible'
			return

		words = _data.getWords()

		qsetItems = _data.getQset().items[0].items
		for i in [0...words.length] by 2                           # Loop through all word pairs.
			for j in [0...qsetItems.length]                        # Loop through the qset word pairs.
				if qsetItems[j].questions[0].text == words[i].word # Find matching questions.
					Materia.Score.submitQuestionForScoring(qsetItems[j].id, words[words[i].matched].word)
					break
		true

	############# EVENT HANDLERS ##################

	_onPrevButton = -> _draw.showGameBoard(-1)
	_onNextButton = -> _draw.showGameBoard(1)

	_onSubmitButton = -> if _submitAnswers() then Materia.Engine.end()

	_onWordOver = (target) -> _draw.wordOver _data.getWords()[target.id.replace _regexNonDigit, '']
	_onWordOut  = (target) -> _draw.wordOut _data.getWords()[target.id.replace _regexNonDigit, '']
	_onWordUp   = (target) -> _draw.wordUp _data.getWords()[target.id.replace _regexNonDigit, '']

	# Public.
	start : start
