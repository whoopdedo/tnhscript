/*******************************************************************************
 * StdDoor in Squirrel
 *
 * Adaptation of the door control script. I've written this in Python, Lua, and
 * now Squirrel. Because it demonstrates many of the things you can do with a
 * script it's a good way to learn.
 *
 * This is a direct copy of the original StdDoor script with changes only made
 * to take advantage of language features.
 *
 * This script is in the public domain.
 */

// All custom scripts begin as with a class
// declaration. SqRootScript is the builtin
// class that the script needs to inherit
// from.
class SqDoor extends SqRootScript {

    // Functions define the behavior of the script.
    // This function will send the message SynchUp
    // to any object that is linked either to or from
    // the door and that has the link data Double.
    // This is how you make double-doors work.
    function PingDoubles() {
        Link.BroadcastOnAllLinksData(self, "SynchUp", "ScriptParams", "Double")
        Link.BroadcastOnAllLinksData(self, "SynchUp", "~ScriptParams", "Double")
    }

    // The game engine communicates with scripts,
    // and scripts with other scripts, using
    // messages. In a script class functions
    // that start with "On" handle the behavior
    // when that message is received.

    // The message Open opens the door.
    function OnOpen() {
        Door.OpenDoor(self)
    }

    // And Close it.
    function OnClose() {
        Door.CloseDoor(self)
    }

    // The Sim message is sent once when a the gameplay
    // part of a mission begins. Which is after the mission
    // loading, difficulty selection, and loadout.
    // Then again when the mission ends.
    function OnSim() {
        if (message().starting) {
            ScanDoubles()
            SetData("Sim", true)
        } else {
            ClearData("Sim")
        }
    }

    // Messages sent when an object is locked and unlocked.
    // Scripts will get NowLocked/NowUnlocked even in editor
    // mode. So check that it only runs during the Sim.
    function OnNowLocked() {
        if (IsDataSet("Sim")) {
            PingDoubles()
            Door.CloseDoor(self)
        }
    }

    function OnNowUnlocked() {
        if (IsDataSet("Sim")) {
            PingDoubles()
            Door.OpenDoor(self)
        }
    }

    // The next two functions start and stop the timer
    // that makes the door auto-close.
    function SetCloseTimer() {
        if (HasProperty("ScriptTiming")) {
            // Remove any existing timers first.
            StopCloseTimer(true)
            // Read it right-to-left. The ScriptTiming property
            // is used as the length of a one-shot timer named
            // Close that is saved as the script data CloseTimer
            SetData("CloseTimer", SetOneShotTimer("Close", GetProperty("ScriptTiming") / 1000.0))
        }
    }

    function StopCloseTimer(kill) {
        if (IsDataSet("CloseTimer")) {
            if (kill)
                KillTimer(GetData("CloseTimer"))
            ClearData("CloseTimer")
        }
    }

    // When the timer counts down a message is sent.
    // A timer can come from other scripts, so always
    // check the name.
    function OnTimer() {
        if (message().name == "Close") {
            StopCloseTimer(false)
            Door.CloseDoor(self)
        }
    }

    // Frob messages are sent when the FrobInfo property
    // has the Script flag.
    function OnFrobWorldEnd() {
        local player_frob = message().Frobber == ObjID("Player")
        // A locked door that is closed, unless frobbed by the player with
        // the lock cheat enabled.
        if (Locked.IsLocked(self) &&
            Door.GetDoorState(self) == eDoorStatus.kDoorClosed &&
            !(player_frob && DarkGame.ConfigIsDefined("LockCheat"))
        ) {
            Sound.PlayEnvSchema(self, "Event Reject, Operation OpenDoor", self)
        } else {
            // Save a script data so the next event will also be tagged
            // as coming from the player.
            if (player_frob)
                SetData("PlayerFrob", true)
            // When a door is halted, go to the opposite of what the door
            // was doing before.
            if (IsDataSet("BeforeHalt")) {
                local before_halt = GetData("BeforeHalt")
                ClearData("BeforeHalt")
                if (before_halt == eDoorAction.kOpening)
                    Door.CloseDoor(self)
                else
                    Door.OpenDoor(self)
            } else {
                Door.ToggleDoor(self)
            }
        }
    }

