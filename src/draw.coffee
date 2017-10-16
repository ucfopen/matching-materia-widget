Namespace('Matching').Draw = do ->
	_currentColor = 0
	_data         = null
	_maxWordWidth = 200
	_maxFontSize  = 17
	_connectWord  = null
	_connectState = null
	_reposition   = []
	_dom =
		boards      : []
		main        : null
		progressBar : null

	init = (dataObject) ->
		_data = dataObject

		# Caches element references to speed lookup
		_dom.main          = $('#main')                  # A wrapper for the entire widget.
		_dom.boardTemplate = $($('#t-board').html())     # Gameboard template.
		_dom.wordTemplate  = $('#column-element').html() # Word template.
		_dom.prev          = $('#prev-button')[0]
		_dom.next          = $('#next-button')[0]
		_dom.submit        = $('#submit-button')[0]
		_dom.currentPage   = $('#page')[0]
		_dom.pageWheel     = $('#page-num')[0].style

		$('#progress-bar svg').html(_makeRect(0))

	getDom = -> _dom

	drawTitle = (title) ->
		# Set title.
		$('#title').html(title)
		if title.length > 38 then $('#title').css 'font-size','1.2em'

	drawWord = (word, $container, wordClass, text, id) ->
		$word = $(_dom.wordTemplate).addClass(wordClass)
		$word.attr('id', id)
		$word.find('.text-wrapper').html(text)
		$word.find('.popup-text').html(text)
		$word.find('.text-wrapper-dummy').html(text)

		word.node           = $word[0]
		word.preinnerCircle = _makeCircle(word.x, word.y, 5)  # inner circle for preview
		word.hollowCircle   = _makeCircle(word.x, word.y, 10) # outer circle
		word.innerCircle    = _makeCircle(word.x, word.y, 5)  # inner circle when connected

		$board = $(word.gameboard)
		$board.find('.predots').append word.preinnerCircle
		$board.find('.hollows').append word.hollowCircle
		$board.find('.dots').append word.innerCircle

		$container.append($word)
		_scaleText $word.find('.word-text')
		word.isLongWord = $word.find('.expand').css('display') isnt 'none'

	drawBoards = (template, numBoards) ->
		# clone board templates
		for i in [0...numBoards]
			board = template
			_dom.main.append board.clone()
			_dom.boards.push document.getElementsByClassName('gameboard')[i] # cache for lookup
			_dom.boards[i].className += ' hidden no-transition' if i > 0     # hide all but first board

		#set all words as not repositioned
		for word, w in _data.getWords()
			_reposition[w] = false

		# show next button if needed
		_dom.next.className = 'button shown' if i > 1

	showGameBoard = (boardDelta) ->
		_connectWord  = null
		_connectState = null
		_game         = _data.getGame()
		_currentBoard = _game.currentGameboard
		_nextBoard    = _currentBoard + boardDelta

		if boardDelta? and _dom.boards[_nextBoard]?
			# Before moving to a new board, hide dot from selected but unmatched word
			for word, w in _data.getWords()
				if word.innerCircle? and word.preinnerCircle? and word.matched is -1
					word.innerCircle.attr 'class', 'hidden'
					word.preinnerCircle.attr 'class', 'hidden'

			_dom.boards[_currentBoard].className = 'gameboard hidden'
			_dom.boards[_nextBoard].className = 'gameboard'
			_game.currentGameboard = _nextBoard
			_updatePageButtons _nextBoard

	# Draws a line from one column to another.
	drawPreline = (word1, word2) ->
		$preline = $(word1.gameboard).find('.preline line')

		$preline.attr
			x1 : word1.x
			y1 : word1.y
			x2 : word2.x
			y2 : word2.y

		$preline.attr 'class', ''
		word1.preinnerCircle.attr 'class', ''

	fadePreline = (board, selectedWord) ->
		$preline = $('.preline line')
		$preline.attr 'class', 'hidden'
		if selectedWord?
			selectedWord.preinnerCircle.attr 'class', 'hidden'

	makeMatch = (word, word2) ->
		# Already matched to this item
		return if !word? or !word2? or word.matched == word2.id

		color = _getRandomColor()

		# This operation could involve 3 words, unmatch them all.
		_unMatchWord word
		_unMatchWord word2

		# Update our word data.
		_data.matchWords(word.id, word2.id)

		# Remove hidden lines from previious unmatching, gives them time to animate away.
		$('.lines .hidden').remove()
		# Connect with a line.
		line = _makeLine('line', word.x, word.y, word2.x, word2.y)
		$(word.gameboard).find('.lines').append line
		word.line = word2.line = line

		word.node.className  = 'word matched'
		word2.node.className = 'word matched'

		updateProgress()

		# Clean up the preline
		fadePreline(word.gameboard)

		word.preinnerCircle.attr 'class', 'hidden'
		word.hollowCircle.attr 'class', 'matched'
		word.innerCircle.attr 'class', color

		word2.preinnerCircle.attr 'class', 'hidden'
		word2.hollowCircle.attr 'class', 'matched hidden'
		word2.innerCircle.attr 'class', color

	showCircle = (id) ->
		if _data.getWords()[id].matched == -1
			_circle = _data.getWords()[id].innerCircle
			_data.getWords()[id].innerCircle.attr 'class', ''

	fadeCircle = (id) ->
		_data.getWords()[id].innerCircle.attr 'class', 'hidden'


	revertCircleColor = (id) ->
		_circle = _data.getWords()[id].innerCircle
		_circle[0].style = ""

	# Animates the popup in.
	expandWord = (id) ->
		if id % 2 == 0
			popupSide = 'left'
		else
			popupSide = 'right'

		$popup = $("#w"+id+" .popup")
		$popText = $("#w"+id+" .popup-text")
		$popArrow = $("#w"+id+" .popup-arrow")

		$popup.addClass 'shown'

		$popText.addClass popupSide
		$popArrow.addClass popupSide

		$popText.addClass 'scrollable'

	# Animates the popup into oblivion.
	shrinkWord = (id) ->
		$("#w"+id+" .popup").removeClass 'shown'
		$("#w"+id+" .popup-text").removeClass 'scrollable'


	wordOver = (word) ->
		if word.isLongWord then expandWord word.id

		if _connectState is 'matching' and not _onSameSide(_connectWord, word)
			drawPreline _connectWord, word
			word.hollowCircle.attr 'class', ''
			word.preinnerCircle.attr 'class', ''

	wordOut = (word) ->
		word.hollowCircle.attr 'class', 'hidden'
		word.preinnerCircle.attr 'class', 'hidden'

		if word.isLongWord then shrinkWord(word.id)

		fadePreline()

	wordUp = (word) ->
		showCircle word.id
		revertCircleColor word.id
		if word.isLongWord then shrinkWord(word.id)

		if _onSameSide(_connectWord, word)
			_connectWord.preinnerCircle.attr 'class', 'hidden'
			if _connectWord.matched is -1 && _connectWord.id isnt word.id then fadeCircle _connectWord.id
			_connectState = null

		switch _connectState
			when 'matching'
				_connectState = null
				makeMatch(word, _connectWord)
			else
				_connectState = 'matching'
				_connectWord = word

	_onSameSide = (word1, word2) ->
		word1? and word2 and word1.isOnLeft is word2.isOnLeft

	_scaleText = ($wordBlock) ->
		# Set up target/dummy pair for question
		$word  = $wordBlock.find('.text-wrapper')
		$dummy = $wordBlock.find('.text-wrapper-dummy')

		fontSize = parseInt($word.css('font-size'))

		# Recursively nudge font size down
		while $dummy.width() > _maxWordWidth
			$dummy.css 'font-size', (fontSize)
			if fontSize <= _maxFontSize then break
			fontSize--

		# Assign new font size and check for overflow
		$word.css 'font-size', fontSize
		if $dummy.width() > _maxWordWidth * 2 then $wordBlock.find('.expand').show()

	_getRandomColor = ->
		if ++_currentColor > 9 then _currentColor = 1
		color = 'c'+ _currentColor

	_unMatchWord = (word) ->
		if word.matched > -1
			matchedWord = _data.getWords()[word.matched]

			matchedWord.innerCircle.attr 'class', 'hidden'
			matchedWord.hollowCircle.attr 'class', 'hidden'
			$(matchedWord.line).attr 'class','hidden'

			matchedWord.matched = -1
			matchedWord.node.className = "word"
			_removeMatchLine word

	_removeMatchLine = (word) ->
		if word.line?
			$(word.line).remove()
			word.preinnerCircle.attr 'class', 'hidden'
			word.hollowCircle.attr 'class', ''
			word.innerCircle.css ''


	_makeCircle = (x, y, r) ->
		circle = $(_makeSVGShape('circle'))
		circle.attr
			class : 'hidden'
			cx    : x
			cy    : y
			r     : r
		circle

	_makeLine = (className, x, y, x2, y2) ->
		line = $(_makeSVGShape('line'))
		line.attr
			class : className
			x1    : x
			y1    : y
			x2    : x2
			y2    : y2
		line

	_makeRect = (width) ->
		rect = $(_makeSVGShape('rect'))
		rect.attr
			id     : 'bar'
			x      : 0
			y      : 0
			width  : width
			height : 10
			rx     : 5
			ry     : 5
		.css
			'stroke-width' : 1
			stroke : '#BDC3C7'
			fill   : '#BDC3C7'
			opacity : 0
		rect

	_makeSVGShape = (type) ->
		shape = document.createElementNS 'http://www.w3.org/2000/svg', type

	# Animates the progress bar and done button.
	updateProgress = ->
		game = _data.getGame()
		width = 160 * ((game.totalItems - game.remainingItems) / game.totalItems)

		$('#progress-bar svg').html(_makeRect(width))

		setTimeout ->
			$('#progress-bar svg rect').css 'opacity' , '1'
		, 10

		if game.remainingItems is 0 then _dom.submit.className = 'glowing button'
		else                             _dom.submit.className = 'unselectable button'

	_updatePageButtons = (pageIndex) ->
		show = 'button shown'
		hide = 'button unselectable'
		_dom.prev.className = if pageIndex is 0 then hide else show
		_dom.next.className = if pageIndex is _data.getGame().numGameboards - 1 then hide else show

		_updatePageLabel pageIndex

	# This crazy little style reset causes the wheel to rotate.
	_updatePageLabel = (pageIndex) ->
		w = _dom.pageWheel
		w.webkitTransform = w.mozTransform = w.msTransform = w.transform = "rotate(#{0+(360*pageIndex-1)}deg)"
		setTimeout ->
			_dom.currentPage.innerHTML = pageIndex+1
		, 300

	# Public
	init          : init
	getDom        : getDom
	drawWord      : drawWord
	showCircle    : showCircle
	makeMatch     : makeMatch
	fadePreline   : fadePreline
	drawPreline   : drawPreline
	drawTitle     : drawTitle
	expandWord    : expandWord
	shrinkWord    : shrinkWord
	showGameBoard : showGameBoard
	wordOver      : wordOver
	wordOut       : wordOut
	wordUp        : wordUp
	drawBoards    : drawBoards
