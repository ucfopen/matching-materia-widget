describe('Matching', function(){

	var widgetInfo = window.__demo__['build/demo'];
	var qset = widgetInfo.qset;
	var $scope = {};
	var ctrl={};

	describe('Creator Controller', function() {

		module.sharedInjector();
		beforeAll(module('matchingCreator'));
		beforeAll(inject(function($rootScope, $controller){
			$scope = $rootScope.$new();
			ctrl = $controller('matchingCreatorCtrl', { $scope: $scope });
		}));

		it('should make a new widget', function(){
		   $scope.initNewWidget({name: 'matcher'});
		   expect($scope.showIntroDialog).toBe(true);
		});

		it('should make an existing widget', function(){
			$scope.initExistingWidget('matcher', widgetInfo, qset.data);
			expect($scope.widget.title).toEqual('matcher');
			expect($scope.widget.wordPairs).toEqual(
				[ Object({ question: 'cambiar', answer: 'to change', id: '' }), Object({ question: 'preferir', answer: 'to prefer', id: '' }), Object({ question: 'poner', answer: 'to put, place, set', id: '' }), Object({ question: 'necesitar', answer: 'to need, require', id: '' }), Object({ question: 'escribir', answer: 'to write', id: '' }), Object({ question: 'enviar', answer: 'to send', id: '' }), Object({ question: 'decir', answer: 'to say, tell', id: '' }), Object({ question: 'venir', answer: 'to come', id: '' }), Object({ question: 'vender', answer: 'to sell', id: '' }) ]
			);
		});
	});
});