    // PlayerToolFrob is sent by StdKey.
    function OnPlayerToolFrob () {
        SetData("PlayerFrob", true)
    }

    // After a door halts unexpectedly, we want a frob to do the reverse
    // of what it was doing before. Otherwise it would just get stuck
    // on whatever was making it halt.
    function OnDoorHalt() {
        // PingDoubles is not called. You would want to call it here to
        // simulate doors that are linked mechanically.
        SetData("BeforeHalt", message().PrevActionType)
        Sound.PlayEnvSchema(self, StateChangeTags(message().ActionType, message().PrevActionType), self)
        SetCloseTimer()
    }

    // Other messages that the door gets as it opens and closes.
    function OnDoorOpening() {
        PingDoubles()
        DarkGame.FoundObject(self)
        Sound.PlayEnvSchema(self,
            StateChangeTags(message().ActionType, message().PrevActionType),
            self
        )
    }

    function OnDoorClosing() {
        PingDoubles()
        Sound.PlayEnvSchema(self,
            StateChangeTags(message().ActionType, message().PrevActionType),
            self
        )
        StopCloseTimer(true)
    }

    function OnDoorClose() {
        Sound.HaltSchema(self)
        Sound.PlayEnvSchema(self,
            StateChangeTags(message().ActionType, message().PrevActionType),
            self
        )
    }

    // This shows an interesting quirk to Squirrel. Commas are optional
    // in function calls. But honestly, never do it.
    function OnDoorOpen() {
        Sound.HaltSchema(self)
        Sound.PlayEnvSchema(self
            StateChangeTags(message().ActionType, message().PrevActionType)
            self
        )
        SetCloseTimer()
    }

    // The Slain message is sent when an object is killed, which usually happens
    // when the hitpoints goes below 0, but not always.
    function OnSlain() {
        // Doors don't really "die".
        Damage.Resurrect(self)
        // Once slain, however, they will be much weaker than before.
        SetProperty("HitPoints", 1)
        // Also, any locks are permanently disabled
        foreach (lock in Link.GetAll("Lock", self))
            Link.Destroy(lock)
        if (HasProperty("Locked")) {
            // Just deleting the property doesn't actually unlock the door.
            SetProperty("Locked", false)
            Property.Remove(self, "Locked")
        }
        if (HasProperty("KeyDst"))
            Property.Remove(self, "KeyDst")
        Door.OpenDoor(self)
    }

    // Given a door state, what will be the final
    // state when the action completes.
    function TargState(state) {
        return {
            [eDoorStatus.kDoorClosed ] = eDoorStatus.kDoorClosed,
            [eDoorStatus.kDoorOpen   ] = eDoorStatus.kDoorOpen,
            [eDoorStatus.kDoorClosing] = eDoorStatus.kDoorClosed,
            [eDoorStatus.kDoorOpening] = eDoorStatus.kDoorOpen,
            [eDoorStatus.kDoorHalt   ] = eDoorStatus.kDoorHalt
        }[state]
    }

    // The double-door magic.
    // Mirror the behavior of the other door,
    // and copy it's lock state too.
    function OnSynchUp() {
        local from = message().from
        local target = TargState(Door.GetDoorState(from)),
              state  = TargState(Door.GetDoorState(self))
        if (state != target) {
            if (target == eDoorStatus.kDoorClosed)
                Door.CloseDoor(self)
            else
                Door.OpenDoor(self)
        }
        // Notice that it doesn't look at Lock links.
        // You'll want to link your lock to both doors, in that case.
        if (Property.Possessed(from, "Locked") &&
            Property.Possessed(self, "Locked") &&
            Property.Get(from, "Locked") != Property.Get(self, "Locked")
        )
            Property.CopyFrom(self, "Locked", from)
    }

