/*****************************************************************************
 * tnhScript 3, Copyright (C) 2017 Tom N Harris <telliamed@whoopdedo.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * The source code and GNU General Public License can be accessed
 * at <https://github.com/whoopdedo/tnhscript>
 ****************************************************************************/

local function strtotime(str)
{
    local match = regexp(@"^\s*((?:\d+(?:\.\d*)?)|(?:\.\d+))([MmSs]?)").capture(str)
    if (match)
    {
        local num = str.slice(match[1].begin, match[1].end).tofloat()
        local suffix = match.len() == 3 ? str.slice(match[2].begin, match[2].end).tolower() : ""
        if (suffix == "m")
            num *= 60000
        else if (suffix == "s")
            num *= 1000
        return num.tointeger()
    }
    return 0
}

local ColorNames = 
{
        black   = 0x000000
        silver  = 0xC0C0C0
        gray    = 0x808080
        grey    = 0x808080
        white   = 0xFFFFFF
        maroon  = 0x000080
        red     = 0x0000FF
        purple  = 0x800080
        fuchsia = 0xFF00FF
        green   = 0x008000
        lime    = 0x00FF00
        olive   = 0x008080
        yellow  = 0x00FFFF
        navy    = 0x800000
        blue    = 0xFF0000
        teal    = 0x808000
        aqua    = 0xFFFF00
}

local function strtocolor(str)
{
    str = str.tolower()
    if (str in ColorNames)
        return ColorNames[str]
    if (str[0] == '#')
    {
        local r = str.slice(1,3).tointeger(16),
              g = str.slice(3,5).tointeger(16),
              b = str.slice(5,7).tointeger(16);
        return b<<16 | g<<8 | r
    }
    local match = regexp(@"(\d+) *, *(\d+) *, *(\d+)").capture(str)
    if (match)
    {
        local r = str.slice(match[1].begin,match[1].end).tointeger(16),
              g = str.slice(match[1].begin,match[1].end).tointeger(16),
              b = str.slice(match[1].begin,match[1].end).tointeger(16);
        return b<<16 | g<<8 | r
    }
    return 0
}

local function CalcTextTime(str)
{
    local count = 0, letter_count = 0, space_count = 0, is_space = false
    foreach (word in split(strip(str), " \r\n\t"))
    {
        if (word == "")
        {
            if (is_space)
            {
                if (++space_count == 3)
                {
                    ++letter_count
                    space_count = 0
                }
            }
            else
            {
                is_space = true
            }
        }
        else
        {
            if (word.len() + letter_count > 3)
            {
                ++count
                letter_count = 0
                space_count = 0
            }
            else
                letter_count += word.len()
            is_space = false
        }
    }
    return 500 * (count < 10 ? 10 : count)
}

