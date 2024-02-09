describe('Matching Creator Controller', function(){
	require('angular/angular.js');
	require('angular-mocks/angular-mocks.js');

	var originalRandom = Math.random
	var randomIndex = 0
	var $scope
	var $controller
	var $timeout
	var widgetInfo
	var materiaCallbacks
	var qset

	afterEach(() => {
		Math.random = originalRandom
	})

	beforeEach(() => {
		jest.resetModules()

		// matching creates random ids for audio answers
		// this will make them predictable
		randomIndex = 0
		Math.random = jest.fn().mockImplementation(() => randomIndex++)

		// mock materia
		global.Materia = {
			CreatorCore: {
				start: jest.fn(),
				alert: jest.fn(),
				cancelSave: jest.fn(),
				getMediaUrl: jest.fn().mockImplementation(id => `http://mock-url/${id}`),
				showMediaImporter: jest.fn(),
				save: jest.fn().mockImplementation((title, qset) => {
					//the creator core calls this on the creator when saving is successful
					materiaCallbacks.onSaveComplete();
					return {title: title, qset: qset};
				})
			}
		}

		// load qset
		widgetInfo = require('../demo.json')
		qset = widgetInfo.qset;

		// load the required code
		angular.mock.module('matching')
		require('../modules/matching.coffee')
		angular.module('ngAnimate', [])
		require('./creator.coffee')

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
			$controller = _$controller_('matchingCreatorCtrl', { $scope: $scope });
			materiaCallbacks = Materia.CreatorCore.start.mock.calls[0][0]
		})
	})


	it('initNewWidget should set defaults on scope', function(){
		materiaCallbacks.initNewWidget({name: 'matcher'});
		expect($scope.widget.wordPairs).toEqual([]);
		expect($scope.showIntroDialog).toBe(true);
		//this defaults if intro title is not set
		expect($scope.widget.title).toEqual("My Matching widget");
	});

	it('should properly set title from input', function () {
		materiaCallbacks.initNewWidget({name: 'matcher'});
		//should give default title if no introTitle defined
		$scope.setTitle();
		expect($scope.widget.title).toEqual("My Matching widget");
		//introTitle is ng-model on input
		$scope.introTitle = "introTitle";
		$scope.setTitle();
		expect($scope.widget.title).toEqual("introTitle");
	});

	it('should properly hide the title-change modal', function(){
		materiaCallbacks.initNewWidget({name: 'matcher'});
		$scope.showTitleDialog = true;
		$scope.hideCover();
		expect($scope.showTitleDialog).toBe(false);
		$scope.showIntroDialog= true;
		$scope.hideCover();
		expect($scope.showIntroDialog).toBe(false);
	});

	it('should make an existing widget', function(){
		materiaCallbacks.initExistingWidget('matcher', widgetInfo, qset.data);
		expect($scope.widget.title).toEqual('matcher');
		expect($scope.widget.wordPairs[0]).toEqual({ question: 'cambiar', answer: 'to change', media: [0,0], id: ''});
		expect($scope.widget.wordPairs[1]).toEqual({ question: 'preferir', answer: 'to prefer', media: [0,0], id: ''});
		initialwordPairs = JSON.parse(JSON.stringify( $scope.widget.wordPairs));
	});

	it('should save the widget properly', function(){
		materiaCallbacks.initExistingWidget('matcher', widgetInfo, qset.data);
		//since we're spying on this, it should return an object with a title and a qset if it determines the widget is ready to save
		var successReport = materiaCallbacks.onSaveClicked();
		//make sure the title was sent correctly
		expect(successReport.title).toBe($scope.widget.title);
		//check one of the questions and its answers to make sure it was sent correctly
		var testQuestion = successReport.qset.items[0].items[0];
		expect(testQuestion.questions[0].text).toBe('cambiar');
		expect(testQuestion.answers[0].text).toBe('to change');
	});

	it('addWordPair works with blank word pairs', function(){
		materiaCallbacks.initNewWidget('matcher');
		//clear the current word pairs accumulated from previous tests
		$scope.widget.wordPairs = [];
		//if fields on word pairs are empty- default values are given
		$scope.addWordPair();
		expect($scope.widget.wordPairs).toMatchSnapshot();
	});

	it('addWordPair works with text', function() {
		materiaCallbacks.initNewWidget('matcher');
		// Add two regular question/answer pairs, total number will be 11
		$scope.addWordPair("question1", "answer1", [0,0]);
		expect($scope.widget.wordPairs).toMatchSnapshot();
	});

	it('addWordPair works with text and an id', function(){
		materiaCallbacks.initNewWidget('matcher');
		//cover the case of an id passed in
		$scope.addWordPair("question", "answer", [0,0], 1);
		expect($scope.widget.wordPairs).toMatchSnapshot();
	});

	it('addWordPair works with media', function(){
		materiaCallbacks.initNewWidget('matcher');
		//cover the case of media passed in
		$scope.addWordPair("", "", ['mock-question.mp3', 'mock-answer.mp3']);
		expect($scope.widget.wordPairs).toMatchSnapshot();
	});

	it('should fail to save with empty questions or answers', function() {
		materiaCallbacks.initExistingWidget('matcher', widgetInfo, qset.data);
		// When three rows are added, their content doesn't matter until being saved
		expect($scope.widget.wordPairs.length).toBe(10);
		$scope.addWordPair(null, null, [0,0]);
		$scope.addWordPair(null, "abc", [0,0]);
		$scope.addWordPair("abc", null, [0,0]);
		expect($scope.widget.wordPairs.length).toBe(13);
		expect(global.Materia.CreatorCore.cancelSave).toHaveBeenCalledTimes(0)

		materiaCallbacks.onSaveClicked();

		expect(Materia.CreatorCore.cancelSave).toHaveBeenCalledTimes(1)
		expect(Materia.CreatorCore.cancelSave).toHaveBeenCalledWith("Widget not ready to save.")
	});

	it('should not save questions with no questions', function() {
		materiaCallbacks.initNewWidget('matcher');

		// Add a wordpair that has no question and no media, total should stay at 11
		materiaCallbacks.onSaveClicked();
		expect(global.Materia.CreatorCore.cancelSave).toHaveBeenCalledTimes(1)
		expect(Materia.CreatorCore.cancelSave).toHaveBeenCalledWith("Widget not ready to save.")
	});

	it('should not save questions that have no text and no audio', function() {
		materiaCallbacks.initExistingWidget('matcher', widgetInfo, qset.data);

		// Add a wordpair that has no question and no media, total should stay at 11
		$scope.addWordPair("", "answer", [0,0]);
		materiaCallbacks.onSaveClicked();
		expect(global.Materia.CreatorCore.cancelSave).toHaveBeenCalledTimes(1)
		expect(Materia.CreatorCore.cancelSave).toHaveBeenCalledWith("Widget not ready to save.")
	});

	it('creates expected qset for an audio question with audio answer', function() {
		materiaCallbacks.initNewWidget('matcher');
		//Add wordpair that has no answer/question text but has answer/question audio (this covers assignString function)
		$scope.addWordPair("", "", ["question.mp3","answer.mp3"]);

		var successReport = materiaCallbacks.onSaveClicked();
		// Make sure the blank description is set to be "Audio"
		expect(successReport.qset).toMatchSnapshot()
	});

	it('creates expected qset for a text question with audio answer', function() {
		materiaCallbacks.initNewWidget('matcher');
		//Add wordpair that has no answer text but has answer audio (this covers assignString function)
		$scope.addWordPair("question", "", [0,"answer.mp3"]);

		var successReport = materiaCallbacks.onSaveClicked();
		// Make sure the blank description is set to be "Audio"
		expect(successReport.qset).toMatchSnapshot()
	});


	it('should properly remove word pair', function(){
		materiaCallbacks.initNewWidget('matcher');
		// Add two regular question/answer pairs, total number will be 11
		$scope.addWordPair("question1", "answer1", [0,0]);
		$scope.addWordPair("question2", "answer2", [0,0]);
		$scope.addWordPair("question3", "answer3", [0,0]);
		// successReport = materiaCallbacks.onSaveClicked();
		// expect(successReport.qset.items[0]).toMatchSnapshot();
		expect($scope.widget.wordPairs).toHaveLength(3)

		// remove question 1 using index 0
		$scope.removeWordPair(0);
		expect($scope.widget.wordPairs).toHaveLength(2)
		expect($scope.widget.wordPairs).toMatchSnapshot()

		// remove question 3 using index 1
		$scope.removeWordPair(1);
		expect($scope.widget.wordPairs).toHaveLength(1)
		expect($scope.widget.wordPairs).toMatchSnapshot()
	});

	it('should remove audio and leave question in place', function(){
		materiaCallbacks.initNewWidget('matcher');
		$scope.addWordPair("question", "", ["question.mp3","answer.mp3"]);
		$scope.removeAudio(0,0);
		expect($scope.widget.wordPairs).toHaveLength(1)
		expect($scope.widget.wordPairs).toMatchSnapshot()
	});

	it('should generate an audio url using getMediaUrl', function(){
		//angular's $sce does some weird un/wrapping, usually it would handle this
		var url = $scope.audioUrl('audioId').$$unwrapTrustedValue();

		expect(Materia.CreatorCore.getMediaUrl).toHaveBeenCalledWith('audioId.mp3');
		expect(url).toBe('http://mock-url/audioId.mp3');
	});

	it('should import questions without assets', function(){
		materiaCallbacks.initNewWidget('matcher');

		var importing = [{
			questions: [{text: 'question'}],
			answers: [{text: 'answer'}],
			id: 11
		}];

		materiaCallbacks.onQuestionImportComplete(importing);

		expect($scope.widget.wordPairs).toMatchSnapshot()
	});

	it('should import questions with assets', function(){
		materiaCallbacks.initNewWidget('matcher');

		var importing = [
			{
				questions: [{text: 'question'}],
				answers: [{text: 'answer'}],
				assets:[
					'mock-asset-1.mp3',
					'mock-asset-2.mp3'
				],
				id: 11
			},
			{
				questions: [{text: 'question2'}],
				answers: [{text: 'answer2'}],
				assets:[
					'mock-asset-3.mp3'
				],
				id: 12
			},
			{
				questions: [{text: 'question3'}],
				answers: [{text: 'answer3'}],
				assets:[
					undefined,
					'mock-asset-4.mp3'
				],
				id: 13
			},
			{
				questions: [{text: 'question4'}],
				answers: [{text: 'answer4'}],
				assets:[
					0,
					'mock-asset-5.mp3'
				],
				id: 14
			},
			{
				questions: [{text: 'question5'}],
				answers: [{text: 'answer5'}],
				assets:[
					'mock-asset-6.mp3',
					0
				],
				id: 15
			}
		];

		materiaCallbacks.onQuestionImportComplete(importing);

		expect($scope.widget.wordPairs).toMatchSnapshot()
	});

	it('checkMedia works properly', function(){
		materiaCallbacks.initNewWidget('matcher');

		$scope.addWordPair("question", "");
		expect($scope.checkMedia(0,0)).toBe(false);
		expect($scope.checkMedia(0,1)).toBe(false);

		$scope.addWordPair("question", "", ["question.mp3","answer.mp3"]);
		expect($scope.checkMedia(1,0)).toBe(true);
		expect($scope.checkMedia(1,1)).toBe(true);

		$scope.addWordPair("question", "", ["question.mp3",0]);
		expect($scope.checkMedia(2,0)).toBe(true);
		expect($scope.checkMedia(2,1)).toBe(false);

		$scope.addWordPair("question", "", [undefined ,0]);
		expect($scope.checkMedia(3,0)).toBe(false);
		expect($scope.checkMedia(3,1)).toBe(false);
	});

	it('should import media properly', function(){
		//create fake media object
		var media = [{id: 'testId1'}];

		//check if media exists and begin import
		expect($scope.checkMedia(0,0)).toBe(false);

		$scope.beginMediaImport(0,0);
		// $scope.onMediaImportComplete(media);

		// media = [{id: 'testId2'}];
		// $scope.beginMediaImport(2,1);
		// $scope.onMediaImportComplete(media);

		// expect($scope.widget.wordPairs[0].media[0]).toBe('testId1');
		// expect($scope.widget.wordPairs[2].media[1]).toBe('testId2');
	});

	it('should give default qset options if question bank options are undefined', function () {

		qset.data.options = {};
		materiaCallbacks.initExistingWidget('matcher', widgetInfo, qset.data);

		expect($scope.enableQuestionBank).toBe(false);
		expect($scope.questionBankVal).toBe(1);
		expect($scope.questionBankValTemp).toBe(1);
	});

	it('should update questionBankVal if questionBankValTemp is valid within the range', function () {

		qset.data.options = {enableQuestionBank: true, questionBankVal: 6};
		materiaCallbacks.initExistingWidget('matcher', widgetInfo, qset.data);

		// set initial values where questionBankValTemp is invalid
		$scope.questionBankValTemp = 11;
		$scope.validateQuestionBankVal();

		// expect questionBankVal to change to wordPairs value
		expect($scope.questionBankVal).toBe(6);

		// this time questionBankValTemp is valid
		$scope.questionBankValTemp = 8;
		$scope.validateQuestionBankVal();

		// expect questionBankVal to be updated to questionBankValTemp
		expect($scope.questionBankVal).toBe(8);

	});

	it('should autosize correctly', function () {
		var lessThan15chars = 'small';
		var greaterThan15chars = 'thisIsNineteenChars';
		var longPair = {question: lessThan15chars, answer: greaterThan15chars};
		var shortPair = {question: lessThan15chars, answer: lessThan15chars};
		var smallHeight = $scope.autoSize(shortPair);
		var bigHeight = $scope.autoSize(longPair);
		//test given to short pairs
		expect(smallHeight).toEqual({height: '25px'});
		//test given a short and a long pair
		//javascript floating point multiplication makes 45.9 a weird number
		expect(bigHeight).toEqual({height: greaterThan15chars.length * 1.1 + 25 + 'px'});
		//test if question given empty value
		expect($scope.autoSize({question: '', answer: 'answer'})).toEqual({height: '25px'});
		//test if answer given empty value
		expect($scope.autoSize({question: 'question', answer: ''})).toEqual({height: '25px'});
		//test if both question and answer are given empty values
		expect($scope.autoSize({question: '', answer: ''})).toEqual({height: '25px'});
		//test if audio is true
		expect($scope.autoSize({question: '', answer: ''}, true)).toEqual({height: '85px'});
		//test if audio is true and there are more than 15 characters
		expect($scope.autoSize({question: 'thisIsNineteenChars', answer: 'thisIsNineteenChars'}, true)).toEqual({height: 85 + greaterThan15chars.length * 1.1 + 'px'});
	});

	// it('should cancel saving if question text and question audio are blank', function(){
	// 	//Add wordpair that has no answer text but has answer audio (this covers assignString function)
	// 	$scope.addWordPair("question", "", [0,"answer.mp3"]);
	// 	//Add wordpair that has no answer/question text but has answer/question audio (this covers assignString function)
	// 	$scope.addWordPair("", "", ["question.mp3","answer.mp3"]);

	// 	//set title again so that the widget fails saving because of
	// 	//question or answer text and audio being blank
	// 	$scope.widget.title = 'Widget Title';
	// 	//add wordpair that has blank question text and no question audio
	// 	$scope.addWordPair("", "answer", [0,0]);
	// 	//the error message should be what we expect it to be
	// 	expect(function(){
	// 		materiaCallbacks.onSaveClicked();
	// 	}).toThrow(new Error('Widget not ready to save.'));
	// });

	// it('should cancel saving if answer text and answer audio are blank', function(){
	// 	//Add wordpair that has no question text but has question audio (this covers assignString function)
	// 	$scope.addWordPair("", "answer", ["question.mp3",0]);
	// 	//remove previously added wordPair so that the widget fails saving on
	// 	//the new wordPair we create that has no answer text/audio
	// 	$scope.widget.wordPairs.splice(11, 1);

	// 	var holdem = $scope.widget.wordPairs;
	// 	$scope.widget.wordPairs = [];

	// 	//add wordpair that has blank answer text and no answer audio
	// 	$scope.addWordPair("question", "", [0,0]);

	// 	//the error message should be what we expect it to be
	// 	expect(function(){
	// 		materiaCallbacks.onSaveClicked();
	// 	}).toThrow(new Error('Widget not ready to save.'));
	// 	$scope.widget.wordPairs = holdem;
	// });
});
