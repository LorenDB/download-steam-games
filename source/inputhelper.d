// SPDX-FileCopyrightText: Loren Burkholder <computersemiexpert@outlook.com>
//
// SPDX-License-Identifier: GPL-3.0

module inputhelper;

import std.stdio;
import std.typecons;
import std.string;

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
        else
            write("[y/n] ");
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

string readString(string prompt, Nullable!string defaultValue = Nullable!string.init)
{
    while (true)
    {
        write(prompt);
        if (!defaultValue.isNull && defaultValue.get != "")
            write("[" ~ defaultValue.get ~ "] ");

        string answer = readln().strip;
        switch (answer)
        {
        case "":
            if (!defaultValue.isNull)
                return defaultValue.get;
            break;
        default:
            break;
        }
    }
}