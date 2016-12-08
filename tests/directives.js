var $compile = null;
var $scope = {};
var element = null;

describe('focusMe Directive', function(){
	var $timeout = null;
	beforeEach(module('matchingCreator'));

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
	beforeEach(module('matchingCreator'));

	beforeEach(inject(function (_$compile_, $rootScope) {
		$compile = _$compile_;
		$scope = $rootScope.$new();
	}));

	it('should correctly use ngEnter directive', function () {
		$scope.enterEvent = function () {
		};
		spyOn($scope, 'enterEvent');
		element = angular.element("<textarea ng-enter='enterEvent()'></textarea>");
		element = $compile(element)($scope);
		$scope.$digest();
		//we can use this function to try difference key press events
		function keyPress(keyCode) {
			var keyEvent = $.Event("keypress", {
				which: keyCode
			});
			return keyEvent
		}

		//test with Backspace key
		var backspaceKey = keyPress(8);
		spyOn(backspaceKey, 'preventDefault');
		element.trigger(backspaceKey);
		expect(backspaceKey.preventDefault).not.toHaveBeenCalled();
		expect($scope.enterEvent).not.toHaveBeenCalled();

		//test with Enter key
		var enterKey = keyPress(13);
		spyOn(enterKey, 'preventDefault');
		element.trigger(enterKey);
		expect(enterKey.preventDefault).toHaveBeenCalled();
		expect($scope.enterEvent).toHaveBeenCalled();
	});
});