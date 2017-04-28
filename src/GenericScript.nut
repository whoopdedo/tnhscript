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

function FixupPlayerLinks(source, player)
{
    local pflink = Link.GetOne("PlayerFactory")
    if (pflink) {
        foreach (oldlink in Link.GetAll(null, source, sLink(pflink).source)) {
            local linkinfo = sLink(oldlink)
            local newlink = Link.Create(linkinfo.flavor, linkinfo.source, player)
            //local data = LinkTools.LinkGetData(oldlink, null)
            //if (data != null)
            //    LinkTools.LinkSetData(newlink, null, data)
            Link.Destroy(oldlink)
        }
    }
}

class GenericScript extends tnhRootScript
{
    m_timing = 0.0
    m_flags = 0

    function TurnOn() {}
    function TurnOff() {}
    function Control() {}

    function InitTrapVars() {
        if (HasProperty("ScriptTiming")) {
            m_timing = GetProperty("ScriptTiming")
        }
        if (HasProperty("TrapFlags")) {
            m_flags = GetProperty("TrapFlags")
        }
    }

    function IsLocked() {
        return Locked.IsLocked(self)
    }

    function SetLock(lock) {
        local lockobj = LinkDest(Link.GetOne("Lock", self))
        if (lockobj) {
            if (HasProperty("Locked"))
                Property.Remove(self, "Locked")
            Property.SetSimple(lockobj, "Locked", lock)
        } else {
            SetProperty("Locked", lock)
        }
    }

    function FixupPlayerLinks() {
        local player = ObjID("Player")
        if (player) {
            ::FixupPlayerLinks(self, player)
            return 0
        } else {
            SetOneShotTimer("DelayedInit", 0.001, "FixupPlayerLinks")
        }
    }

    function OnTimer() {
        if (message().name == "DelayedInit" &&
            message().data == "FixupPlayerLinks"
        ) {
            local player = ObjID("Player")
            if (player)
                ::FixupPlayerLinks(self, player)
        } else if (message().name == "TurnOn") {
            TurnOn()
        } else if (message().name == "TurnOff") {
            TurnOff()
        }
    }

    function OnTurnOn() {
        InitTrapVars()
        if (m_flags & TRAPF_NOON)
            return
        if (!IsLocked()) {
            local result = true
            local inversemsg
            if (m_flags & TRAPF_INVERT) {
                result = TurnOff()
                inversemsg = "TurnOn"
            } else {
                result = TurnOn()
                inversemsg = "TurnOn"
            }
            if (result) {
                if (m_timing > 0)
                    SetOneShotTimer(inversemsg, m_timing)
                if (m_flags & TRAPF_ONCE)
                    SetLock(true)
            }
        }
    }

    function OnTurnOff() {
        InitTrapVars()
        if (m_flags & TRAPF_NOOFF)
            return
        if (!IsLocked()) {
            local result = (m_flags & TRAPF_INVERT)
                ? TurnOn()
                : TurnOff()
            if (result) {
                if (m_flags & TRAPF_ONCE)
                    SetLock(true)
            }
        }
    }

    function OnScriptControl() {
        InitTrapVars()
        if (!IsLocked()) {
            Control()
        }
    }
}

class GenericTrap extends GenericScript {

    function TurnOn() {
        return Switch(true)
    }

    function TurnOff() {
        return Switch(false)
    }

    function Control() {
        local control = message().data
        local turnon = false
        if (typeof control == "string") {
            if (control.lower() in ["on","turnon","true","yes"])
                turnon = true
            else
                turnon = false
        } else
            turnon = !!control
        if (turnon)
            TurnOn()
        else
            TurnOff()
    }
}

class GenericTrigger extends tnhRootScript {

    m_flags = 0

    function InitTrigVars() {
        if (HasProperty("TrapFlags")) {
            m_flags = GetProperty("TrapFlags")
        }
    }

    function IsLocked() {
        return Locked.IsLocked(self)
    }

    function SetLock(lock) {
        SetProperty("Locked", lock)
    }

    function DoTurnOn(data = null) {
        if (m_flags & TRAPF_NOON)
            return
        if (m_flags & TRAPF_ONCE)
            SetLock(true)
        CDSend((m_flags & TRAPF_INVERT)
            ? "TurnOff"
            : "TurnOn", data)
    }

    function DoTurnOff(data = null) {
        if (m_flags & TRAPF_NOOFF)
            return
        if (m_flags & TRAPF_ONCE)
            SetLock(true)
        CDSend((m_flags & TRAPF_INVERT)
            ? "TurnOn"
            : "TurnOff",
            data)
    }
}

class GenericControl extends GenericScript {

    function TurnOn() {
        if ("on" in userparams()) {
            return ControlString(userparams().on.tostring())
        }
        return false
    }

    function TurnOff() {
        if ("off" in userparams()) {
            return ControlString(userparams().off.tostring())
        }
        return false
    }

    function Control() {
        if (typeof message().data == "string")
            return ControlString(message().data)
        return false
    }
}

class GenericScale extends GenericScript {

    m_scale_stim = 0
    m_scale_stim_msg = null

    function Scale() {}

    function InitStimMessage() {
        local params = userparams()
        if (!m_scale_stim && "arcontrol" in params) {
            local stim = ObjID(params.arcontrol)
            if (stim) {
                m_scale_stim_msg = Object.GetName(stim) + "Stimulus"
                //self["On"+m_scale_stim_msg] <= function() { return Stimulus() }
                m_scale_stim = stim
            } else {
                Debug.Log("arcontrol stimulus not found")
                m_scale_stim_msg = ""
            }
        }
    }

    function OnMessage() {
        if (!m_scale_stim_msg)
            InitStimMessage()
        if (MessageIs(m_scale_stim_msg))
            Scale(message().intensity)
    }

    function TurnOn() {
        local params = userparams()
        if ("on" in params)
            return Scale(params.on.tofloat())
        return false
    }

    function TurnOff() {
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

    function Control() {
        Scale(message().data.tofloat())
    }
}
