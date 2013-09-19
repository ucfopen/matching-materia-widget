Namespace('Matching').Engine = do ->
	$main      = null
	$tBoard    = null
	$tWord     = null

	animating  = false

	start = (instance, qset, version = '1') ->
		if not _browserSupportsSvg()
			$('.error-notice-container').show()
			return

		Matching.Data.game.qset = qset

		_cacheVariables()           # Stores references to commonly used nodes.
		_setGameInstanceData()      # Builds information within the Matching.Data object.
		_drawBoards(instance.name)  # Injects the gameboards.
		_shuffleIndices()           # Shuffles indices that will be used to retrieve words.
		_drawBoardContent()         # Injects the gameboard content.
		_fillBoardContent()         # Fills the content with text.

		Matching.Draw.drawProgressBar(Matching.Data.svgNodes)
		Matching.Draw.setEventListeners()
		Matching.Draw.reorderSVG()

	_browserSupportsSvg = ->
		document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.0") || document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#Shape", "1.1")

	_cacheVariables = () ->
		$main   = $('#main')                      # A wrapper for the entire widget.
		$tBoard = $($('#t-board').html())         # Gameboard template.
		$tWord  = $($('#column-element').html())  # Word template.

		Matching.Data.nodes.prev        = document.getElementById('prev-button')
		Matching.Data.nodes.next        = document.getElementById('next-button')
		Matching.Data.nodes.currentPage = document.getElementById('page')
		Matching.Data.nodes.pageWheel   = document.getElementById('page-num').style

	_setGameInstanceData = () ->
		# Widget instance data.
		Matching.Data.game.totalItems        = Matching.Data.game.qset.items[0].items.length
		Matching.Data.game.remainingItems    = Matching.Data.game.totalItems
		Matching.Data.game.numGameboards     = Math.ceil(Matching.Data.game.totalItems/5)
		Matching.Data.game.currentGameboard  = 0
		Matching.Data.game.questionsOnBoard  = []
		Matching.Data.game.qIndices          = []
		Matching.Data.game.ansIndices        = []
		Matching.Data.game.hue               = Math.random()
		Matching.Data.game.randomColor       = Matching.Data.HSVtoRGB(Matching.Data.game.hue, 0.5, 0.95)

		# Control flow gates.
		Matching.Data.gates.animating    = false
		Matching.Data.gates.inWord       = false
		Matching.Data.gates.inColumn     = false
		Matching.Data.gates.prelineDrawn = false

		Matching.Data.nodes.questions = null
		Matching.Data.nodes.answers   = null

		for i in [0..Matching.Data.game.totalItems-1]
			Matching.Data.game.qIndices.push(i)
			Matching.Data.game.ansIndices.push(i)

	_drawBoards = (title) ->
		# Set the game title and insert all gameboards.
		document.getElementById('title').innerHTML = title
		if title.length > 38 then $('#title').css('font-size','1.2em')
		$main.append($tBoard.clone()) for i in [0..Matching.Data.game.numGameboards-1]

		# Cache all gameboards after they've been inserted.
		Matching.Data.nodes.boards = document.getElementsByClassName('gameboard')

		# Hide all gameboards except the first.
		if Matching.Data.game.numGameboards > 1 
			Matching.Data.nodes.boards[i].className = 'gameboard hidden no-transition' for i in [1..Matching.Data.game.numGameboards-1]
			Matching.Data.nodes.next.className = 'button shown'

	_shuffleIndices = () ->
		_numGB = Matching.Data.game.numGameboards
		_top   = Matching.Data.game.totalItems-1              # Store a reference to the top of the array of total word pairs.                                           
		for i in [0.._numGB-1]                                # Iterate through the expected number of gameboards.
			_bottom = _top-4                                  # By default 5 word pairs are put on a single page.
			if i is _numGB-2 then _bottom = Math.ceil(_top/2) # If we're at the second to last gameboard, split the remaining items and use half.
			if i is _numGB-1 then _bottom = 0                 # If we're at the last gameboard, use the remaining items.

			# Stash the number of items on the current gameboard.
			Matching.Data.game.questionsOnBoard[i] = (_top-_bottom)+1  

			_shuffleSection(_top, _bottom, Matching.Data.game.qIndices)
			_shuffleSection(_top, _bottom, Matching.Data.game.ansIndices)

			_top = _bottom-1

		# Since the arrays were shuffled top to bottom, we need to reverse them.
		Matching.Data.game.qIndices.reverse()
		Matching.Data.game.ansIndices.reverse()

	# Shuffles a section of an array.
	_shuffleSection = (top, bottom, array, j=-1) ->
		for i in [top..bottom]
			j = Math.floor(Math.random()*(top-bottom+1))+bottom # J will represent a random index within the current chunk.
			[array[i], array[j]] = [array[j], array[i]]         # Fast swap.

	_drawBoardContent = () ->
		for i in [0..Matching.Data.game.numGameboards-1]
			# Every board contains an svg "canvas". Make D3 references to these.
			Matching.Data.svgNodes.push(d3.select(Matching.Data.nodes.boards[i]).select('.matching-container').select('svg'))

			_$leftColumn  = $(Matching.Data.nodes.boards[i].children[0]) # Cache the current board's left column.
			_$rightColumn = $(Matching.Data.nodes.boards[i].children[1]) # Cache the current board's right column.
			for j in [0..Matching.Data.game.questionsOnBoard[i]-1]
				_$leftColumn.append($tWord.clone().addClass('question')) # Append a word template clone.
				_$rightColumn.append($tWord.clone().addClass('answer'))  # Append a word template clone.

		# These temporary classes will be used by D3 when setting up the "canvas".
		Matching.Data.nodes.questions = document.getElementsByClassName('question')
		Matching.Data.nodes.answers   = document.getElementsByClassName('answer')

	_fillBoardContent = () ->
		_questionId       = 0 # ID's used for matching and drawing.
		_answerId         = 1 # ID's used for matching and drawing.
		_currentGameboard = 0 # The current gameboard.
		_itemsAdded       = 0 # The number of items added on the current board.

		for i in [0..Matching.Data.game.totalItems-1]

			_question = Matching.Data.game.qset.items[0].items[Matching.Data.game.qIndices[i]].questions[0].text
			_answer = Matching.Data.game.qset.items[0].items[Matching.Data.game.ansIndices[i]].answers[0].text
			# Populate the question and question popup with text.
			Matching.Data.nodes.questions[i].children[0].children[0].innerHTML = _question
			Matching.Data.nodes.questions[i].children[1].innerHTML = _question
			# Populate the dummy wrapper
			Matching.Data.nodes.questions[i].children[0].children[1].innerHTML = _question

			# Populate the answer and answer popup with text.
			Matching.Data.nodes.answers[i].children[0].children[0].innerHTML   = _answer
			Matching.Data.nodes.answers[i].children[1].innerHTML   = _answer
			Matching.Data.nodes.answers[i].children[0].children[1].innerHTML = _answer

			_handleTextScaling = (textElement) ->
				# Static settings for word width/height
				max_width = 200
				max_height = 43

				# Set up target/dummy pair for question
				_target = $(textElement.children[0])
				_dummy = $(textElement.children[1]).css('font-size', _target.css('font-size'))

				# Recursively nudge font size down
				while _dummy.width() > max_width
					_size = parseInt(_dummy.css('font-size')) - 1
					_dummy.css 'font-size', (_size)
					if _size <= 17 then break

				# Assign new font size and check for overflow
				_target.css 'font-size', _size
				if _dummy.width() > max_width * 2 then $(textElement.children[2]).show()

			# Run text scaling method for both the question and answer
			_handleTextScaling Matching.Data.nodes.answers[i].children[0]
			_handleTextScaling Matching.Data.nodes.questions[i].children[0]

			Matching.Data.nodes.questions[i].id = 'w'+_questionId # Node ID for question.
			Matching.Data.nodes.answers[i].id   = 'w'+_answerId   # Node ID for answer.

			Matching.Data.setWordObject(Matching.Data.nodes.questions[i], _questionId, _currentGameboard, _itemsAdded)
			Matching.Data.setWordObject(Matching.Data.nodes.answers[i], _answerId, _currentGameboard, _itemsAdded)

			_questionId +=2 # Question IDs will be even.
			_answerId   +=2 # Answer IDs will be odd.
			_itemsAdded++

			if _itemsAdded is Matching.Data.game.questionsOnBoard[_currentGameboard]
				_currentGameboard++
				_itemsAdded = 0

	handlePrevButton = () ->
		if not Matching.Data.gates.animating
			Matching.Data.gates.animating = true
			setTimeout ->
				Matching.Data.gates.animating = false
			, 600

			# Dont allow the user to go to a nonexistant gameboard!
			if Matching.Data.game.currentGameboard > 0
				Matching.Data.nodes.boards[Matching.Data.game.currentGameboard].className = 'gameboard hidden'

				Matching.Data.game.currentGameboard--
				if Matching.Data.game.currentGameboard is 0 then Matching.Data.nodes.prev.className = 'button unselectable'
				if Matching.Data.game.currentGameboard is Matching.Data.game.numGameboards - 2 then Matching.Data.nodes.next.className = 'button shown'

				# Display the board we're animating in.
				setTimeout ->
					Matching.Data.nodes.boards[Matching.Data.game.currentGameboard].className = 'gameboard'
				, 300

				# This crazy little style reset causes the wheel to rotate.
				Matching.Data.nodes.pageWheel.webkitTransform = 'rotate('+(0+(360*Matching.Data.game.currentGameboard-1))+'deg)'
				Matching.Data.nodes.pageWheel.mozTransform    = 'rotate('+(0+(360*Matching.Data.game.currentGameboard-1))+'deg)'
				Matching.Data.nodes.pageWheel.msTransform     = 'rotate('+(0+(360*Matching.Data.game.currentGameboard-1))+'deg)'
				Matching.Data.nodes.pageWheel.transform       = 'rotate('+(0+(360*Matching.Data.game.currentGameboard-1))+'deg)'

				setTimeout ->
					Matching.Data.nodes.currentPage.innerHTML = Matching.Data.game.currentGameboard+1
				, 300

	handleNextButton = () ->
		if not Matching.Data.gates.animating
			Matching.Data.gates.animating = true
			setTimeout ->
				Matching.Data.gates.animating = false
			, 600
			
			if Matching.Data.game.currentGameboard < Matching.Data.game.numGameboards - 1
				Matching.Data.nodes.boards[Matching.Data.game.currentGameboard].className = 'gameboard hidden'

				Matching.Data.game.currentGameboard++
				if Matching.Data.game.currentGameboard is 1 then Matching.Data.nodes.prev.className = 'button shown'
				if Matching.Data.game.currentGameboard is Matching.Data.game.numGameboards - 1 then Matching.Data.nodes.next.className = 'button unselectable'

				setTimeout ->
					Matching.Data.nodes.boards[Matching.Data.game.currentGameboard].className = 'gameboard'
				, 300

				Matching.Data.nodes.pageWheel.webkitTransform = 'rotate('+(360*Matching.Data.game.currentGameboard)+'deg)'
				Matching.Data.nodes.pageWheel.mozTransform    = 'rotate('+(360*Matching.Data.game.currentGameboard)+'deg)'
				Matching.Data.nodes.pageWheel.msTransform     = 'rotate('+(360*Matching.Data.game.currentGameboard)+'deg)'
				Matching.Data.nodes.pageWheel.transform       = 'rotate('+(360*Matching.Data.game.currentGameboard)+'deg)'

				setTimeout ->
					Matching.Data.nodes.currentPage.innerHTML = Matching.Data.game.currentGameboard+1
				, 300

	handleSubmitButton = () ->
		_submitAnswers()
		Materia.Engine.end()

	# Submit matched words for scoring.
	_submitAnswers = ->
		_words     = Matching.Data.words
		_qsetItems = Matching.Data.game.qset.items[0].items
		for i in [0.._words.length-1] by 2                                # Loop through all word pairs.
			do ->
				for j in [0.._qsetItems.length-1]                         # Loop through the qset word pairs.
					if _qsetItems[j].questions[0].text == _words[i].word  # Find matching questions.
						Materia.Score.submitQuestionForScoring(
							_qsetItems[j].id,                             # Send the ID of the question and...
							_words[_words[i].matched].word                # ... the word that the user matched with it.
						)
						break                                             # Once we've submitted our answer, 
                                                                          # continuing through the inner loop is useless.

	# Public.
	start              : start
	handlePrevButton   : handlePrevButton
	handleNextButton   : handleNextButton
	handleSubmitButton : handleSubmitButton
