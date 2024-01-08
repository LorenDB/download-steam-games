// SPDX-FileCopyrightText: Loren Burkholder <computersemiexpert@outlook.com>
//
// SPDX-License-Identifier: GPL-3.0

module info;

import std.stdio;
import std.conv : to;

import config;

void printGameInfo(GameInfo game, bool detailed)
{
    if (detailed)
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
