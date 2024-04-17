const fs = require('fs')
const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const outputPath = path.join(__dirname, 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const copy = widgetWebpack.getDefaultCopyList()

const entries = {
	'creator': [
			path.join(srcPath, 'creator.html'),
			path.join(srcPath, 'modules', 'matching.coffee'),
			path.join(srcPath, 'controllers', 'creator.coffee'),
			path.join(srcPath, 'directives', 'focusMe.coffee'),
			path.join(srcPath, 'directives', 'ngEnter.coffee'),
			path.join(srcPath, 'directives', 'inputStateManager.coffee'),
			path.join(srcPath, 'directives', 'audioControls.coffee'),
			path.join(srcPath, 'creator.scss'),
	],
	'player': [
			path.join(srcPath, 'player.html'),
			path.join(srcPath, 'modules', 'matching.coffee'),
			path.join(srcPath, 'controllers', 'player.coffee'),
			path.join(srcPath, 'directives', 'audioControls.coffee'),
			path.join(srcPath, 'player.scss'),
	],
	'audioControls': [
			path.join(srcPath, 'audioControls.html'),
			path.join(srcPath, 'directives', 'audioControls.coffee'),
			path.join(srcPath, 'audioControls.scss'),
	]
}

const customCopy = copy.concat([
	{
		from: path.join(srcPath, '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	}
])

// options for the build
const options = {
	copyList: customCopy,
	entries: entries
}

let buildConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

module.exports = buildConfig
