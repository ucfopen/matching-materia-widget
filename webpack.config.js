const path = require('path')

let srcPath = path.join(process.cwd(), 'src')
let outputPath = path.join(process.cwd(), 'build')


let matchingConfig = {}
//override the demo with a copy that assigns ids to each question for dev purposes
if (process.env.npm_lifecycle_script == 'webpack-dev-server') {
	matchingConfig.demoPath = 'devmateria_demo.json'
	matchingConfig.preCopy = [{
		from: `${srcPath}/devmateria_demo.json`,
		to: outputPath,
	}]
}

// load the reusable legacy webpack config from materia-widget-dev
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig(matchingConfig)

module.exports = webpackConfig
