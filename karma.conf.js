module.exports = function(config) {
    config.set({

        autoWatch: false,

        basePath: './',

        browsers: ['PhantomJS'],

        files: [
            '../../js/*.js',
            'node_modules/angular/angular.js',
            'node_modules/angular-mocks/angular-mocks.js',
            'node_modules/angular-sanitize/angular-sanitize.js',
            'build/creator.js',
            'tests/*.js'
        ],

        frameworks: ['jasmine'],

        plugins: [
            'karma-coverage',
            'karma-jasmine',
            'karma-junit-reporter',
            'karma-mocha-reporter',
            'karma-phantomjs-launcher'
        ],

        singleRun: true,

        reporters: ['coverage', 'mocha'],

        //reporter-specific configurations

        coverageReporter: {
            check: {
                global: {
                    statements: 90,
                    branches:   90,
                    functions:  90,
                    lines:      90
                },
                each: {
                    statements: 90,
                    branches:   90,
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