{Range} = require 'atom'
path = require 'path'

atom.commands.add 'atom-workspace',
  'user:inspect-element': ->
    atom.openDevTools()
    atom.executeJavaScriptInDevTools('DevToolsAPI.enterInspectElementMode()')

atom.commands.add 'atom-workspace',
  'user:hello': ->
    console.log "HELLO!!"

atom.commands.add 'atom-workspace',
  'user:clear-console': ->
    console.clear()

atom.commands.add 'atom-workspace',
  'user:toggle-show-invisible': ->
    value = atom.config.get('editor.showInvisibles')
    atom.config.set('editor.showInvisibles', not value)

# init.coffee
# -------------------------
# General service comsumer factory
getConsumer = (packageName, provider) ->
  (fn) ->
    atom.packages.onDidActivatePackage (pack) ->
      return unless pack.name is packageName
      service = pack.mainModule[provider]()
      fn(service)

# get vim-mode-plus service API provider
consumeVimModePlus = getConsumer 'vim-mode-plus', 'provideVimModePlus'
requireVimModePlus = (path) ->
  packPath = atom.packages.resolvePackagePath('vim-mode-plus')
  require "#{packPath}/lib/#{path}"

consumeVimModePlus ({Base}) ->
  # MoveToNextWord = Base.getClass('MoveToNextWord')
  # class MoveToNextAlphanumericWord extends MoveToNextWord
  #   wordRegex: /\w+/
  #   @registerCommand()
  #
  # MoveToPreviousWord = Base.getClass('MoveToPreviousWord')
  # class MoveToPreviousAlphanumericWord extends MoveToPreviousWord
  #   wordRegex: /\w+/
  #   @registerCommand()

  TransformStringByExternalCommand = Base.getClass('TransformStringByExternalCommand')
  class Sort extends TransformStringByExternalCommand
    command: 'sort'

  class SortNumerical extends Sort
    command: 'sort'
    args: ['-n']

  class ReverseSort extends SortNumerical
    args: ['-r']

  class ReverseSortNumerical extends ReverseSort
    args: ['-rn']

  class CoffeeCompile extends TransformStringByExternalCommand
    command: 'coffee'
    args: ['-csb', '--no-header']

  class CoffeeCompile extends TransformStringByExternalCommand
    command: 'coffee'
    args: ['-csb', '--no-header']

  class CoffeeEval extends TransformStringByExternalCommand
    command: 'coffee'
    args: ['-se']
    getStdin: (selection) ->
      "console.log #{selection.getText()}"

  class CoffeeInspect extends TransformStringByExternalCommand
    command: 'coffee'
    args: ['-se']
    getStdin: (selection) ->
      """
      {inspect} = require 'util'
      console.log #{selection.getText()}
      """

  userTransformers = [
    Sort, SortNumerical, ReverseSort, ReverseSortNumerical
    CoffeeCompile, CoffeeEval, CoffeeInspect
  ]
  TransformStringBySelectList = Base.getClass('TransformStringBySelectList')
  for transformer in userTransformers
    transformer.commandPrefix = 'vim-mode-plus-user'
    transformer.registerCommand()
    # Push user transformer to transformers so that I can choose my transformers
    # via transform-string-by-select-list command.
    # TransformStringBySelectList::transformers.push(transformer)

atom.commands.add 'atom-workspace',
  'user:package-hot-reload': ->
    atom.project.getPaths().forEach (projectPath) ->
      packName = path.basename(projectPath)
      packName = packName.replace(/^atom-/, '')
      pack = atom.packages.getLoadedPackage(packName)

      if pack?
        console.log "deactivating #{packName}"
        atom.packages.deactivatePackage(packName)
        atom.packages.unloadPackage(packName)

        Object.keys(require.cache)
          .filter (p) ->
            p.indexOf(projectPath + path.sep) is 0
          .forEach (p) ->
            delete require.cache[p]

        atom.packages.loadPackage(packName)
        atom.packages.activatePackage(packName)
        console.log "activated #{packName}"
