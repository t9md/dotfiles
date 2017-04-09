{Range} = require 'atom'
path = require 'path'
# _ = require 'underscore-plus'
# fs = require 'fs-plus'

# General service comsumer factory
# -------------------------
consumeService = (packageName, providerName, fn) ->
  if atom.packages.isPackageActive(packageName)
    pack = atom.packages.getActivePackage(packageName)
    fn(pack.mainModule[providerName]())
  else
    disposable = atom.packages.onDidActivatePackage (pack) ->
      if pack.name is packageName
        disposable.dispose()
        fn(pack.mainModule[providerName]())

getEditorState = null

consumeService 'vim-mode-plus', 'provideVimModePlus', (service) ->
  {Base, getEditorState, observeVimStates} = service

  register = (klass) ->
    klass.commandPrefix = 'vim-mode-plus-user'
    klass.registerCommand()
    klass.registerToSelectList()

  TransformStringByExternalCommand = Base.getClass('TransformStringByExternalCommand')
  class CoffeeCompile extends TransformStringByExternalCommand
    register(this)
    command: 'coffee'
    args: ['-csb', '--no-header']

  class CoffeeEval extends TransformStringByExternalCommand
    register(this)
    command: 'coffee'
    args: ['-se']
    getStdin: (selection) ->
      "console.log #{selection.getText()}"

  class CoffeeInspect extends TransformStringByExternalCommand
    # [1..10]
    register(this)
    command: 'coffee'
    args: ['-se']
    getStdin: (selection) ->
      """
      {inspect} = require 'util'
      console.log #{selection.getText()}
      """

getActiveVimState = ->
  getEditorState(atom.workspace.getActiveTextEditor())

# toggleDevTools = ->
#   activePane = atom.workspace.getActivePane()
#   atom.toggleDevTools().then ->
#     # activePane.focus()
#     atom.focus()
#     # console.log "WHOOO", activePane.isFocused()
#     # atom.workspace.ac

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

atom.commands.add 'atom-workspace',
  'user:inspect-element': ->
    atom.openDevTools()
    atom.executeJavaScriptInDevTools('DevToolsAPI.enterInspectElementMode()')

  'user:open-tryit-coffee': ->
    atom.workspace.open("/Users/t9md/Dropbox/vim/tryit/tryit.coffee")

  'user:hello': ->
    console.log "hello!"

  'user:clear-console': ->
    console.clear()

  'user:toggle-show-invisible': ->
    param = 'editor.showInvisibles'
    atom.config.set(param, not atom.config.get(param))

  'user:package-hot-reload': ->
    hotReloadPackages()

  'user:vmp-version': ->
    console.log atom.packages.getActivePackage('vim-mode-plus').metadata.version

  # 'user:toggle-dev-tools': ->
  #   toggleDevTools()
