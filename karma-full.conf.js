module.exports = function(config) {
	// load the reusable base karma config
	let baseConfig = require('./karma.conf')
	baseConfig(config)
	config.set({
		autoWatch: true,
		coverageReporter: {
			reporters: [
				{ type: 'html', subdir: 'report-html' },
			]
		},
	})
};
