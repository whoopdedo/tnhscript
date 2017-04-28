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

class tnhRootScript extends SqRootScript {

    function DebugString(str) {
//@if DEBUG
        print(str)
//@endif
    }

    function CDSend(message, data = null) {
        if (data == null)
            Link.BroadcastOnAllLinks(self, message, "ControlDevice")
        else
            Link.BroadcastOnAllLinksData(self, message, "ControlDevice", data)
    }

    function GetAnyLink(flavor, src = 0, dst = 0) {
        local links = []
        foreach (link in Link.GetAll(flavor,src,dst))
            links.append(link)
        return links.len() > 0 ? links[Data.RandInt(0, links.len() - 1)] : 0
    }

    function GetAnyLinkInheritedSrc(flavor, src = 0, dst = 0) {
        local links = []
        foreach (link in Link.GetAllInheritedSingle(flavor, src, dst))
            links.append(link)
        return links.len() > 0 ? links[Data.RandInt(0, links.len() - 1)] : 0
    }

    function ParamGetString(name, result = null) {
        local params = userparams()
        if (name in params)
            try
                return params[name].tostring()
            catch (err)
                return ""
        return result
    }

    function ParamGetInt(name, result = null) {
        local params = userparams()
        if (name in params) {
            try {
                result = params[name]
                if (typeof result == "string" && result[0] == '$')
                    return Quest.Get(result.slice(1))
                else
                    return result.tointeger()
            } catch (err)
                return 0
        }
        return result
    }

    function ParamGetFloat(name, result = null) {
        local params = userparams()
        if (name in params)
            try
                return params[name].tofloat()
            catch (err)
                return 0.0
        return result
    }

    function ParamGetBool(name, result = null) {
        local params = userparams()
        if (name in params)
            try {
                result = params[name]
                if (typeof result == "string") {
                    switch (result[0]) {
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
            } catch (err)
                return false
        return result
    }

    function ParamGetObject(name, result = null) {
        local params = userparams()
        if (name in params)
            try
                return ObjID(params[name])
            catch (err)
                return 0
        return result
    }

    function ParamGetObjectRel(name, dst = 0, src = 0, result = null) {
        local params = userparams()
        if (name in params)
            try {
                result = params[name].tostring().tolower()
                if (result == "self")
                    return dst
                if (result == "source")
                    return src
                if (result[0] == '^')
                    return Object.FindClosestObjectNamed(dst, result.slice(1))
                return ObjID(params[name])
            } catch (err)
                return 0
        return result
    }

}
