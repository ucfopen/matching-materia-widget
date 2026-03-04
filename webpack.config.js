const fs = require('fs')
const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const outputPath = path.join(__dirname, 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const copy = widgetWebpack.getDefaultCopyList()

const entries = {
	'creator': [
			path.join(srcPath, 'creator.html'),
			path.join(srcPath, 'modules', 'matching.js'),
			path.join(srcPath, 'controllers', 'creator.js'),
			path.join(srcPath, 'directives', 'focusMe.js'),
			path.join(srcPath, 'directives', 'ngEnter.js'),
			path.join(srcPath, 'directives', 'inputStateManager.js'),
			path.join(srcPath, 'directives', 'audioControls.js'),
			path.join(srcPath, 'creator.scss'),
	],
	'player': [
			path.join(srcPath, 'player.html'),
			path.join(srcPath, 'modules', 'matching.js'),
			path.join(srcPath, 'controllers', 'player.js'),
			path.join(srcPath, 'directives', 'audioControls.js'),
			path.join(srcPath, 'player.scss'),
	],
	'scorescreen': [
		path.join(srcPath, 'scoreScreen.html'),
	 	path.join(srcPath, 'scoreScreen.js'),
	 	path.join(srcPath, 'scoreScreen.scss'),
	],

	'audioControls': [
			path.join(srcPath, 'audioControls.html'),
			path.join(srcPath, 'directives', 'audioControls.js'),
			path.join(srcPath, 'audioControls.scss'),
	]
}

const customCopy = copy.concat([
	{
		from: path.join(__dirname, 'src', '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	},

	{
		from: path.join(__dirname, 'src', 'assets', 'volume-low.svg'), 
		to: path.join(outputPath, 'assets', 'volume-low.svg'),
	},

])

// options for the build
const options = {
	copyList: customCopy,
	entries: entries
}

let buildConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

module.exports = buildConfig
