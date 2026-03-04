/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
angular.module('matching')
// Directive that watches question/answer inputs and manages error states
.directive('inputStateManager', () => ({
    restrict: 'A',

    link($scope, $element, $attrs) {
        $scope.FOCUS = "focus";
        $scope.BLUR = "blur";

        $scope.hasQuestionProblem = false;
        $scope.hasAnswerProblem = false;

        // Fired on focus/blur
        $scope.updateInputState = function(type, evt) {
            const el = angular.element(evt.target);
            switch (type) {
                case $scope.FOCUS:
                    return el.addClass('focused');
                case $scope.BLUR:
                    el.removeClass('focused');
                    // If question is empty AND there is no media, apply error visuals
                    if (el[0].classList.contains('question-text')) {
                        $scope.hasQuestionProblem = !($scope.widget.wordPairs[$attrs.index].question || $scope.checkMedia($attrs.index, 0));
                    }

                    // If answer is empty AND there is no media, apply error visuals
                    if (el[0].classList.contains('answer-text')) {
                        return $scope.hasAnswerProblem = !($scope.widget.wordPairs[$attrs.index].answer || $scope.checkMedia($attrs.index, 1));
                    }
                    break;
            }
        };

        // Hide error highlight as soon as question length > 0, as opposed to when blur happens
        $scope.$watch("pair.question", function(newVal, oldVal) {
            if (((oldVal === null) || (oldVal.length < 1)) && (newVal !== oldVal)) { return $scope.hasQuestionProblem = false; }
        });

        // Hide error highlight as soon as answer length > 0, as opposed to when blur happens
        $scope.$watch("pair.answer", function(newVal, oldVal) {
            if (((oldVal === null) || (oldVal.length < 1)) && (newVal !== oldVal)) { return $scope.hasAnswerProblem = false; }
        });

        return $scope.$watch("pair.media", function(newVal, oldVal) {
            if (newVal[0] !== 0) { $scope.hasQuestionProblem = false; }
            if (newVal[1] !== 0) { return $scope.hasAnswerProblem = false; }
        });
    }
}));
