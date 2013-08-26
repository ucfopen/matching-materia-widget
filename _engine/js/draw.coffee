Namespace('Matching').Draw = do ->
	regexNonDigit = /[^0-9\.]+/g

	# Arrays to store circles and lines.
	words                = []
	paper                = []

	progressBar          = null
	progressBarWidth     = 0

	# Variables for dragging.
	downX                = null
	downY                = null
	deltaX               = null
	deltaY               = null
	pointerX             = null
	pointerY             = null
	pointerdown          = false
	inRectangle          = false
	animating            = false
	first                = false
	dragId               = -1
	dragEndId            = null

	# Color variables.
	hue                  = Math.random()
	randColor            = null
	grey                 = '#5b656d'
	darkGreen            = '#27AE60'
	lightGreen           = '#1ABC9C'

	_totalQuestions      = null
	_remainingQuestions  = null

	# Event handling.
	_ms     = window.navigator.msPointerEnabled
	_mobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/

	downEventType = switch
		when _ms     then "MSPointerDown"
		when _mobile then "touchstart"
		else              "mousedown"
	moveEventType = switch
		when _ms     then "MSPointerMove"
		when _mobile then "touchmove"
		else              "mousemove"
	upEventType = switch
		when _ms     then "MSPointerUp"
		when _mobile then "touchend"
		else              "mouseup"
	enterEventType = switch
		when _ms     then "MSPointerEnter"
		when _mobile then "touchmove"
		else              "mouseenter"
	leaveEventType = switch
		when _ms     then "MSPointerLeave"
		when _mobile then "touchend"
		else              "mouseleave"

	setEventListeners = ->
		# Disable right click and page scrolling on tablets.
		document.oncontextmenu = -> false
		document.addEventListener 'mousedown', (e) -> if e.button is 2 then false else true
		document.addEventListener 'touchmove', (e) -> e.preventDefault()

		document.addEventListener downEventType, (e) ->
			target  = e.target
			$target = $(target)

			if $target.hasClass('word') or $target.hasClass('popup-text')
				if not animating
					inRectangle = true
					pointerdown = true
					downX = e.pageX
					downY = e.pageY
					dragId = target.id.replace regexNonDigit, ''
					rectPointerDown(dragId)
			else if target.id == 'prev-button'
				Matching.Engine.handlePrevButton()
			else if target.id == 'next-button'
				Matching.Engine.handleNextButton()
			else if target.id == 'submit-button'
				Matching.Engine.handleSubmitButton()

		document.addEventListener moveEventType, (e) ->
			if pointerdown
				pointerX = e.pageX
				pointerY = e.pageY

				deltaX = Math.abs(downX-pointerX)
				deltaY = Math.abs(downY-pointerY)

				if deltaX > 2 or deltaY > 2 then startDrag()

		document.addEventListener upEventType, (e) ->
			animating = true
			setTimeout ->
				animating = false
			, 400

			if _mobile
				e.preventDefault()
				e.stopPropagation()
				target = document.elementFromPoint(pointerX, pointerY)
			else
				target = e.target
			$target = $(target)

			if $target.hasClass('word') or $target.hasClass('popup-text')
				dragEndId = target.id.replace regexNonDigit, ''
				rectPointerUp(dragEndId)

			downX       = null
			downY       = null
			first       = true
			pointerdown = false

			# The drag id represents the id of the selected word.
			# The end drag id represents the word that will be matched with the selected word.
			if dragId > -1 and not inRectangle then returnCircle()
			else if dragId > -1 and (dragEndId%2) == (dragId%2) then returnCircle()
			dragId = -1
			dragEndId = -1

		$(document)
		.on enterEventType, '.word', (e) ->
			_id = e.target.id.replace regexNonDigit, ''
			if words[_id].longWord then animatePopupIn(this.id)
			inRectangle = true
			words[_id].hollowCircle.transition()
				.attr('r', 13).duration(400).ease('elastic')

		.on leaveEventType, '.word', (e) -> 
			_id = e.target.id.replace regexNonDigit, ''
			if words[_id].longWord then animatePopupOut(this.id)
			inRectangle = false
			words[_id].hollowCircle.transition()
				.attr('r', 10).duration(400).ease('elastic')
				

		randColor = hsvToRgb(hue, 0.5, 0.95)

	setWordObject = (paper, id, column, gameboard, i) ->
		x = if column is 1 then 270 else 480
		tempObj = document.getElementById('w'+id)

		paper.append('g').attr('class', 'g'+id)

		words[id] =
			id           : id
			column       : column
			gameboard    : gameboard
			selected     : false
			matched      : -1
			line         : paper.select('.g'+id).append('line')
								.attr('x1', x).attr('y1', (i+1)*70.3+65).attr('x2', x).attr('y2', (i+1)*70.3+65)
			hollowCircle : paper.select('.g'+id).append('circle')
								.attr('class', 'hollow-circle')
								.attr('cx', x).attr('cy', (i+1)*70.3+65).attr('r', 10)
			holderCircle : paper.select('.g'+id).append('circle')
								.attr('class', 'holder-circle c'+id)
								.attr('cx', x).attr('cy', (i+1)*70.3+65).attr('r', 0)
			innerCircle  : paper.select('.g'+id).append('circle')
								.attr('class', 'inner-circle c'+id)
								.attr('cx', x).attr('cy', (i+1)*70.3+65).attr('r', 0)
			circleGroup  : paper.select('.g'+id).selectAll('.c'+id)
			word         : tempObj.children[0].innerHTML
			longWord     : tempObj.children[0].innerHTML.length>18
			DOMelement   : tempObj

	getWords = ->
		return words

	startDrag = ->
		if words[dragId].matched < 0
			words[dragId].innerCircle.attr('cx', pointerX).attr('cy', pointerY)
			words[dragId].line.attr('x2', pointerX).attr('y2', pointerY)

	# Brings a dragged circle back to its original position if not matched.
	returnCircle = ->
		words[dragId].innerCircle.transition()
			.attr('cx', words[dragId].holderCircle.attr('cx'))
			.attr('cy', words[dragId].holderCircle.attr('cy'))
			.duration(500).ease('elastic')
		words[dragId].line.transition()
			.attr('x2', words[dragId].holderCircle.attr('cx'))
			.attr('y2', words[dragId].holderCircle.attr('cy'))
			.duration(500).ease('elastic')

	# Brings into view a popup for long strings.
	animatePopupIn = (id) ->
		popup = document.getElementById(id).children[2]

		popup.style.display = 'block'
		setTimeout ->
			popup.className = 'popup-text shown'
		, 5

	animatePopupOut = (id) ->
		popup = document.getElementById(id).children[2]

		popup.className = 'popup-text'
		setTimeout ->
			popup.style.display = 'none'
		, 300

	rectPointerDown = (id) ->
		# A word within the same column is already selected.
		for i in [0..words.length-1]
			if words[id].gameboard == words[i].gameboard && words[id].column == words[i].column && words[i].selected == true && i != id
				unSelectWord(i)
				contractCircle(i)
				break
		# The focused word is matched.
		if words[id].matched > -1
			unMatchingAnimation(id)
			unMatchWords(id)
			selectWord(id)

		# A word within the opposite column is selected.
		for i in [0..words.length-1]
			if words[id].gameboard == words[i].gameboard && words[id].column != words[i].column && words[i].selected == true
				unSelectWord(id, i)
				matchWords(id, i)
				matchingAnimation(id)
				break

		if words[id].matched == -1
			selectWord(id)
			swellCircle(id)

	rectPointerUp = (id) ->
		# The focused word is in the opposite column.
		if dragId > -1 && dragEndId > -1 && dragId%2 != dragEndId%2
			# The focused word is already matched.
			if words[dragEndId].matched > -1
				unMatchingAnimation(dragEndId)
				unMatchWords(dragEndId)
			# The focused word isn't matched.
			if words[dragEndId].matched == -1
				unSelectWord(dragId, dragEndId)
				matchWords(dragId, dragEndId)
				matchingAnimation(dragEndId)

	unMatchWords = (id) ->
		# Remove the matched class from the pair of words.
		words[id].DOMelement.className = "word selected"
		words[words[id].matched].DOMelement.className = "word"

		# Reverse the matching animation.
		unMatchingAnimation(id)
		updateProgressBar('down')
		assessRemainingQuestions('increased')

		# Remove word pairing.
		words[words[id].matched].matched = -1
		words[id].matched = -1

	matchWords = (id1, id2) ->
		# Add a matched status to both words.
		words[id1].DOMelement.className = 'word matched'
		words[id2].DOMelement.className = 'word matched'

		# Store the keys of each word's partner.
		words[id1].matched = id2
		words[id2].matched = id1

		updateProgressBar('up')
		assessRemainingQuestions('decreased')

	unSelectWord = () -> # Accepts variable number of arguments.
		for i in [0..arguments.length-1]
			words[arguments[i]].DOMelement.className = 'word'
			words[arguments[i]].selected = false

	selectWord = (id) ->
		words[id].DOMelement.className = 'word selected'
		words[id].selected = true

	matchingAnimation = (id) ->
		# Transition circles to a matched color.
		words[words[id].matched].hollowCircle.transition().style('stroke', grey).duration(200)
		words[words[id].matched].holderCircle.transition().style('stroke', randColor).style('fill', randColor).duration(200)

		words[id].hollowCircle.transition().style('stroke', grey).duration(200)
		words[id].holderCircle.transition().style('stroke', randColor).style('fill', randColor).duration(200)

		# Move the first selected word's circle to the socket of the second selected word.
		words[words[id].matched].innerCircle.transition()
			.style('stroke', randColor).style('fill', randColor)
			.attr('r', 5)
			.attr('cx', words[id].holderCircle.attr('cx'))
			.attr('cy', words[id].holderCircle.attr('cy'))
			.duration(500).ease('bounce')

		words[id].holderCircle.transition()
			.attr('r', 0)
			.duration(20)
		words[id].innerCircle.transition()
			.attr('r', 0)
			.duration(20)

		# Animate the line with the circle.
		words[words[id].matched].line.transition()
			.style('stroke', grey)
			.attr('x2', words[id].holderCircle.attr('cx'))
			.attr('y2', words[id].holderCircle.attr('cy'))
			.duration(500).ease('bounce')

		# Reset the inner circle matched color.
		randColorReset()

	unMatchingAnimation = (id) ->
		words[words[id].matched].circleGroup.transition()
			.style('stroke', darkGreen).style('fill', darkGreen)
			.attr('r', 0)
			.duration(200)
		words[words[id].matched].hollowCircle.transition()
			.style('stroke', lightGreen)
			.duration(200)

		# The word that we clicked has a circle that's not in its home. Let's bring it home.
		if words[id].innerCircle.attr('cx') != words[id].holderCircle.attr('cx')
			words[id].innerCircle
				.transition()
					.style('stroke', darkGreen).style('fill', darkGreen)
					.attr('cx', words[id].holderCircle.attr('cx'))
					.attr('cy', words[id].holderCircle.attr('cy'))
					.duration(500).ease('elastic')
				.transition()
					.attr('r', 0)
					.duration(200).ease('none')

			words[id].line.transition()
				.style('stroke', darkGreen).style('fill', darkGreen)
				.attr('x2', words[id].holderCircle.attr('cx'))
				.attr('y2', words[id].holderCircle.attr('cy'))
				.duration(500).ease('elastic')
		else
			words[words[id].matched].innerCircle
				.transition()
					.style('stroke', darkGreen).style('fill', darkGreen)
					.attr('cx', words[words[id].matched].holderCircle.attr('cx'))
					.attr('cy', words[words[id].matched].holderCircle.attr('cy'))
					.ease('elastic')
					.duration(500)
				.transition()
					.attr('r', 0)
					.duration(200).ease('none')

			words[words[id].matched].line.transition()
				.style('stroke', darkGreen).style('fill', darkGreen)
				.attr('x2', words[words[id].matched].holderCircle.attr('cx'))
				.attr('y2', words[words[id].matched].holderCircle.attr('cy'))
				.duration(500).ease('elastic')

	swellCircle = (id) ->
		words[id].circleGroup.style('stroke', darkGreen).style('fill', darkGreen).transition().attr('r', '5').attr('stroke-width', 2).duration(200)
		words[id].hollowCircle.transition().style('stroke', darkGreen).duration(200)

	contractCircle = (id) ->
		words[id].circleGroup.transition().attr('r', '0').duration(200)
		words[id].hollowCircle.transition().style('stroke', lightGreen).duration(200)

	# Converts an HSV color to RGB. Equation for conversion can be found at:
	# http://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV
	hsvToRgb = (h, s, v) ->
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

	# Increments circle colors so that repeats are not found on the same page.
	randColorReset = ->
		hue += 0.15
		if hue > 1 then hue = 0.01
		randColor = hsvToRgb(hue, 0.5, 0.95)

	# Progress Bar Methods
	drawProgressBar = ->
		_totalQuestions = Matching.Engine.getTotalQuestions()
		_remainingQuestions = _totalQuestions
		progressBar = paper[paper.length-1].append('rect')
			.attr('x', 0).attr('y', 0)
			.attr('width', 0).attr('height', 10)
			.attr('rx', 5).attr('ry', 5)
			.style('stroke-width', 1)
			.style('stroke', '#BDC3C7')
			.style('fill', '#BDC3C7')

	updateProgressBar = (direction) ->
		if direction is 'up'
			progressBar.transition().attr('width', progressBarWidth += (160/_totalQuestions)).duration(600).ease('bounce')
		else if direction is 'down'
			progressBar.transition().attr('width', progressBarWidth -= (160/_totalQuestions)).duration(600).ease('bounce')

	assessRemainingQuestions = (questions) ->
		if questions is 'increased' and _remainingQuestions is 0
			document.getElementById('submit-button').className = 'unselectable'

		if questions is 'increased' then _remainingQuestions++
		if questions is 'decreased' then _remainingQuestions--

		if _remainingQuestions == 0
			document.getElementById('submit-button').className = ''

	# Public properties:
	paper: paper

	# Public methods:
	setEventListeners : setEventListeners
	getWords          : getWords
	animatePopupOut   : animatePopupOut
	animatePopupIn    : animatePopupIn
	setWordObject     : setWordObject
	drawProgressBar   : drawProgressBar
