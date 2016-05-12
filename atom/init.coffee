{Range} = require 'atom'
path = require 'path'

# General service comsumer factory
# -------------------------
consumeService = (packageName, providerName, fn) ->
  disposable = atom.packages.onDidActivatePackage (pack) ->
    return unless pack.name is packageName
    service = pack.mainModule[providerName]()
    fn(service)
    disposable.dispose()

getEditorState = null
consumeService 'vim-mode-plus', 'provideVimModePlus', (service) ->
  {Base, getEditorState} = service

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

narrowSearch = null
consumeService 'narrow', 'provideNarrow', ({search}) ->
  narrowSearch = search

narrowSearchFromVimModePlusSearch = ->
  vimState = getEditorState(atom.workspace.getActiveTextEditor())
  text = vimState.searchInput.editor.getText()
  vimState.searchInput.confirm()
  console.log 'searching', text
  narrowSearch(text)

hotReloadPackages = ->
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

inspectElement = ->
  atom.openDevTools()
  atom.executeJavaScriptInDevTools('DevToolsAPI.enterInspectElementMode()')

hello = ->
  console.log "hello!"

clearConsole = ->
  console.clear()

toggleInvisible = ->
  param = 'editor.showInvisibles'
  atom.config.set(param, not atom.config.get(param))

atom.commands.add 'atom-workspace',
  'user:inspect-element': -> inspectElement()
  'user:hello': -> hello()
  'user:clear-console': -> clearConsole()
  'user:toggle-show-invisible': -> toggleInvisible()
  'user:package-hot-reload': -> hotReloadPackages()
  'user:narrow-search': -> narrowSearchFromVimModePlusSearch()
