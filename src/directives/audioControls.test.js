describe('audioControls Directive', function(){
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var normalAudio
	var mockAudio
	var directive
	var $scope
	var $controller
	var $timeout
	var $injector
	var $compile
	var element

	beforeEach(() => {
		jest.resetModules()

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

		// load the required code
		angular.mock.module('matching')
		require('../modules/matching.coffee')
		require('./audioControls.coffee')
	})

	afterEach(() => {
		window.Audio = normalAudio;
	})

	const compileElementWithDirective = (audioSource = 'mock-file.mp3') => {
		// mock scope
		$scope = {
			audioSource,
			$apply: jest.fn().mockImplementation(fn => {
				if(angular.isFunction(fn)) fn()
			})
		}

		// initialize the angualr controller
		inject(function(_$injector_, _$compile_){
			$compile = _$compile_
			element = $compile(`<div ng-audio-controls audio-source="{{''}}"></div>`)($scope);
			directive = _$injector_.get('ngAudioControlsDirective')[0];
			controller = _$injector_.instantiate(directive.controller, {
				$scope: $scope
			});
		})
	}


	it('should throw an error if not given a valid source', inject(function($injector){
		expect(() => {compileElementWithDirective(null)}).toThrow('Invalid source!');
	}));

	it('should create audio controls properly', function(){
		spyOn(window, 'Audio');
		compileElementWithDirective()
		expect(element.scope().audioSource).toBe('mock-file.mp3');
		expect(window.Audio).toHaveBeenCalled();
	});

	it('should update duration when audio is done loading', function(){
		compileElementWithDirective();
		expect($scope.duration).toBe(0);
		$scope.audio.ondurationchange();
		expect($scope.duration).toBe(10);
	});

	it('should update the current time when the audio time changes', function(){
		compileElementWithDirective();
		expect($scope.currentTime).toBe(0);
		$scope.audio.currentTime = 5;
		$scope.audio.ontimeupdate();
		expect($scope.currentTime).toBe(5);
	});

	it('should not update audio time while the seek bar in the controls is being moved', function(){
		compileElementWithDirective();
		expect($scope.audio.currentTime).toBe(0);

		expect($scope.selectingNewTime).toBe(false);
		//normally this would be called any time the seek bar is clicked to select a new time
		//we can call it by hand to test
		$scope.preChangeTime();
		expect($scope.selectingNewTime).toBe(true);
		//normally the Audio class handles this itself
		//we're mocking it, so we have to update it by hand
		$scope.audio.currentTime = 5;
		$scope.audio.ontimeupdate();

		expect($scope.currentTime).toBe(0);
	});

	it('should update audio time when the seek bar in the controls is released', function(){
		compileElementWithDirective();
		expect($scope.audio.currentTime).toBe(0);

		//normally this would be bound to a position on the seek bar in the ui
		//we can just change it by hand to test
		$scope.currentTime = 5;
		expect($scope.selectingNewTime).toBe(false);
		$scope.changeTime();
		expect($scope.audio.currentTime).toBe(5);
	});

	it('should play audio if the audio is paused', function(){
		compileElementWithDirective();

		expect($scope.audio.paused).toBe(true);
		$scope.play();
		expect($scope.audio.paused).toBe(false);
	});

	it('should pause audio if the audio is playing', function(){
		compileElementWithDirective();

		expect($scope.audio.paused).toBe(true);
		$scope.play();
		expect($scope.audio.paused).toBe(false);
		$scope.play();
		expect($scope.audio.paused).toBe(true);
	});

	it('should format an audio time position in minute:second format', function(){
		compileElementWithDirective();
		var time = 0;

		//Audio class stores current time as number of seconds elapsed
		time = 105.314; //around one minute and 45 seconds
		expect($scope.toMinutes(time)).toBe('1:45');
		time = 5.49; //around five seconds
		expect($scope.toMinutes(time)).toBe('0:05');
		time = 240.14043; //around four minutes
		expect($scope.toMinutes(time)).toBe('4:00');
	});
});

