-- @description User input changes the lengths of the items
-- @author dragonetti
-- @version 1.0
-- @about
--   Input numbers change length of selected items  -- Input "factor" divided length

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("no items selected")return
end
retval, rhymx = reaper.GetUserInputs( "input2length", 2,"1=1grid  2=2grid  etc.,1 /factor", "1111111111111111,1" )


 name = {rhymx:match("^([^,]+),([^,]+)$")}
rhym1 = name[1]
factor = name[2] 

if rhym1 == nil then return end


rhy = (rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1..rhym1
)

anzahl = string.len(rhy)


for i = 1,anzahl do
 Table_Rhy = {}    
    
  for i=1,anzahl do Table_Rhy[i] = tonumber(string.sub(rhy,i,i)) end
end

for a=1,100 do

ItemsSel = {}  
Idx = 1 

otherItems = {} 
counter = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
     
  
    
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start 
   
   
    old_length = ItemsSel[Idx].oldLength 
    playrate = ItemsSel[Idx].oldPlayrate

    new_length = Table_Rhy[Idx] * grid_length/factor  --new length created from the table values x grid_length
    new_rate = ItemsSel[Idx].oldPlayrate*(old_length/new_length)

  
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate
 

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)

    Idx = Idx + 1 -- 1-based table in Lua 

  else
    otherItems[counter] = {
  item = item,
  take = take,
  track = thisTrack,
    }

    counter = counter + 1
  end
  
end

for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd = prevStart + prevLen


  ItemsSel[i].newStart = prevEnd


  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item
end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_LENGTH", ItemsSel[index].newLength)
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Input2Length", -1)
reaper.SetCursorContext(1,0)

end

