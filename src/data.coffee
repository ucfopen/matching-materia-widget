Namespace('Matching').Data = do ->
	_game  = {} # Holds widget instance data and LOGIC.
	_words = [] # Holds objects that contain word data and svg element references.
	_qset  = {} # holds the qset

	getGame  = -> _game
	getQset  = -> _qset
	getWords = -> _words

	init = (qset) ->
		_qset = qset

		_game.remainingItems   = _game.totalItems = _qset.items[0].items.length
		_game.numGameboards    = Math.ceil(_game.totalItems/6)
		_game.currentGameboard = 0
		_game.questionsOnBoard = []
		_game.qIndices         = []
		_game.ansIndices       = []

		for i in [0..._game.totalItems]
			_game.qIndices.push i
			_game.ansIndices.push i

	addWord = (id, gameboard, i, text) ->
		isOnLeft  = id%2 is 0
		_x        = if isOnLeft then 270 else 480
		_y        = (i+1)*70.3+65

		_words[id] = word =
			id             : id
			gameboard      : gameboard
			selected       : false
			matched        : -1
			word           : text
			isLongWord     : null
			node           : null
			isOnLeft       : isOnLeft
			preinnerCircle : null
			hollowCircle   : null
			innerCircle    : null
			x              : _x
			y              : _y

	matchWords = (id1, id2) ->
		w1 = _words[id1]
		w2 = _words[id2]

		# update matched count
		newMatches = 1
		if w1.matched >= 0 then newMatches-- # if w1 already has a match, it will be unmatched
		if w2.matched >= 0 then newMatches-- # if w1 already has a match, it will be unmatched
		_game.remainingItems -= newMatches

		# Store the keys of each word's partner.
		w1.matched = id2
		w2.matched = id1

		# Remove the selected status.
		w1.selected = false
		w2.selected = false

	init       : init
	addWord    : addWord
	matchWords : matchWords
	getGame    : getGame
	getQset    : getQset
	getWords   : getWords
