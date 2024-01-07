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
        bool windows;
        bool macos;
        bool linux;
    }

    GameInfo[] games;
}

// prompt should have a space at the end!
bool readTruthyOrFalsy(string prompt, Nullable!bool defaultValue = Nullable!bool.init)
{
    while (true)
    {
        write(prompt);
        if (!defaultValue.isNull)
        {
            if (defaultValue.get == true)
                write("[Y/n] ");
            else
                write("[y/N] ");
        }
        string answer = readln().strip.toLower;
        switch (answer)
        {
        case "y":
        case "yes":
        case "true":
        case "1":
            return true;
        case "n":
        case "no":
        case "false":
        case "0":
            return false;
        case "":
            if (!defaultValue.isNull)
                return defaultValue.get;
            break;
        default:
            break;
        }
    }
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

    Config config;
    if (jsonContent.length > 0)
        config = jsonContent.deserialize!Config;

    while (config.steamcmdPath == "")// || !exists(config.steamcmdPath))
    {
        write("Where is your SteamCMD executable located? ");
        config.steamcmdPath = readln().strip.expandTilde.asAbsolutePath.to!string;
    }

    while (config.steamAcctName == "")
    {
        write("What account have you logged into SteamCMD with? ");
        config.steamAcctName = readln().strip;
    }

    while (config.archivePath == "")
    {
        write("Where do you want to store your games? ");
        config.archivePath = readln().strip.expandTilde.asAbsolutePath.to!string;
    }
    if (!config.archivePath.exists())
        config.archivePath.mkdirRecurse();

    if (options.addGame)
    {
        Config.GameInfo newGame;
        write("What is the game's ID (check https://steamdb.info if you are unsure)? ");
        newGame.id = readln().strip;
        write("What name do you want to use for the game? ");
        newGame.name = readln().strip;
        newGame.windows = readTruthyOrFalsy("Does the game support Windows? ");
        newGame.macos = readTruthyOrFalsy("Does the game support macOS? ");
        newGame.linux = readTruthyOrFalsy("Does the game support Linux? ");

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
                string gameString = game.name ~ "-" ~ platform;
                string scriptPath = getcwd() ~  "/.download-" ~ gameString ~ ".txt";
                string gamePath = config.archivePath ~ "/.downloads/" ~ gameString;

                write("Downloading " ~ game.name);
                if (beta != "")
                    write(" beta " ~ beta);
                writeln(" for " ~ platform ~ " to " ~ gamePath ~ "...");

                auto steamcmdScript = File(scriptPath, "w");
                steamcmdScript.writeln("@sSteamCmdForcePlatformType " ~ platform);
                steamcmdScript.writeln("force_install_dir " ~ gamePath);
                steamcmdScript.writeln("login " ~ config.steamAcctName);
                steamcmdScript.write("app_update " ~ game.id);
                if (beta != null)
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

                write("Archiving " ~ game.name);
                if (beta != "")
                    write(" beta " ~ beta);
                writeln(" for " ~ platform ~ " to " ~ gameString ~".tar.gz...");

                auto tarProcess = execute(["tar", "--use-compress-program=pigz", "-cf", gameString ~ ".tar.gz", gamePath]);
                if (tarProcess.status != 0)
                {
                    writeln("Error with tar");
                    return tarProcess.status;
                }
            }
        }
    }

    return 0;
}