    // AI get confused when pathfinding through the
    // common point of double-doors. The AI will attempt
    // to frob both doors, which is essentially frobbing
    // the same door twice.
    // So we create an unrendered object between the
    // doors to, hopefully, force AI to pathfind through
    // either one door or the other.
    function PathAvoidDoubles(door1, door2) {
        // Only the door with the higher ID
        // will create the marker
        if (door2 < door1)
            return
        // The pair of doors must share the same set of rooms.
        // This guards against linked doors that aren't actually
        // next to each other.
        local rooms1 = GetRooms(door1)
        if (!rooms1)
            return
        local rooms2 = GetRooms(door2)
        if (!rooms2)
            return
        if (rooms1[0] != rooms2[0] || rooms1[1] != rooms2[1])
            return
        // Doors without physics? No thank you.
        if (! Property.Possessed(door1, "PhysDims"))
            return
        if (! Property.Possessed(door2, "PhysDims"))
            return
        // All doors should be OBBs.
        local dim1 = Property.Get(door1, "PhysDims", "Size"),
              dim2 = Property.Get(door2, "PhysDims", "Size")
        local pos1 = Object.Position(door1),
              pos2 = Object.Position(door2)
        local mid = (pos1 + pos2) / 2.0
        // Now test if the doors share a common midpoint.
        // note: sum([0.1]*10) == 0.1*10 is false!
        if ((abs(mid.x - pos1.x) - dim1.x < 0.005 ||
             abs(mid.y - pos1.y) - dim1.y < 0.005 ||
             abs(mid.z - pos1.z) - dim1.z < 0.005) &&
            (abs(mid.x - pos2.x) - dim2.x < 0.005 ||
             abs(mid.y - pos2.y) - dim2.y < 0.005 ||
             abs(mid.z - pos2.z) - dim2.z < 0.005)
        ) {
          // We have double-doors, create the marker object.
          local sentinal = Object.Create(ObjID("Marker"))
          // Move it to the midpoint.
          Object.Teleport(sentinal, mid, vector())
          // And make it block the path. The "Repel" flag
          // has the value 2, but there's no named constant
          // for it.
          Property.Set(sentinal, "AI_ObjAvoid", "Flags", 2)
          print("Created sentinal @" + mid)
        }
    }

    // Iterate ScriptParams links to see if we need to create
    // path-avoid markers.
    function ScanDoubles() {
        // IDs are saved to a table so an object is only
        // pinged once.
        local link_cache = {}
        // PathAvoidDoubles is called once for every linked object
        // we find. It's safe for both doors to do this, since
        // only the object with the greater ID creates the marker.
        foreach (l in Link.GetAll("ScriptParams", self)) {
            local object_to = LinkDest(l)
            if (!(object_to in link_cache) &&
                LinkTools.LinkGetData(l, "") == "Double"
            ) {
                link_cache[object_to] <- true
                PathAvoidDoubles(self, object_to)
            }
        }
        // Then again with the reverse links.
        foreach (l in Link. GetAll ("~ScriptParams", self)) {
            // You could squash the case here...
            local object_to = LinkDest(l)
            if (!(object_to in link_cache) &&
                LinkTools.LinkGetData(l, "") == "Double"
            ) {
                link_cache[object_to] <- true
                PathAvoidDoubles(self, object_to)
            }
        }
    }

    // Returns an array of the rooms on either side of this door.
    // The array elements are sorted lowest to highest.
    function GetRooms(door) {
        local ret = [null,null]
        local door_prop
        if (Property.Possessed(door, "RotDoor"))
            door_prop = "RotDoor"
        else if (Property.Possessed(door, "TransDoor"))
            door_prop = "TransDoor"
        else // Not a door.
            return null
        // It's actually not all that hard to get the field
        // name for a property: It's the label Dromed uses
        // for the dialog, spaces and all.
        local r1 = Property.Get(door, door_prop, "Room ID #1"),
              r2 = Property.Get(door, door_prop, "Room ID #2")
        if (r1 > r2)
            ret[0] = r2, ret[1] = r1
        else
            ret[0] = r1, ret[1] = r2
        return ret
    }

