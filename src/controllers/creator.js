angular.module('matching', ['ngAnimate'])
.controller('matchingCreatorCtrl', ['$scope', '$sce', function($scope, $sce) {
	const _qset = {};
	const materiaCallbacks = {};
	// Stores data to be gathered on save.
	$scope.widget = {
		title     : "My Matching widget",
		wordPairs : [],
		uniqueIds : []
	};

	$scope.acceptedMediaTypes = ['audio'];
	const audioRef = [];
	$scope.questionBankDialog = false;
	$scope.enableQuestionBank = false;
	$scope.questionBankValTemp = 1;
	$scope.questionBankVal = 1;

	$scope.autoSize = function(pair, audio) {
		let size;
		const question = pair.question || '';
		const answer = pair.answer || '';
		const len = question.length > answer.length ? question.length : answer.length;
		if (audio === true) {
			size = len > 15 ? 85 + (len * 1.1) : 85;
		} else {
			size = len > 15 ? 25 + (len * 1.1) : 25;
		}
		return {height: size + 'px'};
	};

	// Adds and removes a pair of textareas for users to input a word pair.
	$scope.addWordPair = function(q=null, a=null, media, id) {
		if (media == null) { media = [0,0]; }
		if (id == null) { id = ''; }
		$scope.widget.wordPairs.push({question:q, answer:a, media, id});
	};

	$scope.removeWordPair = function(index) {
		// Update question bank value if it's out of bounds once the word pair is removed
		if($scope.questionBankVal > $scope.widget.wordPairs.length) {
			$scope.questionBankVal = ($scope.questionBankValTemp = $scope.widget.wordPairs.length);
		}

		$scope.widget.wordPairs.splice(index, 1);
	};

	$scope.removeAudio = (index, which) => $scope.widget.wordPairs[index].media.splice(which, 1, 0);

	// Public methods
	materiaCallbacks.initNewWidget = (widget, baseUrl) => $scope.$apply(() => $scope.showIntroDialog = true);

	materiaCallbacks.initExistingWidget = function(title, widget, qset, version, baseUrl) {
		const _items = qset.items[0].items;

		if (qset.options) {
			$scope.enableQuestionBank = qset.options.enableQuestionBank ? qset.options.enableQuestionBank : false;
			$scope.questionBankVal = qset.options.questionBankVal ? qset.options.questionBankVal : 1;
			$scope.questionBankValTemp = qset.options.questionBankVal ? qset.options.questionBankVal : 1;
		}

		return $scope.$apply(function() {
			$scope.widget.title = title;
			$scope.widget.wordPairs = [];
			Array.from(_items).map((item) =>
				$scope.addWordPair(item.questions[0].text, item.answers[0].text, _checkAssets(item), item.id));
		});
	};

	materiaCallbacks.onSaveClicked = function(mode) {
		// don't allow empty sets to be saved.
		if (_buildSaveData() || (mode === 'history')) {
			Materia.CreatorCore.save($scope.widget.title, _qset);
		} else {
			$scope.showErrorDialog = true;
			$scope.$apply();
			Materia.CreatorCore.cancelSave('Widget not ready to save.');
		}
	};

	materiaCallbacks.onSaveComplete = (title, widget, qset, version) => true;

	materiaCallbacks.onQuestionImportComplete = questions => $scope.$apply(() => (() => {
        const result = [];
        for (var question of Array.from(questions)) {
            var assets = _checkAssets(question);

            result.push($scope.addWordPair(
                question.questions[0].text,
                question.answers[0].text,
                assets,
                question.id
            ));
        }
        return result;
    })());

	$scope.beginMediaImport = function(index, which) {
		Materia.CreatorCore.showMediaImporter($scope.acceptedMediaTypes);
		audioRef[0] = index;
		audioRef[1] = which;
	};

	materiaCallbacks.onMediaImportComplete = function(media) {
		$scope.widget.wordPairs[audioRef[0]].media.splice(audioRef[1], 1, media[0].id);
		$scope.$apply(() => true);
	};

	$scope.checkMedia = function(index, which) {
		if (($scope.widget.wordPairs[index] == null)) { return false; }
		return ($scope.widget.wordPairs[index].media[which] !== 0) && ($scope.widget.wordPairs[index].media[which] !== undefined); // value is undefined for older qsets
	};

	// View actions
	$scope.setTitle = function() {
		$scope.widget.title = $scope.introTitle || $scope.widget.title;
		$scope.step = 1;
		$scope.hideCover();
	};

	$scope.hideCover = function() {
		$scope.showTitleDialog = ($scope.showIntroDialog = ($scope.showErrorDialog = ($scope.questionBankDialog = false)));
		$scope.questionBankValTemp = $scope.questionBankVal;
	};

	$scope.audioUrl = assetId => // use $sce.trustAsResourceUrl to avoid interpolation error
    $sce.trustAsResourceUrl(Materia.CreatorCore.getMediaUrl(assetId));

	$scope.validateQuestionBankVal = function() {
		if (($scope.questionBankValTemp >= 1) && ($scope.questionBankValTemp <= $scope.widget.wordPairs.length)) {
			$scope.questionBankVal = $scope.questionBankValTemp;
		}
	};

	// prevents duplicate ids
	const createUniqueAudioAnswerId = function() {
		let uniqueId = 0;
		let intCheck = 0;
		while(intCheck > -1) {
			uniqueId = Math.floor(Math.random() * 10000);
			intCheck = $scope.widget.uniqueIds.indexOf(uniqueId);
		}
		$scope.widget.uniqueIds.push(uniqueId);

		return uniqueId.toString();
	};

	// Private methods

	// _used to set defaults if media is unset on either side
	var _checkAssets = function(object) {
		const assets = [0,0];
		if (object.assets != null) {
			if (object.assets[0] != null) { assets[0] = object.assets[0]; }
			if (object.assets[1] != null) { assets[1] = object.assets[1]; }
		}
		return assets;
	};

	var _buildSaveData = function() {
		
		// validate question bank value in case the word pair count has changed since the dialog was last opened
		if ($scope.questionBankVal > $scope.widget.wordPairs.length) { $scope.questionBankVal = ($scope.questionBankValTemp = $scope.widget.wordPairs.length); }

		_qset.items = [];
		_qset.items[0] = {
			name: "null",
			items: []
		};
		_qset.options = {
			enableQuestionBank: $scope.enableQuestionBank,
			questionBankVal: $scope.questionBankVal
		};
	
		const {
            wordPairs
        } = $scope.widget;
		if (!wordPairs.length) { return false; }

		const toRemove = [];
		for (let i = 0; i < wordPairs.length; i++) {
			// Don't allow any with blank questions (left side)
			var pair = wordPairs[i];
			if (((pair.question == null) || (pair.question.trim() === '')) && !pair.media[0]) {
				toRemove.push(i);
				continue;
			}
			// Don't allow any with blank answers (right side)
			if (((pair.answer == null) || (pair.answer.trim() === '')) && !pair.media[1]) {
				toRemove.push(i);
				continue;
			}
			/*
			BRING THIS BACK WHEN WE'RE READY FOR FAKEOUT OPTIONS
			* Blank answers (right side) are allowed, they just won't show up when playing
			if not pair.answer?
				pair.answer = ''
			*/
			// checks if there are wordpairs with audio that don't have a description
			// if any exist the description placeholder is set to Audio
			if ((pair.media[0] !== 0) && ((pair.question === null) || (pair.question === ''))) {
				pair.question = 'Audio';
			}
			if ((pair.media[1] !== 0) && ((pair.answer === null) || (pair.answer === ''))) {

				pair.answer = 'Audio';
			}

			var pairData = _process(pair, pair.media[0], pair.media[1], createUniqueAudioAnswerId());
			_qset.items[0].items.push(pairData);
		}

		/*
		MAYBE DO THIS LATER, WITH AN EXTRA 'ARE YOU SURE?' STEP BEFORE MASS DELETING
		for i, index in toRemove
			$scope.removeWordPair(i - index)
		$scope.$apply()

		return $scope.widget.wordPairs.length > 0
		*/
		return (toRemove.length === 0) && !(($scope.widget.title === '') || ($scope.widget.wordPairs.length < 1));
	};

	// Get each pair's data from the controller and organize it into Qset form.
	var _process = (wordPair, questionMediaId, answerMediaId, answerAudioId) => ({
        questions: [
            {text: wordPair.question}
        ],

        answers: [{
            text: wordPair.answer.trim(),
            value: '100',
            id: ''
        }
        ],

        type: 'QA',
        id: wordPair.id,
        assets: [questionMediaId, answerMediaId, answerAudioId]
    });

	Materia.CreatorCore.start(materiaCallbacks);
}
]);
