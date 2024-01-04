# download-steam-games

This is a simple script to automate archiving your Steam games.

## Dependencies

You will need to install SteamCMD on a Linux machine (other platforms are not supported for now).
You also need to ensure `tar` and `pigz` are installed; most modern distros probably provide them
out of the box.

## Usage

Start by running SteamCMD and issuing the `login <username>` command with your Steam username. This
will save your Steam credentials so this script does not have to ask you for them every time.

Open a terminal in the source directory and run `dub run -- --add-game`. This allows you to add a game
to your list of games to download. You will need to provide your game's Steam ID; you can find this
(and other information) at https://steamdb.info. You also will be asked for the game's name; you can respond
with anything you want, since this is just used for the folder name for the game download and the final
`.tar.gz` filename.

A few notes about the platform support questions:

1. Answers should be either `true` or `false`.
2. Never answer `true` for a platform that your game does not support; however, you may answer `false` if
   you wish not to archive the game for that platform.
3. Just because a game runs on Linux through Proton does not mean it has Linux support; only answer `true`
   to Linux support if the game actually has a native Linux version available.
4. If in doubt about what platforms are supported, look at the game's Steam page or at https://steamdb.info.

Once you have added a game or so, run `dub run` to download the games. Once the script exits, you should have
all your games in your specified download folder, all nicely `.tar.gz`ed.