    // Creates the schema tags for door sounds
    // based on what the door is doing.
    function StateChangeTags(status, oldstatus) {
        // Converts a door action constant to a schema tag.
        // Tables are an efficient way to store relationships
        // between two things that don't change.
        local DoorAction = {
            [eDoorAction.kClose  ] = "Closed",
            [eDoorAction.kOpen   ] = "Open",
            [eDoorAction.kClosing] = "Closing",
            [eDoorAction.kOpening] = "Opening",
            [eDoorAction.kHalt   ] = "Halted"
        }
        local tags = format("Event StateChange, OpenState %s, OldOpenState %s",
            DoorAction[status], DoorAction[oldstatus])
        if (IsDataSet("PlayerFrob")) {
            // The flag is saved while opening or closing, so the
            // resultant open/close/halt schema will also be from
            // the Player.
            tags += ", CreatureType Player"
            switch (status) {
            case eDoorAction.kOpen:
            case eDoorAction.kClose:
            case eDoorAction.kHalt:
                // These are final actions, so the saved data
                // isn't needed anymore.
                ClearData("PlayerFrob")
            }
        }
        return tags
    }

}

// Doors also respond to TurnOn and TurnOff
// messages. Instead of creating new functions,
// Squirrel allows us to reuse another function
// with a new name. 
SqDoor.OnTurnOn <- SqDoor.OnOpen
SqDoor.OnTurnOff <- SqDoor.OnClose

// A custom class can be derived from another custom class.
// It has the same behavior and message handling as the
// parent class but modified with the functions you
// add to it.
class SqNonAutoDoor extends SqDoor {

    // NonAutoDoor does not open or close when it is
    // unlocked or locked.
    // These functions replace the same named functions
    // in the SqDoor class.
    function OnNowLocked() {
        if (IsDataSet("Sim"))
            PingDoubles()
    }

    function OnNowUnlocked() {
        if (IsDataSet("Sim"))
            PingDoubles()
    }

}

// A SecurityDoor will make AI suspicious if its state changes.
// This shows how to add to a function while still keeping the
// same behavior.
class SecurityDoor extends SqDoor {

    function OnSim() {
        if (message().starting) {
            // Saves the initial door state.
            // Adjust for Opening and Closing.
            SetData("StartDoorState", TargState(Door.GetDoorState(self)))
        }
        // base is a reference to the functions in the parent
        // class. If it was just OnSim then the same function
        // in the current class would be called.
        base.OnSim()
    }

    // Turn on the suspicious flag when opened and the door is supposed
    // to be closed. Turn off the suspicious flag when it's closed again.
    function OnDoorOpen() {
        if (GetData("StartDoorState") != eDoorStatus.kDoorOpen) {
            if (HasProperty("SuspObj"))
                SetProperty("SuspObj", "Is Suspicious", true)
        } else { // GetData("StartDoorState") == eDoorStatus.kDoorOpen
            if (HasProperty("SuspObj"))
                SetProperty("SuspObj", "Is Suspicious", false)
        }
        base.OnDoorOpen()
    }

    // Turn on the suspicious flag when closed and the door is supposed
    // to be open. Turn off the suspicious flag when it's opened again.
    function OnDoorClose() {
        if (GetData("StartDoorState") != eDoorStatus.kDoorClosed) {
            if (HasProperty("SuspObj"))
                SetProperty("SuspObj", "Is Suspicious", true)
        } else { // GetData("StartDoorState") == eDoorStatus.kDoorClosed
            if (HasProperty("SuspObj"))
                SetProperty("SuspObj", "Is Suspicious", false)
        }
        base.OnDoorClose()
    }
  
    // A door that is neither open nor closed will always be suspicious.
    // Even if the starting state was halted, because the angle
    // may have changed.
    function OnDoorHalt() {
        if (HasProperty("SuspObj"))
            SetProperty("SuspObj", "Is Suspicious", true)
        base.OnDoorHalt()
    }

}
