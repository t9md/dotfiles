"use babel"
// const {Range, CompositeDisposable, Disposable} = require('atom');
const path = require("path")
const _ = require("underscore-plus")

// fontFamily: "Ricty"
// fontFamily: "Iosevka-Light"
// fontFamily: "FiraCode-Retina"

function consumeService(packageName, functionName, fn) {
  const consume = pack => fn(pack.mainModule[functionName]())

  if (atom.packages.isPackageActive(packageName)) {
    consume(atom.packages.getActivePackage(packageName))
  } else {
    const disposable = atom.packages.onDidActivatePackage(pack => {
      if (pack.name === packageName) {
        disposable.dispose()
        consume(pack)
      }
    })
  }
}

function consumeVimModePlusService(fn) {
  const consume = (pack) => fn(pack.mainModule.provideVimModePlus())

  const pack = atom.packages.getActivePackage('vim-mode-plus')
  if (pack) {
    consume(pack)
  } else {
    const disposable = atom.packages.onDidActivatePackage(pack => {
      if (pack.name === 'vim-mode-plus') {
        disposable.dispose()
        consume(pack)
      }
    })
  }
}


// consumeService('status-bar', "provideStatusBar", service => {
//   const item = document.createElement('div')
//   item.className = 'inline-block'
//
//   const update = editor => {
//     let text = ""
//     if (editor) {
//       // Show "TextMate" or "TreeSitter" on status-bar.
//       text = editor.languageMode.constructor.name.replace(/LanguageMode$/, "")
//     }
//     item.textContent = text
//   }
//
//   atom.workspace.observeTextEditors(editor => {
//     editor.onDidChangeGrammar(() => {
//       if (atom.workspace.getActiveTextEditor() === editor) {
//         update(editor)
//       }
//     })
//   })
//   atom.workspace.onDidChangeActiveTextEditor(update)
//   service.addLeftTile({item})
// })

consumeVimModePlusService(service => {
  return
  // To evaluate constom-operation feat
  class DeleteWithBackholeRegister extends service.getClass("Delete") {
    execute() {
      this.vimState.register.name = "_"
      super.execute()
    }
  }
  DeleteWithBackholeRegister.commandPrefix = "vim-mode-plus-user"
  DeleteWithBackholeRegister.registerCommand()

  const TransformStringByExternalCommand = service.getClass("TransformStringByExternalCommand")

  class CustomSort extends TransformStringByExternalCommand {
    static commandPrefix = "vim-mode-plus-user"
    command = "sort"
    args = ["-rn"]
  }
  CustomSort.registerToSelectList()
  CustomSort.registerCommand()

  class CoffeeCompile extends TransformStringByExternalCommand {
    static commandPrefix = "vim-mode-plus-user"
    command = "coffee"
    args = ["-csb", "--no-header"]
  }
  CoffeeCompile.registerCommand()

  class CoffeeEval extends TransformStringByExternalCommand {
    // cd /tmp; ls -l
    static commandPrefix = "vim-mode-plus-user"
    command = "coffee"
    args = ["-se"]
    getStdin(selection) {
      return `console.log ${selection.getText()}`
    }
  }
  CoffeeEval.registerCommand()

  class CoffeeInspect extends TransformStringByExternalCommand {
    static commandPrefix = "vim-mode-plus-user"
    command = "coffee"
    args = ["-se"]
    getStdin(selection) {
      return `{inspect} = require 'util';console.log ${selection.getText()}`
    }
  }
  CoffeeInspect.registerCommand()

  class InsertCharacter extends Base.getClass("Operator") {
    static commandPrefix = "vim-mode-plus-user"
    target = "Empty"
    readInputAfterSelect = true

    mutateSelection(selection) {
      const point = selection.getHeadBufferPosition()
      this.editor.setTextInBufferRange([point, point], this.input.repeat(this.getCount()))
    }
  }
  InsertCharacter.registerCommand()
})

async function hotReloadPackages() {
  for (const projectPath of atom.project.getPaths()) {
    let packName = path.basename(projectPath).replace(/^atom-/, "")
    let pack = atom.packages.getLoadedPackage(packName)
    if (!pack) {
      // Retry with capitalized name. e.g hydrogen -> Hydrogen
      packName = packName[0].toUpperCase() + packName.slice(1)
      pack = atom.packages.getLoadedPackage(packName)
    }

    if (pack) {
      console.log(`deactivating ${packName}`)
      await atom.packages.deactivatePackage(packName)
      atom.packages.unloadPackage(packName)

      Object.keys(require.cache)
        .filter(p => p.indexOf(projectPath + path.sep) === 0)
        .forEach(p => {
          if (!p.includes("/node_modules/zeromq/")) {
            return delete require.cache[p]
          }
        })

      atom.packages.loadPackage(packName)
      atom.packages.activatePackage(packName)
      console.log(`activated ${packName}`)
    }
  }
}

function toggleSuppressAutoCompletePlus() {
  const className = "suppress-autocomplete-plus"
  const editor = atom.workspace.getActiveTextEditor()
  const suppressed = editor.element.classList.contains(className)
  editor.element.classList.toggle(className, !suppressed)
}

class SyntaxNodeExproler {
  static create() {
    global = new this()
  }

  constructor() {
    this.marker = null
    this.node = null
  }

  markParent() {
    const editor = atom.workspace.getActiveTextEditor()

    let node

    if (this.node) {
      if (this.node.parent) {
        node = this.node.parent
      } else {
        console.log("no more parent!");
        return
      }
    } else {
      node = editor.languageMode.getSyntaxNodeAtPosition(editor.getCursorBufferPosition())
    }

    if (this.marker) {
      this.marker.destroy()
    }
    console.log({'nodeType': node.type, 'named': node.isNamed});
    this.node = node
    this.marker = editor.markBufferRange(node.range)
    editor.decorateMarker(this.marker, {
      type: 'highlight',
      class: 'vim-mode-plus-highlight-search',
    })

  }

  clear() {
    if (this.marker) {
      this.marker.destroy()
      this.marker = null
    }
    if (this.node) {
      this.node = null
    }
    console.log('clear')
  }
}
global._sn = new SyntaxNodeExproler()

atom.commands.add("atom-workspace", {
  "user:hello"() {
    console.log("hello!")
  },
  "user:clear-console"() {
    console.clear()
  },
  "user:sn-mark-parent"() {
    global._sn.markParent()
  },
  "user:sn-clear"() {
    global._sn.clear()
  },
  "user:toggle-show-invisible"() {
    const param = "editor.showInvisibles"
    atom.config.set(param, !atom.config.get(param))
  },
  "user:toggle-use-tree-sitter-parsers"() {
    const param = "core.useTreeSitterParsers"
    atom.config.set(param, !atom.config.get(param))
    console.log(param, atom.config.get(param))
  },
  "user:report-language-mode"() {
    const editor = atom.workspace.getActiveTextEditor()
    const name = editor.languageMode.constructor.name
    console.log(name);
  },
  "user:package-hot-reload"() {
    hotReloadPackages()
  },
  "user:toggle-suppress-auto-complete-plus"() {
    toggleSuppressAutoCompletePlus()
  },
})

// atom.keymaps.addKeystrokeResolver(({event}) => {
//   // event.
//   // delete e
//   // delete e.keymap
//   // console.log(e);
//   const {keyCode, key} = event
//   console.log(keyCode, key);
//   // if (keyCode === 221) {
//   //   return 'j'
//   // }
// })
