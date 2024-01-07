// SPDX-FileCopyrightText: Loren Burkholder <computersemiexpert@outlook.com>
//
// SPDX-License-Identifier: GPL-3.0

module downloader;

import std.file;
import std.path;
import std.stdio;
import std.process;

import config;

int downloadGame(string name, string id, string platform, string beta, AppConfig config)
{
    string gameString = name;
    if (beta != "")
        gameString ~= "-" ~ beta;
    if (platform != "")
        gameString ~= "-" ~ platform;
    string scriptPath = config.archivePath ~  "/.download-" ~ gameString ~ ".txt";
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
