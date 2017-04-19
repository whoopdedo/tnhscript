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

/*************************
 * KnockOnDoor
 *
 * Signals AI with ``knock_knock`` when a closed & locked door is frobbed.
 * Will also send an Interact message with the data ''knock_knock'' as an
 * alternate way to respond. (Since AI can only have one signal response.)
 *
 * Messages: FrobWorldEnd
 * Links: Owns(AIToSignal, DoorObject)
 * Signals: knock_knock
 */
class KnockOnDoor extends tnhRootScript
{
    function OnFrobWorldEnd()
    {
        if (Locked.IsLocked(self) && Door.GetDoorState(self) == eDoorStatus.kDoorClosed)
            foreach (owns_link in Link.GetAll("~Owns", self, 0))
            {
                local owner = LinkDest(owns_link)
                AI.Signal(owner, "knock_knock")
                PostMessage(owner, "Interact", "knock_knock")
            }
        Reply(true)
    }
}

local DisplayBookText = class {
    m_host = 0

    constructor(host)
    {
        m_host = host
    }

}

/**************************
 * OnScreenText
 * 
 * Display text from a book file on-screen. Supports multiple pages, color, 
 * and auto-scroll. The page to display is specified in the parameter page. 
 * The parameter is modified by the script. The text for a page is in the 
 * book string ``page_0``. There is no effective limit to the number of pages.
 * The color of a page is ``page_0_color`` as #AABBCC (HTML format). The time 
 * to display a page is ``page_0_time``. Time is specified as milliseconds, 
 * or as seconds by appending 's', or as minutes by appending 'm'. So 
 * $$1m$$ = $$60s$$ = $$60000$$. ``page_0_next`` specifies which page to display next.
 * If not specified, the next page is the next in-order, or 0 if it doesn't 
 * exist. ``page_0_auto`` is the time before the next page is automatically 
 * displayed. The auto-scroll time runs concurrently with the display time,
 * so $$page_0_time: 3s$$ and $$page_0_auto: 4s$$ with display the text for 3 seconds,
 * then 1 second later will show the next page.
 *
 * ``ScriptControl`` with just a number will set the current page but not display 
 * it. You can also use a string for greater control. Use //<op><num>//.
 * ^ Op. ^  Result  ^
 * |  @  | Set the page without displaying it.  |
 * |  #  | Set the page then display it.  |
 * |  +  | Increment the page counter.  |
 * |  -  | Decrement the page counter.  |
 *   
 * ``TurnOff`` does nothing. ``ScriptControl`` will set the current page but doesn't
 * display it.
 * The default time is 5 seconds. The default color is white.
 *
 * Inherits: GenericScript
 * Parameters: page
 * Properties: Book
 * Strings: page_n, page_n_color, page_n_time, page_n_auto, page_n_next
 */
class OnScreenText extends GenericScript
{
    function DisplayBookPage(book, page)
    {
        local book_file = "..\\books\\" + book
        local page_s = format("page_%d", page)
        local page_text = Data.GetString(book_file, page_s, "", "strings")
        if (page_text == "")
            return false
        local str = null
        local color = DefaultTextColor()
        local time = 0
        str = Data.GetString(book_file, page_s + "_color", "", "strings")
        if (str != "")
            color = strtocolor(str)
        str = Data.GetString(book_file, page_s + "_time", "", "strings")
        if (str != "")
        {
            local wait = strtotime(str)
            if (wait > 0)
                time = wait
        }
        if (time == 0)
        {
            time = CalcTextTime(page_text)
        }
        DisplayText(page_text, color, time)

        str = Data.GetString(book_file, "page_s" + "_auto", "", "strings")
        if (str != "")
        {
            local wait = strtotime(str)
            if (wait > 0 || str[0] == '0')
            {
                if (wait > time)
                    time = wait
            }
            else
                time = 0
        }
        else
            time = 0
        page++
        str = Data.GetString(book_file, page_s + "_next", "", "strings")
        if (str != "")
            page = str.tointeger()
        str = Data.GetString(book_file, format("page_%d", page), "", "strings")
        if (str == "")
            page = 0
        ChangeBookPage(book, page, time)

        return true
    }

    function DisplayText(text, color, time)
    {
        DarkUI.TextMessage(text, color, time)
    }

    function DisplayPage(page)
    {
        if (!HasProperty("Book"))
        {
            DebugString("Object has no book!")
            return false
        }
        local book = GetProperty("Book")
        if (book.len() == 0)
        {
            DebugString("Object has no book!")
            return false
        }
        return DisplayBookPage(book, page)
    }

    function ChangePage(page)
    {
        return SetData("page", page).tointeger()
    }

    function ChangeBookPage(book, page, time)
    {
        if (time > 0)
        {
            if (IsDataSet("auto_scroll"))
            {
                KillTimer(GetData("auto_scroll"))
                ClearData("auto_scroll")
            }
            SetData("auto_scroll", SetOneShotTimer("AutoScroll", time))
        }
        return ChangePage(page)
    }

    function DefaultTextColor()
    {
        return 0xFFFFFF //RGB(255,255,255)
    }

    function OnBeginScript()
    {
        SetData("page", ParamGetInt("page", 0))
    }

    function OnTimer()
    {
        if (message().name == "AutoScroll")
        {
            ClearData("auto_scroll")
            DisplayPage(GetData("page"))
        }
    }

    function TurnOn()
    {
        if (IsDataSet("auto_scroll"))
        {
            KillTimer(GetData("auto_scroll"))
            ClearData("auto_scroll")
        }
        local page = GetData("page")
        if (page < 0)
            page = 0
        DisplayPage(page)
        Reply(true)
    }

    function Control()
    {
        local control = message().data
        local op = '@'
        local arg = -1
        try
            switch (typeof control)
            {
                case "integer":
                    arg = control; break
                case "float":
                    arg = control.tointeger(); break
                case "string":
                    control = lstrip(control)
                    if (control[0] >= '0' && control[0] <= '9')
                        arg = control.tointeger()
                    else
                    {
                        op = control[0]
                        control = control.slice(1)
                        arg = control[0] == '.' ? 0x7FFFFFFF : control.tointeger()
                    }
                    break
                default:
                    Reply(false)
                    return
            }
        catch(err)
        {
            Reply(false)
            return
        }
        if (arg > 0)
        {
            local page = GetData("page")
            if (arg == 0x7FFFFFFF)
                arg = page
            switch (op)
            {
                case '@':
                    if (page != arg)
                        ChangePage(arg)
                    break
                case '#':
                    DisplayPage(arg); break
                case '+':
                    if (arg != 0)
                        ChangePage(page + arg)
                    break
                case '-':
                    if (arg != 0)
                        ChangePage(arg > page ? 0 : page - arg)
                    break
                case '$':
                default:
                    Reply(false)
                    return
            }
        }
        Reply(true)
    }
}

