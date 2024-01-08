# download-steam-games

This is a simple script to automate archiving your Steam games.

## Features

download-steam-games supports the following features:

- Download game builds for any platform. Even though the script runs on Linux only (for now), you can download
  game builds for Windows, macOS, and Linux.
- Download builds of publicly available beta versions. If your game has publicly downloadable beta versions, you
  can specify one or more betas to archive along with the main release of the game. To find betas, you can look
  at the branches list on your game; see the [KSP2 branches](https://steamdb.info/app/954850/depots/) for an example.
- Add soundtracks to your games. For games that provide soundtracks as a separate package, you can add the soundtrack
  to your game; this both ties it to its parent game and prevents you from downloading it multiple times for different
  platforms.

## Installation

You will need to install [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) on a Linux
machine (other platforms are not supported for now). **Be sure that you use the manual installation
option listed on the SteamCMD page**; that's the only supported installation method for now, although
system SteamCMD packages may get support eventually. It's not important to put SteamCMD at any particular
location, as download-steam-games will ask you for the location when you first run it.

Once you've installed SteamCMD, `cd` to the SteamCMD folder and run `./steamcmd.sh`. This will start
an interactive prompt. In this prompt, run the `login <username>` command with your Steam username. This
will save your Steam credentials so download-steam-games does not have to ask you for them every time.

Next you'll need to install a D toolchain if you don't have one on your system. Install a D compiler and
the Dub package; if in doubt, choose DMD for your compiler.

You also need to ensure `tar` and `pigz` are installed; most modern distros probably provide them
out of the box.

Now `git pull` this repo (if you haven't already) and `cd` into it. Run `dub run`; this will build the app
and run it. As this is the first run, it will ask you for various configuration options. Since you haven't
added any games yet, nothing will be downloaded.

You now have several options for running this program in the future:

1. Continue to use `dub run`. This, combined with regular calls to `git pull`, will ensure that you stay up to date
   but also means that you will have to `cd` to the source directory when you want to run it.
2. Copy the app binary (`./download-steam-games`) to somewhere in your PATH; I recommend `~/.local/bin`.
3. Leave the binary where it is and run it either from the source directory or run it by its full path.

The rest of this README assumes you have copied the binary to your PATH; please adapt the command if you have not. If
you decide to use the `dub run` method, please note that you need to add a `--` to your command if you need to pass any
arguments, like so: `dub run -- list`

## Usage

Open a terminal in the source directory and run `download-steam-games add`. This allows you to add a game to your list of
games to download. You will need to provide your game's Steam ID; you can find this (and other information) at https://steamdb.info.
You also will be asked for the game's name; you can respond with anything you want, since this is just used for the folder
name for the game download and the final `.tar.gz` filename.

A few notes about the platform support questions:

1. Never answer `yes` for a platform that your game does not support; however, you may answer `no` if
   you wish not to archive the game for that platform.
2. Just because a game runs on Linux through Proton does not mean it has Linux support; only answer `yes`
   to Linux support if the game actually has a native Linux version available.
3. If in doubt about what platforms are supported, look at the game's Steam page or at https://steamdb.info.

Once you have added a game or so, run `download-steam-games` to download the games. Once the script exits, you should have
all your games in your specified download folder, all nicely `.tar.gz`ed.

To view a list of all the games you have installed, you can run `download-steam-games list`. This will only display the name
and ID of all your games; if you want to view more information, run `download-steam-games list --detailed` or
`download-steam-games info <game name or ID>`; this will print all information stored about your game. If you want to edit a
game, run `download-steam-games edit <game name or ID>`; to remove a game from the list, run `download-steam-games remove <game name or ID>`.

For any other commands that may be missed here, run `download-steam-games --help` or `download-steam-games <command> --help`.