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

consumeService("vim-mode-plus", "provideVimModePlus", service => {
  return
  const Base = service.Base
  const TransformStringByExternalCommand = Base.getClass("TransformStringByExternalCommand")

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

  class DeleteWithBackholeRegister extends Base.getClass("Delete") {
    static commandPrefix = "vim-mode-plus-user"
    execute() {
      this.vimState.register.name = "_"
      super.execute()
    }
  }
  DeleteWithBackholeRegister.registerCommand()

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

function clipListOfActiveCommunityPackages(arg) {
  const texts = atom.packages
    .getActivePackages()
    .filter(pack => !atom.packages.isBundledPackage(pack.name))
    .map(pack => pack.name + ": " + pack.metadata.version)
  atom.clipboard.write(texts.join("\n") + "\n")
}

function clipListOfLoadedCommunityPackages(arg) {
  const texts = atom.packages
    .getLoadedPackages()
    .filter(pack => !atom.packages.isBundledPackage(pack.name))
    .map(pack => pack.name + ": " + pack.metadata.version)
  atom.clipboard.write(texts.join("\n") + "\n")
}

atom.commands.add("atom-text-editor", "user:autocomplete-plus-select-next-and-confirm", function() {
  const editor = this.getModel()
  atom.commands.dispatch(editor.element, "core:move-down")
  atom.commands.dispatch(editor.element, "autocomplete-plus:confirm")
})

atom.commands.add("atom-workspace", {
  "user:clip-list-of-active-community-packages"() {
    clipListOfActiveCommunityPackages()
  },
  "user:clip-list-of-loaded-community-packages"() {
    clipListOfLoadedCommunityPackages()
  },
  "user:inspect-element"() {
    atom.openDevTools()
    atom.executeJavaScriptInDevTools("DevToolsAPI.enterInspectElementMode()")
  },
  "user:hello"() {
    console.log("hello!")
  },
  "user:clear-console"() {
    console.clear()
  },
  "user:toggle-show-invisible"() {
    const param = "editor.showInvisibles"
    atom.config.set(param, !atom.config.get(param))
  },
  "user:package-hot-reload"() {
    hotReloadPackages()
  },
  "user:vmp-version"() {
    console.log(atom.packages.getActivePackage("vim-mode-plus").metadata.version)
  },
  "user:clip-as-json"() {
    // Broken
    const text = atom.workspace.getActiveTextEditor().getSelectedText()
    console.log(JSON.stringify({configSchema: CONFIG}, null, "  "))
  },
})
