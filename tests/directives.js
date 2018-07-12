var $compile = null;
var $scope = {};
var element = null;

describe('audioControls Directive', function(){
	var normalAudio, mockAudio;
	var directive, controller;
	var elementHtml = '<div ng-audio-controls audio-source="{{\'\'}}"></div>';

	beforeEach(module('matching'));

	beforeEach(inject(function(_$compile_, $rootScope, $httpBackend){
		$compile = _$compile_;
		$scope = $rootScope.$new();
		$httpBackend.whenGET('audioControls.html').respond({test: 'response'});
		$httpBackend.expectGET('audioControls.html');
	}));

	//override Audio if it exists, so we can check behaviors predictably
	beforeEach(function(){
		normalAudio = window.Audio;
		mockAudio = {
			currentTime: 0,
			duration: 10,
			paused: true,
			play: function() {
				this.paused = false;
			},
			pause: function() {
				this.paused = true;
			}
		};
		window.Audio = function() { return mockAudio; };
	});
	afterEach(function() {
		window.Audio = normalAudio;
	});

	var createDirectiveInstance = inject(function($injector) {
		$scope.audioSource = 'test.mp3';

		element = $compile(elementHtml)($scope);
		$scope.$digest();

		directive = $injector.get('ngAudioControlsDirective')[0];
		controller = $injector.instantiate(directive.controller, {
			$scope: $scope
		});
	});

	it('should throw an error if not given a valid source', inject(function($injector){
		element = $compile(angular.element(elementHtml))($scope);
		$scope.$digest();

		directive = $injector.get('ngAudioControlsDirective')[0];
		expect(function(){
			$injector.instantiate(directive.controller, {
				$scope: {audioSource: null}
			});
		}).toThrow('Invalid source!');
	}));

	it('should create audio controls properly', function(){
		spyOn(window, 'Audio');

		createDirectiveInstance();

		expect(element.scope().audioSource).toBe('test.mp3');
		expect(window.Audio).toHaveBeenCalled();
	});

	it('should update duration when audio is done loading', function(){
		createDirectiveInstance();
		var scope = element.scope();

		expect(scope.duration).toBe(0);
		scope.audio.ondurationchange();
		expect(scope.duration).toBe(10);
	});

	it('should update the current time when the audio time changes', function(){
		createDirectiveInstance();
		var scope = element.scope();

		expect(scope.currentTime).toBe(0);

		//normally the Audio class handles this itself
		//we're mocking it, so we have to update it by hand
		scope.audio.currentTime = 5;

		scope.audio.ontimeupdate();
		expect(scope.currentTime).toBe(5);
	});

	it('should update audio time when the seek bar in the controls is moved', function(){
		createDirectiveInstance();
		var scope = element.scope();

		expect(scope.audio.currentTime).toBe(0);

		//normally this would be bound to a position on the seek bar in the ui
		//we can just change it by hand to test
		scope.currentTime = 5;
		scope.changeTime();
		expect(scope.audio.currentTime).toBe(5);
	});

	it('should play audio if the audio is paused', function(){
		createDirectiveInstance();
		var scope = element.scope();

		expect(scope.audio.paused).toBe(true);
		scope.play();
		expect(scope.audio.paused).toBe(false);
	});

	it('should pause audio if the audio is playing', function(){
		createDirectiveInstance();
		var scope = element.scope();

		expect(scope.audio.paused).toBe(true);
		scope.play();
		expect(scope.audio.paused).toBe(false);
		scope.play();
		expect(scope.audio.paused).toBe(true);
	});

	it('should format an audio time position in minute:second format', function(){
		createDirectiveInstance();
		var scope = element.scope();
		var time = 0;

		//Audio class stores current time as number of seconds elapsed
		time = 105.314; //around one minute and 45 seconds
		expect(scope.toMinutes(time)).toBe('1:45');
		time = 5.49; //around five seconds
		expect(scope.toMinutes(time)).toBe('0:05');
		time = 240.14043; //around four minutes
		expect(scope.toMinutes(time)).toBe('4:00');
	});
});

describe('focusMe Directive', function(){
	var $timeout = null;
	beforeEach(module('matching'));

	beforeEach(inject(function(_$compile_, $rootScope, _$timeout_){
		$timeout = _$timeout_;
		$compile = _$compile_;
		$scope = $rootScope.$new();
	}));

	it('should focus given elements when appropriate', function(){
		$scope.activate = false;

		element = $compile(angular.element('<div focus-me="activate"></div>'))($scope);
		$scope.$digest();

		spyOn(element[0], 'focus');
		$scope.activate = true;
		$scope.$digest();
		$timeout.flush();

		//make sure the element was given focus
		expect(element[0].focus).toHaveBeenCalled();
	});
});

