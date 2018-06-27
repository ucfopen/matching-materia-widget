describe('Matching', function(){

	var widgetInfo = window.__demo__['src/demo'];
	// var widgetInfo = window.__demo__['src/devmateria_demo'];
	var qset = widgetInfo.qset;
	var $scope = {};
	var ctrl={};
	var initialwordPairs = {};
	var $compile = {};

	describe('Creator Controller', function() {

		module.sharedInjector();
		beforeAll(module('matching'));

		beforeAll(inject(function(_$compile_, $rootScope, $controller){
			$scope = $rootScope.$new();
			ctrl = $controller('matchingCreatorCtrl', { $scope: $scope });
			$compile = _$compile_;
		}));

		beforeEach(function () {
			spyOn(Materia.CreatorCore, 'save').and.callFake(function(title, qset){
				//the creator core calls this on the creator when saving is successful
				$scope.onSaveComplete();
				return {title: title, qset: qset};
			});
			spyOn(Materia.CreatorCore, 'cancelSave').and.callFake(function(msg){
				throw new Error(msg);
			});
			spyOn($scope, 'addWordPair').and.callThrough();
		});

		it('should make a new widget', function(){
			$scope.initNewWidget({name: 'matcher'});
			expect($scope.widget.wordPairs).toEqual([]);
			expect($scope.showIntroDialog).toBe(true);
			//this defaults if intro title is not set
			expect($scope.widget.title).toEqual("My Matching widget");
		});

		it('should properly set title from input', function () {
			//should give default title if no introTitle defined
			$scope.setTitle();
			expect($scope.widget.title).toEqual("My Matching widget");
			//introTitle is ng-model on input
			$scope.introTitle = "introTitle";
			$scope.setTitle();
			expect($scope.widget.title).toEqual("introTitle");
		});

		it('should properly hide the title-change modal', function(){
			$scope.showTitleDialog = true;
			$scope.hideCover();
			expect($scope.showTitleDialog).toBe(false);
			$scope.showIntroDialog= true;
			$scope.hideCover();
			expect($scope.showIntroDialog).toBe(false);
		});

		it('should make an existing widget', function(){
			$scope.initExistingWidget('matcher', widgetInfo, qset.data);
			expect($scope.widget.title).toEqual('matcher');
			expect($scope.widget.wordPairs[0]).toEqual({ question: 'cambiar', answer: 'to change', media: [0,0], id: ''});
			expect($scope.widget.wordPairs[1]).toEqual({ question: 'preferir', answer: 'to prefer', media: [0,0], id: ''});
			initialwordPairs = JSON.parse(JSON.stringify( $scope.widget.wordPairs));
		});

		it('should save the widget properly', function(){
			//since we're spying on this, it should return an object with a title and a qset if it determines the widget is ready to save
			var successReport = $scope.onSaveClicked();
			//make sure the title was sent correctly
			expect(successReport.title).toBe($scope.widget.title);
			//check one of the questions and its answers to make sure it was sent correctly
			var testQuestion = successReport.qset.items[0].items[0];
			expect(testQuestion.questions[0].text).toBe('cambiar');
			expect(testQuestion.answers[0].text).toBe('to change');
		});

		it('should cancel saving if widget title is invalid', function(){
			//unset the widget title
			$scope.widget.title = '';
			//the error message should be what we expect it to be
			expect(function(){
				$scope.onSaveClicked();
			}).toThrow(new Error('Widget not ready to save.'));
		});

		it('should cancel saving if question text and question audio are blank', function(){
			//Add wordpair that has no answer text but has answer audio (this covers assignString function)
			$scope.addWordPair("question", "", [0,"answer.mp3"]);
			//Add wordpair that has no answer/question text but has answer/question audio (this covers assignString function)
			$scope.addWordPair("", "", ["question.mp3","answer.mp3"]);
			//set title again so that the widget fails saving because of
			//question or answer text and audio being blank
			$scope.widget.title = 'Widget Title';
			//add wordpair that has blank question text and no question audio
			$scope.addWordPair("", "answer", [0,0]);
			//the error message should be what we expect it to be
			expect(function(){
				$scope.onSaveClicked();
			}).toThrow(new Error('Widget not ready to save.'));
		});

		it('should cancel saving if answer text and answer audio are blank', function(){
			//Add wordpair that has no question text but has question audio (this covers assignString function)
			$scope.addWordPair("", "answer", ["question.mp3",0]);
			//remove previously added wordPair so that the widget fails saving on
			//the new wordPair we create that has no answer text/audio
			$scope.widget.wordPairs.splice(11, 1);
			//add wordpair that has blank answer text and no answer audio
			$scope.addWordPair("question", "", [0,0]);
			//the error message should be what we expect it to be
			expect(function(){
				$scope.onSaveClicked();
			}).toThrow(new Error('Widget not ready to save.'));
		});

		it('should properly remove word pair', function(){
			$scope.removeWordPair(0);
			expect($scope.widget.wordPairs[0]).toEqual({question: 'preferir', answer: 'to prefer', media: [0,0], id: ''});
		});

		it('should properly remove audio', function(){
			$scope.removeAudio(0,0);
			expect($scope.widget.wordPairs[0].media[0]).toEqual(0);
		});

		it('should properly add word pairs', function(){
			//clear the current word pairs accumulated from previous tests
			$scope.widget.wordPairs = [];
			//if fields on word pairs are empty- default values are given
			$scope.addWordPair();
			expect($scope.widget.wordPairs[0]).toEqual({question: null, answer: null, media: [0,0], id: ''});
			$scope.addWordPair("question", "answer");
			expect($scope.widget.wordPairs[1]).toEqual({question: "question", answer: "answer", media: [0,0], id: ''});
			//cover the case of an id passed in
			$scope.addWordPair("question", "answer", [0,0], 1);
			expect($scope.widget.wordPairs[2]).toEqual({question: "question", answer: "answer", media: [0,0], id: 1});
			//cover the case of media passed in
			$scope.addWordPair("", "", [1,1]);
			expect($scope.widget.wordPairs[3]).toEqual({question: "", answer: "", media: [1,1], id: ''});
		});

		it('should import questions properly', function(){
			var importing = qset.data.items[0].items;
			//clear the current word pairs accumulated from previous tests
			$scope.widget.wordPairs = [];

			//verify we have a clean slate to test this function
			expect($scope.widget.wordPairs).toEqual([]);
			$scope.onQuestionImportComplete(importing);
			expect($scope.widget.wordPairs).toEqual(initialwordPairs);
		});

		it('should import media properly', function(){
			//create fake media object
			var media = [{id: "audioTest"}];
			//check if media exists and begin import
			$scope.checkMedia(0,0);
			$scope.beginMediaImport(0,0);

			//create and audio tag with a src
			var newAudio = document.createElement("AUDIO");
			var newSource = document.createElement("SOURCE");
			//attach load function to audio tag
			newAudio.load = function() {};
			newAudio.appendChild(newSource);
			newSource.setAttribute("ng-src", "test.mp3");
			document.body.appendChild(newAudio);

			var newAudioTwo = document.createElement("AUDIO");
			var newSourceTwo = document.createElement("SOURCE");
			//attach load function to audio tag
			newAudioTwo.load = function() {};
			newAudioTwo.appendChild(newSourceTwo);
			newSourceTwo.setAttribute("ng-src", "test2.mp3");
			document.body.appendChild(newAudioTwo);
			//create spies to ensure the load function is being called
			audioSpy = spyOn(newAudio, 'load').and.callThrough();
			audioSpyTwo = spyOn(newAudioTwo, 'load').and.callThrough();

			//complete the media import
			$scope.onMediaImportComplete(media);

			expect(audioSpy.calls.any()).toEqual(true);
			expect(audioSpyTwo.calls.any()).toEqual(true);
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
	});
});