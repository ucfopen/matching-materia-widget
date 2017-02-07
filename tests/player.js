describe('Matching', function() {

	var widgetInfo = window.__demo__['src/demo'];
	var qset = widgetInfo.qset;
	var $scope = {};
	var ctrl = {};
	var $compile = {};

	function setup(){
		$scope.currentPage=0;
		$scope.questionCircles = [];
		$scope.questionCircles.push([]);
		$scope.answerCircles = [];
		$scope.answerCircles.push([]);
		$scope.prelines = [
			{ linex1: 50,
				linex2: 100,
				liney1: 20,
				liney2: 40
			}];
		$scope.questionCircles[0].push({
			r:5,
			cx: 6,
			cy: 7,
			id:0,
			isHover: false,
			type: 'question-circle',
			color: 'c0'
		});
		$scope.answerCircles[0].push({
			r:5,
			cx: 6,
			cy: 7,
			id:0,
			isHover: false,
			type: 'answer-circle',
			color: 'c0'
		});
	}

	describe('Player Controller', function () {

		module.sharedInjector();
		beforeAll(module('matchingPlayer'));

		beforeAll(inject(function (_$compile_, $rootScope, $controller) {
			$scope = $rootScope.$new();
			ctrl = $controller('matchingPlayerCtrl', {$scope: $scope});
			$compile = _$compile_;
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
		});

		it('should start properly', function () {
			$scope.start(widgetInfo, qset.data);
			expect($scope.title).toBe('Spanish Verbs');
			expect($scope.totalPages).toBe(2);
			expect($scope.pages.length).toBe(2);
		});

		it('should change gameboard page', function(){
			$scope.currentPage = 0;
			$scope.gotoDifferentPage('next');
			expect($scope.currentPage).toEqual(1);
			$scope.gotoDifferentPage('previous');
			expect($scope.currentPage).toEqual(0);
			//make sure you can't go below 0
			$scope.gotoDifferentPage('previous');
			expect($scope.currentPage).toEqual(0);
		});

		it('should animate gameboard on page change', inject(function($timeout){
			$scope.pageAnimate = false;
			$scope.gotoDifferentPage('next');
			$timeout.flush();
			$timeout.verifyNoPendingTasks();
			expect($scope.pageAnimate).toBe(false);
		}));

		it('should unapply hover selections', function() {
			setup();
			$scope.questionCircles[0][0].isHover = true;
			$scope.answerCircles[0][0].isHover = true;
			$scope.unapplyHoverSelections();
			expect($scope.prelines.length).toBe(0);
			expect($scope.questionCircles[0][0].isHover).toBe(false);
			expect($scope.answerCircles[0][0].isHover).toBe(false);
		});

	});
});