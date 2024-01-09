describe('Matching Player Controller', function(){
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var $scope
	var $controller
	var $timeout
	var widgetInfo
	var materiaCallbacks
	var qset

	function setupQA(){
		//set up questions and answers array
		$scope.currentPage = 0;
		$scope.test = {};
		$scope.test.questions = [];
		$scope.test.answers = [];
		//set page 1 questions and answers in order of ids
		var i, testQIndex, testAIndex;
		for (i = 1; i <= 5; i++) {
			testQIndex = $scope.pages[0].questions.map(function (item) {
				return item.id;
			}).indexOf(i);
			$scope.test.questions.push($scope.pages[0].questions[i]);
			testAIndex = $scope.pages[0].answers.map(function (item) {
				return item.id;
			}).indexOf(i);
			$scope.test.answers.push($scope.pages[0].answers[i]);
		}
		//Add ids to the scope questions/answers
		for(i = 1; i <= 4; i++) {
			$scope.pages[0].answers[i].id = i;
			$scope.pages[0].questions[i].id = i;
		}
	}

	function setupQAIds() {
		//Add ids to the qset
		var i = 0;
		for (var item in qset.data.items[0].items) {
			qset.data.items[0].items[i].id = i;
			i++;
		}
	}

	beforeEach(() => {
		jest.resetModules()

		// mock materia
		global.Materia = {
			Engine: {
				start: jest.fn(),
				end: jest.fn(),
				setHeight: jest.fn(),
				getImageAssetUrl: jest.fn()
			},
			Score: {
				submitQuestionForScoring: jest.fn()
			}
		}

		// load qset
		widgetInfo = require('../demo.json')
		qset = widgetInfo.qset;
		setupQAIds()

		// load the required code
		angular.mock.module('matching')
		require('../modules/matching.coffee')
		// angular.module('ngAnimate', [])
		require('./player.coffee')

		// mock scope
		$scope = {
			$apply: jest.fn().mockImplementation(fn => {
				if(angular.isFunction(fn)) fn()
			})
		}

		// initialize the angualr controller
		inject(function(_$controller_, _$timeout_, _$rootScope_){
			$timeout = _$timeout_;
			// instantiate the controller
			$controller = _$controller_('matchingPlayerCtrl', { $scope: $scope });
			materiaCallbacks = Materia.Engine.start.mock.calls[0][0]
		})
	})

	it('should start properly', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		expect($scope.title).toBe('Spanish Verbs');
		expect($scope.totalPages).toBe(2);
		expect($scope.pages).toHaveLength(2);
	});

	it('should display the keyboard instructions', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		$scope.toggleInstructions();
		expect($scope.showInstructions).toBe(true);
	});

	it('should shuffle the questions and answers without disrupting the array', function () {
		materiaCallbacks.start(widgetInfo, qset.data);

		mock_shuffle = jest.fn($scope._shuffle);

		// Store the initial length of the qset, shuffle, then store the length again
		qsetItems = $scope.qset.items[0].items;
		initialArrayLength = qsetItems.length;
		mock_shuffle(qsetItems);
		LengthAfterShuffle = $scope.qset.items[0].items.length;

		// Check that the mock function was called and that the shuffle didn't change the length of the array
		expect(mock_shuffle).toHaveBeenCalled();
		expect(mock_shuffle).toHaveBeenCalledTimes(1);
		expect(mock_shuffle).toHaveBeenCalledWith(qsetItems);
		expect(initialArrayLength).toEqual(LengthAfterShuffle);

	});

	it('should change to the previous page', inject(function ($timeout) {
		materiaCallbacks.start(widgetInfo, qset.data);
		Materia.Engine.getImageAssetUrl
		$scope.currentPage = 1;
		$scope.changePage('previous');
		$timeout.flush();
		$timeout.verifyNoPendingTasks();
		expect($scope.currentPage).toEqual(0);

		//make sure you can't go below 0
		$scope.changePage('previous');
		$timeout.flush();
		$timeout.verifyNoPendingTasks();
		expect($scope.currentPage).toEqual(0);
	}));

	it('should change to the next page', inject(function ($timeout) {
		materiaCallbacks.start(widgetInfo, qset.data);
		$scope.changePage('next');
		$timeout.flush();
		$timeout.verifyNoPendingTasks();
		expect($scope.currentPage).toEqual(1);

		//make sure you can't go above the highest page
		$scope.changePage('next');
		$timeout.flush();
		$timeout.verifyNoPendingTasks();
		expect($scope.currentPage).toEqual(1);
	}));

	it('should animate on page change', inject(function ($timeout) {
		materiaCallbacks.start(widgetInfo, qset.data);
		$scope.changePage('next');
		$timeout.flush();
		$timeout.verifyNoPendingTasks();
		expect($scope.pageAnimate).toBe(false);
	}));

	it('should not allow page switches before the animation completes', function() {
		materiaCallbacks.start(widgetInfo, qset.data);
		$scope.pageAnimate = true;
		expect($scope.changePage('previous')).toBe(false);
	});

	it('selecting a question and answer creates a match', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();
		expect($scope.matches).toHaveLength(0)

		$scope.selectQuestion($scope.test.questions[0]);
		$scope.selectAnswer($scope.test.answers[1]);

		expect($scope.matches).toHaveLength(1)
		expect($scope.matches[0]).toMatchSnapshot({
			answerIndex: expect.any(Number),
			questionIndex: expect.any(Number)
		})
	});

	it('selecting a question and answer backwards creates a match', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();
		expect($scope.matches).toHaveLength(0)

		$scope.selectAnswer($scope.test.answers[1]);
		$scope.selectQuestion($scope.test.questions[0]);

		expect($scope.matches).toHaveLength(1)
		expect($scope.matches[0]).toMatchSnapshot({
			answerIndex: expect.any(Number),
			questionIndex: expect.any(Number)
		})
	});

	it('override a match with existing answer', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();
		expect($scope.matches).toHaveLength(0)

		$scope.selectAnswer($scope.test.answers[1]);
		$scope.selectQuestion($scope.test.questions[0]);

		expect($scope.matches).toHaveLength(1)

		//questionId:2 answerId:2
		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[1]);

		expect($scope.matches).toHaveLength(1)
		expect($scope.matches[0]).toMatchSnapshot({
			answerIndex: expect.any(Number),
			questionIndex: expect.any(Number)
		})
	});

	it('override a match with existing question', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[1]);


		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[2]);

		expect($scope.matches).toHaveLength(1)
		expect($scope.matches[0]).toMatchSnapshot({
			answerIndex: expect.any(Number),
			questionIndex: expect.any(Number)
		})
	});

	it('handles multiple selected matches', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[2]);
		$scope.selectQuestion($scope.test.questions[2]);
		$scope.selectAnswer($scope.test.answers[3]);
		//match expectation format: [questionid,answerid] [questionid,answerid] ...
		// [2,3] [3,4]
		expect($scope.matches[0].questionId).toEqual(2);
		expect($scope.matches[0].answerId).toEqual(3);
		expect($scope.matches[1].questionId).toEqual(3);
		expect($scope.matches[1].answerId).toEqual(4);
	});

	it('override a match with an existing question and answer', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[1]);

		$scope.selectQuestion($scope.test.questions[2]);
		$scope.selectAnswer($scope.test.answers[2]);

		// should replace all
		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[2]);

		expect($scope.matches).toHaveLength(1)
		expect($scope.matches[0]).toMatchSnapshot({
			answerIndex: expect.any(Number),
			questionIndex: expect.any(Number)
		})
	});

	it('checkForQuestionAudio checks for question/answer audio correctly', function() {
		materiaCallbacks.start(widgetInfo, qset.data);

		$scope.pages[0].questions[0].asset = "test";
		$scope.pages[0].answers[0].asset = "test";

		expect($scope.checkForQuestionAudio(0)).toBe(true)
		expect($scope.checkForAnswerAudio(0)).toBe(true)

		expect($scope.checkForQuestionAudio(2)).toBe(false)
		expect($scope.checkForAnswerAudio(2)).toBe(false)
	});

	it('progress should initialize to zero', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		expect($scope.getProgressAmount()).toBe(0);
	});

	it('progress should incrment as when matches are made', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();
		expect($scope.getProgressAmount()).toBe(0);

		$scope.selectQuestion($scope.test.questions[1]);
		$scope.selectAnswer($scope.test.answers[1]);
		expect($scope.getProgressAmount()).toBe(16);

		$scope.selectQuestion($scope.test.questions[2]);
		$scope.selectAnswer($scope.test.answers[2]);
		expect($scope.getProgressAmount()).toBe(32);
	});

	it('should style circles correctly', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		//id is same as question clicked
		$scope.selectedQA[0].question = 0;
		expect($scope.applyCircleClass($scope.questionCircles[0][0])).toBe(true);

		//id is different from question clicked
		$scope.selectedQA[0].question = 1;
		expect($scope.applyCircleClass($scope.questionCircles[0][0])).toBe(false);

		//id is same as answer clicked
		$scope.selectedQA[0].answer = 0;
		expect($scope.applyCircleClass($scope.answerCircles[0][0])).toBe(true);

		//id is different from answer clicked
		$scope.selectedQA[0].answer = 1;
		expect($scope.applyCircleClass($scope.answerCircles[0][0])).toBe(false);

		//edge case of item not having an appropriate selection type
		$scope.questionCircles[0][0].selectionItem = 'fail';
		expect($scope.applyCircleClass('fail')).toBe(false);
	});

	it('isInMatch finds items in a match', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		expect($scope.isInMatch({type: 'question', id: 1})).toBe(false);
		expect($scope.isInMatch({type: 'answer', id: 1})).toBe(false);

		$scope.selectQuestion($scope.pages[0].questions[1]);
		$scope.selectAnswer($scope.pages[0].answers[1]);

		//question with id=1 is in matches
		expect($scope.isInMatch({type: 'question', id: 1})).toBe(true);
		expect($scope.isInMatch({type: 'answer', id: 1})).toBe(true);

		//invalid type
		expect($scope.isInMatch({type: 'invalied-type', id: 1})).toBe(false);
	});

	it('should create a preline when hover over an item in right column', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		//should not create a preline if a question has not been selected
		$scope.selectedQA[0].question = -1;
		$scope.drawPrelineToRight($scope.pages[0].answers[0]);
		expect($scope.prelines).toHaveLength(0);

		//should draw preline when question selected
		$scope.selectedQA[0].question = 0;
		$scope.drawPrelineToRight($scope.pages[0].answers[0]);
		expect($scope.prelines).toHaveLength(1);

		//should only have 1 preline at a time
		$scope.selectedQA[0].question = 0;
		$scope.drawPrelineToRight($scope.pages[0].answers[0]);
		expect($scope.prelines).toHaveLength(1);
	});

	it('should create a preline when hover over an item in left column', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		//should not draw preline if a answer has not been selected
		$scope.selectedQA[0].answer = -1;
		$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
		expect($scope.prelines).toHaveLength(0);

		//should draw preline when answer selected
		$scope.selectedQA[0].answer = 0;
		$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
		expect($scope.prelines).toHaveLength(1);

		//should only have 1 preline at a time
		$scope.selectedQA[0].answers = 0;
		$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
		expect($scope.prelines).toHaveLength(1);

		//should only have 1 preline at a time
		$scope.selectedQA[0].answers = 0;
		$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
		expect($scope.prelines).toHaveLength(1);
	});

	it('should submit questions correctly with no matches', function () {
		materiaCallbacks.start(widgetInfo, qset.data);
		$scope.submit();
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledTimes(10)
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith(9, null, undefined);
	});

	it('should submit questions correctly with matches', function () {
		materiaCallbacks.start(widgetInfo, qset.data);

		$scope.matches.push({questionId:1, answerId: 1}); // text answer
		$scope.matches.push({questionId:6, answerId: 6}); // audio anwer

		$scope.submit();
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledTimes(10)
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith(1, 'to prefer', null);
		expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith(6, 'to type', 'to type');
	});

	it('unapplyHoverSelections should reset isHover selections', function () {
		materiaCallbacks.start(widgetInfo, qset.data);

		$scope.questionCircles[0][0].isHover = true;
		$scope.answerCircles[0][0].isHover = true;

		expect($scope.questionCircles[0][0].isHover).toBe(true);
		expect($scope.answerCircles[0][0].isHover).toBe(true);

		$scope.unapplyHoverSelections();

		expect($scope.questionCircles[0][0].isHover).toBe(false);
		expect($scope.answerCircles[0][0].isHover).toBe(false);
	});

	it('should put 10 items on 2 pages', function() {
		materiaCallbacks.start(widgetInfo, qset.data);

		expect($scope.pages[0].questions).toHaveLength(5);
		expect($scope.pages[1].questions).toHaveLength(5);
		expect($scope.pages).toHaveLength(2);
	});

	it('should put 6 items on one page', function() {
		// create a new set with 6 pairs and the last answer is blank
		var sixSet = {};
		sixSet = angular.copy(qset);
		sixSet.data.items[0].items = sixSet.data.items[0].items.slice(0,6);

		materiaCallbacks.start(widgetInfo, sixSet.data);

		// now there should be a single full page
		expect($scope.pages).toHaveLength(1);
		expect($scope.pages[0].questions).toHaveLength(6);
	});

	it('should put 7 items on two pages of 4 and 3', function() {
		// create a new set with 6 pairs and the last answer is blank
		var sixSet = {};
		sixSet = angular.copy(qset);
		sixSet.data.items[0].items = sixSet.data.items[0].items.slice(0,7);

		materiaCallbacks.start(widgetInfo, sixSet.data);

		// now there should be a single full page
		expect($scope.pages).toHaveLength(2);
		expect($scope.pages[0].questions).toHaveLength(4);
		expect($scope.pages[1].questions).toHaveLength(3);
	});

	it('should put 8 items on two pages of 4 and 4', function() {
		// create a new set with 6 pairs and the last answer is blank
		var sixSet = {};
		sixSet = angular.copy(qset);
		sixSet.data.items[0].items = sixSet.data.items[0].items.slice(0,8);

		materiaCallbacks.start(widgetInfo, sixSet.data);

		// now there should be a single full page
		expect($scope.pages).toHaveLength(2);
		expect($scope.pages[0].questions).toHaveLength(4);
		expect($scope.pages[1].questions).toHaveLength(4);
	});

	it('should put 8 items on two pages of 5 and 4', function() {
		// create a new set with 6 pairs and the last answer is blank
		var sixSet = {};
		sixSet = angular.copy(qset);
		sixSet.data.items[0].items = sixSet.data.items[0].items.slice(0,9);

		materiaCallbacks.start(widgetInfo, sixSet.data);

		// now there should be a single full page
		expect($scope.pages).toHaveLength(2);
		expect($scope.pages[0].questions).toHaveLength(5);
		expect($scope.pages[1].questions).toHaveLength(4);
	});

	it('should not shuffle if only 1 item', function () {
		var smallQset={};
		angular.copy(qset, smallQset);
		smallQset.data.items[0].items = smallQset.data.items[0].items.slice(0,1);

		materiaCallbacks.start(widgetInfo, smallQset.data);
		expect($scope.pages[0].questions[0].text).toEqual('cambiar');
		expect($scope.pages[0].answers[0].text).toEqual('to change');
	});

	it('should correctly report the text of a match', function() {
		materiaCallbacks.start(widgetInfo, qset.data);
		setupQA();

		questions = [{
			text: 'test-question',
			id: 0,
			pageId: 0,
			type: 'question',
			asset: 'undefined'
		}];

		answers = [{
			text: 'test-answer',
			id: 0,
			pageId: 0,
			type: 'answer',
			asset: 'undefined'
		}];

		$scope.pages[0].questions = questions;
		$scope.pages[0].answers = answers;

		$scope.selectQuestion(questions[0]);
		$scope.selectAnswer(answers[0]);

		console.log($scope.matches);

		expect($scope.getMatchWith($scope.pages[0].questions[0])).toBe($scope.pages[0].answers[0].text);
	});

});
