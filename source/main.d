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
import std.typecons;

import argparse;
import asdf;

import inputhelper;

version(linux)
{
    // Linux is currently the only supported platform
}
else
{
    static assert(false, "Platforms other than Linux are currently not supported!");
}

struct Options
{
    @(NamedArgument("add-game").Description("Add a new game to the game list and then exit"))
    bool addGame;
}

struct Config
{
    string steamcmdPath;
    string steamAcctName;
    string archivePath;

    struct GameInfo
    {
        string id;
        string name;
        string[] betas;

        struct SoundtrackInfo
        {
            string name;
            string id;
        }
        @serdeOptional SoundtrackInfo[] soundtracks;
        bool windows;
        bool macos;
        bool linux;
    }

    GameInfo[] games;
}
Config config;

int downloadGame(string name, string id, string platform, string beta)
{
    string gameString = name;
    if (beta != "")
        gameString ~= "-" ~ beta;
    if (platform != "")
        gameString ~= "-" ~ platform;
    string scriptPath = getcwd() ~  "/.download-" ~ gameString ~ ".txt";
    string gamePath = config.archivePath ~ "/.downloads/" ~ gameString;

    write("Downloading " ~ name);
    if (beta != "")
        write(" beta " ~ beta);
    if (platform != "")
        write(" for " ~ platform);
    writeln(" to " ~ gamePath);

    auto steamcmdScript = File(scriptPath, "w");
    if (platform != "")
        steamcmdScript.writeln("@sSteamCmdForcePlatformType " ~ platform);
    steamcmdScript.writeln("force_install_dir " ~ gamePath);
    steamcmdScript.writeln("login " ~ config.steamAcctName);
    steamcmdScript.write("app_update " ~ id);
    if (beta != "")
        steamcmdScript.write(" -beta " ~ beta);
    steamcmdScript.writeln(" validate");
    steamcmdScript.writeln("quit");
    steamcmdScript.close();
    scope(exit) remove(scriptPath);

    auto steamcmdProcess = execute([config.steamcmdPath ~ "/steamcmd.sh", "+runscript", scriptPath],
                                null,
                                std.process.Config.none,
                                size_t.max,
                                config.steamcmdPath);
    if (steamcmdProcess.status != 0)
    {
        writeln("Error with SteamCMD");
        return steamcmdProcess.status;
    }
    scope(exit) rmdirRecurse(gamePath);

    write("Archiving " ~ name);
    if (beta != "")
        write(" beta " ~ beta);
    if (platform != "")
        write(" for " ~ platform);
    writeln(" to " ~ gameString ~".tar.gz");

    auto tarProcess = execute(["tar", "--use-compress-program=pigz", "-cf", config.archivePath ~ "/" ~ gameString ~ ".tar.gz", gamePath]);
    if (tarProcess.status != 0)
    {
        writeln("Error with tar");
        return tarProcess.status;
    }

    return 0;
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

    if (jsonContent.length > 0)
        config = jsonContent.deserialize!Config;

    if (config.steamcmdPath == "")
        config.steamcmdPath = readString("Where is your SteamCMD executable located? ")
                                .expandTilde.asAbsolutePath.to!string;

    if (config.steamAcctName == "")
        config.steamAcctName = readString("What account have you logged into SteamCMD with? ");

    if (config.archivePath == "")
        config.archivePath = readString("Where do you want to store your games? ", "~/steam-games".nullable)
                                .expandTilde.asAbsolutePath.to!string;
    if (!config.archivePath.exists())
        config.archivePath.mkdirRecurse();

    if (options.addGame)
    {
        Config.GameInfo newGame;
        newGame.id = readString("What is the game's ID (check https://steamdb.info if you are unsure)? ");
        newGame.name = readString("What name do you want to use for the game? ");
        newGame.windows = readTruthyOrFalsy("Does the game support Windows? ");
        newGame.macos = readTruthyOrFalsy("Does the game support macOS? ");
        newGame.linux = readTruthyOrFalsy("Does the game support Linux? ");

        while (readTruthyOrFalsy("Do you want to add a beta version? ", false.nullable))
            newGame.betas ~= readString("Enter the beta name: ");

        while (readTruthyOrFalsy("Do you want to add a soundtrack? ", false.nullable))
        {
            Config.GameInfo.SoundtrackInfo newSoundtrack;
            newSoundtrack.id = readString("What is the soundtrack's ID (check https://steamdb.info if you are unsure)? ");
            newSoundtrack.name = readString("What name do you want to use for the soundtrack? ");
            newGame.soundtracks ~= newSoundtrack;
        }

        config.games ~= newGame;
    }

    configFile.close();
    configFile.open(configFilePath, "w");
    configFile.write(config.serializeToJsonPretty());
    configFile.close();

    if (options.addGame)
        return 0;

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
                int ret = downloadGame(game.name, game.id, platform, beta);
                if (ret != 0)
                    return ret;
            }
        }
        foreach (soundtrack; game.soundtracks)
        {
            int ret = downloadGame(game.name ~ "-soundtrack-" ~ soundtrack.name, soundtrack.id, null, null);
            if (ret != 0)
                return ret;
        }
    }

    return 0;
}
