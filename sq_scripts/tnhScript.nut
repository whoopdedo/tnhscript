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
Debug.Log("tnhScript 3, Copyright (C) 2017 Tom N Harris <telliamed@whoopdedo.org>\n"
  +"This program comes with ABSOLUTELY NO WARRANTY. This is free software,"
  +"and you are welcome to redistribute it under certain conditions; see"
  +"the source code or <https://github.com/whoopdedo/tnhscript> for details.")

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


class tnhRootScript extends SqRootScript
{
    function DebugString(str)
    {
//@if DEBUG
        print(str)
//@endif
    }

    function CDSend(message, data=null)
    {
        if (data == null)
            Link.BroadcastOnAllLinks(self, message, "ControlDevice")
        else
            Link.BroadcastOnAllLinksData(self, message, "ControlDevice", data)
    }

    function GetAnyLink(flavor, src=0, dst=0)
    {
        local links = []
        foreach (link in Link.GetAll(flavor,src,dst))
            links.append(link)
        return links.len() > 0 ? links[Data.RandInt(0, links.len()-1)] : 0
    }

    function GetAnyLinkInheritedSrc(flavor, src=0, dst=0)
    {
        local links = []
        foreach (link in Link.GetAllInheritedSingle(flavor, src, dst))
            links.append(link)
        return links.len() > 0 ? links[Data.RandInt(0, links.len()-1)] : 0
    }

    function ParamGetString(name, result=null)
    {
        local params = userparams()
        if (name in params)
            try
                return params[name].tostring()
            catch(err)
                return ""
        return result
    }

    function ParamGetInt(name, result=null)
    {
        local params = userparams()
        if (name in params)
        {
            try
            {
                result = params[name]
                if (typeof result == "string" && result[0] == '$')
                    return Quest.Get(result.slice(1))
                else
                    return result.tointeger()
            }
            catch(err)
                return 0
        }
        return result
    }

    function ParamGetFloat(name, result=null)
    {
        local params = userparams()
        if (name in params)
            try
                return params[name].tofloat()
            catch(err)
                return 0.0
        return result
    }

    function ParamGetBool(name, result=null)
    {
        local params = userparams()
        if (name in params)
            try
            {
                result = params[name]
                if (typeof result == "string")
                {
                    switch(result[0])
                    {
                        case '1': case 't': case 'T': case 'y': case 'Y':
                            return true
                        case '$':
                            return Quest.Get(result.slice(1)) != 0
                        default:
                            return result.tointeger() != 0
                    }
                }
                else
                    return !!result
            }
            catch(err)
                return false
        return result
    }

    function ParamGetObject(name, result=null)
    {
        local params = userparams()
        if (name in params)
            try
                return ObjID(params[name])
            catch(err)
                return 0
        return result
    }

    function ParamGetObjectRel(name, dst=0, src=0, result=null)
    {
        local params = userparams()
        if (name in params)
            try
            {
                result = params[name].tostring().tolower()
                if (result == "self")
                    return dst
                if (result == "source")
                    return src
                if (result[0] == '^')
                    return Object.FindClosestObjectNamed(dst, result.slice(1))
                return ObjID(params[name])
            }
            catch(err)
                return 0
        return result
    }

}

function FixupPlayerLinks(source, player)
{
    local pflink = Link.GetOne("PlayerFactory")
    if (pflink)
    {
        foreach (oldlink in Link.GetAll(null, source, sLink(pflink).source))
        {
            local linkinfo = sLink(oldlink)
            local newlink = Link.Create(linkinfo.flavor, linkinfo.source, player)
            Link.Destroy(oldlink)
        }
    }
}

class GenericScript extends tnhRootScript
{
    m_timing = 0.0
    m_flags = 0

    function TurnOn() { }
    function TurnOff() { }
    function Control() { }

    function InitTrapVars()
    {
        if (HasProperty("ScriptTiming"))
        {
            m_timing = GetProperty("ScriptTiming")
        }
        if (HasProperty("TrapFlags"))
        {
            m_flags = GetProperty("TrapFlags")
        }
    }

    function IsLocked()
    {
        return Locked.IsLocked(self)
    }

    function SetLock(lock)
    {
        local lockobj = LinkDest(Link.GetOne("Lock", self))
        if (lockobj)
        {
            if (HasProperty("Locked"))
                Property.Remove(self, "Locked")
            Property.SetSimple(lockobj, "Locked", lock)
        }
        else
        {
            SetProperty("Locked", lock)
        }
    }

