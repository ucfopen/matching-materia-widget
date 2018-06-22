const path = require('path')

let matchingConfig = {}
//override the demo with a copy that assigns ids to each question for dev purposes
if (process.env.npm_lifecycle_script == 'webpack-dev-server') {
	matchingConfig.demoPath = 'devmateria_demo.json'
}

// load the reusable legacy webpack config from materia-widget-dev
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig(matchingConfig)

webpackConfig.entry['directives/audioControls.js'] = [path.join(__dirname, 'src', 'directives', 'audioControls.coffee')]
webpackConfig.entry['directives/focusMe.js'] = [path.join(__dirname, 'src', 'directives', 'focusMe.coffee')]
webpackConfig.entry['directives/ngEnter.js'] = [path.join(__dirname, 'src', 'directives', 'ngEnter.coffee')]

webpackConfig.entry['audioControls.css'] = [
	path.join(__dirname, 'src', 'audioControls.scss'),
	path.join(__dirname, 'src', 'audioControls.html')
]

module.exports = webpackConfig
