angular.module('matching', [])
.controller('matchingPlayerCtrl', ['$scope', '$timeout', '$sce', function($scope, $timeout, $sce) {
	const materiaCallbacks = {};
	$scope.title = '';

	$scope.items = [];
	$scope.pages = [];
	$scope.selectedQA = [];
	$scope.matches = [];
	$scope.prelines = [];

	$scope.lines = [];
	$scope.questionCircles = [];
	$scope.answerCircles = [];

	$scope.totalPages = 1;
	$scope.currentPage = 0;
	$scope.totalItems = 0;
	$scope.setCreated = false;

	$scope.isMobile = false

	$scope.completePerPage = [];

	$scope.qset = {};

	$scope.showInstructions = false;

	// these are used for animation
	$scope.pageAnimate = false;
	$scope.pageNext = false;
	const ANIMATION_DURATION = 600;

	let colorNumber = 0;

	const ITEMS_PER_PAGE = 6;
	const NUM_OF_COLORS = 7;
	const CIRCLE_START_X = 20;
	const CIRCLE_END_X = `100%`;
	const LINE_END_X = `95%`;
	const CIRCLE_RADIUS = 10;
	const CIRCLE_SPACING = 72;
	const CIRCLE_OFFSET = 29;
	const PROGRESS_BAR_LENGTH = 160;
	const MOBILE_PX = 576;

	// uses percents to scale the value w/ mobile height changes
	// perPage values are needed because the svg column scales to the size of the word cols
	const _getCircleY = (index, perPage) => {return `${((index+0.6) / perPage) * 100}%`}

	// called when the height of the words are changed,
	// rescales the SVG holder element to the size of the button columns
	const _rescaleSVG = (skipApply) => {
		document.getElementById("holder").style.height = `calc(${window.getComputedStyle(document.getElementsByClassName("column1").item(0)).height} + ${16}px)`
		if(!skipApply)
			$scope.$apply();
	}

	const _boardElement = document.getElementById('gameboard');

	materiaCallbacks.start = function(instance, qset) {
		$scope.qset = qset;
		$scope.title = instance.name;
		$scope.isMobile = window.innerHeight < MOBILE_PX;

		// handle sizing transitions
		window.addEventListener("resize", ()=>{
			
			let newMobile = window.innerWidth < MOBILE_PX;
			if(newMobile != $scope.isMobile) {
				$scope.isMobile = newMobile
				setTimeout(()=> {
					_rescaleSVG()
					_updateLines()
					$scope.$apply();
				}, 300)
			} else {
				_updateLines()
				$scope.$apply()
			}
			
		})

		// Update qset items to only include the number of questions specified in the question bank. Done here since $scope.totalItems depends on it.
		if (qset.options && qset.options.enableQuestionBank) {
			_shuffle(qset.items[0].items);
			const qbItemsLength = qset.options.questionBankVal;
			const rndStart = Math.floor(Math.random() * ((qset.items[0].items.length - qbItemsLength) + 1));
			qset.items[0].items = qset.items[0].items.slice(rndStart, rndStart + qbItemsLength);
		}

		$scope.totalItems = qset.items[0].items.length;
		$scope.totalPages = Math.ceil($scope.totalItems/ITEMS_PER_PAGE);

		document.title = instance.name + ' Materia widget';

		// set up the pages
		for (let i = 1, end = $scope.totalPages, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
			$scope.pages.push({questions:[], answers:[]});
			$scope.selectedQA.push({question:-1, answer:-1});
			$scope.questionCircles.push([]);
			$scope.answerCircles.push([]);
			$scope.completePerPage.push(0);
		}

		let _itemIndex = 0;
		let _pageIndex = 0;
		let _indexShift = 0;

		// Splits the the last items over the last two pages
		const _leftover = $scope.totalItems % ITEMS_PER_PAGE;
		let _splitPoint = ~~(4 + ((_leftover - 1)/2));
		if (_leftover === 0) {
			_splitPoint = -1;
		}

		for (var item of Array.from(qset.items[0].items)) {
			
			if ((_itemIndex === ITEMS_PER_PAGE) || ((_pageIndex === ($scope.totalPages - 2)) && (_itemIndex === _splitPoint))) {
				_shuffle($scope.pages[_pageIndex].questions);
				_shuffle($scope.pages[_pageIndex].answers);
				_itemIndex = 0;
				_indexShift = 0;
				_pageIndex++;
			}

			// computes number of items we are adding in this page
			// needed for scaling spacing between matching lines

			let curCount = ITEMS_PER_PAGE
			let tSplitPoint = _splitPoint == -1 ? 0 : _splitPoint
			let tLeftover = _leftover == 0 ? ITEMS_PER_PAGE : _leftover
			if (_pageIndex === ($scope.totalPages - 2)) {
				curCount = _splitPoint == -1 ? ITEMS_PER_PAGE : _splitPoint
			} else if (_pageIndex === ($scope.totalPages - 1)) {
				if ($scope.totalItems <= ITEMS_PER_PAGE)
					curCount = tLeftover
				else
					curCount = ITEMS_PER_PAGE - tSplitPoint + _leftover
			}

			var wrapQuestionUrl = function() {
				if (item.assets && ((item.assets != null ? item.assets[0] : undefined) !== 0) && ((item.assets != null ? item.assets[0] : undefined) !== undefined)) { // for qsets published after this commit, this value will be 0, for older qsets it's undefined
					return $sce.trustAsResourceUrl(Materia.Engine.getImageAssetUrl(item.assets[0]));
				}
			};

			$scope.pages[_pageIndex].questions.push({
				text: item.questions[0].text ? item.questions[0].text : '[No Text Provided!]',
				id: item.id,
				pageId: _pageIndex,
				type: 'question',
				asset: wrapQuestionUrl()
			});

			//qEl = document.getElementById("q0/0")

			$scope.questionCircles[_pageIndex].push({
				r:CIRCLE_RADIUS,
				cx: CIRCLE_START_X,
				cy: _getCircleY(_itemIndex, curCount),
				id:_itemIndex,
				isHover: false,
				lightHover: false,
				type: 'question-circle',
				color: 'c0'
			});

			/*
			disabling this because fakeouts are not implemented
			* adjust if this is a 'fakeout' answer option
			if ( !Array.isArray(item.assets) or item.assets?[1] == 0) and not item.answers[0].text.length
				_itemIndex++
				_indexShift++
				$scope.totalItems--
				continue
			*/

			var wrapAnswerUrl = function() {
				if (((item.assets != null ? item.assets[1] : undefined) !== 0) && ((item.assets != null ? item.assets[1] : undefined) !== undefined)) { // for qsets published after this commit, this value will be 0, for older qsets it's undefined
					return $sce.trustAsResourceUrl(Materia.Engine.getImageAssetUrl(item.assets[1]));
				}
			};

			$scope.pages[_pageIndex].answers.push({
				text: item.answers[0].text ? item.answers[0].text : '[No Text Provided!]',
				id: item.id,
				pageId: _pageIndex,
				type: 'answer',
				asset: wrapAnswerUrl()
			});

			$scope.answerCircles[_pageIndex].push({
				r:CIRCLE_RADIUS,
				cx: CIRCLE_END_X,
				cy: _getCircleY(_itemIndex, curCount),
				id:_itemIndex,
				isHover: false,
				lightHover: false,
				type: 'answer-circle',
				color: 'c0'
			});

			_itemIndex++;
		}

		// final shuffling for last page
		_shuffle($scope.pages[_pageIndex].questions);
		_shuffle($scope.pages[_pageIndex].answers);
		$scope.setCreated = true;

		Materia.Engine.setHeight();
		$scope.$apply();

		_rescaleSVG()
	};

	$scope.changePage = function(direction) {
		if ($scope.pageAnimate) { return false; }
		_clearSelections();

		// pageAnimate is used by the li elements and the rotating circle, also sets footer onTop
		$scope.pageNext = (direction === 'next');
		$scope.pageAnimate = true;
		$timeout(function() {
			if (direction === 'previous') {
				if (!($scope.currentPage <= 0)) { $scope.currentPage--; }
			}
			if (direction === 'next') {
				if (!($scope.currentPage >= ($scope.totalPages - 1))) { $scope.currentPage++; }
			}

			document.getElementById("holder").style.opacity = 0
		}

		, ANIMATION_DURATION/3);

		$timeout(() => {
			$scope.pageAnimate = false
			_rescaleSVG()
			document.getElementById("holder").style.opacity = 1
		}
		, ANIMATION_DURATION*1.05);

		if (_boardElement) { _boardElement.focus(); }
		if (direction === 'next') { _assistiveNotification('Page incremented.');
		} else if (direction === 'previous') { _assistiveNotification('Page decremented.'); }
	};


	$scope.checkForQuestionAudio = index => $scope.pages[$scope.currentPage].questions[index].asset !== undefined;

	$scope.checkForAnswerAudio = index => $scope.pages[$scope.currentPage].answers[index].asset !== undefined;

	const _pushMatch = function() {
		$scope.matches.push({
			questionId: $scope.selectedQuestion.id,
			questionIndex: $scope.selectedQA[$scope.currentPage].question,
			answerId: $scope.selectedAnswer.id,
			answerIndex: $scope.selectedQA[$scope.currentPage].answer,
			matchPageId: $scope.currentPage
		});

		if ($scope.matches.length === $scope.totalItems) { _assistiveAlert('All matches complete. The done button is now available.'); }
	};

	const _applyCircleColor = function() {
		// find appropriate circle
		$scope.questionCircles[$scope.currentPage][$scope.selectedQA[$scope.currentPage].question].color = _getColor();
		$scope.answerCircles[$scope.currentPage][$scope.selectedQA[$scope.currentPage].answer].color = _getColor();
	};

	var _getColor = () => 'c' + colorNumber;

	const _checkForMatches = function() {
		if (($scope.selectedQA[$scope.currentPage].question !== -1) && ($scope.selectedQA[$scope.currentPage].answer !== -1)) {
			// check if the id already exists in matches
			let match1_AIndex, match1_QIndex, match2_AIndex, match2_QIndex;
			const clickQuestionId = $scope.selectedQuestion.id;
			const clickAnswerId = $scope.selectedAnswer.id;

			// increment color cycle
			colorNumber = (colorNumber+1)%NUM_OF_COLORS;
			if (colorNumber === 0) {
				colorNumber = 1;
			}

			// if the id of the question exists in a set of matches, delete that set of matches
			// get the index of the match where the question/answer exists
			const indexOfQuestion = $scope.matches.map(element => element.questionId).indexOf(clickQuestionId);
			const indexOfAnswer = $scope.matches.map(element => element.answerId).indexOf(clickAnswerId);

			if (indexOfQuestion >= 0) {
				match1_QIndex = $scope.matches[indexOfQuestion].questionIndex;
				match1_AIndex = $scope.matches[indexOfQuestion].answerIndex;
			}

			if (indexOfAnswer >= 0) {
				match2_QIndex = $scope.matches[indexOfAnswer].questionIndex;
				match2_AIndex = $scope.matches[indexOfAnswer].answerIndex;
			}

			// if both question and answer are in matches then take out where they exist in matches
			if ((indexOfQuestion !== -1) && (indexOfAnswer !== -1)) {
				// need to account here for the indexOfQuestion and indexOfAnswer being the same
				$scope.questionCircles[$scope.currentPage][match1_QIndex].color = 'c0';
				$scope.questionCircles[$scope.currentPage][match2_QIndex].color = 'c0';

				$scope.answerCircles[$scope.currentPage][match1_AIndex].color = 'c0';
				$scope.answerCircles[$scope.currentPage][match2_AIndex].color = 'c0';

				$scope.matches.splice(indexOfQuestion, 1);
				// only proceed to do the following if the index of question and answer
				// are not the same- otherwise an extra pair will be deleted
				if (indexOfQuestion !== indexOfAnswer) {
					if (indexOfAnswer > indexOfQuestion) {
						// we have to subtract 1 to account for the previous slice
						$scope.matches.splice(indexOfAnswer-1, 1);
					} else {
						// in this case we don't need to subtract to account for splice
						$scope.matches.splice(indexOfAnswer, 1);
					}
				}
			// only the question exists in a match
			} else if ((indexOfQuestion !== -1)  && (indexOfAnswer === -1)) {
				$scope.questionCircles[$scope.currentPage][match1_QIndex].color = 'c0';
				$scope.answerCircles[$scope.currentPage][match1_AIndex].color = 'c0';
				$scope.matches.splice(indexOfQuestion, 1);
			// only the answer exists in a match
			} else if ((indexOfQuestion === -1) && (indexOfAnswer !== -1)) {
				$scope.questionCircles[$scope.currentPage][match2_QIndex].color = 'c0';
				$scope.answerCircles[$scope.currentPage][match2_AIndex].color = 'c0';
				$scope.matches.splice(indexOfAnswer, 1);
			}

			_assistiveAlert($scope.pages[$scope.currentPage].questions[$scope.selectedQA[$scope.currentPage].question].text + ' matched with ' +
					$scope.pages[$scope.currentPage].answers[$scope.selectedQA[$scope.currentPage].answer].text
			);

			_pushMatch();

			_updateCompletionStatus();

			_applyCircleColor();

			_clearSelections();

			_updateLines();

			$scope.unapplyHoverSelections();

		} else if ($scope.selectedQA[$scope.currentPage].question !== -1) { _assistiveNotification($scope.selectedQuestion.text + ' selected.');
		} else if ($scope.selectedQA[$scope.currentPage].answer !== -1) { _assistiveNotification($scope.selectedAnswer.text + ' selected.'); }
	};

	var _clearSelections = function() {
		$scope.selectedQA[$scope.currentPage].question = -1;
		$scope.selectedQA[$scope.currentPage].answer = -1;
	};

	var _updateCompletionStatus = function() {
		$scope. completePerPage  = [];
		Array.from($scope.matches).map((match) =>
			!$scope.completePerPage[match.matchPageId] ? ($scope.completePerPage[match.matchPageId] = 1)
			: $scope.completePerPage[match.matchPageId]++);
	};

	var _updateLines = function() {
		$scope.lines = [];
		for (let i = 1, end = $scope.totalPages, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
			$scope.lines.push([]);
		}
		return (() => {
			const result = [];
			for (var match of Array.from($scope.matches)) {
				var targetStartY = $scope.questionCircles[match.matchPageId][match.questionIndex].cy;
				var targetEndY = $scope.answerCircles[match.matchPageId][match.answerIndex].cy;
				result.push($scope.lines[match.matchPageId].push({
					startX:CIRCLE_START_X,
					startY:targetStartY,
					endX:LINE_END_X,
					endY:targetEndY
				}));
			}
			return result;
		})();
	};

	$scope.getProgressAmount = function() {
		if ($scope.totalItems === 0) {
			return 0;
		}
		return ($scope.matches.length / $scope.totalItems) * PROGRESS_BAR_LENGTH;
	};

	$scope.applyCircleClass = function(selectionItem) {
		// selectionItem.id is the index of circle
		if (selectionItem.type === 'question-circle') {
			if (selectionItem.id === $scope.selectedQA[$scope.currentPage].question) {
				return true;
			}
		}
		if (selectionItem.type === 'answer-circle') {
			if (selectionItem.id === $scope.selectedQA[$scope.currentPage].answer) {
				return true;
			}
		}
		return false;
	};

	$scope.unapplyHoverSelections = function() {
		$scope.prelines = [];
		$scope.questionCircles[$scope.currentPage].forEach(function(element) {
			element.isHover = false;
			element.lightHover = false;
		});
		$scope.answerCircles[$scope.currentPage].forEach(function(element) {
			element.isHover = false;
			element.lightHover = false;
		});
	};

	// truthiness evaluated from function return
	$scope.isInMatch = function(item) {
		if (item.type === 'question') {
			return $scope.matches.some( match => match.questionId === item.id);
		}

		if (item.type === 'answer') {
			return $scope.matches.some( match => match.answerId === item.id);
		}

		return false;
	};

	$scope.getMatchWith = function(item) {
		if (item.type === 'question') {
			const a = $scope.matches.find( match => match.questionId === item.id);
			if (a) { return $scope.pages[a.matchPageId].answers[a.answerIndex].text; }

		} else if (item.type === 'answer') {
			const q = $scope.matches.find( match => match.answerId === item.id);
			if (q) { return $scope.pages[q.matchPageId].questions[q.questionIndex].text; }
		}
	};

	$scope.drawPrelineToRight = function(hoverItem) {
		const elementId = hoverItem.id;
		// get the index of the item in the current page by finding it with its id
		const endIndex = $scope.pages[$scope.currentPage].answers.map(function(element) {
			if(element !== undefined) {
				return element.id;
			}
			}).indexOf(elementId);

		// exit if a question has not been selected
		if ($scope.selectedQA[$scope.currentPage].question === -1) {
			$scope.answerCircles[$scope.currentPage][endIndex].lightHover = true;
			return;
		}

		const startIndex = $scope.selectedQA[$scope.currentPage].question;

		if ($scope.prelines.length > 0) {
			$scope.prelines = [];
		}

		$scope.prelines.push({
			// left column
			linex1 : $scope.questionCircles[$scope.currentPage][startIndex].cx,
			// right column
			linex2 : LINE_END_X,

			// left column
			liney1 : $scope.questionCircles[$scope.currentPage][startIndex].cy,
			// right column
			liney2 : $scope.answerCircles[$scope.currentPage][endIndex].cy
		});
		$scope.answerCircles[$scope.currentPage][endIndex].isHover = true;
	};

	$scope.drawPrelineToLeft = function(hoverItem) {
		const elementId = hoverItem.id;
		// get the index of the item in the current page by finding it with its id
		const endIndex = $scope.pages[$scope.currentPage].questions.map(function(element) {
			if(element !== undefined) {
				return element.id;
			}
		}).indexOf(elementId);

		// exit if a question has not been selected
		if ($scope.selectedQA[$scope.currentPage].answer === -1) {
			$scope.questionCircles[$scope.currentPage][endIndex].lightHover = true;
			return;
		}

		const startIndex = $scope.selectedQA[$scope.currentPage].answer;

		if ($scope.prelines.length > 0) {
			$scope.prelines = [];
		}

		$scope.prelines.push({
			// right column
			linex1 : LINE_END_X,
			// left column
			linex2 : $scope.questionCircles[$scope.currentPage][endIndex].cx,

			// right column
			liney1 : $scope.answerCircles[$scope.currentPage][startIndex].cy,
			// left column
			liney2 : $scope.questionCircles[$scope.currentPage][endIndex].cy
		});
		$scope.questionCircles[$scope.currentPage][endIndex].isHover = true;
	};

	$scope.selectQuestion = function(selectionItem) {
		const elementId = selectionItem.id;
		// get the index of the item in the current page by finding it with its id
		const indexId = $scope.pages[$scope.currentPage].questions.map(element => element.id).indexOf(elementId);
		// selectedQuestion allows us to find the item we want in our initialized question array at the specified index
		// selectedQuestion represents the question [left] column selection
		$scope.selectedQuestion = $scope.pages[$scope.currentPage].questions[indexId];
		// selectedQA stores the index of the current selected answer and question for a particular page
		$scope.selectedQA[$scope.currentPage].question = indexId;

		_checkForMatches();
	};

	$scope.selectAnswer = function(selectionItem) {
		const elementId = selectionItem.id;
		// get the index of the item in the current page by finding it with its id
		const indexId = $scope.pages[$scope.currentPage].answers.map(element => element.id).indexOf(elementId);
		// selectedAnswer allows us to find the item we want in our initialized question array at the specified index
		// selectedAnswer represents the answer [right] column selection
		$scope.selectedAnswer = $scope.pages[$scope.currentPage].answers[indexId];
		// selectedQA stores the index of the current selected answer and question for a particular page
		$scope.selectedQA[$scope.currentPage].answer = indexId;
		_checkForMatches();
	};

	// toggle keyboard instructions modal
	// certain actions have to be performed on the native dom element, not abstracted through angularjs
	// ng-attr-inert would retain the attribute, which must be completely removed to make elements non-inert again
	$scope.toggleInstructions = function() {
		switch ($scope.showInstructions) {
			case false:
				$timeout(function() {
					const dismissElement = document.getElementById('dialog-dismiss');
					if (dismissElement) { dismissElement.focus(); }
					if (_boardElement) { _boardElement.setAttribute('inert', true); }
				});
				break;

			case true:
				$timeout(function() {
					if (_boardElement) { _boardElement.removeAttribute('inert'); }
					const instructionsElement = document.getElementById('instructions-btn');
					if (instructionsElement) { instructionsElement.focus(); }
				});
				break;
		}

		return $scope.showInstructions = !$scope.showInstructions;
	};

	// manage keypress events when words are focused
	$scope.handleBoardKeypress = function(event, item = null) {
		let error;
		switch (event.key) {
			case 'Enter':
				if (item && (item.type === 'question')) { $scope.selectQuestion(item); }
				if (item && (item.type === 'answer')) { $scope.selectAnswer(item); }
				break;
			case 'ArrowLeft':
				try {
					if (item.type === 'answer') { document.getElementsByClassName('column1')[0].getElementsByClassName('word')[0].focus(); }
					event.preventDefault();
				} catch (error1) {
					error = error1;
					console.warn(error);
				}
				break;
			case 'ArrowRight':
				try {
					if (item.type === 'question') { document.getElementsByClassName('column2')[0].getElementsByClassName('word')[0].focus(); }
					event.preventDefault();
				} catch (error2) {
					error = error2;
					console.warn(error);
				}
				break;
		}
	};

	$scope.submit = function() {
		let asc, i;
		let end;
		const qsetItems = $scope.qset.items[0].items;

		for (i = 0, end = qsetItems.length-1, asc = 0 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
			// get id of the current qset item use that as the 1st argument
			// find the id of that qset item in the matches object array
			var mappedQsetAudioString, mappedQsetItemText;
			var matchedItem = $scope.matches.filter( match => match.questionId === qsetItems[i].id);
			if (matchedItem != null ? matchedItem.length : undefined) {
				var matchedItemAnswerId = matchedItem[0].answerId;
				// get the answer of that match at that question id and use that as the 2nd argument
				mappedQsetItemText = qsetItems.filter( item => item.id === matchedItemAnswerId)[0].answers[0].text;
				// the audioString should ONLY be provided if there is actually an audio asset present for the answer card - we check that by referencing assets[1]. Otherwise, pass null
				mappedQsetAudioString = qsetItems.filter( item => item.id === matchedItemAnswerId)[0].assets && (qsetItems.filter( item => item.id === matchedItemAnswerId)[0].assets[1] !== 0) ? qsetItems.filter( item => item.id === matchedItemAnswerId)[0].assets[2] : null;
			} else {
				mappedQsetItemText = null;
			}
			Materia.Score.submitQuestionForScoring(qsetItems[i].id, mappedQsetItemText, mappedQsetAudioString);
		}
		Materia.Engine.end(true);
	};

	var _shuffle = function(qsetItems) {
		// don't shuffle if less than 2 elements
		if (!(qsetItems.length >= 2)) { return qsetItems; }
		return (() => {
			const result = [];
			for (let index = 1, end = qsetItems.length-1, asc = 1 <= end; asc ? index <= end : index >= end; asc ? index++ : index--) {
				var ref;
				var randomIndex = Math.floor(Math.random() * (index + 1));
				result.push([qsetItems[index], qsetItems[randomIndex]] = Array.from(ref = [qsetItems[randomIndex], qsetItems[index]]), ref);
			}
			return result;
		})();
	};

	var _assistiveNotification = function(msg) {
		const notificationEl = document.getElementById('assistive-notification');
		if (notificationEl) { notificationEl.innerHTML = msg; }
	};

	var _assistiveAlert = function(msg) {
		const alertEl = document.getElementById('assistive-alert');
		if (alertEl) { alertEl.innerHTML = msg; }
	};

	Materia.Engine.start(materiaCallbacks);
}
]);
