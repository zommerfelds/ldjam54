# Gamejam template

A small Heaps project template for web-based games.

[Live demo](https://zommerfelds.github.io/gamejam-template/)

## Instructions

### Prerequisites

* Install [Haxe](https://haxe.org/)
* Install [Git Bash](https://gitforwindows.org/) if you are on Windows
* Optional: [install](https://github.com/HaxeFoundation/hashlink/wiki/Building-and-Installing) HashLink
* Optional: install Python and livereload `pip install livereload`
* Optional: install [Git LFS](https://git-lfs.github.com/)
* Optional: install Visual Studio Code

### Get the code

Fork this repo.

Or manually copy the repo to a new repo: https://github.com/new

```
git clone -o template https://github.com/zommerfelds/gamejam-template.git ldjamXX
cd ldjamXX
git lfs install
git remote add origin https://github.com/zommerfelds/ldjamXX.git # replace zommerfelds by your username
git branch -M main
git push -u origin main
```

* Optional: enable GitHub pages in the repo settings (`/settings/pages`)

### Building

* Install dependencies: `haxelib install build-js.hxml`
* Build the assets package: `bash run buildres` or `bash run buildres_py` (depending on your system setup)
* Compile the project: `bash run compile` (or Ctrl+Shift+B in vscode)

## TODO

* Add credits button
* Easily support query params for debugging

## Random links for game jams

* Sound generator: [jsfxr](https://sfxr.me/)
* Music tool: [Bosca Ceoil download](https://boscaceoil.net/downloads/boscaceoil_win_v2.zip)
* Level editor: [LDtk](https://ldtk.io/)
* AI generated music: https://ecrettmusic.com/
* Generic tips and links: https://sharks-interactive.github.io/JamTips/