    function FixupPlayerLinks()
    {
        local player = ObjID("Player")
        if (player)
        {
            ::FixupPlayerLinks(self, player)
            return 0
        }
        else
        {
            SetOneShotTimer("DelayedInit", 0.001, "FixupPlayerLinks")
        }
    }

    function OnTimer()
    {
        if (message().name == "DelayedInit" && message().data == "FixupPlayerLinks")
        {
            local player = ObjID("Player")
            if (player)
                ::FixupPlayerLinks(self, player)
        }
        else if (message().name == "TurnOn")
        {
            TurnOn()
        }
        else if (message().name == "TurnOff")
        {
            TurnOff()
        }
    }

    function OnTurnOn()
    {
        InitTrapVars()
        if ((m_flags & TRAPF_NOON))
            return
        if (!IsLocked())
        {
            local result = true
            local inversemsg
            if (m_flags & TRAPF_INVERT)
            {
                result = TurnOff()
                inversemsg = "TurnOn"
            }
            else
            {
                result = TurnOn()
                inversemsg = "TurnOn"
            }
            if (result)
            {
                if (m_timing > 0)
                    SetOneShotTimer(inversemsg, m_timing)
                if (m_flags & TRAPF_ONCE)
                    SetLock(true)
            }
        }
    }

    function OnTurnOff()
    {
        InitTrapVars()
        if (m_flags & TRAPF_NOOFF)
            return
        if (!IsLocked())
        {
            local result = (m_flags & TRAPF_INVERT) ? TurnOn() : TurnOff()
            if (result)
            {
                if (m_flags & TRAPF_ONCE)
                    SetLock(true)
            }
        }
    }

    function OnScriptControl()
    {
        InitTrapVars()
        if (!IsLocked())
        {
            Control()
        }
    }
}

class GenericTrap extends GenericScript
{
    function TurnOn()
    {
        return Switch(true)
    }

    function TurnOff()
    {
        return Switch(false)
    }

    function Control()
    {
        local control = message().data
        local turnon = false
        if (typeof(control) == "string")
        {
            if (control.lower() in ["on","turnon","true","yes"])
                turnon = true
            else
                turnon = false
        }
        else
            turnon = !!control
        if (turnon)
            TurnOn()
        else
            TurnOff()
    }
}

class GenericTrigger extends tnhRootScript
{
    m_flags = 0

    function InitTrigVars()
    {
        if (HasProperty("TrapFlags"))
        {
            m_flags = GetProperty("TrapFlags")
        }
    }

    function IsLocked()
    {
        return Locked.IsLocked(self)
    }

    function SetLock(lock)
    {
        SetProperty("Locked", lock)
    }

    function DoTurnOn(data = null)
    {
        if (m_flags & TRAPF_NOON)
            return
        if (m_flags & TRAPF_ONCE)
            SetLock(true)
        CDSend((m_flags & TRAPF_INVERT) ? "TurnOff" : "TurnOn", data)
    }

    function DoTurnOff(data = null)
    {
        if (m_flags & TRAPF_NOOFF)
            return
        if (m_flags & TRAPF_ONCE)
            SetLock(true)
        CDSend((m_flags & TRAPF_INVERT) ? "TurnOn" : "TurnOff", data)
    }
}

class GenericControl extends GenericScript
{
    function TurnOn()
    {
        if ("on" in userparams())
        {
            return ControlString(userparams().on.tostring())
        }
        return false
    }

    function TurnOff()
    {
        if ("off" in userparams())
        {
            return ControlString(userparams().off.tostring())
        }
        return false
    }

    function Control()
    {
        if (typeof message().data == "string")
            return ControlString(message().data)
        return false
    }
}

class GenericScale extends GenericScript
{

    m_scale_stim = 0
    m_scale_stim_msg = null

    function Scale() { }

    function InitStimMessage()
    {
        local params = userparams()
        if (!m_scale_stim && "arcontrol" in params)
        {
            local stim = ObjID(params.arcontrol)
            if (stim)
            {
                m_scale_stim_msg = Object.GetName(stim) + "Stimulus"
                m_scale_stim = stim
            }
            else
            {
                Debug.Log("arcontrol stimulus not found")
                m_scale_stim_msg = ""
            }
        }
    }

