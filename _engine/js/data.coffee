# All methods and properties in "Data" are public,
# but need to be protected.
# So we'll make it an object literal.
Namespace('Matching').Data =
	svgNodes   : [] # Holds svg elements for each gameboard.
	nodes      : {} # Holds gameboard, word, and misc node references.
	game       : {} # Holds widget instance data and LOGIC.
	gates      : {} # Holds boolean values that regulate control flow.
	words      : [] # Holds objects that contain word data and svg element references.

	setWordObject : (node, id, gameboard, i) ->
		_x        = if id%2 is 0 then 270 else 480
		container = @svgNodes[gameboard]
		word = @words[id] = {}
		yLoc = (i+1)*70.3+65

		# Only the left column words will possess lines for matching.
		if id%2 is 0
			word.line = container.append('line').attr
				class : 'line'
				x1: _x
				y1: yLoc
				x2: _x
				y2: yLoc

		# Low opacity green line for previewing new connections
		word.preline = container.append('line').attr
			class: 'pre-line'
			x1: _x
			y1: yLoc
			x2: _x
			y2: yLoc

		# inner circle for preview
		word.preinnerCircle = container.append('circle').attr
			class: "pre-inner-circle c#{id}"
			cx: _x
			cy: yLoc
			r: 5

		# outer circle
		word.hollowCircle = container.append('circle').attr
			class: 'hollow-circle'
			cx: _x
			cy: yLoc
			r: 10

		# inner circle when connected
		word.innerCircle = container.append('circle').attr
			class: "inner-circle c#{id}"
			cx: _x
			cy: yLoc
			r: 5

		word.gameboard = gameboard
		word.selected  = false
		word.matched   = -1
		word.word      = node.children[0].children[0].innerHTML
		word.longWord  = node.children[0].children[2].style.display != ''
		word.node      = node

	selectWord : (id) ->
		if @words[id].node.className is 'word matched'
			@words[id].node.className  = 'word matched selected'
		else @words[id].node.className = 'word selected'

		@words[id].selected = true

	unSelectWord : (id) ->
		# If the word is matched, unselected but retain its matching.
		if @words[id].node.className is 'word matched selected'
			@words[id].node.className  = 'word matched'
		else @words[id].node.className = 'word'

		Matching.Data.words[id].selected = false

	matchWords : (id1, id2) ->
		# Handle potential unmatching.
		@unMatchWords(id1)
		@unMatchWords(id2)

		@words[id1].node.className = 'word matched m-anim'
		@words[id2].node.className = 'word matched m-anim'

		# Store the keys of each word's partner.
		@words[id1].matched = id2
		@words[id2].matched = id1

		# Remove the selected status.
		@words[id1].selected = false
		@words[id2].selected = false

		Matching.Draw.updateProgressBar('up')
		Matching.Draw.updateRemaining('down')

	stripMatchAnimation : (id1, id2) ->
		@words[id1].node.className = 'word matched'
		@words[id2].node.className = 'word matched'

	unMatchWords : (id) ->
		if @words[id].matched > -1
			Matching.Draw.unMatchAnimation(@words[id].matched)

			@words[@words[id].matched].matched = -1
			@words[@words[id].matched].node.className = "word"

			Matching.Draw.updateProgressBar('down')
			Matching.Draw.updateRemaining('up')
	
	oppositeSelected : (id) ->
		_start = if id%2 is 0 then 1 else 0
		for i in [_start..@words.length-1] by 2
			if @words[id].gameboard is @words[i].gameboard && @words[i].selected == true
				return i
		return false

	colorReset : () ->
		@game.hue += 0.15
		if (@game.hue > 1) then @game.hue = 0.01
		@game.randomColor = @HSVtoRGB(@game.hue, 0.5, 0.95)

	HSVtoRGB : (h, s, v) ->
		h_i = parseInt(h*6)
		f = h*6 - h_i
		p = v * (1 - s)
		q = v * (1 - f*s)
		t = v * (1 - (1 - f) * s)
		switch h_i
			when 0 then r = v; g = t; b = p
			when 1 then r = q; g = v; b = p
			when 2 then r = p; g = v; b = t
			when 3 then r = p; g = q; b = v
			when 4 then r = t; g = p; b = v
			when 5 then r = v; g = p; b = q
		'rgb('+parseInt(r*256)+','+parseInt(g*256)+','+parseInt(b*256)+')'
