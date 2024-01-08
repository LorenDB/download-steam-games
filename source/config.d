// SPDX-FileCopyrightText: Loren Burkholder <computersemiexpert@outlook.com>
//
// SPDX-License-Identifier: GPL-3.0

module config;

import std.typecons;

import asdf;

struct SoundtrackInfo
{
    string name;
    string id;
}

struct GameInfo
{
    string id;
    string name;
    string[] betas;
    @serdeOptional SoundtrackInfo[] soundtracks;
    bool windows;
    bool macos;
    bool linux;
}

struct AppConfig
{
    string steamcmdPath;
    string steamAcctName;
    string archivePath;

    GameInfo[] games;

    Nullable!GameInfo getGameByNameOrId(string nameOrId)
    {
        foreach (game; games)
            if (game.name == nameOrId || game.id == nameOrId)
                return game.nullable;

        return Nullable!GameInfo.init;
    }
}