    function OnMessage()
    {
        if (!m_scale_stim_msg)
            InitStimMessage()
        if (MessageIs(m_scale_stim_msg))
            Scale(message().intensity)
    }

    function TurnOn()
    {
        local params = userparams()
        if ("on" in params)
            return Scale(params.on.tofloat())
        return false
    }

    function TurnOff()
    {
        local scale = 0.0
        local params = userparams()
        if ("off" in params)
            scale = params.off.tofloat()
        else if ("on" in params)
            scale = -params.on.tofloat()
        else
            return false
        return Scale(scale)
    }

    function Control()
    {
        Scale(message().data.tofloat())
    }
}

class ScriptController extends GenericControl
{
    function ControlString(control)
    {
        local dest = ObjID(message().data2)
        if (dest)
        {
            SendMessage(dest, "ScriptControl", control)
        }
        else
        {
            CDSend("ScriptControl", self, control)
        }
        return true
    }
}

class CommandControl extends GenericControl
{
    function ControlString(control)
    {
        foreach (cmd in split(control, ";"))
            Debug.Command(cmd)
        return true
    }
}

class TrapMoveRelative extends GenericControl
{
    function IterateLinks(delta)
    {
         foreach (link in Link.GetAll("ControlDevice", self))
         {
             local target = LinkDest(link)
             if (delta.rotate_axes)
             {
                 Object.Teleport(target, delta.position, delta.facing, target)
             }
             else
             {
                 local destpos = Object.Position(target)
                 destpos += delta.position
                 local destfacing = Object.Facing(target)
                 destfacing += delta.facing
                 Object.Teleport(target, destpos, destfacing, 0)
             }
             if (Property.Possessed(target, "PhysState"))
             {
                 local vels = Property.Get(target, "PhysState", "Velocity")
                 vels += delta.velocity
                 Property.Set(target, "PhysState", "Velocity", vels)
                 local rot_vels = Property.Get(target, "PhysState", "Rot Velocity")
                 rot_vels += delta.rotation
                 Property.Set(target, "PhysState", "Rot Velocity", rot_vels)
             }
         }
         return true
    }

    function ControlString(control)
    {
        local group_pat = regexp(@"; *((\\;|[^;])*)")
        local number_pat = regexp(@"^(\w+) *= *([\+\-]?(\d+(\.\d*)?|\.\d+))")
        local delta = {
            position = vector(),
            velocity = vector(),
            facing = vector(),
            rotation = vector(),
            rotate_axes = false
        }
        control = ";"+control
        for (group=null, i=0; i < control.len(); i = group[0].end+1)
        {
            group = group_pat.capture(a, i)
            if (!group)
                break
            local cap = control.slice(group[1].begin, group[1].end)
            local match = number_pat.capture(cap)
            if (match)
            {
                local value = cap.slice(match[2].begin, match[2].end).tofloat()
                switch(cap.slice(match[1].begin, match[1].end))
                {
                    case "x":
                        delta.position.x = value; break
                    case "y":
                        delta.position.y = value; break
                    case "z":
                        delta.position.z = value; break
                    case "dx":
                        delta.velocity.x = value; break
                    case "dy":
                        delta.velocity.y = value; break
                    case "dz":
                        delta.velocity.z = value; break
                    case "b":
                        delta.facint.x = value; break
                    case "p":
                        delta.facint.y = value; break
                    case "h":
                        delta.facint.z = value; break
                    case "db":
                        delta.rotation.x = value; break
                    case "dp":
                        delta.rotation.y = value; break
                    case "dh":
                        delta.rotation.z = value; break
                    case "rotate_axes":
                        delta.rotate_axes = value != 0; break
                }
            }
        }
        return IterateLinks(delta)
    }

    function TurnOn()
    {
        local params = userparams()
        local delta = {
            position = vector("x" in params ? params.x : 0.0,
                              "y" in params ? params.y : 0.0,
                              "z" in params ? params.z : 0.0),
            velocity = vector("dx" in params ? params.dx : 0.0,
                              "dy" in params ? params.dy : 0.0,
                              "dz" in params ? params.dz : 0.0),
            facing = vector("b" in params ? params.b : 0.0,
                            "p" in params ? params.p : 0.0,
                            "h" in params ? params.h : 0.0),
            rotation = vector("db" in params ? params.db : 0.0,
                              "dp" in params ? params.dp : 0.0,
                              "dh" in params ? params.dh : 0.0),
            rotate_axes = "rotate_axes" in params && params.rotate_axes
        }
        return IterateLinks(delta)
    }

