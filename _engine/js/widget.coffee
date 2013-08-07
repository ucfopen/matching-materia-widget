Namespace('Matching').Engine = do ->
	# Elements.
	_$mainScreen         = null
	_$board              = null
	_$columnElement      = null
	_$popupText          = null
	_pageNum             = null
	_pageNumStyle        = null
	_$prevButton         = null
	_$nextButton         = null

	_qset                = null
	_questions           = []
	_answers             = []
	_shuffledQuestions   = []
	_shuffledAnswers     = []
	_animating           = false
	_currentGameboard    = 0
	_numGameboards       = null
	# This stores the indices of matched words in an array of arrays
	# Each sub-array has length of 2 and stores the left/right matched word indices.
	_totalQuestions      = null
	_remainingQsetItems  = null

	# Event handling.
	_ms     = window.navigator.msPointerEnabled
	_mobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/

	downEventType = switch
		when _ms     then "MSPointerDown"
		when _mobile then "touchstart"
		else              "mousedown"

	# Called by Materia.Engine when widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_cacheVariables()
		_storeWords()
		_shuffleWords()
		_drawBoard(instance.name)
		_cacheLateVariables()
		Matching.Draw.setEventListeners()

	_cacheVariables = ->
		_$mainScreen     = $('#main')
		_$board          = $($('#t-board').html())
		_$columnElement  = $($('#column-element').html())
		_$prevButton     = $('#prev-button')
		_$nextButton     = $('#next-button')

	_cacheLateVariables = ->
		_$popupText      = $('.popup-text')
		_pageNum         = document.getElementById('page')
		_pageNumStyle    = document.getElementById('page-num').style

	# Store questions and answers in arrays.
	_storeWords = ->
		_totalQuestions = _qset.items[0].items.length
		_remainingQsetItems = _totalQuestions
		_numGameboards = Math.ceil(_totalQuestions/5)

		questionsPerBoard = 5
		k = 0
		for i in [0.._numGameboards-1]
			# Decide how many questions this board will contain.
			_remainingQsetItems-=5
			if _remainingQsetItems < 3 then questionsPerBoard = 3
			if i == _numGameboards-1 
				questionsPerBoard = if (_totalQuestions-(i*5))<3 then (_totalQuestions-(i*5))+2 else (_totalQuestions-(i*5))

			# Push a new array to store this gameboard's words.
			_questions.push([])
			_answers.push([])

			_shuffledQuestions.push([])
			_shuffledAnswers.push([])

			# Transfer items from the qset to our arrays.
			for j in [0..questionsPerBoard-1]
				_questions[i].push(_qset.items[0].items[k].questions[0].text)
				_answers[i].push(_qset.items[0].items[k].answers[0].text)

				_shuffledQuestions[i].push(j)
				_shuffledAnswers[i].push(j)

				k++

	# Shuffle any array.
	_shuffle = (a) ->
		for i in [a.length-1..1]
			j = Math.floor Math.random() * (i + 1)
			[a[i], a[j]] = [a[j], a[i]]

	# Shuffle the stored words.
	_shuffleWords = ->
		for i in [0.._shuffledQuestions.length-1]
			_shuffle(_shuffledQuestions[i])
			_shuffle(_shuffledAnswers[i])

	# Draw the main board.
	_drawBoard = (title) ->
		_remainingQsetItems = _totalQuestions

		# Populate the game title.
		document.getElementById('title').innerHTML = title

		# Set event listeners for toggling pages.
		if _numGameboards > 1 
			_$nextButton.removeClass('unselectable').addClass('shown')

		wordId = 0
		questionsPerBoard = 5
		for i in [0.._numGameboards-1]
			# Decide how many questions this board will contain.
			_remainingQsetItems-=5
			if _remainingQsetItems < 3 then questionsPerBoard = 3
			if i == _numGameboards-1 
				questionsPerBoard = if (_totalQuestions-(i*5))<3 then (_totalQuestions-(i*5))+2 else (_totalQuestions-(i*5))

			# Clone a new gameboard.
			_$mainScreen.append(_$board.clone().attr('id', 'board'+i))
			if i > 0 then $('#board'+i).addClass('hidden')

			# Find the current board's drawing canvas and store it.
			document.getElementById('board'+i).children[2].id = 'container'+i
			Matching.Draw.paper.push(d3.select('body').select('#container'+i).select('svg'))

			for j in [0..questionsPerBoard-1]
				# Populate the left column.
				$('#board'+i+' .column1').append(_$columnElement.clone().attr('id', 'w'+wordId))
				$('#board'+i+' .column1 #w'+wordId+' .word-text').html(_questions[i][_shuffledQuestions[i][j]]).addClass('left')
				$('#board'+i+' .column1 #w'+wordId+' .popup-text').attr('id', 'popup'+wordId).html(_questions[i][_shuffledQuestions[i][j]])
				Matching.Draw.setWordObject(Matching.Draw.paper[i], wordId, 1, i, j)

				wordId++

				# Populate the right column.
				$('#board'+i+' .column2').append(_$columnElement.clone().attr('id', 'w'+wordId).addClass('right'))
				$('#board'+i+' .column2 #w'+wordId+' .word-text').html(_answers[i][_shuffledAnswers[i][j]]).addClass('right')
				$('#board'+i+' .column2 #w'+wordId+' .popup-text').attr('id', 'popup'+wordId).html(_answers[i][_shuffledAnswers[i][j]])
				Matching.Draw.setWordObject(Matching.Draw.paper[i], wordId, 2, i, j)

				wordId++

		# Draw the progress bar.
		Matching.Draw.paper.push d3.select('body').select('#questions-answered').select('svg')
		Matching.Draw.drawProgressBar()

	handlePrevButton = ->
		if not _animating
			_animating = true;
			setTimeout -> 
				_animating = false
			, 600

			# Dont allow the user to go to a nonexistant gameboard!
			if _currentGameboard > 0
				$('#board'+_currentGameboard).addClass('hidden')

				_currentGameboard--
				if _currentGameboard is 0
					_$prevButton.addClass('unselectable').removeClass('shown')
				if _currentGameboard is _numGameboards - 2
					_$nextButton.removeClass('unselectable').addClass('shown')

				setTimeout ->
					$('#board'+_currentGameboard).removeClass('hidden')
				, 300

				_pageNumStyle.webkitTransform = 'rotate('+(0+(360*_currentGameboard-1))+'deg)'
				_pageNumStyle.mozTransform    = 'rotate('+(0+(360*_currentGameboard-1))+'deg)'
				_pageNumStyle.msTransform     = 'rotate('+(0+(360*_currentGameboard-1))+'deg)'
				_pageNumStyle.transform       = 'rotate('+(0+(360*_currentGameboard-1))+'deg)'

				setTimeout ->
					_pageNum.innerHTML = _currentGameboard+1
				, 300

	handleNextButton = ->
		if not _animating
			_animating = true;
			setTimeout -> 
				_animating = false
			, 600
			
			if _currentGameboard < _numGameboards - 1
				$('#board'+_currentGameboard).addClass('hidden')

				_currentGameboard++
				if _currentGameboard is 1
					_$prevButton.removeClass('unselectable').addClass('shown')
				if _currentGameboard is _numGameboards - 1
					_$nextButton.addClass('unselectable').removeClass('shown')

				setTimeout ->
					$('#board'+_currentGameboard).removeClass('hidden')
				, 300

				_pageNumStyle.webkitTransform = 'rotate('+(360*_currentGameboard)+'deg)'
				_pageNumStyle.mozTransform    = 'rotate('+(360*_currentGameboard)+'deg)'
				_pageNumStyle.msTransform     = 'rotate('+(360*_currentGameboard)+'deg)'
				_pageNumStyle.transform       = 'rotate('+(360*_currentGameboard)+'deg)'

				setTimeout ->
					_pageNum.innerHTML = _currentGameboard+1
				, 300

	handleSubmitButton = ->
		_submitAnswers()
		Materia.Engine.end()

	getTotalQuestions = ->
		return _totalQuestions

	# Submit matched words for scoring.
	_submitAnswers = ->
		# We need to look through all matchable questions.
		for i in [0..Matching.Draw.getWords().length-1]
			do ->
				for j in [0.._qset.items[0].items.length-1]
					if _qset.items[0].items[j].questions[0].text == Matching.Draw.words[i].word
						Materia.Score.submitQuestionForScoring(_qset.items[0].items[j].id, Matching.Draw.words[Matching.Draw.words[i].matched].word)
						break
		

	# Public Methods:
	start              : start
	handlePrevButton   : handlePrevButton
	handleNextButton   : handleNextButton
	handleSubmitButton : handleSubmitButton
	getTotalQuestions  : getTotalQuestions
