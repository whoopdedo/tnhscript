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

/********************
 * ScriptController
 *
 * Send a ``ScriptControl`` message to other objects.
 *
 * Inherits: GenericControl
 */
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

/********************
 * CommandControl
 *
 * Execute an arbitrary command.
 *
 * Inherits: GenericControl
 */
class CommandControl extends GenericControl
{
    function ControlString(control)
    {
        foreach (cmd in split(control, ";"))
            Debug.Command(cmd)
        return true
    }
}

/***********************
 * TrapMoveRelative
 *
 * Move and apply velocity to an object relative to its current position
 *
 * Inherits: GenericControl
 * Links: ControlDevice(TrapObject, TargetObject)
 * Parameters: x,y,z, dx,dy,dz, h,p,b, dh,dp,db, rotate_axes
 */
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

/*************************
 * TrapCamAttach
 *
 * Attach the camera to the script object.
 *
 * Inherits: GenericTrap
 * Parameters: nolens, static, forcereturn
 */
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

/*********************
 * TrapFreezePlayer
 *
 * Prevent the player from moving.
 *
 * Inherits: GenericScale
 * Parameters: freeze_speed, freeze_name
 */
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

/*****************
 * TrapRenderFlash
 *
 * Displays a render flash as described by an archetype linked from this object
 * with a RenderFlash link.
 * Also, if there is a schema linked with SoundDescription, that will be played.
 *
 * One small drawback is that this will cause the current weapon to be deselected.
 *
 * Inherits: GenericTrap
 * Messages: TurnOn
 * Links: RenderFlash(TrapObject, FlashArchetype), SoundDescription(TrapObject, SchemaArchetype)
 */
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
            local schema = GetAnyLink("SoundDescription", self)
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

/********************
 * TrapFadeOut
 *
 * Fade to black.
 *
 * Inherits: GenericScale
 */
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
            //DarkGame.FadeIn(-value) // Not working. Is the API broken?
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

/********************
 * ZeroGravRoom
 * 
 * Sets the player's gravity to zero when entered. Sets it to 100% on exit.
 * 
 * This is a copy of the script with the same name from System Shock 2.
 * 
 * Messages: PlayerRoomEnter, PlayerRoomExit
 */
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

