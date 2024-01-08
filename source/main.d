// SPDX-FileCopyrightText: Loren Burkholder <computersemiexpert@outlook.com>
//
// SPDX-License-Identifier: GPL-3.0

import std.stdio;
import std.file;
import std.csv;
import std.string;
import std.json;
import std.path;
import std.conv: to;
import std.process;
import std.sumtype;
import std.algorithm;
import std.typecons;

import argparse;
import asdf;

import inputhelper;
import downloader;
import config;

version(linux)
{
    // Linux is currently the only supported platform
}
else
{
    static assert(false, "Platforms other than Linux are currently not supported!");
}

@(Command("add").ShortDescription("Add a new game to the game list and then exit"))
struct AddGameAction
{
}

@(Command("list").ShortDescription("List all games and then exit"))
struct ListGamesAction
{
    @(NamedArgument("detailed").Description("Print detailed information about every game"))
    bool detailed;
}

@(Command("download").ShortDescription("Download all games in the list"))
struct DownloadGamesAction
{
}

@(Command("remove").ShortDescription("Remove a game by name or ID"))
struct RemoveGameAction
{
    @(PositionalArgument(0))
    string game;
}

@(Command("edit").ShortDescription("Edit a game by name or ID"))
struct EditGameAction
{
    @(PositionalArgument(0))
    string game;
}

@(Command("info").ShortDescription("Get information about a game"))
struct GameInfoAction
{
    @PositionalArgument(0)
    string game;
}

struct Options
{
    @SubCommands SumType!(DownloadGamesAction,
                          AddGameAction,
                          ListGamesAction,
                          RemoveGameAction,
                          EditGameAction,
                          GameInfoAction)
        command;
}

