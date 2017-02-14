describe('Matching', function() {

	var widgetInfo = window.__demo__['src/devmateria_demo'];
	var qset = widgetInfo.qset;
	var $scope = {};
	var ctrl = {};
	var $compile = {};

	function setupQA(){
		//set up questions and answers array
		$scope.currentPage = 0;
		$scope.test = {};
		$scope.test.questions = [];
		$scope.test.answers = [];

		//set page 1 questions in order of ids
		var i;
		for (i = 1; i <= 5; i++) {
			$scope.test.questions[i-1] = $scope.pages[0].questions.find(function (item) {
				return item.id === (i)
			});
			$scope.test.answers[i-1] = $scope.pages[0].answers.find(function (item) {
				return item.id === (i)
			});
		}
	}

	describe('Player Controller', function () {

		module.sharedInjector();
		beforeAll(module('matchingPlayer'));

		beforeAll(inject(function (_$compile_, $rootScope, $controller) {
			$scope = $rootScope.$new();
			ctrl = $controller('matchingPlayerCtrl', {$scope: $scope});
			$compile = _$compile_;
			$scope.setupQA = function(){
				//set up questions and answers array
				$scope.currentPage = 0;
				$scope.test = {};
				$scope.test.questions = [];
				$scope.test.answers = [];

				//set page 1 questions in order of ids
				var i;
				for (i = 1; i <= 5; i++) {
					$scope.test.questions[i-1] = $scope.pages[0].questions.find(function (item) {
						return item.id === (i)
					});
					$scope.test.answers[i-1] = $scope.pages[0].answers.find(function (item) {
						return item.id === (i)
					});
				}
			}
		}));

		beforeEach(function () {
			spyOn(Materia.CreatorCore, 'save').and.callFake(function (title, qset) {
				//the creator core calls this on the creator when saving is successful
				$scope.onSaveComplete();
				return {title: title, qset: qset};
			});
			spyOn(Materia.CreatorCore, 'cancelSave').and.callFake(function (msg) {
				throw new Error(msg);
			});
			spyOn(Materia.Score, 'submitQuestionForScoring');
		});

		it('should start properly', function () {
			$scope.start(widgetInfo, qset.data);
			expect($scope.title).toBe('Spanish Verbs');
			expect($scope.totalPages).toBe(2);
			expect($scope.pages.length).toBe(2);
		});

		it('should change to the previous page', function(){
			$scope.currentPage = 1;
			$scope.changePage('previous');
			expect($scope.currentPage).toEqual(0);
			//make sure you can't go below 0
			$scope.changePage('previous');
			expect($scope.currentPage).toEqual(0);
		});

		it('should change to the next page', function(){
			$scope.changePage('next');
			expect($scope.currentPage).toEqual(1);
			$scope.changePage('next');
			//make sure you can't go above the highest page
			expect($scope.currentPage).toEqual(1);
		});

		it('should animate on page change', inject(function($timeout){
			$scope.changePage('next');
			$timeout.flush();
			$timeout.verifyNoPendingTasks();
			expect($scope.pageAnimate).toBe(false);
		}));

		it('make a match -- start from empty matches', function() {
			setupQA();
			//questionId:1 answerId:2
			$scope.selectQuestion($scope.test.questions[0]);
			$scope.selectAnswer($scope.test.answers[1]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [1,2]
			expect($scope.matches[0].questionId).toEqual(1);
			expect($scope.matches[0].answerId).toEqual(2);
		});

		it('make a match -- when existing match clicked', function() {
			//questionId:1 answerId:2
			//clicking in different order for additional testing
			$scope.selectAnswer($scope.test.answers[1]);
			$scope.selectQuestion($scope.test.questions[0]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [1,2]
			expect($scope.matches[0].questionId).toEqual(1);
			expect($scope.matches[0].answerId).toEqual(2);
		});

		it('make a match -- override a match with existing answer', function() {
			//questionId:2 answerId:2
			$scope.selectQuestion($scope.test.questions[1]);
			$scope.selectAnswer($scope.test.answers[1]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [2,2]
			expect($scope.matches[0].questionId).toEqual(2);
			expect($scope.matches[0].answerId).toEqual(2);
		});

		it('make a match -- override a match with existing question', function() {
			//questionId:2 answerId:3
			$scope.selectQuestion($scope.test.questions[1]);
			$scope.selectAnswer($scope.test.answers[2]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [2,3]
			expect($scope.matches[0].questionId).toEqual(2);
			expect($scope.matches[0].answerId).toEqual(3);
		});

		it('make a match -- add a match to set up for next case', function() {
			//questionId:3 answerId:4
			$scope.selectQuestion($scope.test.questions[2]);
			$scope.selectAnswer($scope.test.answers[3]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [2,3] [3,4]
			expect($scope.matches[0].questionId).toEqual(2);
			expect($scope.matches[0].answerId).toEqual(3);
			expect($scope.matches[1].questionId).toEqual(3);
			expect($scope.matches[1].answerId).toEqual(4);
		});

		it('make a match -- override a match with an existing question and answer', function() {
			//questionId:3 answerId:3
			$scope.selectQuestion($scope.test.questions[2]);
			$scope.selectAnswer($scope.test.answers[2]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [3,3]
			// expect($scope.matches[0].questionId).toEqual(2);
			// expect($scope.matches[0].answerId).toEqual(2);
			expect($scope.matches[0].questionId).toEqual(3);
			expect($scope.matches[0].answerId).toEqual(3);
		});

		it('make a match -- add a match to set up for final case', function() {
			//questionId:1 answerId:2
			$scope.selectQuestion($scope.test.questions[0]);
			$scope.selectAnswer($scope.test.answers[1]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [3,3] [1,2]
			expect($scope.matches[0].questionId).toEqual(3);
			expect($scope.matches[0].answerId).toEqual(3);
			expect($scope.matches[1].questionId).toEqual(1);
			expect($scope.matches[1].answerId).toEqual(2);
		});

		it('make a match -- override existing question/answer where ' +
			'answerindex clicked > questionindex clicked' +
			'and questionindex != answerindex', function() {

			//reverse matches so the answer clicked exists at a later
			//index in matches
			var firstMatch = $scope.matches.shift();
			$scope.matches.push(firstMatch);

			//questionId:1 answerId:3
			$scope.selectQuestion($scope.test.questions[0]);
			$scope.selectAnswer($scope.test.answers[2]);
			//match expectation format: [questionid,answerid] [questionid,answerid] ...
			// [1,3]
			expect($scope.matches[0].questionId).toEqual(1);
			expect($scope.matches[0].answerId).toEqual(3);
		});

		it('should return the the correct progress amount of completed questions', function(){
			//at this point --- 1 match 9 total items 160 is progress bar length
			expect($scope.getProgressAmount()).toBe((1/9) *160);

			//in case there are no items
			$scope.totalItems = 0;
			expect($scope.getProgressAmount()).toBe(0);
		});

		it('should style circles correctly', function(){
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

		it('style question and answers correctly', function () {
			//put questions in order of id
			$scope.pages[0].questions = $scope.test.questions;
			//put answers in order of id
			$scope.pages[0].answers = $scope.test.answers;

			//current state of matches [1,3]

			//question with id=1 is in matches
			expect($scope.isInMatch($scope.pages[0].questions[0])).toBe(1);

			//answer with id=3 is in matches
			expect($scope.isInMatch($scope.pages[0].answers[2])).toBe(1);

			//invalid type
			$scope.pages[0].questions[0].type = 'fail';
			expect($scope.isInMatch($scope.pages[0].questions[0])).toBe(0);
		});

		it('should draw preline when hover over an item in right column', function () {
			//should not draw preline if a question has not been selected
			$scope.selectedQA[0].question = -1;
			$scope.drawPrelineToRight($scope.pages[0].answers[0]);
			expect($scope.prelines.length).toBe(0);

			//should draw preline when question selected
			$scope.selectedQA[0].question = 0;
			$scope.drawPrelineToRight($scope.pages[0].answers[0]);
			expect($scope.prelines.length).toBe(1);

			//should only have 1 preline at a time
			$scope.selectedQA[0].question = 0;
			$scope.drawPrelineToRight($scope.pages[0].answers[0]);
			expect($scope.prelines.length).toBe(1);
		});

		it('should draw preline when hover over an item in left column', function () {
			$scope.prelines = [];

			//should not draw preline if a answer has not been selected
			$scope.selectedQA[0].answer = -1;
			$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
			expect($scope.prelines.length).toBe(0);

			//should draw preline when answer selected
			$scope.selectedQA[0].answer = 0;
			$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
			expect($scope.prelines.length).toBe(1);

			//should only have 1 preline at a time
			$scope.selectedQA[0].answers = 0;
			$scope.drawPrelineToLeft($scope.pages[0].questions[0]);
			expect($scope.prelines.length).toBe(1);
		});

		it('should submit questions correctly', function () {
			$scope.matches = [];
			$scope.matches.push({questionId:1, answerId: 1});
			$scope.submit();
			expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith(1, 'to change');
			$scope.matches = [];
			$scope.submit();
			expect(Materia.Score.submitQuestionForScoring).toHaveBeenCalledWith(1, null);
		});

		it('should unapply hover selections', function() {
			$scope.currentPage=0;
			$scope.questionCircles = [[]];
			$scope.answerCircles = [[]];
			$scope.prelines = [
				{ test: 'test'
				}];
			$scope.questionCircles[0].push({
				isHover: false
			});
			$scope.answerCircles[0].push({
				isHover: false
			});

			$scope.questionCircles[0][0].isHover = true;
			$scope.answerCircles[0][0].isHover = true;
			$scope.unapplyHoverSelections();
			expect($scope.prelines.length).toBe(0);
			expect($scope.questionCircles[0][0].isHover).toBe(false);
			expect($scope.answerCircles[0][0].isHover).toBe(false);
		});

		it('should not shuffle if only 1 item', function(){
			var smallQset={};
			angular.copy(qset, smallQset);
			smallQset.data.items[0].items = smallQset.data.items[0].items.slice(0,1);
			$scope.pages = [];
			$scope.start(widgetInfo, smallQset.data);
			expect($scope.pages[0].questions[0].text).toEqual(
					'cambiar');
			expect($scope.pages[0].answers[0].text).toEqual(
					'to change');
		});
	});
});