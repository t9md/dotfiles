{Range} = require 'atom'
path = require 'path'

# General service comsumer factory
# -------------------------
consumeService = (packageName, providerName, fn) ->
  disposable = atom.packages.onDidActivatePackage (pack) ->
    if pack.name is packageName
      service = pack.mainModule[providerName]()
      fn(service)
      disposable.dispose()

getEditorState = null
consumeService 'vim-mode-plus', 'provideVimModePlus', (service) ->
  {Base, getEditorState, observeVimStates} = service

  observeVimStates (vimState) ->
    vimState.modeManager.onDidActivateMode (event) ->
      console.log 'activate', event
    # vimState.modeManager.onDidDeactivateMode (event) ->
    #   console.log 'de-activate', event

  register = (klass) ->
    klass.commandPrefix = 'vim-mode-plus-user'
    klass.registerCommand()
    klass.registerToSelectList()

  TransformStringByExternalCommand = Base.getClass('TransformStringByExternalCommand')
  # class Sort extends TransformStringByExternalCommand
  #   command: 'sort'
  #   register(this)

  class SortNumerical extends TransformStringByExternalCommand
    command: 'sort'
    args: ['-n']
    register(this)

  class ReverseSort extends SortNumerical
    register(this)
    args: ['-r']

  class ReverseSortNumerical extends ReverseSort
    register(this)
    args: ['-rn']

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
    register(this)
    command: 'coffee'
    args: ['-se']
    getStdin: (selection) ->
      """
      {inspect} = require 'util'
      console.log #{selection.getText()}
      """

getEditor = ->
  atom.workspace.getActiveTextEditor()

getActiveVimState = ->
  getEditorState(getEditor())

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

moveToFirstCharacterOfLineOrIndent = (event, editor) ->
  cursorMoved = null
  for cursor in editor.getCursors()
    if cursor.isAtBeginningOfLine()
      point = cursor.getBufferPosition()
      cursor.moveToFirstCharacterOfLine()
      if not cursorMoved? and not point.isEqual(cursor.getBufferPosition())
        cursorMoved = true

  unless cursorMoved
    event.abortKeyBinding()

atom.commands.add 'atom-workspace',
  'user:inspect-element': -> inspectElement()
  'user:hello': -> hello()
  'user:clear-console': -> clearConsole()
  'user:toggle-show-invisible': -> toggleInvisible()
  'user:package-hot-reload': -> hotReloadPackages()

atom.commands.add 'atom-text-editor',
  'user:move-to-first-character-of-line-or-indent': (event) ->
    moveToFirstCharacterOfLineOrIndent(event, this.getModel())
