
describe('inputStateManager Directive', function() {
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var $scope
	var $compile
	var $timeout
	var element

	beforeEach(() => {
		jest.resetModules()

		// load the required code
		angular.mock.module('matching')
		require('../modules/matching.coffee')
		require('./inputStateManager.coffee')

		// initialize the angualr controller
		inject(function(_$compile_, _$controller_, _$timeout_, _$rootScope_){
			$timeout = _$timeout_;
			$compile = _$compile_
			$scope = _$rootScope_.$new();
			$scope.checkMedia = jest.fn().mockReturnValue(true)
		})
	})

	var createQuestionDirectiveInstance = inject(function($injector) {
		var elementHtml =
			'<div>' +
				'<div class="green-box"' +
					'data-index="0"' +
					'ng-repeat="pair in widget.wordPairs" ' +
					'input-state-manager>' +
					'<textarea class="question-text"' +
						'ng-class="{\'hasProblem\' : hasQuestionProblem}"' +
						'ng-model="pair.question"' +
						'ng-focus="updateInputState(FOCUS, $event)"' +
						'ng-blur="updateInputState(BLUR, $event)">' +
					'</textarea>' +
				'</div>' +
			'</div>';
		element = $compile(elementHtml)($scope);
		$scope.$digest();
	});

	var createAnswerDirectiveInstance = inject(function($injector) {
		var elementHtml =
			'<div>' +
				'<div class="green-box"' +
					'data-index="0"' +
					'ng-repeat="pair in widget.wordPairs" ' +
					'input-state-manager>' +
					'<textarea class="answer-text"' +
						'ng-class="{\'hasProblem\' : hasAnswerProblem}"' +
						'ng-model="pair.answer"' +
						'ng-focus="updateInputState(FOCUS, $event)"' +
						'ng-blur="updateInputState(BLUR, $event)">' +
					'</textarea>' +
				'</div>' +
			'</div>';

		element = $compile(elementHtml)($scope);
		$scope.$digest();
	});

	var refreshElement = function(element) {
		element.triggerHandler('focus');
		element.triggerHandler('blur');
	};

	var getAnswerTextArea = function(){ return angular.element(element[0].querySelector('.answer-text'))}
	var getQuestionTextArea = function(){ return angular.element(element[0].querySelector('.question-text'))}

	it('hasProblem class shouldnt be applied before blur event', function() {
		$scope.widget = {wordPairs: [{answer: 5, question: null, media: [0, 0]}]}
		createQuestionDirectiveInstance();
		var questionElement = getQuestionTextArea()

		expect(questionElement.hasClass('hasProblem')).toBe(false);
	});

	it('should correctly indicate an empty question input has a problem', function() {
		$scope.widget = {wordPairs: [{answer: 5, question: '', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createQuestionDirectiveInstance();
		var questionElement = getQuestionTextArea()
		refreshElement(questionElement)

		expect(questionElement.hasClass('hasProblem')).toBe(true);
	});

	it('should correctly indicate a non-empty question input is valid', function() {
		$scope.widget = {wordPairs: [{answer: 5, question: 'question', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createQuestionDirectiveInstance();
		var questionElement = getQuestionTextArea()
		refreshElement(questionElement);

		expect(questionElement.hasClass('hasProblem')).toBe(false);
	});

	it('should correctly indicate a empty question with media is valid', function() {
		$scope.widget = {wordPairs: [{answer: 5, question: '', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(true) // media
		createQuestionDirectiveInstance();
		var questionElement = getQuestionTextArea()
		refreshElement(questionElement);

		expect(questionElement.hasClass('hasProblem')).toBe(false);
	});

	it('should update status when a question is set', function() {
		$scope.widget = {wordPairs: [{answer: 5, question: '', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createQuestionDirectiveInstance();
		var questionElement = getQuestionTextArea()
		refreshElement(questionElement);

		expect(questionElement.hasClass('hasProblem')).toBe(true);

		$scope.widget.wordPairs[0].question = 'should-be-valid-now'
		$scope.$digest(); // update
		expect(questionElement.hasClass('hasProblem')).toBe(false);
	});

	it('should update status after question media is set', function() {
		$scope.widget = {wordPairs: [{answer: '', question: '', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createQuestionDirectiveInstance();
		var questionElement = getQuestionTextArea()
		refreshElement(questionElement);

		expect(questionElement.hasClass('hasProblem')).toBe(true);

		$scope.widget.wordPairs[0].media = [1, 0]
		$scope.$digest(); // update
		expect(questionElement.hasClass('hasProblem')).toBe(false);
	});

	it('should correctly indicate a answer is valid', function() {
		$scope.widget = {wordPairs: [{answer: 'answer', question: 'question', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createAnswerDirectiveInstance();
		var answerElement = getAnswerTextArea()
		refreshElement(answerElement);

		expect(answerElement.hasClass('hasProblem')).toBe(false);
	});

	it('should correctly indicate an empty answer input has a problem', function() {
		$scope.widget = {wordPairs: [{answer: '', question: 'question', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // has media
		createAnswerDirectiveInstance();
		var answerElement = getAnswerTextArea()
		refreshElement(answerElement);

		expect(answerElement.hasClass('hasProblem')).toBe(true);
	});

	it('should correctly indicate an empty answer with media is valid', function() {
		$scope.widget = {wordPairs: [{answer: '', question: 'question', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(true) // has media
		createAnswerDirectiveInstance();
		var answerElement = getAnswerTextArea()
		refreshElement(answerElement);

		expect(answerElement.hasClass('hasProblem')).toBe(false);
	});


	it('should update status when an answer is set', function() {
		$scope.widget = {wordPairs: [{answer: '', question: '', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createAnswerDirectiveInstance();
		var answerElement = getAnswerTextArea()
		refreshElement(answerElement);

		expect(answerElement.hasClass('hasProblem')).toBe(true);

		$scope.widget.wordPairs[0].answer = 'should-be-valid-now'
		$scope.$digest(); // update
		expect(answerElement.hasClass('hasProblem')).toBe(false);
	});


	it('should update status when an answer media is set', function() {
		$scope.widget = {wordPairs: [{answer: '', question: '', media: [0, 0]}]}
		$scope.checkMedia.mockReturnValue(false) // no media
		createAnswerDirectiveInstance();
		var answerElement = getAnswerTextArea()
		refreshElement(answerElement);

		expect(answerElement.hasClass('hasProblem')).toBe(true);

		$scope.widget.wordPairs[0].media = [0, 1]
		$scope.$digest(); // update
		expect(answerElement.hasClass('hasProblem')).toBe(false);
	});

});
