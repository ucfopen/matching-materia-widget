Namespace('Matching').Engine = do ->
	$main      = null
	$tBoard    = null
	$tWord     = null

	animating  = false

	start = (instance, qset, version = '1') ->
		Matching.Data.game.qset = qset

		_cacheVariables()           # Stores references to commonly used nodes.
		_setGameInstanceData()      # Builds information within the Matching.Data object.
		_drawBoards(instance.name)  # Injects the gameboards.
		_shuffleIndices()           # Shuffles indices that will be used to retrieve words.
		_drawBoardContent()         # Injects the gameboard content.
		_fillBoardContent()         # Fills the content with text.

		Matching.Draw.setEventListeners()
		Matching.Draw.reorderSVG()

	_cacheVariables = () ->
		$main   = $('#main')                      # A wrapper for the entire widget.
		$tBoard = $($('#t-board').html())         # Gameboard template.
		$tWord  = $($('#column-element').html())  # Word template.

		Matching.Data.nodes.prev        = document.getElementById('prev-button')
		Matching.Data.nodes.next        = document.getElementById('next-button')
		Matching.Data.nodes.currentPage = document.getElementById('page')
		Matching.Data.nodes.pageWheel   = document.getElementById('page-num').style

	_setGameInstanceData = () ->
		Matching.Data.game.totalItems        = Matching.Data.game.qset.items[0].items.length
		Matching.Data.game.remainingItems    = Matching.Data.game.totalItems
		Matching.Data.game.numGameboards     = Math.ceil(Matching.Data.game.totalItems/5)
		Matching.Data.game.currentGameboard  = 0
		Matching.Data.game.questionsOnBoard  = []
		Matching.Data.game.qIndices          = []
		Matching.Data.game.ansIndices        = []
		Matching.Data.game.hue               = Math.random()
		Matching.Data.game.randomColor       = Matching.Data.HSVtoRGB(Matching.Data.game.hue, 0.5, 0.95)

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
		$main.append($tBoard.clone()) for i in [0..Matching.Data.game.numGameboards-1]

		# Cache all gameboards after they've been inserted.
		Matching.Data.nodes.boards = document.getElementsByClassName('gameboard')

		# Hide all gameboards except the first.
		Matching.Data.nodes.boards[i].className = 'gameboard hidden' for i in [1..Matching.Data.game.numGameboards-1]
		if Matching.Data.game.numGameboards > 1 then Matching.Data.nodes.next.className = 'button shown'

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

		Matching.Draw.drawProgressBar(Matching.Data.svgNodes)

	_fillBoardContent = () ->
		_questionId       = 0 # ID's used for matching and drawing.
		_answerId         = 1 # ID's used for matching and drawing.
		_currentGameboard = 0
		_itemsAdded       = 0

		for i in [0..Matching.Data.game.totalItems-1]
			# Populate the question and question popup with text.
			Matching.Data.nodes.questions[i].children[0].innerHTML = Matching.Data.game.qset.items[0].items[Matching.Data.game.qIndices[i]].questions[0].text
			Matching.Data.nodes.questions[i].children[1].innerHTML = Matching.Data.game.qset.items[0].items[Matching.Data.game.qIndices[i]].questions[0].text

			# Populate the answer and answer popup with text.
			Matching.Data.nodes.answers[i].children[0].innerHTML   = Matching.Data.game.qset.items[0].items[Matching.Data.game.ansIndices[i]].answers[0].text
			Matching.Data.nodes.answers[i].children[1].innerHTML   = Matching.Data.game.qset.items[0].items[Matching.Data.game.ansIndices[i]].answers[0].text

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
				Matching.Data.nodes.pageWheel.oTransform      = 'rotate('+(0+(360*Matching.Data.game.currentGameboard-1))+'deg)'
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
				Matching.Data.nodes.pageWheel.oTransform      = 'rotate('+(360*Matching.Data.game.currentGameboard)+'deg)'
				Matching.Data.nodes.pageWheel.transform       = 'rotate('+(360*Matching.Data.game.currentGameboard)+'deg)'

				setTimeout ->
					Matching.Data.nodes.currentPage.innerHTML = Matching.Data.game.currentGameboard+1
				, 300

	handleSubmitButton = () ->
		_submitAnswers()
		Materia.Engine.end()

	# TODO: rewrite this silly thing.
	# Submit matched words for scoring.
	_submitAnswers = ->
		words = Matching.Data.words
		# We need to look through all matchable questions.
		for i in [0..words.length-1]
			do ->
				for j in [0..Matching.Data.game.qset.items[0].items.length-1]
					if Matching.Data.game.qset.items[0].items[j].questions[0].text == words[i].word
						Materia.Score.submitQuestionForScoring(
							Matching.Data.game.qset.items[0].items[j].id, 
							words[words[i].matched].word
						)
						break

	# Public.
	start              : start
	handlePrevButton   : handlePrevButton
	handleNextButton   : handleNextButton
	handleSubmitButton : handleSubmitButton
