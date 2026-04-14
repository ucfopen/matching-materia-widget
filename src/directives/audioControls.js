angular.module('matching')

.directive('ngAudioControls', () => ({
    restrict: 'EA',

    scope: {
        audioSource: '@audioSource'
    },

    templateUrl: 'audioControls.html',

    controller: ['$scope', '$sce', function($scope, $sce) {
        $scope.audio = null;
        $scope.currentTime = 0;
        $scope.duration = 0;
        $scope.selectingNewTime = false;

        if (typeof $scope.audioSource === "string") {
            $scope.audio = new Audio();
            $scope.audio.src = $sce.trustAsResourceUrl($scope.audioSource);
        } else {
            throw 'Invalid source!';
        }

        $scope.play = function() {
            if ($scope.audio.paused) { $scope.audio.play();
            } else { $scope.audio.pause(); }
        };

        $scope.toMinutes = function(time) {
            const minutes = parseInt(Math.floor(time / 60), 10);
            let seconds = parseInt(Math.floor(time % 60), 10);
            if (seconds < 10) { seconds = '0' + seconds; }
            return '' + minutes + ':' + seconds;
        };

        $scope.preChangeTime = () => $scope.selectingNewTime = true;
        $scope.changeTime = function() {
            $scope.selectingNewTime = false;
            $scope.audio.currentTime = $scope.currentTime;
        };

        // should only occur once, when the file is done loading
        $scope.audio.ondurationchange = function() {
            $scope.currentTime = 0;
            $scope.duration = $scope.audio.duration;
            $scope.$apply();
        };

        return $scope.audio.ontimeupdate = function() {
            if (!$scope.selectingNewTime) {
                $scope.currentTime = $scope.audio.currentTime;
                $scope.$apply();
            }
        };
    }
    ]
}));
angular.bootstrap(document, ['matching']);