    function OnSim()
    {
        if (message().starting)
            FixupPlayerLinks()
    }
}

class TrapCamAttach extends GenericTrap
{
    function Switch(turnon)
    {
        if (turnon)
        {
            if (ParamGetBool("nolens"))
            {
                Debug.Command("cam_attach ",self)
            }
            else
            {
                if (ParamGetBool("static"))
                    Camera.StaticAttach(self)
                else
                    Camera.DynamicAttach(self)
            }
        }
        else
        {
            if (ParamGetBool("forcereturn"))
                Camera.ForceCameraReturn()
            else
                Camera.CameraReturn(self)
        }
    }
}

class TrapFreezePlayer extends GenericScale
{

    function OnBeginScript()
    {
        if (!IsDataSet("is_frozen"))
            SetData("is_frozen", false)
    }

    function TurnOn()
    {
        if (!GetData("is_frozen"))
        {
            local value = ParamGetFloat("freeze_speed", 0.0)
            DrkInv.AddSpeedControl(ParamGetString("freeze_name", "Freeze"), value, value)
            SetData("is_frozen", true)
        }
        return true
    }

    function TurnOff()
    {
        if (GetData("is_frozen"))
        {
            DrkInv.RemoveSpeedControl(ParamGetString("freeze_name", "Freeze"))
            SetData("is_frozen", false)
        }
        return true
    }

    function Scale(value)
    {
            local name = ParamGetString("freeze_name", "Freeze")
            if (GetData("is_frozen"))
                DrkInv.RemoveSpeedControl(name)
            DrkInv.AddSpeedControl(name, value, value)
            SetDat("is_frozen", true)
            return true
    }
}

class TrapRenderFlash extends GenericTrap
{
    function Switch(turnon)
    {
        if (GetAPIVersion() < 8)
        {
            Debug.MPrint("TrapRenderFlash requires Thief v1.24 or SS2 v2.45")
            return
        }
        if (turnon)
        {
            local player = ObjID("Player")
            local avatar = Object.Archetype(player)
            local flavor = linkkind("RenderFlash")
            local flashlink = GetAnyLinkInheritedSrc(flavor, self)
            if (!flashlink)
            {
                Debug.MPrint("RenderFlash could not be found")
                return
            }
            local olddest = 0
            local oldlink = Link.GetOne(flavor, avatar)
            if (oldlink)
            {
                olddest = LinkDest(oldlink)
                Link.Destroy(oldlink)
            }
            local newlink = Link.Create(flavor, avatar, LinkDest(flashlink))
            local schema = GetAnyLink(linkkind("SoundDescription"), self)
            if (schema)
                Sound.PlaySchemaAmbient(player, LinkDest(schema))
            Camera.StaticAttach(player)
            Camera.CameraReturn(player)
            Link.Destroy(newlink)
            if (olddest)
                Link.Create(flavor, avatar, olddest)
        }
    }
}

class TrapFadeOut extends GenericScale
{
}

if (GetAPIVersion() >= 8)
{
    function TrapFadeOut::Scale(value)
    {
        if (value < 0)
        {
            DarkGame.FadeToBlack(-1)
        }
        else
            DarkGame.FadeToBlack(value)
        return true
    }
}
else
{
    function TrapFadeOut::Scale(value)
    {
        DarkGame.FadeToBlack(value)
        return true
    }

    function TrapFadeOut::TurnOff()
    {
        DarkGame.FadeToBlack(-1);
        Reply(true)
    }
}

class ZeroGravRoom extends tnhRootScript
{
    function OnPlayerRoomEnter()
    {
        local move_obj = message().MoveObjId
        Property.Set(move_obj, "PhysAttr", "Gravity %", 0.0)
        Property.Set(move_obj, "PhysAttr", "Base Friction", 1.0)
    }

    function OnPlayerRoomExit()
    {
        local move_obj = message().MoveObjId
        local room_obj = message().ToObjId
        local gravity = 100.0
        if (Property.Possessed(room_obj, "RoomGrav"))
            gravity = Property.Get(room_obj, "RoomGrav")
        Property.Set(move_obj, "PhysAttr", "Gravity %", gravity)
    }
}


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
        return 0xFFFFFF 
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

