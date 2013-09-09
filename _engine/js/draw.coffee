Namespace('Matching').Draw = do ->

	# Environmental conditions.
	_ms     = window.navigator.msPointerEnabled
	_mobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/

	inPopup = false

	# Event types will adapt to different input types.
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

	regexNonDigit = /[^0-9\.]+/g

	# Colors.
	darkGreen  = '#27AE60'
	darkBlue   = '#283845'
	lightGreen = '#1ABC9C'
	grey       = '#5b656d'

	_progressBar        = null
	_progressBarWidth   = 0
	_remainingItems     = null
	_totalItems         = null

	pointerX = null
	pointerY = null
	downId   = null
	upId     = null

	setEventListeners = () ->
		document.addEventListener downEventType, (event) ->
			target = event.target
			switch target.tagName
				when "LI"
					downId = target.id.replace regexNonDigit, ''
					_handleDownEvent(downId)
				when "DIV"
					downId = target.parentNode.id.replace regexNonDigit, ''
					_handleDownEvent(downId)
			switch target.id
				when 'prev-button' then Matching.Engine.handlePrevButton()
				when 'next-button' then Matching.Engine.handleNextButton()
				when 'submit-button' then Matching.Engine.handleSubmitButton()

		# Replaces the "Up" event type.
		Hammer(document).on 'release', (event) ->
			target = event.target
			switch target.tagName
				when "LI"
					upId = target.id.replace regexNonDigit, ''
					_handleUpEvent(upId)
				when "DIV"
					upId = target.parentNode.id.replace regexNonDigit, ''
					_handleUpEvent(upId)

		#### TODO: Only limited dragging exists. Implement better dragging. ####
		# Will pickup drag events from most inputs including touch and mouse.
		Hammer(document).on 'drag', (event) ->
			if event.gesture.startEvent.target.tagName is 'LI'
				pointerX = event.gesture.center.pageX
				pointerY = event.gesture.center.pageY

				if Matching.Data.words[downId].matched < 0 && not Matching.Data.gates.inColumn
					Matching.Data.words[downId].preinnerCircle
						.style('opacity', 1)
						.attr('cx', pointerX).attr('cy', pointerY)
					Matching.Data.words[downId].preline
						.style('opacity', 1)
						.attr('x2', pointerX).attr('y2', pointerY)

		if _mobile
			# Prevents scrolling.
			document.addEventListener 'touchmove', (e) -> e.preventDefault()

			Hammer(document).on 'touch', (event) ->
				#### TODO: code to replace mouseenter, mouseleave for mobile devices. ####

		else
			# Disables right click.
			document.oncontextmenu = -> false
			document.addEventListener 'mousedown', (e) -> if e.button is 2 then false else true

			document.addEventListener 'mouseover', (event) ->
				target = event.target
				switch target.tagName
					when "DIV" then inPopup = true
					when "LI"  then _handleEnterEvent(target)
					when "svg" then if Matching.Data.gates.prelineDrawn then _fadePreline()
					when "UL"  then Matching.Data.gates.inColumn = true

			document.addEventListener 'mouseout', (event) ->
				target = event.target
				switch target.tagName
					when "DIV" then inPopup = false; _handleLeaveEvent(target.parentNode)
					when "LI"  then setTimeout ->
						if not inPopup then  _handleLeaveEvent(target)
					, 5
					when "UL"  then Matching.Data.gates.inColumn = true

	reorderSVG = () ->
		d3.selection.prototype.moveToFront = () ->
			return this.each -> this.parentNode.appendChild(this)

		# Makes all inner circles the top nodes so that they overlap any lines.
		d3.select('body').selectAll('.inner-circle').each ->
			this.parentNode.appendChild(this)

	_handleEnterEvent = (target) ->
		Matching.Data.gates.inWord = true

		_id = target.id.replace regexNonDigit, ''
		Matching.Data.words[_id].hollowCircle.transition()
			.attr('r', 13).duration(400).ease('elastic')

		if Matching.Data.oppositeSelected(_id) isnt false
			_drawPreline(Matching.Data.words[downId], Matching.Data.words[_id])
		if Matching.Data.words[_id].longWord then animatePopupIn(target.id)

	_handleLeaveEvent = (target) ->
		Matching.Data.gates.inWord = false

		_id = target.id.replace regexNonDigit, ''
		Matching.Data.words[_id].hollowCircle.transition()
			.attr('r', 10).duration(400).ease('elastic')

			if Matching.Data.words[_id].longWord then animatePopupOut(target.id)

	_handleDownEvent = (id) ->
		if not Matching.Data.gates.animating
			# A word within the same column is already selected.
			_start = if id%2 is 0 then 0 else 1
			for i in [_start..Matching.Data.words.length-1] by 2
				if Matching.Data.words[id].gameboard == Matching.Data.words[i].gameboard && Matching.Data.words[i].selected == true && i != id
					Matching.Data.unSelectWord(i)
					if Matching.Data.words[i].node.className != 'word matched'
						_contractCircle(i)
					break

			Matching.Data.selectWord(id)
			_swellCircle(id)

	_handleUpEvent = (id) ->
		if not Matching.Data.gates.animating
			Matching.Data.gates.animating = true
			setTimeout ->
				Matching.Data.gates.animating = false
			, 300

			_start = if id%2 is 0 then 1 else 0
			_oppositeId = Matching.Data.oppositeSelected(id)
			if _oppositeId isnt false                        # A word within the opposite column is selected.
				Matching.Data.matchWords(id, _oppositeId)    # Register a new pairing.
				setTimeout ->
					Matching.Data.stripMatchAnimation(id, _oppositeId)
				, 500
				_matchAnimation(id)                          # Animate the new pairing.

	_drawPreline = (source, socket) ->
		source.preinnerCircle
			.attr('cx', socket.innerCircle.attr('cx'))
			.attr('cy', socket.innerCircle.attr('cy'))
			.transition()
				.style('opacity', 0.8)
				.duration(300)

		source.preline
			.attr('x2', socket.innerCircle.attr('cx'))
			.attr('y2', socket.innerCircle.attr('cy'))
			.transition()
				.style('opacity', 0.4)
				.duration(300)

		Matching.Data.gates.prelineDrawn = true

	_fadePreline = () ->
		Matching.Data.words[downId].preinnerCircle
			.transition()
				.style('opacity', 0)
				.duration(300)
		Matching.Data.words[downId].preline
			.transition()
				.style('opacity', 0)
				.duration(300)

	_matchAnimation = (id) ->
		# Fade out the pre-line and circle
		Matching.Data.words[Matching.Data.words[id].matched].preline.transition()
			.style('opacity', 0).duration(300)
		Matching.Data.words[Matching.Data.words[id].matched].preinnerCircle.transition()
			.style('opacity', 0).duration(300)

		# Fade the hollow circles to the matched color.
		Matching.Data.words[Matching.Data.words[id].matched].hollowCircle.transition()
			.style('stroke', grey).duration(200)
		Matching.Data.words[id].hollowCircle.transition()
			.style('stroke', grey).duration(200)

		# Fade in the inner circles.
		Matching.Data.words[id].innerCircle
			.style('stroke', Matching.Data.game.randomColor).style('fill', Matching.Data.game.randomColor)
		Matching.Data.words[id].innerCircle
			.transition()
				.style('opacity', 1)
				.duration(300)
		Matching.Data.words[Matching.Data.words[id].matched].innerCircle
			.style('stroke', Matching.Data.game.randomColor).style('fill', Matching.Data.game.randomColor)
		Matching.Data.words[Matching.Data.words[id].matched].innerCircle
			.transition()
				.style('opacity', 1)
				.duration(300)

		# Fade in the connecting line.
		if id%2 is 0 then Matching.Data.words[id].line
			.attr('x2', Matching.Data.words[Matching.Data.words[id].matched].innerCircle.attr('cx'))
			.attr('y2', Matching.Data.words[Matching.Data.words[id].matched].innerCircle.attr('cy'))
			.transition()
				.style('opacity', 1)
				.duration(500)
		else Matching.Data.words[Matching.Data.words[id].matched].line
			.attr('x2', Matching.Data.words[id].innerCircle.attr('cx'))
			.attr('y2', Matching.Data.words[id].innerCircle.attr('cy'))
			.transition()
				.style('opacity', 1)
				.duration(500)

		Matching.Data.colorReset()

	unMatchAnimation = (id) ->
		Matching.Data.words[id].innerCircle
			.transition()
				.style('opacity', 0)
				.duration(500)

		Matching.Data.words[id].hollowCircle
			.transition()
				.style('stroke', lightGreen)
				.duration(500)

		if id%2 is 1
			Matching.Data.words[Matching.Data.words[id].matched].line
				.transition()
					.style('opacity', 0)
					.duration(500)
		else 
			Matching.Data.words[id].line
				.transition()
					.style('opacity', 0)
					.duration(500)

	_swellCircle = (id) ->
		if Matching.Data.words[id].matched > -1
			Matching.Data.words[id].hollowCircle
				.transition()
					.style('stroke', darkBlue)
					.duration(200)
		else
			Matching.Data.words[id].innerCircle
				.style('fill', darkGreen).style('stroke', darkGreen)
				.transition()
					.style('opacity', 1)
					.duration(200)

			Matching.Data.words[id].hollowCircle
				.transition()
					.style('stroke', darkGreen)
					.duration(200)

	_contractCircle = (id) ->
		Matching.Data.words[id].innerCircle
			.transition()
				.style('opacity', 0)
				.duration(200)

		Matching.Data.words[id].hollowCircle
			.transition()
				.style('stroke', lightGreen)
				.duration(200)

	animatePopupIn = (id) ->
		popup = document.getElementById(id).children[1]

		popup.style.display = 'block'
		setTimeout ->
			popup.className = 'popup-text shown'
		, 5

	animatePopupOut = (id) ->
		popup = document.getElementById(id).children[1]

		popup.className = 'popup-text'
		setTimeout ->
			popup.style.display = 'none'
		, 300

	drawProgressBar = () ->
		Matching.Data.svgNodes.push d3.select('body').select('#questions-answered').select('svg')

		_totalItems     = Matching.Data.game.totalItems
		_remainingItems = Matching.Data.game.totalItems
		_progressBar    = Matching.Data.svgNodes[Matching.Data.svgNodes.length-1].append('rect')
			.attr('x', 0).attr('y', 0)
			.attr('width', 0).attr('height', 10)
			.attr('rx', 5).attr('ry', 5)
			.style('stroke-width', 1)
			.style('stroke', '#BDC3C7')
			.style('fill', '#BDC3C7')

	updateProgressBar = (direction) ->
		if direction is 'up'
			_progressBar.transition().attr('width', _progressBarWidth += (160/_totalItems)).duration(600).ease('bounce')
		else if direction is 'down'
			_progressBar.transition().attr('width', _progressBarWidth -= (160/_totalItems)).duration(600).ease('bounce')

	updateRemaining = (questions) ->
		if questions is 'up' and _remainingItems is 0
			document.getElementById('submit-button').className = 'unselectable'

		if questions is 'up'   then _remainingItems++
		if questions is 'down' then _remainingItems--

		if _remainingItems is 0
			document.getElementById('submit-button').className = 'glowing'

	# Public
	setEventListeners : setEventListeners
	reorderSVG        : reorderSVG
	animatePopupIn    : animatePopupIn
	animatePopupOut   : animatePopupOut
	unMatchAnimation  : unMatchAnimation
	drawProgressBar   : drawProgressBar
	updateProgressBar : updateProgressBar
	updateRemaining   : updateRemaining