int main(string[] args)
{
    immutable configFileFolder = "~/.config/download-steam-games/".expandTilde;
    immutable configFilePath = configFileFolder ~ "config.json";

    Options options;
    if (!CLI!Options.parseArgs(options, args[1 .. $]))
        return 1;

    if (!configFilePath.exists())
    {
        configFileFolder.mkdirRecurse();
        // create the file
        auto file = File(configFilePath, "w");
        // will automatically close
    }

    auto configFile = File(configFilePath, "r");
    string jsonContent;
    while (!configFile.eof())
        jsonContent ~= configFile.readln().strip();

    AppConfig config;
    if (jsonContent.length > 0)
        config = jsonContent.deserialize!AppConfig;

    if (config.steamcmdPath == "")
        config.steamcmdPath = readString("Where is your SteamCMD executable located?")
                                .expandTilde.asAbsolutePath.to!string;

    if (config.steamAcctName == "")
        config.steamAcctName = readString("What account have you logged into SteamCMD with?");

    if (config.archivePath == "")
        config.archivePath = readString("Where do you want to store your games?", "~/steam-games".nullable)
                                .expandTilde.asAbsolutePath.to!string;
    if (!config.archivePath.exists())
        config.archivePath.mkdirRecurse();

    configFile.close();
    configFile.open(configFilePath, "w");
    configFile.write(config.serializeToJsonPretty());
    configFile.close();

    return options.command.match!((.DownloadGamesAction) {
        foreach (game; config.games)
        {
            string[] platforms;
            if (game.windows)
                platforms ~= "windows";
            if (game.macos)
                platforms ~= "macos";
            if (game.linux)
                platforms ~= "linux";

            // an empty string indicates the non-beta download
            string[] betas = game.betas ~ [""];

            foreach (platform; platforms)
            {
                foreach (beta; betas)
                {
                    int ret = downloadGame(game.name, game.id, platform, beta, config);
                    if (ret != 0)
                        return ret;
                }
            }
            foreach (soundtrack; game.soundtracks)
            {
                int ret = downloadGame(game.name ~ "-soundtrack-" ~ soundtrack.name, soundtrack.id, null, null, config);
                if (ret != 0)
                    return ret;
            }
        }

        return 0;
    }, (.AddGameAction) {
        GameInfo newGame;
        newGame.id = readString("What is the game's ID (check https://steamdb.info if you are unsure)?");
        newGame.name = readString("What name do you want to use for the game?");
        newGame.windows = readTruthyOrFalsy("Does the game support Windows?");
        newGame.macos = readTruthyOrFalsy("Does the game support macOS?");
        newGame.linux = readTruthyOrFalsy("Does the game support Linux?");

        while (readTruthyOrFalsy("Do you want to add a beta version?", false.nullable))
            newGame.betas ~= readString("Enter the beta name:");

        while (readTruthyOrFalsy("Do you want to add a soundtrack?", false.nullable))
        {
            SoundtrackInfo newSoundtrack;
            newSoundtrack.id = readString("What is the soundtrack's ID (check https://steamdb.info if you are unsure)?");
            newSoundtrack.name = readString("What name do you want to use for the soundtrack?");
            newGame.soundtracks ~= newSoundtrack;
        }

        config.games ~= newGame;
        configFile.open(configFilePath, "w");
        configFile.write(config.serializeToJsonPretty());
        configFile.close();
        return 0;
    }, (.ListGamesAction listGames) {
        foreach (game; config.games)
        {
            if (listGames.detailed)
            {
                writeln(game.name);
                writeln("\tID: " ~ game.id);

                string[] platforms;
                if (game.windows)
                    platforms ~= "Windows";
                if (game.macos)
                    platforms ~= "macOS";
                if (game.linux)
                    platforms ~= "Linux";
                if (platforms.length == 0)
                    platforms ~= "None";
                writeln("\tPlatforms: " ~ platforms.to!string);

                if (game.betas.length > 0)
                    writeln("\tBetas: " ~ game.betas.to!string);
                if (game.soundtracks.length > 0)
                {
                    writeln("\tSoundtracks:");
                    foreach (soundtrack; game.soundtracks)
                    {
                        writeln("\t\tName: " ~ soundtrack.name);
                        writeln("\t\tID: " ~ soundtrack.id);
                    }
                }
            }
            else
                writeln(game.id ~ "\t" ~ game.name);
        }

        return 0;
    }, (.RemoveGameAction removeAction) {
        if (removeAction.game == "")
        {
            writeln("No game specified");
            return 0;
        }

        for (int i = 0; i < config.games.length; ++i)
        {
            auto game = config.games[i];
            if (game.name == removeAction.game || game.id == removeAction.game)
            {
                if (readTruthyOrFalsy("Are you sure you want to delete " ~ game.name ~ "?", false.nullable))
                {
                    config.games = config.games.remove(i);
                    writeln("Removed " ~ game.name);
                    configFile.open(configFilePath, "w");
                    configFile.write(config.serializeToJsonPretty());
                    configFile.close();
                }
                else
                    writeln("Aborting.");
                return 0;
            }
        }
        writeln("Could not find a game with the name or ID " ~ removeAction.game ~ "!");
        return -1;
    }, (.EditGameAction editAction) {
        if (editAction.game == "")
        {
            writeln("No game specified");
            return 0;
        }

        for (int i = 0; i < config.games.length; ++i)
        {
            auto game = config.games[i];
            if (game.name == editAction.game || game.id == editAction.game)
            {
                game.id = readString("What is the game's ID (check https://steamdb.info if you are unsure)?", game.id.nullable);
                game.name = readString("What name do you want to use for the game?", game.name.nullable);
                game.windows = readTruthyOrFalsy("Does the game support Windows?", game.windows.nullable);
                game.macos = readTruthyOrFalsy("Does the game support macOS?", game.macos.nullable);
                game.linux = readTruthyOrFalsy("Does the game support Linux?", game.linux.nullable);

                if (game.betas.length > 0)
                {
                    writeln("Betas: " ~ game.betas.to!string);
                    // TODO: allow removing or editing betas
                }
                while (readTruthyOrFalsy("Do you want to add a beta version?", false.nullable))
                    game.betas ~= readString("Enter the beta name:");

                if (game.soundtracks.length > 0)
                {
                    writeln("Soundtracks: " ~ game.soundtracks.to!string);
                    // TODO: allow removing or editing soundtracks
                }
                while (readTruthyOrFalsy("Do you want to add a soundtrack?", false.nullable))
                {
                    SoundtrackInfo newSoundtrack;
                    newSoundtrack.id = readString("What is the soundtrack's ID (check https://steamdb.info if you are unsure)?");
                    newSoundtrack.name = readString("What name do you want to use for the soundtrack?");
                    game.soundtracks ~= newSoundtrack;
                }

                config.games[i] = game;
                configFile.open(configFilePath, "w");
                configFile.write(config.serializeToJsonPretty());
                configFile.close();
                return 0;
            }
        }
        writeln("Could not find a game with the name or ID " ~ editAction.game ~ "!");
        return -1;
    }, (.GameInfoAction infoAction) {
        if (infoAction.game == "")
        {
            writeln("No game specified");
            return 0;
        }

        for (int i = 0; i < config.games.length; ++i)
        {
            auto game = config.games[i];
            if (game.name == infoAction.game || game.id == infoAction.game)
            {
                writeln(game.name);
                writeln("\tID: " ~ game.id);

                string[] platforms;
                if (game.windows)
                    platforms ~= "Windows";
                if (game.macos)
                    platforms ~= "macOS";
                if (game.linux)
                    platforms ~= "Linux";
                if (platforms.length == 0)
                    platforms ~= "None";
                writeln("\tPlatforms: " ~ platforms.to!string);

                if (game.betas.length > 0)
                    writeln("\tBetas: " ~ game.betas.to!string);
                if (game.soundtracks.length > 0)
                {
                    writeln("\tSoundtracks:");
                    foreach (soundtrack; game.soundtracks)
                    {
                        writeln("\t\tName: " ~ soundtrack.name);
                        writeln("\t\tID: " ~ soundtrack.id);
                    }
                }
                return 0;
            }
        }
        writeln("Could not find a game with the name or ID " ~ infoAction.game ~ "!");
        return -1;
    });
}
