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

consumeService("vim-mode-plus", "provideVimModePlus", ({Base}) => {
  const TransformStringByExternalCommand = Base.getClass("TransformStringByExternalCommand")

  class CoffeeCompile extends TransformStringByExternalCommand {
    command = "coffee"
    args = ["-csb", "--no-header"]
  }

  class CoffeeEval extends TransformStringByExternalCommand {
    command = "coffee"
    args = ["-se"]
    getStdin(selection) {
      return `console.log ${selection.getText()}`
    }
  }

  class CoffeeInspect extends TransformStringByExternalCommand {
    command = "coffee"
    args = ["-se"]
    getStdin(selection) {
      return `{inspect} = require 'util';console.log ${selection.getText()}`
    }
  }

  class DeleteWithBackholeRegister extends Base.getClass("Delete") {
    static commandPrefix = "vim-mode-plus-user"
    execute() {
      this.vimState.register.name = "_"
      super.execute()
    }
  }
  DeleteWithBackholeRegister.registerCommand()

  for (const klass of [CoffeeCompile, CoffeeEval, CoffeeInspect]) {
    klass.commandPrefix = "vim-mode-plus-user"
    klass.registerCommand()
  }
})

function hotReloadPackages() {
  atom.project.getPaths().forEach(projectPath => {
    let packName = path.basename(projectPath).replace(/^atom-/, "")
    let pack = atom.packages.getLoadedPackage(packName)
    if (!pack) {
      // Retry with capitalized name. e.g hydrogen -> Hydrogen
      packName = packName[0].toUpperCase() + packName.slice(1)
      pack = atom.packages.getLoadedPackage(packName)
    }

    if (pack) {
      console.log(`deactivating ${packName}`)
      atom.packages.deactivatePackage(packName)
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
  })
}

function clipListOfActiveCommunityPackages(arg) {
  const listOfActiveCommunityPackages =
    atom.packages
      .getActivePackages()
      .filter(pack => !atom.packages.isBundledPackage(pack.name))
      .map(pack => pack.name + ": " + pack.metadata.version)
      .join("\n") + "\n"
  atom.clipboard.write(listOfActiveCommunityPackages)
}

atom.commands.add("atom-workspace", {
  "user:clip-list-of-active-community-packages"() {
    clipListOfActiveCommunityPackages()
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
