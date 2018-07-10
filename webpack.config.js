const path = require('path')

let matchingConfig = {}
//override the demo with a copy that assigns ids to each question for dev purposes
if (process.env.npm_lifecycle_script == 'webpack-dev-server') {
	matchingConfig.demoPath = 'devmateria_demo.json'
}

// load the reusable legacy webpack config from materia-widget-dev
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig(matchingConfig)

delete webpackConfig.entry['creator.js']
delete webpackConfig.entry['player.js']

webpackConfig.entry['modules/matching.js'] = [path.join(__dirname, 'src', 'modules', 'matching.coffee')]

webpackConfig.entry['controllers/creator.js'] = [path.join(__dirname, 'src', 'controllers', 'creator.coffee')]
webpackConfig.entry['controllers/player.js'] = [path.join(__dirname, 'src', 'controllers', 'player.coffee')]

webpackConfig.entry['directives/audioControls.js'] = [path.join(__dirname, 'src', 'directives', 'audioControls.coffee')]
webpackConfig.entry['directives/focusMe.js'] = [path.join(__dirname, 'src', 'directives', 'focusMe.coffee')]
webpackConfig.entry['directives/ngEnter.js'] = [path.join(__dirname, 'src', 'directives', 'ngEnter.coffee')]
webpackConfig.entry['directives/inputStateManager.js'] = [path.join(__dirname, 'src', 'directives', 'inputStateManager.coffee')]

webpackConfig.entry['audioControls.css'] = [
	path.join(__dirname, 'src', 'audioControls.scss'),
	path.join(__dirname, 'src', 'audioControls.html')
]

module.exports = webpackConfig
