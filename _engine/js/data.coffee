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
		_x         = if id%2 is 0 then 270 else 480
		container  = this.svgNodes[gameboard]

		this.words[id] = {}

		# Only the left column words will possess lines for matching.
		if id%2 is 0 then this.words[id].line = container.append('line')
			.attr('class', 'line')
			.attr('x1', _x).attr('y1', (i+1)*70.3+65).attr('x2', _x).attr('y2', (i+1)*70.3+65)

		this.words[id].preline        = container.append('line')
			.attr('class', 'pre-line')
			.attr('x1', _x).attr('y1', (i+1)*70.3+65).attr('x2', _x).attr('y2', (i+1)*70.3+65)
		this.words[id].preinnerCircle = container.append('circle')
			.attr('class', 'pre-inner-circle c'+id)
			.attr('cx', _x).attr('cy', (i+1)*70.3+65).attr('r', 5)
		this.words[id].hollowCircle   = container.append('circle')
			.attr('class', 'hollow-circle')
			.attr('cx', _x).attr('cy', (i+1)*70.3+65).attr('r', 10)
		this.words[id].innerCircle    = container.append('circle')
			.attr('class', 'inner-circle c'+id)
			.attr('cx', _x).attr('cy', (i+1)*70.3+65).attr('r', 5)

		this.words[id].gameboard = gameboard
		this.words[id].selected  = false
		this.words[id].matched   = -1
		this.words[id].word      = node.children[0].innerHTML
		this.words[id].longWord  = node.children[0].innerHTML.length>18
		this.words[id].node      = node

	selectWord : (id) ->
		if this.words[id].node.className is 'word matched'
			this.words[id].node.className  = 'word matched selected'
		else this.words[id].node.className = 'word selected'

		this.words[id].selected = true

	unSelectWord : (id) ->
		# If the word is matched, unselected but retain its matching.
		if this.words[id].node.className is 'word matched selected'
			this.words[id].node.className  = 'word matched'
		else this.words[id].node.className = 'word'

		Matching.Data.words[id].selected = false

	matchWords : (id1, id2) ->
		# Handle potential unmatching.
		this.unMatchWords(id1)
		this.unMatchWords(id2)

		this.words[id1].node.className = 'word matched m-anim'
		this.words[id2].node.className = 'word matched m-anim'

		# Store the keys of each word's partner.
		this.words[id1].matched = id2
		this.words[id2].matched = id1

		# Remove the selected status.
		this.words[id1].selected = false
		this.words[id2].selected = false

		Matching.Draw.updateProgressBar('up')
		Matching.Draw.updateRemaining('down')

	stripMatchAnimation : (id1, id2) ->
		this.words[id1].node.className = 'word matched'
		this.words[id2].node.className = 'word matched'

	unMatchWords : (id) ->
		if this.words[id].matched > -1
			Matching.Draw.unMatchAnimation(this.words[id].matched)

			this.words[this.words[id].matched].matched = -1
			this.words[this.words[id].matched].node.className = "word"

			Matching.Draw.updateProgressBar('down')
			Matching.Draw.updateRemaining('up')
	
	oppositeSelected : (id) ->
		_start = if id%2 is 0 then 1 else 0
		for i in [_start..this.words.length-1] by 2
			if this.words[id].gameboard is this.words[i].gameboard && this.words[i].selected == true
				return i
		return false

	colorReset : () ->
		this.game.hue += 0.15
		if (this.game.hue > 1) then this.game.hue = 0.01
		this.game.randomColor = this.HSVtoRGB(this.game.hue, 0.5, 0.95)

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
