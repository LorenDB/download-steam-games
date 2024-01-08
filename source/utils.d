// SPDX-FileCopyrightText: Loren Burkholder <computersemiexpert@outlook.com>
//
// SPDX-License-Identifier: GPL-3.0

module utils;

int indexOf(BaseType)(BaseType[] range, BaseType value)
{
    for (int i = 0; i < range.length; ++i)
    {
        if (range[i] == value)
            return i;
    }
    return -1;
}

int indexOf(alias pred, BaseType)(BaseType[] range, BaseType value)
{
    for (int i = 0; i < range.length; ++i)
    {
        if (pred(range[i], value))
            return i;
    }
    return -1;
}

int indexOf(alias pred, BaseType)(BaseType[] range)
{
    for (int i = 0; i < range.length; ++i)
    {
        if (pred(range[i]))
            return i;
    }
    return -1;
}
