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

  # observeVimStates (vimState) ->
  #   vimState.modeManager.onDidDeactivateMode ({mode}) ->
  #     if mode is 'insert'
  #       vimState.editor.clearSelections()

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
  for klass in userTransformers
    klass.commandPrefix = 'vim-mode-plus-user'
    klass.registerCommand()
    klass.registerToSelectList()
    # Push user transformer to transformers so that I can choose my transformers
    # via transform-string-by-select-list command.
    # TransformStringBySelectList::transformers.push(transformer)

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

# class ReplaceString extends TransformString
#   @extend()
#   requireInput: true
#   input: null
#
#   initialize: ->
#     @focusInput(charsMax: 10)
#
#   initialize: ->
#     @onDidConfirmInput (input) =>
#       return unless @input
#       [@from, @to] = input.split('')
#       @processOperation()
#       # @onConfirm(input)
#     # @onDidChangeInput (input) => @addHover(input)
#     # @onDidCancelInput => @cancelOperation()
#     # if @requireTarget
#     #   @onDidSetTarget =>
#     #     @vimState.input.focus({@charsMax})
#     # else
#     #   @vimState.input.focus({@charsMax})
#
#   getNewText: (text) ->
#     from = ///#{_.escapeRegExp(@from)}///g
#     text.replace(from, @to)


  # initialize: ->
  #   @setTarget @new("MoveToRelativeLineWithMinimum", {min: 1})
  #
  # mutateSelection: (selection) ->
  #   [startRow, endRow] = selection.getBufferRowRange()
  #   swrap(selection).expandOverLine()
  #   rows = for row in [startRow..endRow]
  #     text = @editor.lineTextForBufferRow(row)
  #     if @trim and row isnt startRow
  #       text.trimLeft()
  #     else
  #       text
  #   selection.insertText @join(rows) + "\n"
  #
  # join: (rows) ->
  #   rows.join(" #{@input} ")



# atom.commands.add 'atom-text-editor', 'click', (event) ->
#   console.log 'clicked'

atom.commands.add 'atom-workspace',
  'user:inspect-element': -> inspectElement()
  'user:hello': -> hello()
  'user:clear-console': -> clearConsole()
  'user:toggle-show-invisible': -> toggleInvisible()
  'user:package-hot-reload': -> hotReloadPackages()
