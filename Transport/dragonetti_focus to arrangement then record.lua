-- @description set focus to Arrangement an then record
-- @author Dragonetti
-- @version 1.0.0
-- @about
--   prevents the deletion of the track instead of the item after recording.
reaper.SetCursorContext(1,nil)
reaper.Main_OnCommand(1013,0) 