describe('ngEnter Directive', function() {
	beforeEach(module('matching'));

	beforeEach(inject(function (_$compile_, $rootScope) {
		$compile = _$compile_;
		$scope = $rootScope.$new();
	}));

	it('should correctly use ngEnter directive', function () {
		$scope.enterEvent = function () {};
		spyOn($scope, 'enterEvent');
		element = angular.element("<textarea ng-enter='enterEvent()'></textarea>");
		element = $compile(element)($scope);
		$scope.$digest();
		//we can use this function to try difference key press events
		function keyPress(keyCode) {
			var keyEvent = new Event('keydown');
			keyEvent.which = keyCode;
			return keyEvent;
		}

		//test with Backspace key
		var backspaceKey = keyPress(8);
		spyOn(backspaceKey, 'preventDefault');
		element.triggerHandler(backspaceKey);
		expect(backspaceKey.preventDefault).not.toHaveBeenCalled();
		expect($scope.enterEvent).not.toHaveBeenCalled();

		//test with Enter key
		var enterKey = keyPress(13);
		spyOn(enterKey, 'preventDefault');
		element.triggerHandler(enterKey);
		expect(enterKey.preventDefault).toHaveBeenCalled();
		expect($scope.enterEvent).toHaveBeenCalled();
	});
});

describe('inputStateManager Directive', function() {
	beforeEach(module('matching'));

	beforeEach(inject(function(_$compile_, $rootScope, $controller) {
		$scope = $rootScope.$new();
		ctrl = $controller('matchingCreatorCtrl', { $scope: $scope });
		$compile = _$compile_;

		$scope.controller = ctrl;
	}));

	var createQuestionDirectiveInstance = inject(function($injector) {
		var elementHtml =
			'<div>' +
				'<div class="green-box"' +
					'data-index="0"' +
					'ng-repeat="pair in widget.wordPairs"' +
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
					'ng-repeat="pair in widget.wordPairs"' +
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

	it('should correctly indicate an empty question input has a problem', function() {
		$scope.widget.wordPairs =[];
		$scope.addWordPair('','',[0,0]);

		createQuestionDirectiveInstance();
		var questionElement = angular.element(element[0].querySelector('.question-text'));

		expect(questionElement.hasClass('hasProblem')).toBe(true);
		refreshElement(questionElement);
		expect(questionElement.hasClass('hasProblem')).toBe(true);
	});

	it('should correctly indicate a non-empty question input is valid', function() {
		$scope.widget.wordPairs =[];
		$scope.addWordPair('','',[0,0]);

		createQuestionDirectiveInstance();
		var questionElement = angular.element(element[0].querySelector('.question-text'));

		//make sure a question with text is valid
		$scope.widget.wordPairs[0].question = 'question';
		expect(questionElement.hasClass('hasProblem')).toBe(true);
		refreshElement(questionElement);
		expect(questionElement.hasClass('hasProblem')).toBe(false);

		//double-check that a question without text or media is invalid
		$scope.widget.wordPairs[0].question = '';
		refreshElement(questionElement);
		expect(questionElement.hasClass('hasProblem')).toBe(true);

		//make sure question with no text but media is valid
		$scope.widget.wordPairs[0].media = [1,0];
		refreshElement(questionElement);
		expect(questionElement.hasClass('hasProblem')).toBe(false);
	});

	it('should correctly indicate an empty answer input has a problem', function() {
		$scope.widget.wordPairs =[];
		$scope.addWordPair('','',[0,0]);

		createAnswerDirectiveInstance();
		var answerElement = angular.element(element[0].querySelector('.answer-text'));

		expect(answerElement.hasClass('hasProblem')).toBe(true);
		refreshElement(answerElement);
		expect(answerElement.hasClass('hasProblem')).toBe(true);
	});

	it('should correctly indicate a non-empty answer input is valid', function() {
		$scope.widget.wordPairs =[];
		$scope.addWordPair('','',[0,0]);

		createAnswerDirectiveInstance();
		var answerElement = angular.element(element[0].querySelector('.answer-text'));

		//make sure a answer with text is valid
		$scope.widget.wordPairs[0].answer = 'answer';
		expect(answerElement.hasClass('hasProblem')).toBe(true);
		refreshElement(answerElement);
		expect(answerElement.hasClass('hasProblem')).toBe(false);

		//double-check that a answer without text or media is invalid
		$scope.widget.wordPairs[0].answer = '';
		refreshElement(answerElement);
		expect(answerElement.hasClass('hasProblem')).toBe(true);

		//make sure answer with no text but media is valid
		$scope.widget.wordPairs[0].media = [0,1];
		refreshElement(answerElement);
		expect(answerElement.hasClass('hasProblem')).toBe(false);
	});
});