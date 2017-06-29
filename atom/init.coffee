{Range, CompositeDisposable, Disposable} = require 'atom'
path = require 'path'
_ = require 'underscore-plus'

# fontFamily: "Ricty"
# fontFamily: "Iosevka-Light"
# fontFamily: "FiraCode-Retina"

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
  # return
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

countVmpDecorations = (arg) ->
  getDecorations = (editor) ->
    pattern = /vim-mode-plus/

    decorations = []
    for id, decoration of editor.decorationsStateForScreenRowRange(0, editor.getLineCount())
      if decoration.properties.class.match(pattern)
        decorations.push(decoration)
    decorations

  decorations = []
  for editor in atom.workspace.getTextEditors()
    decorations.push(getDecorations(editor)...)
  countResult = _.countBy decorations, (d) -> d.properties.class
  {inspect} = require 'util'
  console.log inspect(countResult)

hotReloadPackages = ->
  atom.project.getPaths().forEach (projectPath) ->
    packName = path.basename(projectPath)
    packName = packName.replace(/^atom-/, '')
    pack = atom.packages.getLoadedPackage(packName)
    unless pack?
      # Retry with capitalized name. e.g hydrogen -> Hydrogen
      packName = packName[0].toUpperCase() + packName[1...]
      pack = atom.packages.getLoadedPackage(packName)

    if pack?
      console.log "deactivating #{packName}"
      atom.packages.deactivatePackage(packName)
      atom.packages.unloadPackage(packName)

      Object.keys(require.cache)
        .filter (p) -> p.indexOf(projectPath + path.sep) is 0
        .forEach (p) ->
          unless p.includes('/node_modules/zeromq/')
            delete require.cache[p]

      atom.packages.loadPackage(packName)
      atom.packages.activatePackage(packName)
      console.log "activated #{packName}"

saveListOfActiveCommunityPackagesToClipBoard = (arg) ->
  listOfActiveCommunityPackages = atom.packages.getActivePackages()
    .filter (pack) -> not atom.packages.isBundledPackage(pack.name)
    .map (pack) -> pack.name + ': ' + pack.metadata.version
    .join("\n") + "\n"
  atom.clipboard.write(listOfActiveCommunityPackages)

atom.commands.add 'atom-workspace',
  'user:save-list-of-active-community-packages-to-clip-board': ->
  'user:save-list-of-active-community-packages-to-clip-board': ->
    saveListOfActiveCommunityPackagesToClipBoard()

  'user:inspect-element': ->
    atom.openDevTools()
    atom.executeJavaScriptInDevTools('DevToolsAPI.enterInspectElementMode()')

  'user:open-tryit-coffee': ->
    atom.workspace.open("/Users/t9md/Dropbox/vim/tryit/tryit.coffee")

  'user:count-vmp-decorations': ->
    countVmpDecorations()

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

  'user:clip-as-json': ->
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    console.log JSON.stringify({configSchema: CONFIG}, null, '  ')

  'user:focus-taken-away-repro': ->
    for dir in atom.project.getPaths()
      atom.project.removePath(dir)
