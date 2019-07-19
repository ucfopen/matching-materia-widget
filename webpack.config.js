const fs = require('fs')
const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const outputPath = path.join(__dirname, 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const entries = widgetWebpack.getDefaultEntries()
const copy = widgetWebpack.getDefaultCopyList()

// Append the new items we want copied
copy.push({
	from: srcPath+'audioControls.html',
	to: outputPath,
})

entries['creator.js'] = [
	path.join(srcPath, 'modules', 'matching.coffee'),
	path.join(srcPath, 'controllers', 'creator.coffee'),
	path.join(srcPath, 'directives', 'audioControls.coffee'),
	path.join(srcPath, 'directives', 'focusMe.coffee'),
	path.join(srcPath, 'directives', 'ngEnter.coffee'),
	path.join(srcPath, 'directives', 'inputStateManager.coffee')
]

entries['player.js'] = [
	path.join(srcPath, 'modules', 'matching.coffee'),
	path.join(srcPath, 'controllers', 'player.coffee'),
	path.join(srcPath, 'directives', 'audioControls.coffee')
]

entries['guides/player.temp.html'] = [
	path.join(srcPath, '_guides', 'player.md'),
	path.join(srcPath, '_guides', 'creator.md')
]

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
