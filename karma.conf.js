module.exports = function(config) {
	config.set({

		autoWatch: true,

		basePath: './',

		browsers: ['PhantomJS'],

		files: [
			'node_modules/angular/angular.js',
			'node_modules/angular-animate/angular-animate.js',
			'node_modules/angular-mocks/angular-mocks.js',
			'node_modules/angular-sanitize/angular-sanitize.js',
			'node_modules/materia-client-assets/dist/js/materia.js',
			'node_modules/materia-client-assets/dist/js/materia.creatorcore.js',
			'node_modules/materia-client-assets/dist/js/materia.enginecore.js',
			'node_modules/materia-client-assets/dist/js/materia.scorecore.js',
			'src/demo.json',
			'src/devmateria_demo.json',
			'build/creator.js',
			'build/player.js',
			'build/directives/*.js',
			'tests/*.js'
		],

		frameworks: ['jasmine'],

		plugins: [
			'karma-coverage',
			'karma-eslint',
			'karma-jasmine',
			'karma-json-fixtures-preprocessor',
			'karma-mocha-reporter',
			'karma-phantomjs-launcher'
		],

		preprocessors: {
			'build/*.js': ['coverage', 'eslint'],
			'src/demo.json': ['json_fixtures'],
			'src/devmateria_demo.json': ['json_fixtures']
		},

		jsonFixturesPreprocessor: {
			variableName: '__demo__'
		},

		//plugin-specific configurations
		eslint: {
			stopOnError: true,
			stopOnWarning: false,
			showWarnings: true,
			engine: {
				configFile: '.eslintrc.json'
			}
		},

		reporters: ['coverage', 'mocha'],

		//reporter-specific configurations

		coverageReporter: {
			check: {
				global: {
					statements: 90,
					branches:   85,
					functions:  90,
					lines:      90
				},
				each: {
					statements: 90,
					branches:   85,
					functions:  90,
					lines:      90
				}
			},
			reporters: [
				{ type: 'cobertura', subdir: '.', file: 'coverage.xml' }
			]
		},

		mochaReporter: {
			output: 'autowatch'
		}

	});
};