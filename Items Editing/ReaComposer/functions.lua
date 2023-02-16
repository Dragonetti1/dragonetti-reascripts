--@noindex

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------FUNCTIONS---------------------------------------------------------------------------------------------------------------------------------
--===========================================================================================================================================================================



--===========================================================================================================================
--===============================crazylength===============================================================================
--======================================================================================================================
function crazy_length(b,am)

select_tracks = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(select_tracks,0)
sel_tracks_count =  reaper.CountSelectedTracks( 0 )

 local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  ) -- time selection
_,grid = reaper.GetSetProjectGrid( 0, false ) -- get grid  
bpm = reaper.TimeMap2_GetDividedBpmAtTime( 0, loop_start ) -- bpm at loop_start


--Length of an item at a 1/64 grid.
--No item should be smaller than this (particle).

grid_mod = math.floor(grid*10000)
--grid straight
if grid_mod==10000 or grid_mod==5000 or grid_mod==2500 or grid_mod==1250 or grid_mod==625 or grid_mod==312 then particle = 0.015625 end -- for straight grid (1/64)
if grid_mod==6666 or grid_mod==3333 or grid_mod==1666 or grid_mod==833 or grid_mod==416 or grid_mod==208 then particle = 0.0208333333 end -- for 1/32 triplet

ICount = reaper.CountSelectedMediaItems(0)

if ICount ==0 then return
end 


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1
for i = 1, ICount  do
  item = reaper.GetSelectedMediaItem(0, i-1)
    min_length =  reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
   
   if min_length <= particle*240/bpm/10 then return   end 
end  

--counts selected items
for i = 0, ICount-1 ,1 do

  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 
  if take == nil then return end


    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    if take ~=  nil then
       
        ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
       end
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")

old_length = ItemsSel[Idx].oldLength


-- x is 1 or -1 comes from buttons from the GUI
--change the length with the help of a function   
--==============================================================================================
if b==nil then b=1 end
if am==nil then am=1 end


if i==0 then aos = 0 end

if b==0 then

  aos = (am*-0.1*xpi*(i-(ICount/sel_tracks_count/2-0.5))/ICount)
  else

  aos = am*0.1*math.cos((2*math.pi*(i-(ICount/2-0.5))/(ICount/b))-math.pi/xpi*2)   -- aos is an add or subtract factor of 1/64
--  aos = 1/b*am*1/ICount*(i-(ICount/2-0.5))
--  aos = math.sin(i-(ICount/2-0.5))+1/64*(i-(ICount/2-0.5))
--    aos = (4*(i-(ICount/2-0.5))/8)^3
end    
  add_length = aos*particle*480/bpm -- add_length in seconds depends on bpm is added to or subtracted from the old length.    
    playrate = ItemsSel[Idx].oldPlayrate
    if playrate ~= nil then
        new_rate = ItemsSel[Idx].oldPlayrate
       
        end 
     
    new_length = old_length + add_length -- add_length in seconds depends on bpm is added to or subtracted from the old length.
    new_rate = old_length/new_length*playrate
    
    
 
    ItemsSel[Idx].newLength = new_lengthS
    ItemsSel[Idx].newRate = new_rate
  
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    if take == nil then return end
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
        

    Idx = Idx + 1 -- 1-based table in Lua 
end


for i = 2, Idx - 1 do

  --grabs items
  local prevItem = ItemsSel[i-1].thisItem
  local thisItem = ItemsSel[i].thisItem
  

  --grabs previous item's info
  local prevStart = reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
  local prevLen   = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH")
  local prevEnd   = prevStart + prevLen

  ItemsSel[i].newStart = prevEnd

  reaper.SetMediaItemInfo_Value(thisItem, "D_POSITION", prevEnd) --sets item to be at the end of the previous item

end

local selected_item_count = 0 -- counter for selected items
for i = 0, reaper.CountTracks() - 1 do
  local track = reaper.GetTrack(0, i) -- get track
  local track_item_count = reaper.CountTrackMediaItems(track) -- get number of items on track
  for j = 0, track_item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, j) -- get item on track
    if reaper.IsMediaItemSelected(item) then -- check if item is selected
      selected_item_count = selected_item_count + 1 -- increment counter for selected items
      reaper.SetTrackSelected(track, true) -- select track
      break -- break inner loop to avoid selecting track multiple times
    end
  end
end

if selected_item_count == 0 then -- if no items are selected
  reaper.ShowMessageBox("No items selected.", "Error", 0) -- show error message
end



local first_track = reaper.GetSelectedTrack(0, 0) -- get first selected track
local item_count = reaper.CountTrackMediaItems(first_track) -- get number of items on first track
local positions = {} -- table to store positions
local lengths = {} -- table to store lengths
local playrates = {} -- table to store playrates

for i = 0, item_count - 1 do
  local item = reaper.GetTrackMediaItem(first_track, i) -- get item on first track
  if reaper.IsMediaItemSelected(item) then -- check if item is selected
    local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION") -- get position of selected item
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") -- get length of selected item
    local playrate = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PLAYRATE") -- get playrate of selected item
    table.insert(positions, position) -- insert position into table
    table.insert(lengths, length) -- insert length into table
    table.insert(playrates, playrate) -- insert playrate into table
  end
end
 
for j = 0, reaper.CountTracks() - 1 do
  local track = reaper.GetTrack(0, j) -- get track
  if track ~= first_track then -- don't process first track again
    local track_item_count = reaper.CountTrackMediaItems(track) -- get number of items on track
    local index = 1 -- counter for tables
    for k = 0, track_item_count - 1 do
      local track_item = reaper.GetTrackMediaItem(track, k) -- get item on track
      if reaper.IsMediaItemSelected(track_item) then -- check if item is selected
        reaper.SetMediaItemInfo_Value(track_item, "D_POSITION", positions[index]) -- set position of selected item
        reaper.SetMediaItemInfo_Value(track_item, "D_LENGTH", lengths[index]) -- set length of selected item
        reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(track_item), "D_PLAYRATE", playrates[index]) -- set playrate of selected item
        index = index + 1 -- increment index
      end
    end
  end
end

reaper.UpdateArrange() -- update arrangement view
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

end
--===========================================================================================================
--==========================================================================================================

function length_sinus(x,s1)

 local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )
_,grid = reaper.GetSetProjectGrid( 0, false ) -- get grid
bpm = reaper.TimeMap2_GetDividedBpmAtTime( 0, loop_start )



grid_mod = math.floor(grid*10000)
--grid triple or straight
if grid_mod==10000 or grid_mod==5000 or grid_mod==2500 or grid_mod==1250 or grid_mod==625 or grid_mod==312 then ground = 0.015625 end -- for straight grid
if grid_mod==6666 or grid_mod==3333 or grid_mod==1666 or grid_mod==833 or grid_mod==416 or grid_mod==208 then ground = 0.0208333333 end -- for trip

s2=s1

select_tracks = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(select_tracks,0)
sel_tracks_count =  reaper.CountSelectedTracks( 0 )

ICount_all = reaper.CountSelectedMediaItems(0)



if ICount_all ==0 then return
end 


ICount = ICount_all/sel_tracks_count

for i = 1, ICount  do
  item = reaper.GetSelectedMediaItem(0, i-1)
    min_length =  reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
   
   if min_length <= ground*240/bpm then return   end 
end  


------------------------------------------------ 

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1



mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

--ICount = reaper.CountSelectedMediaItems(0)
for i = 0, ICount - 1 do

  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    if take ~=  nil then
       
        ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
       end
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    grid_mod = math.floor(grid*10000)
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
    


old_length = ItemsSel[Idx].oldLength



--change the length with the help of a sinus function    
if s1==nil then s1=0 end
 
if s1==0 then   
  aos = (0.05*(x)*((i)-(ICount/2-0.5)))   -- aos is an add or subtract factor of 64straight or 32triplet 
elseif s1==1 then 
  aos =math.sin(0.07*((x)*((i)-(ICount/2-0.5))))
  elseif s1==2 then 
    aos =math.sin(0.2*((x)*((i)-(ICount/2-0.5))))
    elseif s1==3 then 
        aos =math.sin(0.4*((x)*((i)-(ICount/2-0.5))))
        elseif s1==4 then 
                aos =math.sin(0.8*((x)*((i)-(ICount/2-0.5))))
    elseif s1==5 then 
      aos = math.sin(1.1*(x)*(i-(ICount/2-0.5)))
      elseif s1==6 then 
            aos = math.sin(8*(x)*(i-(ICount/2-0.5)))
  end
--------------------------------------------------------------------  
    
    playrate = ItemsSel[Idx].oldPlayrate
    if playrate ~= nil then
        new_rate = ItemsSel[Idx].oldPlayrate
       
        end 
     
    new_length = old_length+(aos*ground*480/bpm) -- factor * very small straight(1/64) or triplet(1/32 triplet) grid 
    
    new_rate = old_length/new_length*playrate
    
    
 
    ItemsSel[Idx].newLength = new_lengthS
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
reaper.Undo_EndBlock("Item Random Position", -1)

end

--==================================================================================================================
--============================= Length_SEQ_Input=====================================================================
--=======================================================================================================================
function length_input()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end


function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("no items selected")return
end
retval, rhymx = reaper.GetUserInputs( "input2length", 2,"1=1grid  2=2grid  etc.,1 /factor", "1111111111111111,1" )
if not retval then return end


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
  if take == nil then return end

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
end
---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------LENGHT_RANDOM------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825

------------------------------------------------
function length_random()

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.PreventUIRefresh(1)   

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
   
    
   Grids = {"1","2"}   
 
    Rand = Grids[math.random(1,#Grids)]   
    number = tonumber(Rand)       
   
    old_length = ItemsSel[Idx].oldLength 
    playrate = ItemsSel[Idx].oldPlayrate
    new_length = number * grid_length --new length randomly created from the table values x grid_length
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
reaper.Undo_EndBlock("Item Position", -1)
reaper.SetCursorContext(1,0)

end


--[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Delete selected items outside time selection
   * Author:      Archie
   * Version:     1.02
   * Описание:    Удаление выбранных элементов вне времени выбора
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Archie(---)
   * Gave idea:   Archie(---)
   * Extension:   Reaper 6.03+ http://www.reaper.fm/
   * Changelog:
   *              v.1.0 [10.02.20]
   *                  + initialе
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================


    -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    -------------------------------------------------------
    local function DeleteMediaItem(item);
    if item then;
    local tr = reaper.GetMediaItem_Track(item);
    reaper.DeleteTrackMediaItem(tr,item);
    end;
    end;
    -------------------------------------------------------


    local CountSelItem = reaper.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;


    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0); -- В Аранже
    if timeSelStart == timeSelEnd then no_undo() return end;

    local Undo;

    for i = CountSelItem-1,0,-1 do;

    local SelItem = reaper.GetSelectedMediaItem(0,i);
    local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION");
    local LenIt = reaper.GetMediaItemInfo_Value(SelItem,"D_LENGTH");
    local EndIt = PosIt + LenIt;

    if PosIt < timeSelEnd and EndIt > timeSelStart then;

    if not Undo then reaper.Undo_BeginBlock()Undo=1 end;

    if PosIt < timeSelEnd and EndIt > timeSelEnd then;
        local Right = reaper.SplitMediaItem(SelItem,timeSelEnd);
        if Right then
        DeleteMediaItem(Right);
        end
    end

    if PosIt < timeSelStart and EndIt > timeSelStart then;
        local Left = reaper.SplitMediaItem(SelItem,timeSelStart);
        if Left then
        DeleteMediaItem(SelItem);
        end
    end;
    else;
    if not Undo then reaper.Undo_BeginBlock()Undo=1 end;
    DeleteMediaItem(SelItem);
    end;
    end;


    if Undo then;
    reaper.Undo_EndBlock("Delete selected items outside time selection",-1);
    else;
    no_undo();
    end;
    reaper.UpdateArrange();



end
--============================================================================================================
--=================================== RESET_RATE_LENGTH  =====================================================
--============================================================================================================

function reset_rate_length()

-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

ItemsSelCount = reaper.CountSelectedMediaItems(0)

for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 
  if take == nil then return end

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  --  ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
    
    source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
    source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == ""
     then 
     play_factor = 1
     new_length = source_length*(60/tempo)
     
     else
     
     play_factor = tempo/bpm1
     new_length = source_length/play_factor
     
     end
  
    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    
    
    
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = play_factor

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", play_factor)

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
reaper.Undo_EndBlock("reset_rate_length", -1)
reaper.SetCursorContext(1,0)
--Msg(source_length)
end


--============================================================================================================
--=================================== LENGTH_TO_GRID  =====================================================
--============================================================================================================
--set item_length to one grid_length--
function length_to_grid()

-----------------------------------
    local tbl={};
    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if timeSelStart~=timeSelEnd then;
    reaper.PreventUIRefresh(19862675);
    for i = 1, reaper.CountMediaItems(0)do;
    local item = reaper.GetMediaItem(0,i-1);
    local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
    if pos >= timeSelEnd then;
        tbl[#tbl+1]={};tbl[#tbl].item=item;tbl[#tbl].pos=pos;
    end;
    end; 
    end;
    -----------------------------------
local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

   
   ItemsSel = {}
   
   ItemsSelCount = reaper.CountSelectedMediaItems(0)  
   for i = 0, ItemsSelCount - 1 do      
     item = reaper.GetSelectedMediaItem(0, i)  
     take = reaper.GetActiveTake(item) 
   
     Idx = i + 1 -- 1-based table in Lua    
     ItemsSel[Idx] = {} 
     ItemsSel[Idx].thisItem = item
     ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
     ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
     ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
   
     tempo = reaper.Master_GetTempo(0)
     
     factor = 120 / tempo
     
     start = ItemsSel[1].position 

     _,grid = reaper.GetSetProjectGrid(0, false)
   
     ppq = reaper.MIDI_GetPPQPosFromProjQN(take, 1+reaper.MIDI_GetProjQNFromPPQPos(take, 0))
     new_length = grid*2*factor

     old_length = ItemsSel[Idx].length
     playrate = ItemsSel[Idx].playrate
   
     new_rate = ItemsSel[Idx].playrate*(old_length/new_length)

     reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
     reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", playrate)

   end
reaper.SetCursorContext(1,0)
end 



--============================================================================================================
--===================================       LENGTH_HALF  =====================================================
--============================================================================================================
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825
function length_half()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
------------------------------------------------ 
-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

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
    if take ~=  nil then
       
        ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
       end
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  
    
    Grids = {"2"} 
    Rand = Grids[math.random(1,#Grids)]  
    number = tonumber(Rand) 
    
    
   

    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    if playrate ~= nil then
        new_rate = ItemsSel[Idx].oldPlayrate*number
        end
    
    
    new_length = old_length/number
    


    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate


    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    if take ~= nil then
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
      end

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
reaper.Undo_EndBlock("Item Random Position", -1)

end
--Msg(grid)


--============================================================================================================
--=================================== LENGTH_DOUBLE  =====================================================
--============================================================================================================
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825
function length_double()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
------------------------------------------------ 
-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

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
    
    if take ~=  nil then
   
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
   end
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  
    
    Grids = {"0.5"} 
    Rand = Grids[math.random(1,#Grids)]  
    number = tonumber(Rand) 
    --number = 2*grid
    
   

    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    
    if playrate ~= nil then
    new_rate = ItemsSel[Idx].oldPlayrate*number
    end
    new_length = old_length/number


    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate


    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    
    if take ~= nil then
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
  end
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
reaper.Undo_EndBlock("Item Random Position", -1)

end
--Msg(grid)

--========================================================================================================================
--=================================== LENGTH_TRIPLET  ====================================================================
--========================================================================================================================
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825
function length_triplet()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
------------------------------------------------ 
-- local function Msg(str)
--  reaper.ShowConsoleMsg(tostring(str) .. "\n")
--end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item) 
 if take == nil then return end
  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    _,grid = reaper.GetSetProjectGrid( 0, false )
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  
    
    Grids = {"1.5"} 
    Rand = Grids[math.random(1,#Grids)]  
    number = tonumber(Rand) 
    --number = 2*grid
    
   

    old_length = ItemsSel[Idx].oldLength
    playrate = ItemsSel[Idx].oldPlayrate
    
    new_rate = ItemsSel[Idx].oldPlayrate*number
    new_length = old_length/number
    


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
reaper.Undo_EndBlock("Item Random Position", -1)

end
--Msg(grid)
--========================================================================================================================
--=================================== RATE_RESET  ====================================================================
--========================================================================================================================
function rate_reset()

ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
   
  Idx = i + 1 -- 1-based table in Lua      
  ItemsSel[Idx] = {}  
  ItemsSel[Idx].thisItem = item 
  ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) 
  ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") 
  ItemsSel[Idx].pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )
  ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
  ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") 
  ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
  ItemsSel[Idx].source = reaper.GetMediaItemTake_Source(take)
  
   start = ItemsSel[1].position   
   old_playrate = ItemsSel[Idx].playrate
  
   source = reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
   
   _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
   _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
  
   if bpm1 == "" then
   -- bpm1 = 120
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE",1)
  else
  
  playrate_factor = tempo/bpm1
     
  reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE",playrate_factor )
  
end
end 

reaper.UpdateTimeline()  

reaper.UpdateArrange()

end  


--========================================================================================================================
--=================================== RATE_TRIPLET    ====================================================================
--========================================================================================================================
function rate_triplet()

--function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
    if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )+0.005
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"0.750"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
     marker=reaper.FindTempoTimeSigMarker(0, start )
     retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, marker )
     bpm1 = bpm
       
       end
     
   playrate_factor = tempo/bpm1
    old_length = ItemsSel[Idx].oldLength
  playrate = ItemsSel[Idx].old_rate
  new_rate = playrate_factor * number
   ItemsSel[Idx].newRate = new_rate

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

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end    


--========================================================================================================================
--=================================== RATE_HALF       ====================================================================
--========================================================================================================================
function rate_half()

--function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
    if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"0.5"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
       bpm1 = 120
       end
   playrate_factor = tempo/bpm1
    old_length = ItemsSel[Idx].oldLength
  playrate = ItemsSel[Idx].old_rate
  new_rate = playrate * number
   ItemsSel[Idx].newRate = new_rate

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

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end  


--========================================================================================================================
--===================================  RATE_TO_RIGHT  ====================================================================
--========================================================================================================================
function rate_double()
--function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
    if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"2.0"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
  
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
  bpm1 = 120
  end
     
   playrate_factor = tempo/bpm1
    old_length = ItemsSel[Idx].oldLength
  playrate = ItemsSel[Idx].old_rate
  new_rate = playrate * number
   ItemsSel[Idx].newRate = new_rate

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

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end


end



--========================================================================================================================
--=================================== RATE_RANDOM_WITHOUT_CHANGING_LENGTH  ===============================================
--========================================================================================================================

--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end

function rate_random()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
    if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
       tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )       
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )+0.005
    ItemsSel[Idx].old_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
   
   rates = {"1.5","2.0","1","0.75","0.5","0.667"}
   Rand = rates[math.random(1,#rates)]    
   number = tonumber(Rand) 
  
   source = reaper.GetMediaItemTake_Source( take ) reaper.GetMediaItemTake_Source( take ) 
   source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
      
      _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
     _, _, tempo = reaper.TimeMap_GetTimeSigAtTime( 0, start )
     
     if bpm1 == "" then
       playrate_factor = 1
       else
     
   playrate_factor = tempo/bpm1
   end
    old_length = ItemsSel[Idx].oldLength
      playrate = ItemsSel[Idx].oldPlayrate
      new_rate = playrate_factor * number
   ItemsSel[Idx].newRate = new_rate

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

  ItemsSel[i].newStart = prevEnd

end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 
  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_PLAYRATE", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end
--========================================================================================================================
--=================================== STARTOFFS_LEFT_ONE_GRID  ==================================================================
--========================================================================================================================

-- @description Move item content left one grid unit
-- @version 1.0
-- @author me2beats
-- @changelog
--  + init
function startoffs_left()
local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end

r.Undo_BeginBlock()
r.ApplyNudge(0, 0, 4, 2, -1, 0, 0)
r.Undo_EndBlock('move item content left one grid unit', -1)
end
--========================================================================================================================
--=================================== STARTOFFS_RIGHT_ONE_GRID  ==================================================================
--========================================================================================================================

-- @description Move item content right one grid unit
-- @version 1.0
-- @author me2beats
-- @changelog
--  + init
function startoffs_right()
local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end

r.Undo_BeginBlock()
r.ApplyNudge(0, 0, 4, 2, 1, 0, 0)
r.Undo_EndBlock('move item content left one grid unit', -1)
end




--========================================================================================================================
--=================================== RANDOM_STARTOFFS  ==================================================================
--========================================================================================================================

----- script by dragonetti ----



function random_startoffs()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.PreventUIRefresh(1)   

for a=1,1 do
ItemsSel = {}  
Idx = 1  
 
otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
  
ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
     bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
       tonumber(({reaper.CF_GetMediaSourceMetadata( src, "bpm", "" )})[2])
  _, comment = reaper.GetMediaFileMetadata(source, "XMP:dm/logComment" )    
  
  if bpm == nil then bpm = 120 end
 
  local thisTrack = reaper.GetMediaItem_Track(item)
 --if comment ~= "phrase" then break end
  if thisTrack == mainTrack then
     
    
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source )
    
    start = ItemsSel[1].oldPosition  
    grid_end = reaper.BR_GetNextGridDivision( start)      
    grid_length = grid_end - start
  -----
  length = ItemsSel[Idx].source_length
    note_start = ItemsSel[Idx].startoffs
    onebar = ItemsSel[Idx].startoffs + 2.5
    
    
    _, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(proj, false) -- backup current grid settings
   
    bpm1 = reaper.TimeMap2_GetDividedBpmAtTime( 0, start )
    
    if bpm == 120 then bpm = bpm1
    else bpm = bpm end
    
   timing = (60/bpm) * 4
    
   grid_length = (grid * timing)      -- one bar at tempo 96bpm = 2.5 s
    
    factor = (length/grid_length)
    factor1 = math.floor(factor+0.5)
    rand_factor = math.random (1,factor1)
   new_start = rand_factor * grid_length
   -----    

 
    ItemsSel[Idx].newRate = new_start


  
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", new_start)

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


  ItemsSel[i].newStart = prevEnd



end

--if comment ~= "phrase" then break end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end

  reaper.SetMediaItemInfo_Value(otherItems[i].item, "D_POSITION", ItemsSel[index].newStart or ItemsSel[index].oldPosition) 

  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_STARTOFFS", ItemsSel[index].newRate)

  index = index + 1  
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

if endposi == loop_end then break end
end

end


--================================================================================================================================
--======================================= PHRASE_BUILDER_1RIGHT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_1_right()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)
    if num_chords==0 then Msg("no chordtrack ") return end
    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")+0.01
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
      if take == nil then return end
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo+7) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_2LEFT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_2_left()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo-2) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_2_RIGHT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_2_right()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)

    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo+2) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_builder()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)
    if num_chords==0 then Msg("no chordtrack ") return end
    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
      if take == nil then return end
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

--================================================================================================================================
--======================================= PHRASE_BUILDER_1_LEFT =========================================================================
--================================================================================================================================
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging
--function phrase_builder_x()
-- phrase_builder 
--  Thanks MusoBob
-- Display a message in the console for debugging

function phrase_1_left()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
   
    note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7 
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  

  note2 = 0
  

  if string.find(",Maj,M,maj7", ","..chord..",", 1, true)       then note2=0  end  -- ionian
  if string.find(",m7,min7,-7,min6", ","..chord..",", 1, true)  then note2=-2 end  -- dorian 
  if string.find(",m7b9,", ","..chord..",", 1, true)            then note2=-4 end  -- phrygian
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=-4 end  -- lydian
  if string.find(",7,dom,", ","..chord..",", 1, true)           then note2=-7 end  -- mixolydian  
  if string.find(",m,", ","..chord..",", 1, true)               then note2=3  end  -- aeloian  
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true)       then note2=1  end  -- lokrian 
  
end


--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
  
  for i = 0, sel_tracks -1  do
  
  
    track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
  
    track_number = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) 
    
    ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)
    if num_chords==0 then Msg("no chordtrack ") return end
    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
    item_start = reaper.GetMediaItemInfo_Value( current_item, "D_POSITION")
    
    --Does item start within region
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
        reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
    else -- track == nil/no track with that name was
          num_chords = reaper.CountTrackMediaItems(ctrack)
          
    if item_start >= pos and item_start < rgnend then 
      
      get_chord_notes(r) -- get the chord notes for current region
      

      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      take = reaper.GetActiveTake(current_item)
      if take == nil then return end
    source =  reaper.GetMediaItemTake_Source( take )
    _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
    
        if key == "C" or key == "Am" or key == "" then transpo = 0
       elseif key == "C#" or key == "A#m"then transpo = -1
       elseif key == "Db" or key == "Bbm"then transpo = -1
       elseif key == "D"  or key == "Bm"then transpo = -2
       elseif key == "Eb" or key == "Cm"then transpo = -3
        elseif key == "E" or key == "C#m"then transpo = -4
        elseif key == "F" or key == "Dm"then transpo = -5
       elseif key == "F#" or key == "D#m"then transpo = -6
       elseif key == "Gb" or key == "Ebm"then transpo = -6
        elseif key == "G" or key == "Em"then transpo = -7 
       elseif key == "G#" or key == "E#m"then transpo = -8
       elseif key == "Ab" or key == "Fm"then transpo = -8 
        elseif key == "A" or key == "F#m"then transpo = -9
        elseif key == "Bb" or key == "Gm"then transpo = -10
        elseif key == "B" or key == "G#m"then transpo = -11
        elseif key == "Cb" or key == "Abm"then transpo = -11
       if not key then end
       end
  
    
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+note2+transpo-5) -- phrase transpose
      
    
    end
    reaper.UpdateItemInProject(current_item)
      end
    end
   end
  end -- items loop end
    end -- regions loop end
  end
  end  
 end 
main()  
  

::skip:: 
  
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------set_rate_1_and length to source-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------
function rate_1_length_source()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.Main_OnCommand(40652,0)
sel_items = reaper.CountSelectedMediaItems(0)
if sel_items < 1 then
  return
end

for i = 0, sel_items - 1 do
     item = reaper.GetSelectedMediaItem(0, i)
     take = reaper.GetActiveTake(item, 0)
   _, bpm = reaper.GetMediaFileMetadata(source, "XMP:dm/tempo" ) -- consideration of the original key Metadata from wav file "Key" 
   _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
   rate = bpm/bpm1

   sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
    
     reaper.SetMediaItemInfo_Value( item,"D_LENGTH" , sourcelength*rate )
end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------RESET_CONTENT------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
------- 
function reset_content()

ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  take = reaper.GetActiveTake(item)   
    
  Idx = i + 1 -- 1-based table in Lua    
  ItemsSel[Idx] = {}
  ItemsSel[Idx].thisItem = item
  ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
  ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")


 -- onebar = ItemsSel[Idx].startoffs + 2



 
  reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS",0)
 
end 
reaper.UpdateArrange()
 
end
--===========================================================================================================================================
--================================random_source_length_to_source_length======================================================================
--===========================================================================================================================================
------script--- random_source_length_to_source_length---
---script idea - dragonetti --
--thanks to MusoBob
-- and code parts of .. mpl,me2beats 

-----------------------------------------------------------  key minus transpo ------------------------------------------------
function random_source_length_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end
-----------------------------------------------------------------------------------------------------------------------------
----------- Switch item source file to random in folder -- by ---    me2beats -------



local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

function shuffle(array)

  function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
  end

  local counter = #array
  while counter > 1 do
    local index = math.random(counter)
    swap(array, index, counter)
    counter = counter - 1
  end
end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

--r.Main_OnCommand(40440,0)

for j = 0, r.CountSelectedMediaItems()-1 do
  local it = r.GetSelectedMediaItem(0,j)
  
  
  local tk = r.GetActiveTake(it)
  if not tk then goto cnt end
  if r.TakeIsMIDI(tk) then goto cnt end
  local src = r.GetMediaItemTake_Source(tk)
  if not src then goto cnt end
  local src_fn = r.GetMediaSourceFileName(src, '')
  local folder = src_fn:match[[(.*)\]]

  local clonedsource

  local pos, new_fn, files
  pos = r.GetExtState(folder, 'pos')
  if not (pos and pos ~= '') then
  
    local t = {}
    for i = 0, 10000 do
  local fn = r.EnumerateFiles(folder, i)
  if not fn or fn == '' then break end
  if fn:match'%.wav$' or fn:match'%.mp3$' or fn:match'%.aiff$' then
    t[#t+1] = folder..[[\]]..fn
  end
    end

    files = #t
    shuffle(t)
    
  
    for i = 1, files do
  local ext_key = tostring(i)
  r.SetExtState(folder, ext_key, t[i], 0)
    end

    r.SetExtState(folder, 'pos', 1, 0)
    r.SetExtState(folder, 'files', files, 0)
    pos = 1
    new_fn = t[1]
  else
    files = tonumber(r.GetExtState(folder, 'files'))
    pos = tonumber(r.GetExtState(folder, 'pos'))
    local f
    for i = 1, files do
  if pos <= files-1 then pos = pos+1 else pos = 1 end
  new_fn = r.GetExtState(folder, tostring(pos))
  if r.file_exists(new_fn) then f = pos break end
    end
    if not f then new_fn = nil
    else
  r.SetExtState(folder, 'pos', pos, 0)
    end

  end
  
  if new_fn then
    clonedsource = r.PCM_Source_CreateFromFile(new_fn)
    r.SetMediaItemTake_Source(tk, clonedsource)
    r.GetSetMediaItemTakeInfo_String(tk, 'P_NAME', new_fn:match[[.*\(.*)]], 1)
    r.UpdateItemInProject(it)
  end 
  
  ::cnt::
  
end
--reaper.Main_OnCommand(42228,0) --Item: Set item start/end to source media start/end --
r.Main_OnCommand(40439,0)   -- Item: Set selected media online --
r.Main_OnCommand(40047,0)  -- Peaks: Build any missing peaks --
r.PreventUIRefresh(-1)

r.Undo_EndBlock('Switch item source', -1)
--------------------------------------------------------------------------------------


------------------------------- mirror script by dragonetti, MusoBob ( source mpl script)---------------------------------

sel_item_count = reaper.CountSelectedMediaItems( 0 )

for i = 0, sel_item_count - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item, 0)

   sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
           rate = reaper.GetMediaItemTakeInfo_Value( take, "D_PLAYRATE" )
     reaper.SetMediaItemInfo_Value( item,"D_LENGTH" , sourcelength/rate )   -- new source length to item length --
end

item_table_source_filename = {}
item_table_source_start = {}
item_table_source_length = {}
item_table_playrate = {}
item_table_source_pos = {}
item_table_source = {}
item_table_color = {}
table_mute = {}
item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1
item_table_mute = {}

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
for selitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   
   thisItem = reaper.GetSelectedMediaItem(0 , selitem )
   thisTrack = reaper.GetMediaItem_Track(thisItem)
   item = reaper.GetMediaItem(1, selitem )
   take = reaper.GetActiveTake(item)

  
  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount 
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end
reaper.Main_OnCommand(40297,0)

commandID = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(commandID, 0)
name = reaper.ReverseNamedCommandLookup(commandID) 

sel_track_count =  reaper.CountSelectedTracks(0 )
upper_track = reaper.GetSelectedTrack( 0, 0 )

reaper.CountSelectedMediaItems(0)

for xselitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   upper_item = reaper.GetTrackMediaItem( upper_track, xselitem )
   first_item = reaper.GetSelectedMediaItem(0 , 0)
   xthisItem = reaper.GetSelectedMediaItem(0 , xselitem)
   xtake =  reaper.GetActiveTake(xthisItem )
    
    mute =  reaper.GetMediaItemInfo_Value(xthisItem, "B_MUTE" )
   color = reaper.GetMediaItemInfo_Value(xthisItem, "I_CUSTOMCOLOR" )
  source_pos = reaper.GetMediaItemInfo_Value( xthisItem, "D_POSITION" )
  source = reaper.GetMediaItemTake_Source(xtake)
   playrate = reaper.GetMediaItemTakeInfo_Value( xtake, "D_PLAYRATE" )
   source_length = reaper.GetMediaItemInfo_Value( xthisItem, "D_LENGTH" )
   source_start = reaper.GetMediaItemTakeInfo_Value( xtake, "D_STARTOFFS" )
   retval, source_filename = reaper.GetSetMediaItemTakeInfo_String(xtake, "P_NAME", "", 0)
   
  table.insert(item_table_mute, mute)
  table.insert(item_table_color, color)
  table.insert(item_table_source, source)
  table.insert(item_table_source_pos, source_pos)
  table.insert(item_table_playrate, playrate)
  table.insert(item_table_source_length, source_length)
  table.insert(item_table_source_start, source_start)
  table.insert(item_table_source_filename, source_filename)
  
end

---mute------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_mute)
  
  if item_table_mute[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",item_table_mute[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_mute[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE", item_table_mute[index] )
  index = index + 1
end
---- color ---
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_color)
  
  if item_table_color[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "I_CUSTOMCOLOR",item_table_color[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_color[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "I_CUSTOMCOLOR", item_table_color[index] )
  index = index + 1
end
-------- source -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source)
  
  if item_table_source[ptid] then
    reaper.SetMediaItemTake_Source(reaper.GetActiveTake(item_ptrs[i]), item_table_source[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source[index] then
    index = 1
  end

  reaper.SetMediaItemTake_Source(reaper.GetActiveTake(other_items[i].item),  item_table_source[index] )
  index = index + 1
end
------------ position -----------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_pos)
  
  if item_table_source_pos[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i],"D_POSITION" ,item_table_source_pos[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_pos[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item,"D_POSITION" ,  item_table_source_pos[index] )
  index = index + 1
end

-------- playrate -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_playrate)
  
  if item_table_playrate[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_PLAYRATE", item_table_playrate[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_playrate[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_PLAYRATE",  item_table_playrate[index] )
  index = index + 1
end

---------length------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_length)
  
  if item_table_source_length[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "D_LENGTH",item_table_source_length[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_length[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "D_LENGTH", item_table_source_length[index] )
  index = index + 1
end

-------- startoffs -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_start)
  
  if item_table_source_start[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_STARTOFFS", item_table_source_start[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_start[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_STARTOFFS",  item_table_source_start[index] )
  index = index + 1
end

-------- filename -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_filename)
  
  if item_table_source_filename[ptid] then
    reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item_ptrs[i]),"P_NAME", item_table_source_filename[ptid],1)
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_filename[index] then
    index = 1
  end

  reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(other_items[i].item),"P_NAME",  item_table_source_filename[index],1 )
  index = index + 1
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   

startOut, endOut = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)

 newstart = startOut
 newend = endOut




---]]----------------------- items together depending on regions and columns -- MusoBob ---------------
function items_together()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

  first_item = reaper.GetSelectedMediaItem(0, 0)
  
  
  item_t = {}

  item_count = reaper.CountSelectedMediaItems(0)
  
    -- main action
    for i = 2, item_count do
  item = reaper.GetSelectedMediaItem(0, i-1)
  if item ~= nil then
    prev_item = reaper.GetSelectedMediaItem(0, i-2)
    prev_item_pos = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")
    prev_item_len = reaper.GetMediaItemInfo_Value(prev_item, "D_LENGTH")
    newpos = prev_item_pos + prev_item_len
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", newpos)
    
    
  end  
     end 
  end
  
  


function count_regions()

  sel_item_count = reaper.CountSelectedMediaItems( 0 )
  first_item = reaper.GetSelectedMediaItem(0, 0) -- first selected item
  items_track = reaper.GetMediaItemTrack( first_item )
  
  reaper.Main_OnCommand( 40297, 0 ) -- Track: Unselect all tracks
  reaper.SetTrackSelected( items_track, 1 )
  
  first_item_num = reaper.GetMediaItemInfo_Value(first_item, "IP_ITEMNUMBER")
  first_item_start = reaper.GetMediaItemInfo_Value( first_item, "D_POSITION" )
  last_item = reaper.GetSelectedMediaItem(0, sel_item_count-1) 
  last_item_start = reaper.GetMediaItemInfo_Value( last_item, "D_POSITION" )
  item_count =  reaper.CountMediaItems( 0 )
  
  sel_item_table = {}
  
  for i = 0, item_count -1 do
    
    item = reaper.GetMediaItem( 0, i )
    is_sel = reaper.IsMediaItemSelected( item )
    if is_sel then 
  item_num = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")
    
  table.insert(sel_item_table, item_num)
    end
  end  
  
  reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
  
  markeridx, first_region = reaper.GetLastMarkerAndCurRegion( 0, first_item_start )
  markeridx, last_region = reaper.GetLastMarkerAndCurRegion( 0, last_item_start )     
  
  
  for i = first_region, last_region do 
  
    retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers3(0, i)
    start_time, end_time = reaper.GetSet_LoopTimeRange(true, true, posOut, rgnendOut, 0)
    
    reaper.Main_OnCommand( 40718, 0 ) -- Item: Select all items on selected tracks in current time selection
    items_together()
    
  end
  
  reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
  reaper.Main_OnCommand( 40635, 0 ) -- Time selection: Remove time selection

end 


function count_tracks()

  item_count =  reaper.CountMediaItems( 0 )
  sel_item_count1 = reaper.CountSelectedMediaItems( 0 )
  all_sel_item_table = {}
  
  for i = 0, item_count -1 do
    
    item = reaper.GetMediaItem( 0, i )
    is_sel = reaper.IsMediaItemSelected( item )
    if is_sel then
  
  table.insert(all_sel_item_table, i)
    end
  end 

  reaper.Main_OnCommand( 40297, 0 ) -- Track: Unselect all tracks

  for i = 0, item_count -1 do
    
    item = reaper.GetMediaItem( 0, i )
    is_sel = reaper.IsMediaItemSelected( item )
    if is_sel then 
  
  item_track = reaper.GetMediaItemTrack( item )
  reaper.SetTrackSelected( item_track, 1 )
    
    end
  end 
  
  track_count =  reaper.CountTracks( 0 )
  sel_track_table = {}
  for t = 0, track_count -1 do
    
    trackid = reaper.GetTrack( 0, t )
    
    is_track_sel = reaper.IsTrackSelected( trackid )
    if is_track_sel then
  
  table.insert(sel_track_table,t)
    end
  end
  
  sel_track_count = reaper.CountSelectedTracks2( 0, 0 )
  
  for s = 1, sel_track_count do
  
    reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
    trackid = reaper.GetTrack( 0, sel_track_table[s] )
    reaper.SetOnlyTrackSelected( trackid )
    
    for ic = 1, sel_item_count1 do
  
  item = reaper.GetMediaItem( 0, all_sel_item_table[ic] )
  item_track = reaper.GetMediaItemTrack(item)
  
  if trackid == item_track then
  
    reaper.SetMediaItemSelected( item, 1 )
  end
    end
    
    count_regions()
    
  end 
  ------------------------------------------------------------
  -----------------------------------------------------
  ---------------------------------------------
  reaper.Main_OnCommand( 40289, 0 ) -- Item: Unselect all items
  reaper.Main_OnCommand( 40635, 0 ) -- Time selection: Remove time selection
  
  for i = 1, sel_item_count1 do
  
    item = reaper.GetMediaItem( 0, all_sel_item_table[i] )
    reaper.SetMediaItemSelected( item, 1 )
    
  end
end

count_tracks()
reaper.Main_OnCommand(1068,0 ) -- toggle loop on/off

startOut, endOut = reaper.GetSet_LoopTimeRange(true, true, newstart, newend, true)
reaper.Main_OnCommand(1068,0 )   -- toggle loop on/off
reaper.UpdateArrange()

 
end
--=============================================================================================================
--============================== shuffle_startoffs================================================================
--===============================================================================================================
---------------------------------------------------------------------------------------
--- random_length within the time selection depending on grid----
----- script by  jkuk,dragonetti and solger -------
---https://forum.cockos.com/showthread.php?p=2285825#post2285825

function shuffle_startoffs()

--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

ItemsSel = {}
Idx = 1

otherItems = {} 
counter = 1

loop_start, loop_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false  )

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))


ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  take = reaper.GetActiveTake(item)
  if take == nil then return end

  local thisTrack = reaper.GetMediaItem_Track(item)

  if thisTrack == mainTrack then
   
    ItemsSel[Idx] = {} 
    ItemsSel[Idx].thisItem = item
    ItemsSel[Idx].oldPosition =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].oldPlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].oldStartoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    ItemsSel[Idx].oldLength = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
    
    start = ItemsSel[1].oldPosition  
    
    _, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(proj, false) -- backup current grid settings   
   
  source = reaper.GetMediaItemTake_Source( take ) 
  source_length, lengthIsQN = reaper.GetMediaSourceLength( source )
     --_, bpm = reaper.GetMediaFileMetadata(source, "XMP:dm/tempo" ) -- consideration of the original key Metadata from wav file "Key" 
  _,bpm1 = reaper.GetMediaFileMetadata(source,"Generic:BPM")
  
  if bpm1 =="" then 
  
   
     --  new_rate = 1
    marker=reaper.FindTempoTimeSigMarker(0, start )
    retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, marker )
    bpm1 = bpm
  -- source_length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )*(bpm/120)
   grid_length = grid*2 *120/bpm
   bar_length = 120/bpm
     --  new_rate = 1
    else
    
   bar_length = 240/bpm1
   grid_length = (grid * bar_length)      -- one bar at tempo 96bpm = 2.5 s
end   
    --    if grid_length > source_length then return end
  --  rand_factor = math.random(rand_factor)
  --  new_start = rand_factor * grid_length
     -- rand_factor = (source_length*new_rate)/grid_length  
    

    new_length = ItemsSel[Idx].oldLength
    new_rate = ItemsSel[Idx].oldPlayrate
   -- new_startoffs = ItemsSel[Idx].oldStartoffs + new_start
    

    
   rand_factor = (source_length*new_rate)/grid_length 
   rand_factor_new = math.floor(rand_factor)
   factor_x = math.random(0,rand_factor_new)
   new_startoffs = factor_x*grid_length
    
    ItemsSel[Idx].newLength = new_length
    ItemsSel[Idx].newRate = new_rate
    ItemsSel[Idx].newStartoffs = new_startoffs
    

    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",new_length)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
   reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", new_startoffs)

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



end

local index = 1
for i = 1, counter - 1 do
  if index > Idx - 1 then index = 1 end


  reaper.SetMediaItemTakeInfo_Value(otherItems[i].take, "D_STARTOFFS", ItemsSel[index].newStartoffs)

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Item Random Position", -1)

--Msg(grid_length)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- random source ----------------------------------------------
----------------------------------------------------------------------------------------------------------



function random_source_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  reaper.SetMediaItemInfo_Value( item, "B_LOOPSRC", 0)  ---loop source off -----
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end

----------- Switch item source file to random in folder -- by ---    me2beats -------------------------------------------------------



local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end

function shuffle(array)

  function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
  end

  local counter = #array
  while counter > 1 do
    local index = math.random(counter)
    swap(array, index, counter)
    counter = counter - 1
  end
end

local items = r.CountSelectedMediaItems()
if items == 0 then bla() return end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

--r.Main_OnCommand(40440,0)

for j = 0, r.CountSelectedMediaItems()-1 do
  local it = r.GetSelectedMediaItem(0,j)
  
  
  local tk = r.GetActiveTake(it)
  if not tk then goto cnt end
  if r.TakeIsMIDI(tk) then goto cnt end
  local src = r.GetMediaItemTake_Source(tk)
  if not src then goto cnt end
  local src_fn = r.GetMediaSourceFileName(src, '')
  local folder = src_fn:match[[(.*)\]]

  local clonedsource

  local pos, new_fn, files
  pos = r.GetExtState(folder, 'pos')
  if not (pos and pos ~= '') then
  
    local t = {}
    for i = 0, 10000 do
  local fn = r.EnumerateFiles(folder, i)
  if not fn or fn == '' then break end
  if fn:match'%.wav$' or fn:match'%.mp3$' or fn:match'%.aiff$' then
    t[#t+1] = folder..[[\]]..fn
  end
    end

    files = #t
    shuffle(t)
    
  
    for i = 1, files do
  local ext_key = tostring(i)
  r.SetExtState(folder, ext_key, t[i], 0)
    end

    r.SetExtState(folder, 'pos', 1, 0)
    r.SetExtState(folder, 'files', files, 0)
    pos = 1
    new_fn = t[1]
  else
    files = tonumber(r.GetExtState(folder, 'files'))
    pos = tonumber(r.GetExtState(folder, 'pos'))
    local f
    for i = 1, files do
  if pos <= files-1 then pos = pos+1 else pos = 1 end
  new_fn = r.GetExtState(folder, tostring(pos))
  if r.file_exists(new_fn) then f = pos break end
    end
    if not f then new_fn = nil
    else
  r.SetExtState(folder, 'pos', pos, 0)
    end

  end
  
  if new_fn then
    clonedsource = r.PCM_Source_CreateFromFile(new_fn)
    r.SetMediaItemTake_Source(tk, clonedsource)
    r.GetSetMediaItemTakeInfo_String(tk, 'P_NAME', new_fn:match[[.*\(.*)]], 1)
    r.UpdateItemInProject(it)
  end 
  
  ::cnt::
  
end
--reaper.Main_OnCommand(42228,0) --Item: Set item start/end to source media start/end --
r.Main_OnCommand(40439,0)   -- Item: Set selected media online --
r.Main_OnCommand(40047,0)  -- Peaks: Build any missing peaks --
r.PreventUIRefresh(-1)

r.Undo_EndBlock('Switch item source', -1)
--------------------------------------------------------------------------------------


------------------------------- mirror script by dragonetti ( source mpl script)---------------------------------

sel_item_count = (reaper.CountSelectedMediaItems( 0 ))

item_table_source_filename = {}
item_table_source_start = {}
item_table_source_length = {}
item_table_playrate = {}
item_table_source_pos = {}
item_table_source = {}
item_table_color = {}
table_mute = {}
item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1
item_table_mute = {}

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))
for selitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   
   thisItem = reaper.GetSelectedMediaItem(0 , selitem )
   thisTrack = reaper.GetMediaItem_Track(thisItem)
   item = reaper.GetMediaItem(1, selitem )
   take = reaper.GetActiveTake(item)

  
  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount 
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end
reaper.Main_OnCommand(40297,0)

commandID = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(commandID, 0)
name = reaper.ReverseNamedCommandLookup(commandID) 

sel_track_count =  reaper.CountSelectedTracks(0 )
upper_track = reaper.GetSelectedTrack( 0, 0 )

reaper.CountSelectedMediaItems(0)

for xselitem = 0, (reaper.CountSelectedMediaItems(0)-1) do
   upper_item = reaper.GetTrackMediaItem( upper_track, xselitem )
   first_item = reaper.GetSelectedMediaItem(0 , 0)
   xthisItem = reaper.GetSelectedMediaItem(0 , xselitem)
   xtake =  reaper.GetActiveTake(xthisItem )
    
    mute =  reaper.GetMediaItemInfo_Value(xthisItem, "B_MUTE" )
   color = reaper.GetMediaItemInfo_Value(xthisItem, "I_CUSTOMCOLOR" )
  source_pos = reaper.GetMediaItemInfo_Value( xthisItem, "D_POSITION" )
  source = reaper.GetMediaItemTake_Source(xtake)
   playrate = reaper.GetMediaItemTakeInfo_Value( xtake, "D_PLAYRATE" )
   source_length = reaper.GetMediaItemInfo_Value( xthisItem, "D_LENGTH" )
   source_start = reaper.GetMediaItemTakeInfo_Value( xtake, "D_STARTOFFS" )
   retval, source_filename = reaper.GetSetMediaItemTakeInfo_String(xtake, "P_NAME", "", 0)
   
  table.insert(item_table_mute, mute)
  table.insert(item_table_color, color)
  table.insert(item_table_source, source)
  table.insert(item_table_source_pos, source_pos)
  table.insert(item_table_playrate, playrate)
  table.insert(item_table_source_length, source_length)
  table.insert(item_table_source_start, source_start)
  table.insert(item_table_source_filename, source_filename)
  
end


--------------------------------------------------------

---mute------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_mute)
  
  if item_table_mute[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",item_table_mute[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_mute[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE", item_table_mute[index] )
  index = index + 1
end
---- color ---
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_color)
  
  if item_table_color[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "I_CUSTOMCOLOR",item_table_color[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_color[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "I_CUSTOMCOLOR", item_table_color[index] )
  index = index + 1
end
-------- source -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source)
  
  if item_table_source[ptid] then
    reaper.SetMediaItemTake_Source(reaper.GetActiveTake(item_ptrs[i]), item_table_source[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source[index] then
    index = 1
  end

  reaper.SetMediaItemTake_Source(reaper.GetActiveTake(other_items[i].item),  item_table_source[index] )
  index = index + 1
end
------------ position -----------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_pos)
  
  if item_table_source_pos[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i],"D_POSITION" ,item_table_source_pos[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_pos[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item,"D_POSITION" ,  item_table_source_pos[index] )
  index = index + 1
end

-------- playrate -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_playrate)
  
  if item_table_playrate[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_PLAYRATE", item_table_playrate[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_playrate[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_PLAYRATE",  item_table_playrate[index] )
  index = index + 1
end

---------length------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_length)
  
  if item_table_source_length[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "D_LENGTH",item_table_source_length[ptid])
  end
end
local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_length[index] then
    index = 1
  end

  reaper.SetMediaItemInfo_Value(other_items[i].item, "D_LENGTH", item_table_source_length[index] )
  index = index + 1
end

-------- startoffs -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_start)
  
  if item_table_source_start[ptid] then
    reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(item_ptrs[i]),"D_STARTOFFS", item_table_source_start[ptid])
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_start[index] then
    index = 1
  end

  reaper.SetMediaItemTakeInfo_Value(reaper.GetActiveTake(other_items[i].item),"D_STARTOFFS",  item_table_source_start[index] )
  index = index + 1
end

-------- filename -------
for i = 1, itemCount - 1 do 
  local ptid = ( (i-1)%#item_table_source_filename)
  
  if item_table_source_filename[ptid] then
    reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item_ptrs[i]),"P_NAME", item_table_source_filename[ptid],1)
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not item_table_source_filename[index] then
    index = 1
  end

  reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(other_items[i].item),"P_NAME",  item_table_source_filename[index],1 )
  index = index + 1
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   


  
reaper.UpdateArrange() -- Update the arrangement (often needed)
 
reaper.PreventUIRefresh(-1)

end
--==========================================================================================================================
--===================================== SCALE BUILDER ======================================================================
--==========================================================================================================================


function scale_builder()

local reaper = reaper


local retval, seq = reaper.GetUserInputs("scale sequencer", 1, "seq (q-o)octa=(a-k)semi(1-8) extrawidth=80", "iteiteit")
if not retval then return end


function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


function get_chord_notes(citem)  
      
 _, region_name = reaper.GetSetMediaItemInfo_String(citem, "P_NOTES", "", false) 
            pos = reaper.GetMediaItemInfo_Value( citem, "D_POSITION" )-0.05
         length = reaper.GetMediaItemInfo_Value( citem, "D_LENGTH" )
     region_end = pos+length      
    
     
  if string.match( region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end

     if not chord then Msg("Can't recognize a chord") end 
     if #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  

  note_root = 0 
  -- 60 = C3
  if root == "C" then root_note = 0
  elseif root == "C#" then root_note = 1
  elseif root == "Db" then root_note = 1 
  elseif root == "D"  then root_note = 2
  elseif root == "D#" then root_note = 3 
  elseif root == "Eb" then root_note = 3
  elseif root == "E"  then root_note = 4
  elseif root == "F"  then root_note = 5
  elseif root == "F#" then root_note = 6
  elseif root == "Gb" then root_note = 6
  elseif root == "G"  then root_note = 7 
  elseif root == "G#" then root_note = 8
  elseif root == "Ab" then root_note = 8
  elseif root == "A"  then root_note = 9
  elseif root == "A#" then root_note = 10  
  elseif root == "Bb" then root_note = 10
  elseif root == "B"  then root_note = 11
  if not root then end
  end
  
    if string.find(",Maj7,maj7,Maj7,Maj,M,M7,maj9,maj13,", ","..chord..",", 1, true) then notew=2  notee=4  noter=5  notet=7  notez=9  noteu=11  end -- Ionian 
    if string.find(",m7,min7,-7,m9,m11,m13,", ","..chord..",", 1, true)              then notew=2  notee=3  noter=5  notet=7  notez=9  noteu=10  end -- Dorian
    if string.find(",m7b9,m7b9b13", ","..chord..",", 1, true)             then notew=1  notee=3  noter=5  notet=7  notez=8  noteu=10  end -- Phrygian
    if string.find(",maj7#11,maj#11,maj+4,", ","..chord..",", 1, true)          then notew=2  notee=4  noter=6  notet=7  notez=9  noteu=11  end -- Lydian
    if string.find(",7,dom,9,11,13,", ","..chord..",", 1, true)              then notew=2  notee=4  noter=5  notet=7  notez=9  noteu=10  end -- Mixolydian
    if string.find(",m,min,", ","..chord..",", 1, true)                   then notew=2  notee=3  noter=5  notet=7  notez=8  noteu=10  end -- Aeolian
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then notew=1  notee=3  noter=5  notet=6  notez=8  noteu=10  end -- Locrian
    if string.find(",7aug,7+,", ","..chord..",", 1, true)           then notew=2  notee=4  noter=6  notet=8  notez=10  noteu=12  end -- whole tone scale
    if string.find(",7b9,7b5,", ","..chord..",", 1, true)           then notew=1  notee=3  noter=4  notet=6  notez=7  noteu=9  end -- diminish scale
    if string.find(",7alt,", ","..chord..",", 1, true)           then notew=1  notee=3  noter=4  notet=6  notez=8  noteu=10  end -- altered Scale
             
            noteq=0 
            notei=noteq+12
            notey=notez
            note1=noteq-1
            note2=notew-1
            note3=notee-1
            note4=noteq
            note5=noter+1
            note6=notet+1
            note7=notez+1
            note8=noteq
            note9=notei+1
            notea=noteq-12
            notes=notew-12
            noted=notee-12
            notef=noter-12
            noteg=notet-12
            noteh=notez-12
            notej=noteu-12
            notek=notei-12

end

local function main()

  local ctrack = getTrackByName("chordtrack")
  if ctrack == nil then
    return
  end

   num_ctrack_items = reaper.CountTrackMediaItems(ctrack)
   selected_items = reaper.CountSelectedMediaItems(0 )
   local takes = {}
  for i = 0, selected_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    takes[#takes + 1] = take
  end
  
  -- Loop through each selected item
  for i = 0, selected_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")-0.001
    local item_end = item_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")-0.001
    local sel_take = reaper.GetActiveTake(item)
    local item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, "D_PITCH")
    
     
    -- Loop through each item(chordSymbols) on the chordtrack
    for j = 0, num_ctrack_items - 1 do
      local citem = reaper.GetTrackMediaItem(ctrack, j)
      local start_time = reaper.GetMediaItemInfo_Value(citem, "D_POSITION")-0.001
      local end_time = start_time + reaper.GetMediaItemInfo_Value(citem, "D_LENGTH")
      local _,citem_notes = reaper.GetSetMediaItemInfo_String(citem, "P_NOTES", "", false)
      take = reaper.GetActiveTake(item)
      if take == nil then return end
      source = reaper.GetMediaItemTake_Source( take )
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
           
        if key == "C" or key == "Am" or key == "" then transpo = 0
               elseif key == "C#" or key == "A#m" then transpo = -1
               elseif key == "Db" or key == "Bbm" then transpo = -1
               elseif key == "D"  or key == "Bm"  then transpo = -2
               elseif key == "Eb" or key == "Cm"  then transpo = -3
               elseif key == "E"  or key == "C#m" then transpo = -4
               elseif key == "F"  or key == "Dm"  then transpo = -5
               elseif key == "F#" or key == "D#m" then transpo = -6
               elseif key == "Gb" or key == "Ebm" then transpo = -6
               elseif key == "G"  or key == "Em"  then transpo = -7 
               elseif key == "G#" or key == "E#m" then transpo = -8
               elseif key == "Ab" or key == "Fm"  then transpo = -8 
               elseif key == "A"  or key == "F#m" then transpo = -9
               elseif key == "Bb" or key == "Gm"  then transpo = -10
               elseif key == "B"  or key == "G#m" then transpo = -11
               elseif key == "Cb" or key == "Abm" then transpo = -11
              if not key then end
              end
      get_chord_notes(citem)
      sequence = {}
      
      for i = 1, string.len(seq) do
        local variable_name = "note" .. string.sub(seq, i, i)
        sequence[i] = _G[variable_name]
      end
      if variable_name==nil then variable_name=noteq end
     
     local index = 1
     local take, item, pitch
     for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
       item = reaper.GetSelectedMediaItem(0, i)
       if reaper.GetMediaItemInfo_Value(item, "D_POSITION") >= start_time and reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")-0.003 <= end_time then
         take = reaper.GetActiveTake(item)
         if take ~= nil then
           pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
           reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH",root_note + sequence[index])
           index = index + 1
           if index > #sequence then index = 1 end
         end
       end
       end
     end
 end
  reaper.UpdateArrange()
end

reaper.defer(main)

end
--=================================================================================================================
--============================= arpeggio inversion up ==================================================================
--=================================================================================================================
function arpeggio_up()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end



  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 255
  note6 = 255
  note7 = 255

  if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
  if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
  if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
  if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
  if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
  if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
  if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
  if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
  if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
  if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
  if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
  if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
  if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
  if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
  if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
  if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
  if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
  if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
  if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
  if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
  if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
  if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
  if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
  if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
  if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
  if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
  if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
  if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
  if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
  if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
  if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
  if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
  if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
  if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
  if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
  if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
  if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
  if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
  if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
  if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
  if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
  if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
  if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
  if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
  if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
  if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
  if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
  if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
  if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
  if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
  if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
  if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
  if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
  if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
  if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
  if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
  if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
  if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
  if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
  if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
  if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
  if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
  if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
  if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
  if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
  if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
  if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
  if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
  if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
  if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
  if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
  if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
  if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
  if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
  if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
  if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
  if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
  if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
  if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
  if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
  if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
  if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
  if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
  if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
  if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
  if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
  if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
  if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
  if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
  if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
  if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
  if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
  if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
  if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
  if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
  if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
  if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
  if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
  if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
  if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
  if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
  if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
  if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
  if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
  if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
  if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
  if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
  if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
  if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
  if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
  if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
  if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
  if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
  if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
  if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
  if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
  if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
  if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
  if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
  if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
  if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
  if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
  if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
  if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
  if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
  if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
  if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
  if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
  if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
  if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
  if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
  if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
  if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
  if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
  if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
  if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end
  

end



--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

  items = reaper.CountMediaItems(0)
  
  sel_tracks = reaper.CountSelectedTracks(0) 
  
 ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end

    for r = 0, num_chords -1 do -- regions loop start    
    
  chord_item = reaper.GetTrackMediaItem(ctrack, r )
                        pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                     length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                     rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
    
    current_item = reaper.GetMediaItem( 0, x )
  
    item_start = (reaper.GetMediaItemInfo_Value( current_item, "D_POSITION"))+0.1
    
    --Does item start within region
    
    if item_start  >= pos and item_start < rgnend then 
      --Msg("r "..r) 
      --Msg("markrgnindexnumber ".. markrgnindexnumber)
     get_chord_notes(r) -- get the chord notes for current region
      

      
      
     
     take = reaper.GetActiveTake(current_item)
     if take == nil then return end
        source =  reaper.GetMediaItemTake_Source( take )
        _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
        
            if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
                   elseif key == "C#" or key == "A#m"then transpo = -1
                   elseif key == "Db" or key == "Bbm"then transpo = -1
                   elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
                   elseif key == "Eb" or key == "Cm"then transpo = -3
                    elseif key == "E" or key == "e" or key == "C#m"then transpo = -4 
                    elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
                   elseif key == "F#" or key == "D#m"then transpo = -6
                   elseif key == "Gb" or key == "Ebm"then transpo = -6
                    elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
                   elseif key == "G#" or key == "E#m"then transpo = -8
                   elseif key == "Ab" or key == "Fm"then transpo = -8  
                    elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
                    elseif key == "Bb" or key == "Gm"then transpo = -10
                    elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
                    elseif key == "Cb" or key == "Abm"then transpo = -11
                   if not key then end
                   end         
 
   
        
     old_pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
     root_note = old_pitch - transpo - note1  
     third_note = old_pitch - transpo - note1
     quint_note = old_pitch - transpo - note1
     sept_note = old_pitch - transpo - note1
     
        
         if root_note ==-48   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-48 )
     elseif root_note ==-36   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-36 )
     elseif root_note ==-24   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-24 )
     elseif root_note ==-12   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-12 )
     elseif root_note ==0     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2 )
     elseif root_note ==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+12 )
     elseif root_note ==24    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+24 )
     elseif root_note ==36    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+36 )
     elseif root_note ==48    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+48 )
     elseif root_note ==60    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+48 )
     
     elseif third_note ==-45 or third_note ==-32   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-48 )
     elseif third_note ==-33 or third_note ==-32   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-36 )
     elseif third_note ==-21 or third_note ==-20   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-24 )
     elseif third_note ==-9 or third_note ==-8     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-12 )
     elseif third_note ==3  or third_note ==4      then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3 )
     elseif third_note ==15 or third_note ==16     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+12 )
     elseif third_note ==27 or third_note ==28     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+24 )
     elseif third_note ==39 or third_note ==40     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+36 )
     elseif third_note ==51 or third_note ==40     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+48 )
    
     elseif quint_note ==-41   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-48 )
     elseif quint_note ==-29   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-36 )
     elseif quint_note ==-17   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-24 )
     elseif quint_note ==-5   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH",  note1+note4-12 )
     elseif quint_note ==7    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH",  note1+note4 )
     elseif quint_note ==19   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH",  note1+note4+12 )
     elseif quint_note ==31   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH",  note1+note4+24 )
     elseif quint_note ==43   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH",  note1+note4+36 )
     elseif quint_note ==55   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH",  note1+note4+48 )
     
     
     elseif sept_note ==-38 or sept_note ==-37    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-36 )
     elseif sept_note ==-26 or sept_note ==-25    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-24 )
     elseif sept_note ==-14 or sept_note ==-13    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-12 )
     elseif sept_note ==-2  or sept_note ==-1     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1 )
     elseif sept_note ==10  or sept_note ==11     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+12 )
     elseif sept_note ==22  or sept_note ==23     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+24 )
     elseif sept_note ==34  or sept_note ==35     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+36 )
     elseif sept_note ==46  or sept_note ==47     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+48 )
     elseif sept_note ==58  or sept_note ==59     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+48 )
          

     
    reaper.UpdateItemInProject(current_item)
      end

     
      end          
     
      end       
        
    end
   end
   
  end -- items loop end
   -- regions loop end
  
 
  
 

  
main()  
  
reaper.Main_OnCommand(40297,0)   


::skip:: 
  

end

--=================================================================================================================
--============================= arpeggio inversion down ==================================================================
--=================================================================================================================
-- Display a message in the console for debugging
function arpeggio_down()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end



  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 =7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 255
  note6 = 255
  note7 = 255

  if string.find(",Maj,maj,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
  if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
  if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
  if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
  if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
  if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
  if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
  if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
  if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
  if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
  if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
  if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
  if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
  if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
  if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
  if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
  if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
  if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
  if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
  if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
  if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
  if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
  if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
  if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
  if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
  if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
  if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
  if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
  if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
  if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
  if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
  if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
  if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
  if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
  if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
  if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
  if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
  if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
  if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
  if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
  if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
  if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
  if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
  if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
  if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
  if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
  if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
  if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
  if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
  if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
  if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
  if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
  if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
  if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
  if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
  if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
  if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
  if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
  if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
  if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
  if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
  if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
  if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
  if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
  if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
  if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
  if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
  if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
  if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
  if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
  if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
  if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
  if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
  if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
  if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
  if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
  if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
  if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
  if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
  if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
  if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
  if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
  if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
  if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
  if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
  if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
  if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
  if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
  if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
  if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
  if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
  if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
  if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
  if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
  if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
  if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
  if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
  if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
  if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
  if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
  if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
  if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
  if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
  if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
  if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
  if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
  if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
  if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
  if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
  if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
  if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
  if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
  if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
  if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
  if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
  if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
  if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
  if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
  if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
  if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
  if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
  if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
  if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
  if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
  if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
  if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
  if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
  if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
  if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
  if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
  if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
  if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
  if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
  if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
  if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
  if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end
  

end



--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

  items = reaper.CountMediaItems(0)
  
  sel_tracks = reaper.CountSelectedTracks(0) 
  
 ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end

    for r = 0, num_chords -1 do -- regions loop start    
    
  chord_item = reaper.GetTrackMediaItem(ctrack, r )
                        pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                     length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                     rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
    
    current_item = reaper.GetMediaItem( 0, x )
  
    item_start = (reaper.GetMediaItemInfo_Value( current_item, "D_POSITION"))+0.1
    
    --Does item start within region
    
    if item_start  >= pos and item_start < rgnend then 
      --Msg("r "..r) 
      --Msg("markrgnindexnumber ".. markrgnindexnumber)
     get_chord_notes(r) -- get the chord notes for current region
      

      
      
     
     take = reaper.GetActiveTake(current_item)
     if take == nil then return end
        source =  reaper.GetMediaItemTake_Source( take )
        _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
        
            if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
                   elseif key == "C#" or key == "A#m"then transpo = -1
                   elseif key == "Db" or key == "Bbm"then transpo = -1
                   elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
                   elseif key == "Eb" or key == "Cm"then transpo = -3
                    elseif key == "E" or key == "e" or key == "C#m"then transpo = -4 
                    elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
                   elseif key == "F#" or key == "D#m"then transpo = -6
                   elseif key == "Gb" or key == "Ebm"then transpo = -6
                    elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
                   elseif key == "G#" or key == "E#m"then transpo = -8
                   elseif key == "Ab" or key == "Fm"then transpo = -8  
                    elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
                    elseif key == "Bb" or key == "Gm"then transpo = -10
                    elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
                    elseif key == "Cb" or key == "Abm"then transpo = -11
                   if not key then end
                   end         
    -- Msg(note3)
   --  Msg(note4)
        
     old_pitch  = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
     root_note  = old_pitch - transpo - note1  
     third_note = old_pitch - transpo - note1
     quint_note = old_pitch - transpo - note1
     sept_note  = old_pitch - transpo - note1
     
  --   Msg(third_note)
  
         if root_note ==-48 and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-60 )
     elseif root_note ==-36 and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-48 )
     elseif root_note ==-24 and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-36)
     elseif root_note ==-12 and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-24)
     elseif root_note ==0   and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-12)
     elseif root_note ==12  and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3)
     elseif root_note ==24  and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+12)
     elseif root_note ==36  and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+24 )
     elseif root_note ==48  and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+36 )
     elseif root_note ==60  and note4==12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+48 )
     
     elseif root_note ==-48 and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-60 )
     elseif root_note ==-36 and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-48 )
     elseif root_note ==-12 and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-24 )
     elseif root_note ==-12 and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-24 )
     elseif root_note ==0   and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4-12 )
     elseif root_note ==12  and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4 )
     elseif root_note ==24  and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4+12 )
     elseif root_note ==36  and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4+24 )
     elseif root_note ==48  and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4+36 )
     elseif root_note ==60  and note4~=12    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note4+48 )
     
     elseif third_note ==-45 or third_note ==-32   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-48 )
     elseif third_note ==-33 or third_note ==-32   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-36 )
     elseif third_note ==-21 or third_note ==-20   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-24 )
     elseif third_note ==-9 or third_note ==-8     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1-12 )
     elseif third_note ==3  or third_note ==4      then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1 )
     elseif third_note ==15 or third_note ==16     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+12 )
     elseif third_note ==27 or third_note ==28     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+24 )
     elseif third_note ==39 or third_note ==40     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+36 )
     elseif third_note ==51 or third_note ==40     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+48 )
     
     elseif quint_note ==-41  then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-48 )
     elseif quint_note ==-29  then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-36 )
     elseif quint_note ==-17  then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-24 )
     elseif quint_note ==-5   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2-12 )
     elseif quint_note ==7    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2 )
     elseif quint_note ==19   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+12 )
     elseif quint_note ==31   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+24 )
     elseif quint_note ==43   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+36 )
     elseif quint_note ==55   then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note2+48 )
    
     elseif sept_note ==-38 or sept_note ==-25    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-48 )
     elseif sept_note ==-26 or sept_note ==-25    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-36 )
     elseif sept_note ==-14 or sept_note ==-13    then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-24 )
     elseif sept_note ==-2  or sept_note ==-1     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3-12 )
     elseif sept_note ==10  or sept_note ==11     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3 )
     elseif sept_note ==22  or sept_note ==23     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+12 )
     elseif sept_note ==34  or sept_note ==35     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+24 )
     elseif sept_note ==46  or sept_note ==47     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+36 )
     elseif sept_note ==58  or sept_note ==47     then   reaper.SetMediaItemTakeInfo_Value( take,"D_PITCH", note1+note3+48 )
     
          
    
     
    reaper.UpdateItemInProject(current_item)
      end
  
     
      end          
     
      end       
        
    end
   end
   
  end -- items loop end
   -- regions loop end
  
 
  
 

  
main()  
  
reaper.Main_OnCommand(40297,0)   


::skip:: 
  

end

--===========================================================================================================================
--============================================ CHORD_BUILDER ==================================================================
--============================================================================================================================
--Thanks MusoBob


--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
--end

function chord_builder() 
-- cliffon track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


function pitch_compensation(current_item) -- compensate audi items with different source pitches -- metadata key must set

          take = reaper.GetActiveTake(current_item)
          if take == nil then return end
        source =  reaper.GetMediaItemTake_Source( take )
        _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
        
               if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
           elseif key == "C#" or key == "A#m"then transpo = -1
           elseif key == "Db" or key == "Bbm"then transpo = -1
           elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
           elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "e" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
           elseif key == "F#" or key == "D#m"then transpo = -6
           elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
           elseif key == "G#" or key == "E#m"then transpo = -8
           elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
           if not key then end
           end         
end

function get_chord_notes(r) 

            item0 =  reaper.GetTrackMediaItem(ctrack,r )
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
    
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 255
  note6 = 255
  note7 = 255

  if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
  if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
  if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
  if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
  if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
  if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
  if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
  if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
  if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
  if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
  if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
  if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
  if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
  if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
  if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
  if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
  if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
  if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
  if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
  if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
  if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
  if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
  if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
  if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
  if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
  if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
  if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
  if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
  if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
  if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
  if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
  if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
  if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
  if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
  if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
  if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
  if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
  if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
  if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
  if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
  if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
  if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
  if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
  if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
  if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
  if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
  if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
  if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
  if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
  if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
  if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
  if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
  if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
  if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
  if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
  if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
  if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
  if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
  if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
  if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
  if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
  if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
  if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
  if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
  if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
  if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
  if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
  if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
  if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
  if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
  if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
  if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
  if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
  if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
  if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
  if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
  if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
  if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
  if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
  if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
  if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
  if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
  if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
  if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
  if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
  if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
  if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
  if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
  if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
  if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
  if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
  if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
  if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
  if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
  if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
  if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
  if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
  if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
  if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
  if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
  if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
  if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
  if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
  if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
  if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
  if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
  if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
  if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
  if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
  if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
  if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
  if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
  if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
  if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
  if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
  if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
  if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
  if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
  if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
  if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
  if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
  if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
  if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
  if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
  if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
  if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
  if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
  if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
  if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
  if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
  if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
  if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
  if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
  if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
  if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
  if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end
  
end


--MAIN---------------------------------------------------------------
function main()
       
  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

       items = reaper.CountMediaItems(0)
  sel_tracks = reaper.CountSelectedTracks(0) 
 

  for x = 0, items -1 do -- items loop start
   
      media_item = reaper.GetMediaItem( 0, x )
   selected_item = reaper.IsMediaItemSelected(media_item) 

   if selected_item then
   
    current_item = reaper.GetMediaItem( 0, x )
      item_start = (reaper.GetMediaItemInfo_Value( current_item, "D_POSITION"))+0.001 
 
    --Does item start within region 
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    Msg("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
     if num_chords==0 then Msg("no chords") return end 
    end
    for r = 0, num_chords -1 do -- regions loop start 
               
               chord_item = reaper.GetTrackMediaItem(ctrack, r )
                      pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                   length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                   rgnend = pos+length  
 
    if item_start  >= pos and item_start < rgnend then 

      get_chord_notes(r) -- get the chord notes for current region
      
      for i = 0, sel_tracks -1  do
         
      track = reaper.GetSelectedTrack(0,(sel_tracks-1)-i)
      
     
      if i == 0 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      if take == nil then return end
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note1+transpo) -- chord root 
     
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 1 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note2+note1+transpo) -- chord root 
      if take == nil then return end
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 2 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note3+note1+transpo) -- chord root 
      if take == nil then return end
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 3 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note4+note1+transpo) -- chord root
      if take == nil then return end
      reaper.UpdateItemInProject(current_item)
      end
      
      if i == 4 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note5+note1+transpo) -- chord root 
      if take == nil then return end
      reaper.UpdateItemInProject(current_item)
      end          
      
      if i == 5 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note6+note1+transpo) -- chord root  
      if take == nil then return end
      reaper.UpdateItemInProject(current_item)
      end          
      
      if i == 6 and reaper.GetMediaItem_Track( current_item ) == track then
      
      pitch_compensation(current_item)
      reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH',note7+note1+transpo) -- chord root 
      if take == nil then return end
      reaper.UpdateItemInProject(current_item)
       end          
     end
    end
   end -- items loop end
  end -- regions loop end
  end
  end  
  


  
main()  
  
reaper.Main_OnCommand(40297,0)   

::skip:: 
end  

--=======================================================================================================
--================================ scale_previous ===========================================================
--=======================================================================================================

-- Display a message in the console for debugging
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
function scale_step(multi)
-- cliffon track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return 
end
 

 
function get_chord_notes(ir)
             
            item0 = reaper.GetTrackMediaItem(ctrack,ir)
   _, region_name = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false)
   
   if string.match(region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find (region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end

     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

          items = 0
          items = reaper.CountSelectedMediaItems(0)
         ctrack = getTrackByName("chordtrack")
    num_regions = reaper.CountTrackMediaItems( ctrack)
   if num_regions==0 then Msg("no chords") return end
   
    if items == 0 then goto finish end
   
   
    for i = 0, items-1 do
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")
  
  for ir = 0, num_regions -1 do -- regions end loop start 
  
     itemx = reaper.GetTrackMediaItem(ctrack, ir )
       pos = reaper.GetMediaItemInfo_Value( itemx, "D_POSITION" )
    length = reaper.GetMediaItemInfo_Value( itemx, "D_LENGTH" )
    rgnend = pos+length
   
   item_region = ir
   
    if item_pos >= pos and item_pos < rgnend then break end
  end
  
        take = reaper.GetActiveTake(sel_item)
        if take == nil then return end
      source = reaper.GetMediaItemTake_Source( take )
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
          if key == "C" or key == "Am" or key == "" then transpo = 0
         elseif key == "C#" or key == "A#m" then transpo = -1
         elseif key == "Db" or key == "Bbm" then transpo = -1
         elseif key == "D"  or key == "Bm"  then transpo = -2
         elseif key == "Eb" or key == "Cm"  then transpo = -3
          elseif key == "E" or key == "C#m" then transpo = -4
          elseif key == "F" or key == "Dm"  then transpo = -5
         elseif key == "F#" or key == "D#m" then transpo = -6
         elseif key == "Gb" or key == "Ebm" then transpo = -6
          elseif key == "G" or key == "Em"  then transpo = -7 
         elseif key == "G#" or key == "E#m" then transpo = -8
         elseif key == "Ab" or key == "Fm"  then transpo = -8 
          elseif key == "A" or key == "F#m" then transpo = -9
          elseif key == "Bb" or key == "Gm" then transpo = -10
          elseif key == "B" or key == "G#m" then transpo = -11
          elseif key == "Cb" or key == "Abm"then transpo = -11
         if not key then end
         end
     
  
  get_chord_notes(item_region)
  
    match=0
       
    for s = 1, 57 do
    
      if not sel_item then break end
      sel_take = reaper.GetActiveTake(sel_item)
      item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')  

      if (item_pitch-transpo)-note1 == scale[s] then 
        match=1  
        
        new_pitch = scale[s+multi]+note1+transpo 
        reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
        reaper.UpdateItemInProject(sel_item)
        break
      end
      
    end
    
     if match==0 then
      new_pitch = item_pitch-1
    reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
    reaper.UpdateItemInProject(sel_item)
      end
      
  end
  ::finish::  
  end


  
main() 

end
  
  






--=======================================================================================================
--================================ scale_next ===========================================================
--=======================================================================================================

-- Display a message in the console for debugging
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
function scale_next()
-- cliffon track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return 
end
 

 
function get_chord_notes(ir)  
            item0 =  reaper.GetTrackMediaItem( ctrack,ir )
   _, region_name = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false)
   
   
    
  if string.match( region_name, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(region_name, "/") then
      root, chord, slash = string.match(region_name, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(region_name, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end

     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

          items = 0
          items = reaper.CountSelectedMediaItems(0)
         ctrack = getTrackByName("chordtrack")
    num_regions = reaper.CountTrackMediaItems( ctrack)
   
    if items == 0 then goto finish end
   
   
    for i = 0, items-1 do
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")
  
  for ir = 0, num_regions -1 do -- regions end loop start 
  
     itemx = reaper.GetTrackMediaItem(ctrack, ir )
       pos = reaper.GetMediaItemInfo_Value( itemx, "D_POSITION" )
    length = reaper.GetMediaItemInfo_Value( itemx, "D_LENGTH" )
    rgnend = pos+length
   
   item_region = ir
   
    if item_pos >= pos and item_pos < rgnend then break end
  end
  
        take = reaper.GetActiveTake(sel_item)
      source = reaper.GetMediaItemTake_Source( take )
      _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
          if key == "C" or key == "Am" or key == "" then transpo = 0
         elseif key == "C#" or key == "A#m"then transpo = -1
         elseif key == "Db" or key == "Bbm"then transpo = -1
         elseif key == "D"  or key == "Bm"then transpo = -2
         elseif key == "Eb" or key == "Cm"then transpo = -3
          elseif key == "E" or key == "C#m"then transpo = -4
          elseif key == "F" or key == "Dm"then transpo = -5
         elseif key == "F#" or key == "D#m"then transpo = -6
         elseif key == "Gb" or key == "Ebm"then transpo = -6
          elseif key == "G" or key == "Em"then transpo = -7 
         elseif key == "G#" or key == "E#m"then transpo = -8
         elseif key == "Ab" or key == "Fm"then transpo = -8 
          elseif key == "A" or key == "F#m"then transpo = -9
          elseif key == "Bb" or key == "Gm"then transpo = -10
          elseif key == "B" or key == "G#m"then transpo = -11
          elseif key == "Cb" or key == "Abm"then transpo = -11
         if not key then end
         end
     
  
  get_chord_notes(item_region)
  
    match=0
       
    for s = 1, 57 do
    
      if not sel_item then break end
      sel_take = reaper.GetActiveTake(sel_item)
      item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')  

      if (item_pitch-transpo)-note1 == scale[s] then 
        match=1  
        
        new_pitch = scale[s+1]+note1+transpo 
        reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
        reaper.UpdateItemInProject(sel_item)
        break
      end
      
    end
    
     if match==0 then
      new_pitch = item_pitch+1
    reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
    reaper.UpdateItemInProject(sel_item)
      end
      
  end
  ::finish::  
  end


  
main() 

end
  





-----------------------------------------------------------------------------------------------------
--------------------------------------------chord_down--------------------------------------------------
-----------------------------------------------------------------------------------------------------
function chord_inversion_down()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)
-----------------------------------------------------------  key minus transpo ------------------------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end
-----------------------------------------------------------------------------------------------------------------------------
--sorts whatever array that is passed to it in descending order (highest to lowest)
function bubbleSort(A)
  local n = #A
  local swapped = false

  repeat
    swapped = false

    for i = 2, n do
  if A[i-1] > A[i] then
    A[i] , A[i-1] = A[i-1] , A[i]
    swapped = true
  end
    end
  until not swapped

  return A
end


--main code
groups = {}
counter = 0
prevTrack = nil
isFirstTrack = true

--loop through and organize items into a multidimensional array
for i = 0, reaper.CountSelectedMediaItems() - 1 do
  local thisItem = reaper.GetSelectedMediaItem(0, i)
  local thisTake = reaper.GetActiveTake(thisItem)

  if thisTake then
    local thisTrack = reaper.GetMediaItem_Track(thisItem)

    if thisTrack == prevTrack then
  if isFirstTrack then table.insert(groups, {takes = {}, pitches = {}}) end
  counter = counter + 1
    else
  if i == 0 then table.insert(groups, {takes = {}, pitches = {}}) else isFirstTrack = false end
  counter = 1
    end

    table.insert(groups[counter].takes, thisTake)
    table.insert(groups[counter].pitches, reaper.GetMediaItemTakeInfo_Value(thisTake, "D_PITCH"))

    prevTrack = thisTrack
  end
end


for i = 1, #groups do
  local tempPitches = groups[i].pitches

  pitchesNum = #tempPitches

  tempPitches = bubbleSort(tempPitches) --sorts all of the pitches so highest is first
  lowestPitch = tempPitches[pitchesNum] - 12 --sets the highest pitch as an octave higher than whatever the lowest pitch is

  --loops through all of the pitches to make sure the lowest pitch raised by an octave isn't already in the list of pitches
    --if it is, it will raise the next lowest pitch by an octave and check - repeating this step until it breaks out
  isEqual = false
  nextIndex = pitchesNum

  while true do
    for j = nextIndex-1, 1, -1 do
  if tempPitches[j] == lowestPitch then
    isEqual = true
    break
  end
    end

    if isEqual == true then
  nextIndex = nextIndex - 1
  lowestPitch = tempPitches[nextIndex] - 12 

  isEqual = false
    else
  break
    end

    if nextIndex < 1 then break end --check to break out of the while in case something goes wrong and everything is equal
  end

  tempPitches[pitchesNum] = lowestPitch --sets the lowest pitch to whatever the highest pitch became
  tempPitches = bubbleSort(tempPitches) --resorts all of the pitches so highest is first

  pitchesNum = pitchesNum + 1

  --go through and change the pitches in the current grouping
  local tempTakes = groups[i].takes
  for j = 1, #tempTakes do
    reaper.SetMediaItemTakeInfo_Value(tempTakes[j], "D_PITCH", tempPitches[pitchesNum - j])
  end
end
------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Swap Pitches Down", -1)
end
------------------------------------------------------------------------------------------------------
--------------------------------------chord_up-------------------------------------------------------
-----------------------------------------------------------------------------------------------------
function chord_inversion_up()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)
-----------------------------------------------------------  key minus transpo ------------------------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  
  
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch

     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
           elseif key == "E" or key == "C#m"then transpo = -4
           elseif key == "F" or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
           elseif key == "G" or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
           elseif key == "A" or key == "F#m"then transpo = -9
           elseif key == "Bb" or key == "Gm"then transpo = -10
           elseif key == "B" or key == "G#m"then transpo = -11
           elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
      
   

  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch - transpo )
  
 

end
-----------------------------------------------------------------------------------------------------------------------------
--sorts whatever array that is passed to it in descending order (highest to lowest)
function bubbleSort(A)
  local n = #A
  local swapped = false

  repeat
    swapped = false

    for i = 2, n do
  if A[i-1] < A[i] then
    A[i-1] , A[i] = A[i] , A[i-1]
    swapped = true
  end
    end
  until not swapped

  return A
end


--main code
groups = {}
counter = 0
prevTrack = nil
isFirstTrack = true

--loop through and organize items into a multidimensional array
for i = 0, reaper.CountSelectedMediaItems() - 1 do
  local thisItem = reaper.GetSelectedMediaItem(0, i)
  local thisTake = reaper.GetActiveTake(thisItem)

  if thisTake then
    local thisTrack = reaper.GetMediaItem_Track(thisItem)

    if thisTrack == prevTrack then
  if isFirstTrack then table.insert(groups, {takes = {}, pitches = {}}) end
  counter = counter + 1
    else
  if i == 0 then table.insert(groups, {takes = {}, pitches = {}}) else isFirstTrack = false end
  counter = 1
    end

    table.insert(groups[counter].takes, thisTake)
    table.insert(groups[counter].pitches, reaper.GetMediaItemTakeInfo_Value(thisTake, "D_PITCH"))

    prevTrack = thisTrack
  end
end


for i = 1, #groups do
  local tempPitches = groups[i].pitches

  pitchesNum = #tempPitches

  tempPitches = bubbleSort(tempPitches) --sorts all of the pitches so highest is first
  highestPitch = tempPitches[pitchesNum] + 12 --sets the highest pitch as an octave higher than whatever the lowest pitch is

  --loops through all of the pitches to make sure the lowest pitch raised by an octave isn't already in the list of pitches
    --if it is, it will raise the next lowest pitch by an octave and check - repeating this step until it breaks out
  isEqual = false
  nextIndex = pitchesNum

  while true do
    for j = nextIndex-1, 1, -1 do
  if tempPitches[j] == highestPitch then
    isEqual = true
    break
  end
    end

    if isEqual == true then
  nextIndex = nextIndex - 1
  highestPitch = tempPitches[nextIndex] + 12

  isEqual = false
    else
  break
    end

    if nextIndex < 1 then break end --check to break out of the while in case something goes wrong and everything is equal
  end

  tempPitches[pitchesNum] = highestPitch --sets the lowest pitch to whatever the highest pitch became
  tempPitches = bubbleSort(tempPitches) --resorts all of the pitches so highest is first

  --go through and change the pitches in the current grouping
  local tempTakes = groups[i].takes
  for j = 1, #tempTakes do
    reaper.SetMediaItemTakeInfo_Value(tempTakes[j], "D_PITCH", tempPitches[j])
  end
end
------------------------------------------------   key plus transpo  --------------------------------

ItemsSel = {} 

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  source =  reaper.GetMediaItemTake_Source( take )
    
    Idx = i + 1 -- 1-based table in Lua      
    ItemsSel[Idx] = {}
    ItemsSel[Idx].thisItem = item 
    ItemsSel[Idx].position =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    ItemsSel[Idx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    ItemsSel[Idx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    ItemsSel[Idx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH") 
    ItemsSel[Idx].startoffs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")  
    ItemsSel[Idx].source_length = reaper.GetMediaSourceLength( source ) 
 
 
    old_pitch = ItemsSel[Idx].pitch
    old_playrate =  ItemsSel[Idx].playrate
    pos = ItemsSel[Idx].position
     
_, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
           if key == "C" or key == "Am" or key == "" then transpo = 0
          elseif key == "C#" or key == "A#m"then transpo = -1
          elseif key == "Db" or key == "Bbm"then transpo = -1
          elseif key == "D"  or key == "Bm"then transpo = -2
          elseif key == "Eb" or key == "Cm"then transpo = -3
          elseif key == "E"  or key == "C#m"then transpo = -4
          elseif key == "F"  or key == "Dm"then transpo = -5
          elseif key == "F#" or key == "D#m"then transpo = -6
          elseif key == "Gb" or key == "Ebm"then transpo = -6
          elseif key == "G"  or key == "Em"then transpo = -7 
          elseif key == "G#" or key == "E#m"then transpo = -8
          elseif key == "Ab" or key == "Fm"then transpo = -8 
          elseif key == "A"  or key == "F#m"then transpo = -9
          elseif key == "Bb" or key == "Gm"then transpo = -10
          elseif key == "B"  or key == "G#m"then transpo = -11
          elseif key == "Cb" or key == "Abm"then transpo = -11
          if not key then end
          end                
       _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
       
       reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", old_pitch + transpo )
       
end                   
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Swap Pitches Up", -1)


end
------------------------------------------------------------------------------------------------------
---------------------------------------Pitch invers----------------------------------------------------------
------------------------------------------------------------------------------------------------------
--diatonic_inversion_
--script by MusoBob and dragonetti
function pitch_invers_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end
 
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

    items = 0
    items = reaper.CountSelectedMediaItems(0)
    retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    --Msg("items="..items) 
 --   if items == 0 then goto finish end 
    
    for i = 0, items -1 do 
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")+0.005
  
 ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)
 
    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
    take = reaper.GetActiveTake(sel_item)
    if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
  _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
  
      if key == "C" or key == "Am" or key == "" then transpo = 0
     elseif key == "C#" or key == "A#m"then transpo = -1
     elseif key == "Db" or key == "Bbm"then transpo = -1
     elseif key == "D"  or key == "Bm"then transpo = -2
     elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "Dm"then transpo = -5
     elseif key == "F#" or key == "D#m"then transpo = -6
     elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "Em"then transpo = -7 
     elseif key == "G#" or key == "E#m"then transpo = -8
     elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
     if not key then end
     end
  
  get_chord_notes(r)
  
    
  for s = 1, 57 do
  
    if not sel_item then break end
    sel_take = reaper.GetActiveTake(sel_item) 
    item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')          
     
    if item_pitch-note1 == scale[s] then 
      new_pitch = scale[#scale + 1 - s]+note1
   
      reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch)
      reaper.UpdateItemInProject(sel_item)
       
   
      break 
    end
   end 
  end
  end
    end      

::finish::  
end  


main() 

end
  
  

----------------------------------------------------------------------------------------------------
---------------------------------pitch_compressor------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--- over 12 pitch trans -12 ---
---script by dragonetti---

function pitch_comp()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

--- select items with grid length ---




 item_count = reaper.CountSelectedMediaItems(0)
    for i = item_count - 1, 0, -1 do
     --   for i=0, item_count - 1 do
     item = reaper.GetSelectedMediaItem( 0, i )
     take =  reaper.GetActiveTake( item )
     if take == nil then return end
    length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )

  pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )
  tempo = reaper.Master_GetTempo(0)   
  factor = 120 / tempo
   _,grid = reaper.GetSetProjectGrid(0, false)
  grid_length = (grid*2*factor)
  
  
    if pitch > 11 then
     reaper.SetMediaItemTakeInfo_Value( take, "D_PITCH", pitch -12)
     elseif pitch < -11 then
     reaper.SetMediaItemTakeInfo_Value( take, "D_PITCH", pitch +12)
  
end
end


reaper.UpdateArrange()
    
end
    
--=================================================================================================
--========================================= pitch_plus_7 ============================================
--=================================================================================================

function pitch_plus_7()
ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
   
  Idx = i + 1 -- 1-based table in Lua      
  ItemsSel[Idx] = {}  
  ItemsSel[Idx].thisItem = item 
  ItemsSel[Idx].pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )

  pitch =  ItemsSel[Idx].pitch  
 
  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch+7)

end 

reaper.UpdateTimeline()  
reaper.UpdateArrange()
end  

--=================================================================================================
--========================================= pitch_minus_7 ============================================
--=================================================================================================

function pitch_minus_7()
ItemsSel = {}

ItemsSelCount = reaper.CountSelectedMediaItems(0)
for i = 0, ItemsSelCount - 1 do      
  item = reaper.GetSelectedMediaItem(0, i)  
  
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  source =  reaper.GetMediaItemTake_Source( take )
   
  Idx = i + 1 -- 1-based table in Lua      
  ItemsSel[Idx] = {}  
  ItemsSel[Idx].thisItem = item 
  ItemsSel[Idx].pitch =  reaper.GetMediaItemTakeInfo_Value( take, "D_PITCH" )

  pitch =  ItemsSel[Idx].pitch  
 
  reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch-7)

end 

reaper.UpdateTimeline()  
reaper.UpdateArrange()
end      
----------------------------------------------------------------------------------------------------
-------------------------------------pitch rand in scale---------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Display a message in the console for debugging
function pitch_rand()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
 
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end
 
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end
  

  note1 = 0 
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = 7
  elseif root == "G#" then note1 = 8
  elseif root == "Ab" then note1 = 8
  elseif root == "A" then note1 = 9
  elseif root == "A#" then note1 = 10
  elseif root == "Bb" then note1 = 10
  elseif root == "B" then note1 = 11
  if not root then end
  end
  
  Ionian     = {-48,-46,-44,-43,-41,-39,-37,-36,-34,-32,-31,-29,-27,-25,-24,-22,-20,-19,-17,-15,-13,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48}
  Dorian     = {-48,-46,-45,-43,-41,-39,-38,-36,-34,-33,-31,-29,-27,-26,-24,-22,-21,-19,-17,-15,-14,-12,-10,-9,-7,-5,-3,-2,0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48}
  Phrygian   = {-48,-47,-45,-43,-41,-40,-38,-36,-35,-33,-31,-29,-28,-26,-24,-23,-21,-19,-17,-16,-14,-12,-11,-9,-7,-5,-4,-2,0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48}
  Lydian     = {-48,-46,-44,-42,-41,-39,-37,-36,-34,-32,-30,-29,-27,-25,-24,-22,-20,-18,-17,-15,-13,-12,-10,-8,-6,-5,-3,-1,0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48}
  Mixolydian = {-48,-46,-44,-43,-41,-39,-38,-36,-34,-32,-31,-29,-27,-26,-24,-22,-20,-19,-17,-15,-14,-12,-10,-8,-7,-5,-3,-2,0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48}
  Aeolian    = {-48,-46,-45,-43,-41,-40,-38,-36,-34,-33,-31,-29,-28,-26,-24,-22,-21,-19,-17,-16,-14,-12,-10,-9,-7,-5,-4,-2,0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48}
  Locrian    = {-48,-47,-45,-43,-42,-40,-38,-36,-35,-33,-31,-30,-28,-26,-24,-23,-21,-19,-18,-16,-14,-12,-11,-9,-7,-6,-4,-2,0,1,3,5,6,8,10,12,13,15,17,18,21,22,24,25,27,29,30,32,34,36,37,39,41,42,44,46,48}


  if string.find(",Maj7,maj7,Maj7,Maj,M,M7,", ","..chord..",", 1, true) then note2=2  note3=4  note4=5  note5=7  note6=9  note7=11 scale = Ionian end -- Ionian 
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true)              then note2=2  note3=3  note4=5  note5=7  note6=9  note7=10 scale = Dorian end -- Dorian
  if string.find(",m7b9,", ","..chord..",", 1, true)                    then note2=1  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Phrygian end -- Phrygian
  if string.find(",maj7#11,maj#11,", ","..chord..",", 1, true)          then note2=2  note3=4  note4=6  note5=7  note6=9  note7=11 scale = Lydian end -- Lydian
  if string.find(",7,dom,9,13,", ","..chord..",", 1, true)              then note2=2  note3=4  note4=5  note5=7  note6=9  note7=10 scale = Mixolydian end -- Mixolydian
  if string.find(",m,min,", ","..chord..",", 1, true)                   then note2=2  note3=3  note4=5  note5=7  note6=8  note7=10 scale = Aeolian end -- Aeolian
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true)           then note2=1  note3=3  note4=5  note5=6  note6=8  note7=10 scale = Locrian end -- Locrian


end


--MAIN---------------------------------------------------------------
function main()

    items = 0
    items = reaper.CountSelectedMediaItems(0)
    retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    --Msg("items="..items) 
 --   if items == 0 then goto finish end 
    
    for i = 0, items -1 do 
    
  sel_item = reaper.GetSelectedMediaItem( 0, i )
  
  item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION")+0.005
  
 ctrack = getTrackByName("chordtrack")
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
            reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
        else -- track == nil/no track with that name was
     
    num_chords = reaper.CountTrackMediaItems(ctrack)
 
    for r = 0, num_chords -1 do -- regions loop start    
    
           chord_item = reaper.GetTrackMediaItem(ctrack, r )
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
  
    take = reaper.GetActiveTake(sel_item)
  source =  reaper.GetMediaItemTake_Source( take )
  _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
  
      if key == "C" or key == "Am" or key == "" then transpo = 0
     elseif key == "C#" or key == "A#m"then transpo = -1
     elseif key == "Db" or key == "Bbm"then transpo = -1
     elseif key == "D"  or key == "Bm"then transpo = -2
     elseif key == "Eb" or key == "Cm"then transpo = -3
      elseif key == "E" or key == "C#m"then transpo = -4
      elseif key == "F" or key == "Dm"then transpo = -5
     elseif key == "F#" or key == "D#m"then transpo = -6
     elseif key == "Gb" or key == "Ebm"then transpo = -6
      elseif key == "G" or key == "Em"then transpo = -7 
     elseif key == "G#" or key == "E#m"then transpo = -8
     elseif key == "Ab" or key == "Fm"then transpo = -8 
      elseif key == "A" or key == "F#m"then transpo = -9
      elseif key == "Bb" or key == "Gm"then transpo = -10
      elseif key == "B" or key == "G#m"then transpo = -11
      elseif key == "Cb" or key == "Abm"then transpo = -11
     if not key then end
     end
  
  get_chord_notes(r)
    
    for s = 1, 57 do
  if not sel_item then break end
  sel_take = reaper.GetActiveTake(sel_item)
  item_pitch = reaper.GetMediaItemTakeInfo_Value(sel_take, 'D_PITCH')
  source =  reaper.GetMediaItemTake_Source(sel_take )
  
    scale_notes ={-12,-12,0,0,0,-12,note3,note5,-note5,-note5,note3,note5,note2,note4,note6,note7,12,12,12}
    
    rand = scale_notes [math.random(1,#scale_notes)]    
  
    new_pitch = rand + transpo +note1
    reaper.SetMediaItemTakeInfo_Value(sel_take, 'D_PITCH',new_pitch) 
    reaper.UpdateItemInProject(sel_item)
    break
  end
  end
  end
  end
  end
  ::finish::  



  
main() 
--Msg(rand) 
end
---------------------------------------------------------------------------------------------------
 --[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Item; invert select items on its tracks in time selection.lua
   * Author:      Archie
   * Version:     1.03
   * О скрипте:   инвертировать выделенные элементы на своих дорожках во временном выделении  
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   *              http://vk.com/reaarchie
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Dragonetti(cocos Forum) http://forum.cockos.com/showpost.php?p=2303125&postcount=10
   * Gave idea:   Dragonetti(cocos Forum)
   * Extension:   Reaper 6.10+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.02 [140620]
   *                  + fixes bug

   *              v.1.0 [10620]
   *                  + initialе
--]]
    --======================================================================================
    --////////////  НАСТРОЙКИ  \\\\\\\\\\\\  SETTINGS  ////////////  НАСТРОЙКИ  \\\\\\\\\\\\
    --======================================================================================
function select_all_items()
    local MODE = 0;
    -- = 0; Left: count items by end
    -- = 1; Left: count items by position
        -----------------------------
    -- = 0; Слева: подсчет предметов по окончанию
    -- = 1; Слева: подсчет предметов по позициям

    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================


    --=====================================================
    local function no_undo()reaper.defer(function()end)end;
    --=====================================================

    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if timeSelStart==timeSelEnd then no_undo();return end;

    local CountSelItems = reaper.CountSelectedMediaItems(0);
    if CountSelItems == 0 then no_undo();return end;

    local t = {};
    local tbl = {};
    for i = 1, CountSelItems do;
    local itemSel = reaper.GetSelectedMediaItem(0,i-1);
    local pos = reaper.GetMediaItemInfo_Value(itemSel,"D_POSITION");
    local len = reaper.GetMediaItemInfo_Value(itemSel,"D_LENGTH");
    if MODE == 1 then len = 0.000000001 end;
    if pos < timeSelEnd and pos+len > timeSelStart then;
    local track = reaper.GetMediaItem_Track(itemSel);
    if not t[tostring(track)]then;
        t[tostring(track)]=track;
        tbl[#tbl+1] = track;
    end;
    end;
    end;


    if #tbl > 0 then;

    reaper.PreventUIRefresh(9978458);
    reaper.Undo_BeginBlock();

    for i = 1, #tbl do;
    local CountTrackItem = reaper.CountTrackMediaItems(tbl[i]);
    for i2 = 1, CountTrackItem do;
        local item = reaper.GetTrackMediaItem(tbl[i],i2-1);
        local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
        local len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH");
        if MODE == 1 then len = 0.000000001 end;
        if pos < timeSelEnd and pos+len > timeSelStart then;
        local sel = reaper.GetMediaItemInfo_Value(item,"B_UISEL");
        reaper.SetMediaItemInfo_Value(item,"B_UISEL",1);
        elseif pos > timeSelEnd then;
        break;
        end;
    end;
    end;

    reaper.PreventUIRefresh(-9978458);
    reaper.Undo_EndBlock('invert select items on its tracks in time selection',-1);
    reaper.UpdateArrange();
    end;
end;



----------------------------------------------------------------------------------------------------
-------------------------------SELECT_10-------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function select_10_x(hallo)
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


math.randomseed(os.time())

sequenzen = {hallo}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='s' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end


----------------------------------------------------------------------------------------------------
------------------------Select_1000-----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function select_1000_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


sequenzen = {"suuu"}   
seq = sequenzen[math.random(1,#sequenzen)]   


item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end



parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='s' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
 
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid])
 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end
----------------------------------------------------------------------------------------------------
-----------------------------------SELECT_100----------------------------------------------
----------------------------------------------------------------------------------------------------
function select_100_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end




sequenzen = {"suu"}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='s' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end
--==========================================================================
--===================== SELECT only unmuted items =========================
--============================================================================

-- @description Select only unmuted items from selected items
-- @author Dragonetti
-- @version 1.0
function select_unmuted()
  CountSelItem = reaper.CountSelectedMediaItems(0)
 if CountSelItem == 0 then  return end

  for i = CountSelItem-1,0,-1 do
    local SelItem = reaper.GetSelectedMediaItem(0,i)
    
if reaper.GetMediaItemInfo_Value(SelItem,"B_MUTE")==1
then reaper.SetMediaItemInfo_Value(SelItem,"B_UISEL",0)
      
end     
  end


reaper.UpdateArrange()
end
--=========================================================================================================
--===================== SELECT_ONLY_ON_GRID ========================================================
--=========================================================================================================
function select_only_on_grid()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end


 item_count = reaper.CountSelectedMediaItems(0)
     for i = item_count - 1, 0, -1 do
  --   for i=0, item_count - 1 do
  item = reaper.GetSelectedMediaItem( 0, i )
     
 
 start =  reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  starty  =     math.floor(start)
      y = string.sub(starty,1,6)
  
    closest_grid = reaper.BR_GetClosestGridDivision( start )
    
 
     mult = 10^(3)
    hallo =math.floor(closest_grid * mult + 0.5) / mult
    starty =math.floor(start * mult + 0.5) / mult
 
   
 
    
    if starty ~= hallo then
 
     reaper.SetMediaItemInfo_Value( item, "B_UISEL", 0 )
   
 end
 end
 
 reaper.UpdateArrange()
    
end
--=================================================================================================================
--============================= SELECT_ROOT_NOTE ==================================================================
--=================================================================================================================
-- Display a message in the console for debugging
function select_root_note()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end



  
function get_chord_notes(r)  

   item0 =  reaper.GetTrackMediaItem(ctrack,r )
      _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
      
    if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
     if string.find(item_notes, "/") then
        root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
     else
        root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
     end
       
       if not chord or #chord == 0 then chord = "Maj" end
       if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D" then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E" then note1 = 4
  elseif root == "F" then note1 = 5
  elseif root == "F#" then note1 = 6
  elseif root == "Gb" then note1 = 6
  elseif root == "G" then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A" then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B" then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 255
  note6 = 255
  note7 = 255

  if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
  if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
  if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
  if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
  if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
  if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
  if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
  if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
  if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
  if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
  if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
  if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
  if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
  if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
  if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
  if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
  if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
  if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
  if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
  if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
  if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
  if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
  if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
  if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
  if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
  if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
  if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
  if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
  if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
  if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
  if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
  if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
  if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
  if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
  if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
  if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
  if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
  if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
  if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
  if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
  if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
  if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
  if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
  if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
  if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
  if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
  if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
  if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
  if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
  if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
  if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
  if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
  if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
  if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
  if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
  if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
  if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
  if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
  if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
  if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
  if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
  if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
  if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
  if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
  if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
  if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
  if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
  if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
  if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
  if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
  if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
  if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
  if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
  if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
  if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
  if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
  if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
  if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
  if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
  if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
  if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
  if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
  if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
  if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
  if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
  if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
  if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
  if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
  if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
  if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
  if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
  if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
  if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
  if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
  if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
  if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
  if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
  if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
  if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
  if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
  if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
  if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
  if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
  if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
  if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
  if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
  if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
  if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
  if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
  if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
  if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
  if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
  if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
  if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
  if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
  if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
  if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
  if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
  if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
  if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
  if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
  if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
  if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
  if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
  if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
  if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
  if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
  if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
  if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
  if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
  if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
  if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
  if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
  if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
  if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
  if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
  if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
  if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
  if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
  if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
  if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
  if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
  if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
  if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
  if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
  if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
  if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
  if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
  if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
  if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
  if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
  if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
  if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
  if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
  if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
  if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
  if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
  if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
  if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
  if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
  if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
  if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
  if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
  if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
  if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
  if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
  if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
  if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
  if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end
  

end



--MAIN---------------------------------------------------------------
function main()

  commandID2 = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
  reaper.Main_OnCommand(commandID2, 0) -- SWS: Select only track(s) with selected item(s) _SWS_SELTRKWITEM

  items = reaper.CountMediaItems(0)
  
  sel_tracks = reaper.CountSelectedTracks(0) 
  
 ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end

    for r = 0, num_chords -1 do -- regions loop start    
    
  chord_item = reaper.GetTrackMediaItem(ctrack, r )
                        pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                     length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                     rgnend = pos+length  
  
  for x = 0, items -1 do -- items loop start
   
   media_item = reaper.GetMediaItem( 0, x )
   
   selected_item = reaper.IsMediaItemSelected(media_item) 
   
   if selected_item then
    
    current_item = reaper.GetMediaItem( 0, x )
  
    item_start = (reaper.GetMediaItemInfo_Value( current_item, "D_POSITION"))+0.1
    
    --Does item start within region
    
    if item_start  >= pos and item_start < rgnend then 
      --Msg("r "..r) 
      --Msg("markrgnindexnumber ".. markrgnindexnumber)
     get_chord_notes(r) -- get the chord notes for current region
      

      
      
     
     take = reaper.GetActiveTake(current_item)
     if take == nil then return end
        source =  reaper.GetMediaItemTake_Source( take )
        _, key = reaper.GetMediaFileMetadata(source, "XMP:dm/key" ) -- consideration of the original key Metadata from wav file "Key" 
        
            if key == "C" or key == "c" or key == "Am" or key == "" then transpo = 0
                   elseif key == "C#" or key == "A#m"then transpo = -1
                   elseif key == "Db" or key == "Bbm"then transpo = -1
                   elseif key == "D"  or key == "d"  or key == "Bm"then transpo = -2
                   elseif key == "Eb" or key == "Cm"then transpo = -3
                    elseif key == "E" or key == "e" or key == "C#m"then transpo = -4 
                    elseif key == "F" or key == "f" or key == "Dm"then transpo = -5
                   elseif key == "F#" or key == "D#m"then transpo = -6
                   elseif key == "Gb" or key == "Ebm"then transpo = -6
                    elseif key == "G" or key == "g" or key == "Em"then transpo = -7 
                   elseif key == "G#" or key == "E#m"then transpo = -8
                   elseif key == "Ab" or key == "Fm"then transpo = -8 
                    elseif key == "A" or key == "a" or key == "F#m"then transpo = -9
                    elseif key == "Bb" or key == "Gm"then transpo = -10
                    elseif key == "B" or key == "b" or key == "G#m"then transpo = -11
                    elseif key == "Cb" or key == "Abm"then transpo = -11
                   if not key then end
                   end         
       
       
     old_pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
     root_note = old_pitch - transpo - note1
     if root_note ~=0  and root_note ~=12 then  reaper.SetMediaItemInfo_Value( current_item, "B_UISEL", 0 )
      --   elseif root_note ~=-12 then reaper.SetMediaItemInfo_Value( current_item, "B_UISEL", 0 ) 
     
    reaper.UpdateItemInProject(current_item)
      end
    --  if root_note ~= 0  then  reaper.SetMediaItemInfo_Value( current_item, "B_UISEL", 0 )
     
      end          
     
      end       
        
    end
   end
   
  end -- items loop end
   -- regions loop end
  
 
  
 

  
main()  
  
reaper.Main_OnCommand(40297,0)   


::skip:: 
  

--Msg(root_note)

end
--=================================================================================================================
--====================== pattern select ===========================================================================
--=================================================================================================================

--thanks mpl
function pattern_select()

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("no selected items")return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

retval, seq1 = reaper.GetUserInputs( "pattern select", 1,"1=select 0=unselect", "01" )
if not retval then return end

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end



parsed_t = {}

for char in seq1:gmatch('%d') do 
  local val = 0

  if char=='1' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
 
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid])
 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_UISEL",parsed_t[index])

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end
--=================================================================================================================
--===================== INVERT_SELECTION_IN TIME SELECTION ========================================================
--=================================================================================================================
 --[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Item; invert select items on its tracks in time selection.lua
   * Author:      Archie
   * Version:     1.03
   * О скрипте:   инвертировать выделенные элементы на своих дорожках во временном выделении  
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   *              http://vk.com/reaarchie
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Dragonetti(cocos Forum) http://forum.cockos.com/showpost.php?p=2303125&postcount=10
   * Gave idea:   Dragonetti(cocos Forum)
   * Extension:   Reaper 6.10+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.02 [140620]
   *                  + fixes bug

   *              v.1.0 [10620]
   *                  + initialе
--]]
    --======================================================================================
    --////////////  НАСТРОЙКИ  \\\\\\\\\\\\  SETTINGS  ////////////  НАСТРОЙКИ  \\\\\\\\\\\\
    --======================================================================================
function invert_item_selection()
    local MODE = 0;
    -- = 0; Left: count items by end
    -- = 1; Left: count items by position
        -----------------------------
    -- = 0; Слева: подсчет предметов по окончанию
    -- = 1; Слева: подсчет предметов по позициям

    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================


    --=====================================================
    local function no_undo()reaper.defer(function()end)end;
    --=====================================================

    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
    if timeSelStart==timeSelEnd then no_undo();return end;

    local CountSelItems = reaper.CountSelectedMediaItems(0);
    if CountSelItems == 0 then no_undo();return end;

    local t = {};
    local tbl = {};
    for i = 1, CountSelItems do;
    local itemSel = reaper.GetSelectedMediaItem(0,i-1);
    local pos = reaper.GetMediaItemInfo_Value(itemSel,"D_POSITION");
    local len = reaper.GetMediaItemInfo_Value(itemSel,"D_LENGTH");
    if MODE == 1 then len = 0.000000001 end;
    if pos < timeSelEnd and pos+len > timeSelStart then;
    local track = reaper.GetMediaItem_Track(itemSel);
    if not t[tostring(track)]then;
        t[tostring(track)]=track;
        tbl[#tbl+1] = track;
    end;
    end;
    end;


    if #tbl > 0 then;

    reaper.PreventUIRefresh(9978458);
    reaper.Undo_BeginBlock();

    for i = 1, #tbl do;
    local CountTrackItem = reaper.CountTrackMediaItems(tbl[i]);
    for i2 = 1, CountTrackItem do;
        local item = reaper.GetTrackMediaItem(tbl[i],i2-1);
        local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
        local len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH");
        if MODE == 1 then len = 0.000000001 end;
        if pos < timeSelEnd and pos+len > timeSelStart then;
        local sel = reaper.GetMediaItemInfo_Value(item,"B_UISEL");
        reaper.SetMediaItemInfo_Value(item,"B_UISEL",math.abs(sel-1));
        elseif pos > timeSelEnd then;
        break;
        end;
    end;
    end;

    reaper.PreventUIRefresh(-9978458);
    reaper.Undo_EndBlock('invert select items on its tracks in time selection',-1);
    reaper.UpdateArrange();
    end;

end;

--=================================================================================================================
--===================== SELECT_PREV_ITEM ========================================================
--=================================================================================================================
--[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Select Previous item in track
   * Author:      Archie
   * Version:     1.02
   * Описание:    Выберите предыдущий элемент в треке
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Archie(Rmm)
   * Gave idea:   borisuperful(Rmm)
   * Extension:   Reaper 6.03+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.0 [07.02.20]
   *                  + initialе
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================

function select_prev_item()


    ------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    local CountSelitem = reaper.CountSelectedMediaItems(0);
    if CountSelitem == 0 then no_undo() return end;


    local CountTrack = reaper.CountTracks(0);
    if CountTrack == 0 then no_undo() return end;

    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);

    for i = 1,CountTrack do;
    local track = reaper.GetTrack(0,i-1);

    ---
    local CountTrItem = reaper.CountTrackMediaItems(track);
    local sel2,item2;
    for i = 1,CountTrItem do;

    local item = reaper.GetTrackMediaItem(track,i-1);
    local take = reaper.GetActiveTake(item);

    local sel = reaper.GetMediaItemInfo_Value(item,'B_UISEL');

    if sel == 1 and sel2 == 0 then;
    reaper.SetMediaItemInfo_Value(item2,'B_UISEL',1);
    reaper.SetMediaItemInfo_Value(item,'B_UISEL',0);
  sel = 0;
    end;
    sel2 = sel;
    item2 = item;
    end;
    ---
    end;

    reaper.PreventUIRefresh(1);
    reaper.Undo_EndBlock('Select Previous item in track',-1);

    reaper.UpdateArrange();

end;

--=================================================================================================================
--===================== SELECT_NEXT_ITEM ========================================================
--=================================================================================================================
--[[
   * Тест только на windows  /  Test only on windows.
   * Отчет об ошибке: Если обнаружите какие либо ошибки, то сообщите по одной из указанных ссылок ниже (*Website)
   * Bug Reports: If you find any errors, please report one of the links below (*Website)
   *
   * Category:    Item
   * Description: Select Next item in track
   * Author:      Archie
   * Version:     1.02
   * Описание:    Выберите следующий пункт в треке
   * Website:     http://forum.cockos.com/showthread.php?t=212819
   *              http://rmmedia.ru/threads/134701/
   * DONATION:    http://money.yandex.ru/to/410018003906628
   * DONATION:    http://paypal.me/ReaArchie?locale.x=ru_RU
   * Customer:    Archie(Rmm)
   * Gave idea:   borisuperful(Rmm)
   * Extension:   Reaper 6.03+ http://www.reaper.fm/
   *              SWS v.2.10.0 http://www.sws-extension.org/index.php
   * Changelog:
   *              v.1.0 [07.02.20]
   *                  + initialе
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================

function select_next_item()



    ------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------


    local CountSelitem = reaper.CountSelectedMediaItems(0);
    if CountSelitem == 0 then no_undo() return end;


    local CountTrack = reaper.CountTracks(0);
    if CountTrack == 0 then no_undo() return end;

    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);

    for i = 1,CountTrack do;
    local track = reaper.GetTrack(0,i-1);

    ---
    local CountTrItem = reaper.CountTrackMediaItems(track);
    local sel2,item2;
    for i = CountTrItem-1,0,-1 do;

    local item = reaper.GetTrackMediaItem(track,i);
    local take = reaper.GetActiveTake(item);

    local sel = reaper.GetMediaItemInfo_Value(item,'B_UISEL');

    if sel == 1 and sel2 == 0 then;
        reaper.SetMediaItemInfo_Value(item2,'B_UISEL',1);
        reaper.SetMediaItemInfo_Value(item,'B_UISEL',0);
        sel = 0;
    end;
    sel2 = sel;
    item2 = item;
    end;
    ---
    end;

    reaper.PreventUIRefresh(1);
    reaper.Undo_EndBlock('Select Next item in track',-1);

    reaper.UpdateArrange();

end;

--====================================================================================================
--============================== SELECT_CHORD =======================================================
--====================================================================================================
function select_chord()

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end

 
    --Does item start within region 
    ctrack = getTrackByName("chordtrack")
    
    if ctrack==nil then -- if a track named "chordtrack" was found/that track doesn't equal nil
    reaper.ShowMessageBox("There is no track with name: chordtrack" ,"Error: Name Not Found", 0) do return end
     
    else -- track == nil/no track with that name was
      num_chords = reaper.CountTrackMediaItems(ctrack)
      
    end
   


--Archie
--]]
    --======================================================================================
    --////////////// SCRIPT \\\\\\\\\\\\\\  SCRIPT  //////////////  SCRIPT  \\\\\\\\\\\\\\\\
    --======================================================================================

  --  function select_region()

    local CountSelItem = reaper.CountSelectedMediaItems(0);
    if CountSelItem == 0 then  return end;


    cursor_pos = reaper.GetCursorPosition()
 --   _, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cursor_pos )
 --   retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( regionidx )

      for r = 0, num_chords -1 do -- regions loop start 
               
               chord_item = reaper.GetTrackMediaItem(ctrack, r )
                      xpos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                   length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                   xrgnend = xpos+length  
 
    if cursor_pos  >= xpos and cursor_pos < xrgnend then 
     pos = xpos
     rgnend = xrgnend

        

end
end


    for i = CountSelItem-1,0,-1 do;

        local SelItem = reaper.GetSelectedMediaItem(0,i);
        local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION")+0.05;
        local LenIt = reaper.GetMediaItemInfo_Value(SelItem,"D_LENGTH");
        local EndIt = PosIt + (LenIt-0.1);

        if PosIt < rgnend and EndIt > pos then;


            if PosIt < rgnend and EndIt > rgnend then;
                local Right = reaper.SplitMediaItem(SelItem,rgnend);
                if Right then
                    reaper.SetMediaItemInfo_Value( Right, "B_UISEL", 0 );
                end
            end

            if PosIt < pos and EndIt > pos then;
                local Left = reaper.SplitMediaItem(SelItem,pos);
                if Left then
                    reaper.SetMediaItemInfo_Value( Left, "B_UISEL", 0 );
                end
            end;
        else;
         
            reaper.SetMediaItemInfo_Value( SelItem, "B_UISEL", 0 );
        end;
    end;


 
    reaper.UpdateArrange();


end

----------------------------------------------------------------------------------------------------
---------------------------------SELECT_HIGH_PITCH-----------------------------------------------------------
----------------------------------------------------------------------------------------------------
function select_high_pitch_x()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local items, winner = {}

reaper.Undo_BeginBlock()

for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
  local item = reaper.GetSelectedMediaItem(nil, i)
  local take = reaper.GetActiveTake(item) 
  local pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
  if not winner or pitch > winner.pitch then
    winner = { item=item, pitch=pitch }
  end
  table.insert(items, item)
end

for _, item in ipairs(items) do   
  if item ~= winner.item then
    reaper.SetMediaItemSelected(item, false)
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock(script_name, 0)
end

--========================================================================================================
--======================= Volume Sequence ================================================================
--========================================================================================================


function volume_sequence()
local retval, input_str = reaper.GetUserInputs("item volume sequenz",1, "1=0db  2=-0.2db 3=-0.4db " , "12")
if not retval then return end

-- Extrahiere Längen und Akzente aus dem Benutzereingabestring 
local length_str = input_str


-- Konvertiere Längen- und Akzent-Strings in Tabellen
local sequence = {}
for i = 1, #length_str do
  sequence[i] = tonumber(length_str:sub(i, i))
end
selected_tracks = {}
num_selected_items = reaper.CountSelectedMediaItems(0)
for i = 0, num_selected_items - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    track = reaper.GetMediaItem_Track(item)
    selected_tracks[track] = true
end

-- Selektiere alle Tracks, die im Set enthalten sind
num_tracks = reaper.CountTracks(0)
for i = 0, num_tracks - 1 do
    track = reaper.GetTrack(0, i)
    if selected_tracks[track] then
        reaper.SetTrackSelected(track, true)
    else
        reaper.SetTrackSelected(track, false)
    end
end

selected_tracks = {}
num_selected_items = reaper.CountSelectedMediaItems(0)
for i = 0, num_selected_items - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    track = reaper.GetMediaItem_Track(item)
    selected_tracks[track] = true
end

-- Define the sequence


-- Process each selected track
for track in pairs(selected_tracks) do
    count = 0
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        item = reaper.GetTrackMediaItem(track, i)
        if reaper.IsMediaItemSelected(item) then
            count = count + 1
            sequence_index = (count - 1) % #sequence + 1 -- Get the current sequence index
            if sequence[sequence_index] == 3 then -- Reduce volume
                new_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL") - 0.4
                reaper.SetMediaItemInfo_Value(item, "D_VOL", new_vol)
            elseif  sequence[sequence_index] == 2 then -- Reduce volume  
                new_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL") - 0.2
                reaper.SetMediaItemInfo_Value(item, "D_VOL", new_vol)
            elseif sequence[sequence_index] == 1 then -- Do nothing
                -- Do nothing
            end
        end
    end
end

reaper.UpdateArrange()
end
--=================================================================================================================
--====================== VOLUME ===========================================================================
--=================================================================================================================
function volume_curve(divider,phase,amplitude)

select_tracks = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(select_tracks,0)
track_count = reaper.CountSelectedTracks( 0 )
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)



xx=math.floor(ItemsSelCount/track_count)


ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then Msg("no selected items")return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end



--divider=400
--phase=1
--amplitude=8

parsed_t = {}
for e = 1, xx do
parsed_t[e] = (amplitude*0.1*math.cos((divider*0.1*((math.pi*e)+(phase*0.1*xx)))/(xx/7))+1)--+ (1*math.cos((0.5*math.pi*e)/(1))+0.5)

end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
 
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "D_VOL",parsed_t[ptid])
 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "D_VOL",parsed_t[index])

  index = index + 1
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

end
----------------------------------------------------------------------------------------------------
-----------------------------UNMUTE-----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function unmute()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


math.randomseed(os.time())

sequenzen = {"s"}   
seq = sequenzen[math.random(1,#sequenzen)]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, reaper.CountSelectedMediaItems(0) do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do 
  local val = 0

  if char=='u' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end

for i = 1, itemCount - 1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",parsed_t[ptid]) 
  end
end


local lastTrack, index
for i = 1, otherCount - 1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end
----------------------------------------------------------------------------------------------------
-------------------------MUTE_RANDOM--------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function mute_random(v,zufall)
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)




math.randomseed(os.time())
if v == 0 then 
sequenzen = {"u","um","umm","ummmm","ummmmmm","ummmmmmmm","ummmmmmmmm","ummmmmmmmmm"}
elseif v == 1 then
sequenzen = {"muuuuuuuuuuuuuuu","umuuuuuuuuuuuuuu","uumuuuuuuuuuuuuu","uuumuuuuuuuuuuuu","uuuumuuuuuuuuuuu","uuuuumuuuuuuuuuu","uuuuuumuuuuuuuuu","uuuuuuumuuuuuuuu"} 
elseif v == 2 then
sequenzen = {"mmuuuuuuuuuuuuuu","ummuuuuuuuuuuuuu","uummuuuuuuuuuuuu","uuummuuuuuuuuuuu","uuuummuuuuuuuuuu","uuuuummuuuuuuuuu","uuuuuummuuuuuuuu","uuuuuuummuuuuuuu"} 
elseif v == 3 then
sequenzen = {"mmmuuuuuuuuuuuuu","ummmuuuuuuuuuuuu","uummmuuuuuuuuuuu","uuummmuuuuuuuuuu","uuuummmuuuuuuuuu","uuuuummmuuuuuuuu","uuuuuummmuuuuuuu","uuuuuuummmuuuuuu"} 
elseif v == 4 then
sequenzen = {"mmmmuuuuuuuuuuuu","ummmmuuuuuuuuuuu","uummmmuuuuuuuuuu","uuummmmuuuuuuuuu","uuuummmmuuuuuuuu","uuuuummmmuuuuuuu","uuuuuummmmuuuuuu","uuuuuuummmmuuuuu"} 
elseif v == 5 then
sequenzen = {"mmmmmuuuuuuuuuuu","ummmmmuuuuuuuuuu","uummmmmuuuuuuuuu","uuummmmmuuuuuuuu","uuuummmmmuuuuuuu","uuuuummmmmuuuuuu","uuuuuummmmmuuuuu","uuuuuuummmmmuuuu"} 
elseif v == 6 then
sequenzen = {"mmmmmmuuuuuuuuuu","ummmmmmuuuuuuuuu","uummmmmmuuuuuuuu","uuummmmmmuuuuuuu","uuuummmmmmuuuuuu","uuuuummmmmmuuuuu","uuuuuummmmmmuuuu","uuuuuuummmmmmuuu"} 
elseif v == 7 then
sequenzen = {"mmmmmmmuuuuuuuuu","ummmmmmmuuuuuuuu","uummmmmmmuuuuuuu","uuummmmmmmuuuuuu","uuuummmmmmmuuuuu","uuuuummmmmmmuuuu","uuuuuummmmmmmuuu","uuuuuuummmmmmmuu"} 
elseif v == 8 then
sequenzen = {"mmmmmmmmuuuuuuuu","ummmmmmmmuuuuuuu","uummmmmmmmuuuuuu","uuummmmmmmmuuuuu","uuuummmmmmmmuuuu","uuuuummmmmmmmuuu","uuuuuummmmmmmmuu","uuuuuuummmmmmmmu"} 
elseif v == 9 then
sequenzen = {"mmmmmmmmmuuuuuuu","ummmmmmmmmuuuuuu","uummmmmmmmmuuuuu","uuummmmmmmmmuuuu","uuuummmmmmmmmuuu","uuuuummmmmmmmmuu","uuuuuummmmmmmmmu","uuuuuuummmmmmmmm"} 
elseif v == 10 then
sequenzen = {"mmmmmmmmmmuuuuuu","ummmmmmmmmmuuuuu","uummmmmmmmmmuuuu","uuummmmmmmmmmuuu","uuuummmmmmmmmmuu","uuuuummmmmmmmmmu","uuuuuummmmmmmmmm","uuuuuummmmmmmmmm"} 
elseif v == 11 then
sequenzen = {"mmmmmmmmmmmuuuuu","ummmmmmmmmmmuuuu","uummmmmmmmmmmuuu","uuummmmmmmmmmmuu","uuuummmmmmmmmmmu","uuuuummmmmmmmmmm","muuuuummmmmmmmmm","mmuuuuummmmmmmmm"} 
elseif v == 12 then
sequenzen = {"mmmmmmmmmmmmuuuu","ummmmmmmmmmmmuuu","uummmmmmmmmmmmuu","uuummmmmmmmmmmmu","uuuummmmmmmmmmmm","uuuummmmmmmmmmmm","uuuummmmmmmmmmmm","uuuummmmmmmmmmmm"} 
elseif v == 13 then
sequenzen = {"mmmmmmmmmmmmmuuu","ummmmmmmmmmmmmuu","uummmmmmmmmmmmmu","uuummmmmmmmmmmmm","uuummmmmmmmmmmmm","uuummmmmmmmmmmmm","uuummmmmmmmmmmmm","uuummmmmmmmmmmmm"} 
elseif v == 14 then
sequenzen = {"mmmmmmmmmmmmmmuu","ummmmmmmmmmmmmmu","uummmmmmmmmmmmmm","muummmmmmmmmmmmm","mmuummmmmmmmmmmm","mmmuummmmmmmmmmm","mmmmuummmmmmmmmm","mmmmmuummmmmmmmm"} 
elseif v == 15 then
sequenzen = {"mmmmmmmmmmmmmmmu","ummmmmmmmmmmmmmm","mummmmmmmmmmmmmm","mmummmmmmmmmmmmm","mmmummmmmmmmmmmm","mmmmummmmmmmmmmm","mmmmmummmmmmmmmm","mmmmmmummmmmmmmm"} 
elseif v == 16 then
sequenzen = {"muuuuuuu","umuuuuuu","uumuuuuu","uuumuuuu","uuuumuuu","uuuuumuu","uuuuuumu","uuuuuuum"}
elseif v == 17 then
sequenzen = {"mmuuuuuu","ummuuuuu","uummuuuu","uuummuuu","uuuummuu","uuuuummu","uuuuuumm","uuuuuumm"}
elseif v == 18 then 
sequenzen = {"mmmuuuuu","ummmuuuu","uummmuuu","uuummmuu","uuuummmu","uuuuummm","muuuuumm","mmuuuuum"}
elseif v == 19 then
sequenzen = {"mmmmuuuu","ummmmuuu","uummmmuu","uuummmmu","uuuummmm","muuuummm","mmuuuumm","mmmuuuum"}
elseif v == 20 then
sequenzen = {"mmmmmuuu","ummmmmuu","uummmmmu","uuummmmm","muuummmm","mmuuummm","mmmuuumm","mmmmuuum"}
elseif v == 21 then
sequenzen = {"mmmmmmuu","ummmmmmu","uummmmmm","muummmmm","mmuummmm","mmmuummm","mmmmuumm","mmmmmuum"}
elseif v == 22 then
sequenzen = {"mmmmmmmu","ummmmmmm","mummmmmm","mmummmmm","mmmummmm","mmmmummm","mmmmmumm","mmmmmmum"}
elseif v == 23 then
sequenzen = {"uuum","muuu","umuu","mmuuummm","mmmuuumm","mmumuumm","muuummmu","mmuuummm"}
elseif v == 24 then
sequenzen = {"uumm","muum","mmuu","ummu","mmumummm","mmummumm","mummmmum","ummmmmmu"}
elseif v == 25 then
sequenzen = {"mmum","mmmu","ummm","mumm","mmmmummu","mummummm","mummmmmu","umummmmm"}
elseif v == 26 then
sequenzen = {"ummmmmmmmmmmummu","mumumuuu","ummummumumumumum","ummummummummumum","muumuumuumummumm","ummummmmummummmm","ummummum","mmuummuummummumm"}

 end
--if zufall==nil then zufall = 1 end 
seq = sequenzen[zufall+1]   

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, (reaper.CountSelectedMediaItems(0)),1 do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do  
  local val = 0

  if char=='m' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end
--if zufall ~= nil then
--teiler = itemCount/zufall end

wert = tonumber(zufall)
for i = 1, (itemCount - 1),1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",parsed_t[ptid]) 
  end
end

 
local lastTrack, index
for i = 1, (otherCount - 1),1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end
--==========================================================================================
--======================== mute_exact ==========================================================
--============================================================================================

function mute_exact()

--if sub==16 then a=118 
--else a=117 end

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

select_tracks = reaper.NamedCommandLookup("_SWS_SELTRKWITEM")
reaper.Main_OnCommand(select_tracks,0)
track_count = reaper.CountSelectedTracks( 0 )
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
reaper.PreventUIRefresh(1)



xx=math.floor(ItemsSelCount/track_count)





if ran==false  then
astr="uuuuuuuuuuuuuuuuuuvvvvvvvvuvuv"
local res = ""
  for i = 1, (ItemsSelCount/track_count/teiler) do
    res = res .. string.char(math.random(117, 118))
  end

xastr = string.gsub(astr, "u", res, 100) 

astr = xastr



else

ran = true

if teiler > xx then teiler = 1 end
res = string.rep("v",math.ceil(math.floor(xx/teiler)))
str = string.gsub(res, "v", "u", dinger)
um = string.rep(str,teiler)
--str = string.gsub(res, "u", "v", dinger)
--xstr = string.rep(str,teiler*2)
if sub > xx-1 then sub=1 end

astr = string.sub(um, sub)


 end


seq = astr 

item_ptrs = {}
itemCount = 1
other_items = {}
otherCount = 1

mainTrack = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0))

for selitem = 1, (reaper.CountSelectedMediaItems(0)),1 do
  local thisItem = reaper.GetSelectedMediaItem(0 , selitem - 1)
  local thisTrack = reaper.GetMediaItem_Track(thisItem)

  if thisTrack == mainTrack then
    item_ptrs[itemCount] =  thisItem
    itemCount = itemCount + 1
  
  else
    other_items[otherCount] = {
  item = thisItem,
  track = thisTrack,
    }

    otherCount = otherCount + 1
  end
end


parsed_t = {}

for char in seq:gmatch('%a') do  
  local val = 0

  if char=='v' then val = 1 end 

  parsed_t[#parsed_t+1] = val 
end
--if zufall ~= nil then
--teiler = itemCount/zufall end

--wert = tonumber(zufall)
for i = 1, (itemCount - 1),1 do 
  local ptid = (1+ (i-1)%#parsed_t)

  if parsed_t[ptid] then
    reaper.SetMediaItemInfo_Value(item_ptrs[i], "B_MUTE",parsed_t[ptid]) 
  end
end

 
local lastTrack, index
for i = 1, (otherCount - 1),1 do
  if not lastTrack or lastTrack ~= other_items[i].track then
    index = 1
    lastTrack = other_items[i].track
  elseif not parsed_t[index] then
    index = 1
  end


  reaper.SetMediaItemInfo_Value(other_items[i].item, "B_MUTE",parsed_t[index])

  index = index + 1
end


reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
end

----------------------------------------------------------------------------------------------------
-------------------------INVERT_SELECTED------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- invert selection item in time selection
function invert_selection()    
    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0)
    if timeSelStart~=timeSelEnd then
    
    local CountItems = reaper.CountMediaItems(0)
    if CountItems > 0 then;
    for i = 1, CountItems do;
        local track = reaper.GetSelectedTrack(0,0)
        local CountTrItems = reaper.CountTrackMediaItems(track)
        local selc_item = reaper.GetSelectedMediaItem( 0, i-1 )
        local item = reaper.GetMediaItem(0,i-1)
        local pos = reaper.GetMediaItemInfo_Value(CountTrItems,"D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(selc_item,"D_LENGTH")
        if pos < timeSelEnd and pos+len > timeSelStart then
        reaper.SetMediaItemInfo_Value(item,"B_UISEL",math.abs(reaper.GetMediaItemInfo_Value(selc_item,"B_UISEL")-1))
        end;
    end;
    end;
    end;
    
    reaper.UpdateArrange();
end
--======================================================================================================================================
--============================================ SHUFFLE_ORDER =============================================================================
--==========================================================================================================================================
--[[
 * ReaScript Name: Shuffle order of selected items columns keeping snap offset positions and parent tracks
 * About: This works nicely only if there is as many items selected on each track, as it works on item selected ID on track and not "visual" columns
 * Author: X-Raym
 * Author URI: https://www.extremraym.com
 * Repository: GitHub > X-Raym > REAPER-ReaScripts
 * Repository URI: https://github.com/X-Raym/REAPER-ReaScripts
 * Licence: GPL v3
 * Forum Thread: Script (Lua): Shuffle Items
 * Forum Thread URI: http://forum.cockos.com/showthread.php?t=159961
 * REAPER: 5.0
 * Version: 2.0
--]]

--[[
 * Changelog:
 * v2.0 (2021-01-07)
  + new core
  # remove group support
 * v1.1 (2016-01-07)
  + Preserve grouping if groups active. Treat first selected item (in position) in each group as group leader (other are ignored during the alignement).
 * v1.0 (2015-06-09)
  + Initial Release
--]]

-------------------------------------------------------------
function shuffle_order()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-------------------------------------------------------------

-- SHUFFLE TABLE FUNCTION
-- https://gist.github.com/Uradamus/10323382
function shuffle(t)
  local tbl = {}
  for i = 1, #t do
    tbl[i] = t[i]
  end
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  if do_tables_match( t, tbl ) then -- MOD: be sure tables are different
    --tbl = shuffle(t)
  end
  return tbl
end

function do_tables_match( a, b )
  return table.concat(a) == table.concat(b)
end


-------------------------------------------------------------
function Main()

  -- Get Columns of Selected Items
  columns = {} -- Original minimum positions and list of items for each columns
  positions = {} -- Minimum positions of items snap for each columns
  local column = 0

  for i = 0, count_sel_items - 1 do

    local item = reaper.GetSelectedMediaItem(0,i)
    local track = reaper.GetMediaItemTrack( item )
    local track_id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")

    if track_id ~= last_track_id then column = 0 end -- reset column counter
    column = column + 1 -- increment column

    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_snap = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    local item_possnap = item_pos + item_snap

    if not columns[column] then
      columns[column] = {min_possnap = item_possnap, items = {} }
    else
      columns[column].min_possnap = math.min( columns[column].min_possnap, item_possnap )
    end
    positions[column] = columns[column].min_possnap
    table.insert(columns[column].items, item)

    last_track_id = track_id

  end

  if #columns > 1 then --  No need if there is only one column
    positions = shuffle( positions )

    for i, column in ipairs( columns ) do
      offset = positions[i] - column.min_possnap
      for j, item in ipairs( column.items ) do
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_pos + offset)
      end
    end

  end

end

-- INIT -----------------------------------------------------

count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 1 then

  reaper.PreventUIRefresh(1)

  reaper.Undo_BeginBlock()

  Main()

  reaper.Undo_EndBlock("Shuffle order of selected items columns keeping snap offset positions and parent tracks", -1)

  reaper.PreventUIRefresh(-1)

  reaper.UpdateArrange()

end


-- Xenakios/SWS: Reposition selected items.
-- Convert to Lua from SWS C++



function GetSelectedMediaItemsOnTrack(tr)
  items = {}
  for j = 0, reaper.GetTrackNumMediaItems(tr)-1 do
    local item = reaper.GetTrackMediaItem(tr, j)
    if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then items[#items+1] = item end
  end
  return items
end

function hallo()


  bEnd = true   -- Start = false, End = true

  for i = 0, reaper.CountTracks(0)-1 do
    track = reaper.CSurf_TrackFromID(i + 1, false)
    items = GetSelectedMediaItemsOnTrack(track)
    for j = 2, #items do
      dPrevItemStart = reaper.GetMediaItemInfo_Value(items[j-1], "D_POSITION")
      dNewPos = dPrevItemStart 
      if (bEnd) then
        dNewPos = dNewPos + reaper.GetMediaItemInfo_Value(items[j-1], "D_LENGTH")
      end
      reaper.SetMediaItemInfo_Value(items[j], "D_POSITION", dNewPos)
    end
  end
end

hallo()

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------ORDER_PITCH---------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --[[
  * ReaScript Name: Sort selected items by pitch (ascending)
  * Description:    Sorts selected items from shortest to longest
  * Instructions:   - Select items
  *                 - Run the script
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: Mordi & spk77 , changed by dragonetti
  * Author URI:
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 1.0
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2016-06-26)
    + Changed script to only work on selected items.
]]
function order_pitch()
ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end

function get_item_lengths()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then 
  t[i].item = item  
  t[i].len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  t[i].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    end
  end
  return t
end

sort_func = function(a,b) -- https://forums.coronalabs.com/topic/37595-nested-sorting-on-multi-dimensional-array/
      if (a.pitch < b.pitch) then
        -- primary sort on length -> a before b
        return true
      --[[
      elseif (a.len > b.len) then
        -- primary sort on length -> b before a
        return false
      else
        -- primary sort tied, resolve w secondary sort on position
        return a.position < b.position
      --]]
      end
    end
      
function sort_items_by_length()
  local data = get_item_lengths()
  if data == nil then return end
  if #data == 0 then return end
  local pos = reaper.GetMediaItemInfo_Value(data[1].item, "D_POSITION") -- get first item pos
  
  table.sort(data, sort_func)
  
  for i=1, #data do
    local l = data[i].len
    reaper.SetMediaItemInfo_Value(data[i].item, "D_POSITION", pos)
    pos=pos+l
  end
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Sort items by length (ascending)", -1, -1)
end

sort_items_by_length()

end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------ORDER_RATE---------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --[[
  * ReaScript Name: Sort selected items by pitch (ascending)
  * Description:    Sorts selected items from shortest to longest
  * Instructions:   - Select items
  *                 - Run the script
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: Mordi & spk77 , changed by dragonetti
  * Author URI:
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 1.0
  * REAPER:
  * Extensions:
]]
 

--[[
 Changelog:
 * v1.0 (2016-06-26)
    + Changed script to only work on selected items.
]]
function order_rate()

ItemsSelCount = reaper.CountSelectedMediaItems(0)
if ItemsSelCount ==0 then return
end
function get_item_lengths()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then 
  t[i].item = item  
  t[i].len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  take = reaper.GetActiveTake(item)
  if take == nil then return end
  t[i].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
  t[i].rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    end
  end
  return t
end

sort_func = function(a,b) -- https://forums.coronalabs.com/topic/37595-nested-sorting-on-multi-dimensional-array/
      if (a.rate < b.rate) then
        -- primary sort on length -> a before b
        return true
      end
    end
      
function sort_items_by_length()
  local data = get_item_lengths()
  if data == nil then return end
  if #data == 0 then return end
  local pos = reaper.GetMediaItemInfo_Value(data[1].item, "D_POSITION") -- get first item pos
  
  table.sort(data, sort_func)
  
  for i=1, #data do
    local l = data[i].len
    reaper.SetMediaItemInfo_Value(data[i].item, "D_POSITION", pos)
    pos=pos+l
  end
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Sort items by length (ascending)", -1, -1)
end

sort_items_by_length()
end
--==================================================================================================================
--============================== MIDI_RAND ===========================================================
--===================================================================================================================
function midi_rand()
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
reaper.Main_OnCommand(40006,0)
math.randomseed(os.time())
cursor = reaper.GetCursorPosition()          
bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, cursor )
bar_length = 240/bpm
_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)
grid_length = bar_length*grid
note_quantity = 1/grid
bar_ppq = 3840
grid_ppq = 3840/note_quantity
accent = note_quantity/4
--velocity_rand = math.random(100,127)

random_anzahl = math.random(0,note_quantity-1)

rand1=math.random(0,random_anzahl)
rand2=math.random(0,random_anzahl)
rand3=math.random(0,random_anzahl)
rand4=math.random(0,random_anzahl)
rand5=math.random(0,random_anzahl)
rand6=math.random(0,random_anzahl)
rand7=math.random(0,random_anzahl)
rand8=math.random(0,random_anzahl)
rand9=math.random(0,random_anzahl)
rand10=math.random(0,random_anzahl)
velocity_values={126,100}
 velo = velocity_values[math.random(1,#velocity_values)] 

muted_table={false,true}
muted = muted_table[math.random(1,#muted_table)]
--function generate_midi()
for i=0, reaper.CountSelectedTracks(0) do
--velocity_rand = math.random(100,127)
track =  reaper.GetSelectedTrack2( 0, i, 0 )
if track == nil then
    return
    end

midiItem = reaper.CreateNewMIDIItemInProj(track, cursor,1)
reaper.SetMediaItemSelected(midiItem, true)
reaper.SetMediaItemInfo_Value(midiItem, "B_LOOPSRC",1)
midiTake = reaper.GetActiveTake(midiItem)
item_length=reaper.MIDI_GetProjTimeFromPPQPos( midiTake,cursor+bar_length) 
 reaper.SetMediaItemLength( midiItem,cursor+bar_length, true )
reaper.SetMediaItemInfo_Value( midiItem, "D_LENGTH", bar_length )



for var = 1,note_quantity
 do
if var == accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end
elseif var == 2*accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end
elseif var == 3*accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end
elseif var == 4*accent+1 then do
reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 127)
end 

elseif var == rand1  then do 
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60,100)
end
elseif var == rand2 then do 
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand3 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand4 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60,100)   
end 
elseif var == rand5 then do 
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand6 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand7 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand8 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end
elseif var == rand9 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end 
elseif var == rand10 then do
reaper.MIDI_InsertNote(midiTake, true,true, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)
end

else

reaper.MIDI_InsertNote(midiTake, true,false, (var-1)*grid_ppq, grid_ppq*(var), 1, 60, 100)

end


end
reaper.GetSetMediaItemTakeInfo_String(midiTake, 'P_NAME',72, true)

reaper.SetMediaItemInfo_Value(midiItem, 'I_CUSTOMCOLOR', reaper.ColorToNative(201,3,57)|0x1000000  )



--Msg(note_quantity)

end
end

--==================================================================================================================
--============================== MIDI_RAND 2===========================================================
--===================================================================================================================
function midi_sequenz()
--function Msg(variable)
-- reaper.ShowConsoleMsg(tostring(variable).."\n")
--end

reaper.Main_OnCommand(40006,0) --delete selected items

cursor = reaper.GetCursorPosition() 
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) 

bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, cursor )
bar_length = 240/bpm
_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)

grid_length = bar_length*grid
note_quantity = 1/grid
qn = note_quantity/4
bar_ppq = 3840 
grid_ppq = 3840/note_quantity
accent = note_quantity/4

factor = {1,2,3,4,1,1}


n1 = grid_ppq*factor[math.random(1,#factor)]
n2 = grid_ppq*factor[math.random(1,#factor)]
n3 = grid_ppq*factor[math.random(1,#factor)]
n4 = grid_ppq*factor[math.random(1,#factor)] 
n5 = grid_ppq*factor[math.random(1,#factor)]
n6 = grid_ppq*factor[math.random(1,#factor)]
n7 = grid_ppq*factor[math.random(1,#factor)]
n8 = grid_ppq*factor[math.random(1,#factor)]
n9 = grid_ppq*factor[math.random(1,#factor)]
n10 = grid_ppq*factor[math.random(1,#factor)]

s1 = n1/grid_ppq*grid_length
s2 = n2/grid_ppq*grid_length
s3 = n3/grid_ppq*grid_length
s4 = n4/grid_ppq*grid_length
s5 = n5/grid_ppq*grid_length
s6 = n6/grid_ppq*grid_length
s7 = n7/grid_ppq*grid_length
s8 = n8/grid_ppq*grid_length
s9 = n9/grid_ppq*grid_length
s10 = n10/grid_ppq*grid_length

velo = {80,90,110,120}

v1 = velo[math.random(1,#velo)]
v2 = velo[math.random(1,#velo)]
v3 = velo[math.random(1,#velo)]
v4 = velo[math.random(1,#velo)]
v5 = velo[math.random(1,#velo)]
v6 = velo[math.random(1,#velo)]
v7 = velo[math.random(1,#velo)]
v8 = velo[math.random(1,#velo)]
v9 = velo[math.random(1,#velo)]
v10 = velo[math.random(1,#velo)]


velocity_values={126,100}
velo = velocity_values[math.random(1,#velocity_values)] 

muted_table={false,true}
muted = muted_table[math.random(1,#muted_table)]

for i=0, reaper.CountSelectedTracks(0) do   
track =  reaper.GetSelectedTrack2( 0, i, 0 )  
if track == nil then
    return
    end 
    
midiItem1 = reaper.CreateNewMIDIItemInProj(track, cursor,1)
reaper.SetMediaItemSelected(midiItem1, true)
reaper.SetMediaItemInfo_Value(midiItem1, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem1, "D_LENGTH", s1 ) 
midiTake1 = reaper.GetActiveTake(midiItem1)
reaper.MIDI_InsertNote(midiTake1, true,muted, 0,n1, 1, 60, v1)
reaper.SetMediaItemSelected(midiItem1, true)

midiItem2 = reaper.CreateNewMIDIItemInProj(track,cursor+s1,1)
reaper.SetMediaItemSelected(midiItem2, true)
reaper.SetMediaItemInfo_Value(midiItem2, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem2, "D_LENGTH", s2 ) 
midiTake2 = reaper.GetActiveTake(midiItem2)
reaper.MIDI_InsertNote(midiTake2, true,false, 0,n2, 1, 60, v2)
reaper.SetMediaItemSelected(midiItem2, true)

midiItem3 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2,1)
reaper.SetMediaItemSelected(midiItem3, true)
reaper.SetMediaItemInfo_Value(midiItem3, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem3, "D_LENGTH", s3 ) 
midiTake3 = reaper.GetActiveTake(midiItem3)
reaper.MIDI_InsertNote(midiTake3, true,false, 0,n3, 1, 60, v3)
reaper.SetMediaItemSelected(midiItem3, true)

midiItem4 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3,1)
reaper.SetMediaItemSelected(midiItem4, true)
reaper.SetMediaItemInfo_Value(midiItem4, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem4, "D_LENGTH", s4 ) 
midiTake4 = reaper.GetActiveTake(midiItem4)
reaper.MIDI_InsertNote(midiTake4, true,false, 0,n4, 1, 60, v4)
reaper.SetMediaItemSelected(midiItem4, true)

midiItem5 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4,1)
reaper.SetMediaItemSelected(midiItem5, true)
reaper.SetMediaItemInfo_Value(midiItem5, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem5, "D_LENGTH", s5 ) 
midiTake5 = reaper.GetActiveTake(midiItem5)
reaper.MIDI_InsertNote(midiTake5, true,false, 0,n5, 1, 60, v5)
reaper.SetMediaItemSelected(midiItem5, true)

midiItem6 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5,1)
reaper.SetMediaItemSelected(midiItem6, true)
reaper.SetMediaItemInfo_Value(midiItem6, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem6, "D_LENGTH", s6 ) 
midiTake6 = reaper.GetActiveTake(midiItem6)
reaper.MIDI_InsertNote(midiTake6, true,false, 0,n6, 1, 60, v6)
reaper.SetMediaItemSelected(midiItem6, true)

midiItem7 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6,1)
reaper.SetMediaItemSelected(midiItem7, true)
reaper.SetMediaItemInfo_Value(midiItem7, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem7, "D_LENGTH", s7 )  
midiTake7 = reaper.GetActiveTake(midiItem7)
reaper.MIDI_InsertNote(midiTake7, true,false, 0,n7, 1, 60, v7)
reaper.SetMediaItemSelected(midiItem7, true)

midiItem8 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6+s7,1)
reaper.SetMediaItemSelected(midiItem8, true)
reaper.SetMediaItemInfo_Value(midiItem8, "B_LOOPSRC",1) 
reaper.SetMediaItemInfo_Value( midiItem8, "D_LENGTH", s8 ) 
midiTake8 = reaper.GetActiveTake(midiItem8)
midiTake8 = reaper.GetActiveTake(midiItem8)
reaper.MIDI_InsertNote(midiTake8, true,false, 0,n8, 1, 60, v8)
reaper.SetMediaItemSelected(midiItem8, true)

midiItem9 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6+s7+s8,1)
reaper.SetMediaItemSelected(midiItem9, true)
reaper.SetMediaItemInfo_Value(midiItem9, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem9, "D_LENGTH", s9 ) 
midiTake9 = reaper.GetActiveTake(midiItem9)
reaper.MIDI_InsertNote(midiTake9, true,false, 0,n9, 1, 60, v9)
reaper.SetMediaItemSelected(midiItem9, true)

midiItem10 = reaper.CreateNewMIDIItemInProj(track,cursor+s1+s2+s3+s4+s5+s6+s7+s8+s9,1)
reaper.SetMediaItemSelected(midiItem10, true)
reaper.SetMediaItemInfo_Value(midiItem10, "B_LOOPSRC",1)
reaper.SetMediaItemInfo_Value( midiItem10, "D_LENGTH", s10 ) 
midiTake10 = reaper.GetActiveTake(midiItem10)
reaper.MIDI_InsertNote(midiTake10, true,false, 0,n10, 1, 60, v10)
reaper.SetMediaItemSelected(midiItem10, true)


end
 
end
--==================================================================================================================
--============================== MIDI_PATTERN 3===========================================================
--===================================================================================================================
function midi_creator()
local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end
local retval, input_str = reaper.GetUserInputs("Create Midi Pattern", 2, "Length 1=1unit  2=2unit  0=mute,UNIT " , "3323324444,16")
if not retval then return end

-- Extrahiere Längen und Akzente aus dem Benutzereingabestring 
local length_str = input_str:sub(1, input_str:find(",") - 1)
local grid_division = input_str:sub(input_str:find(",") + 1)


-- Konvertiere Längen- und Akzent-Strings in Tabellen
local sequence = {}
for i = 1, #length_str do
  sequence[i] = tonumber(length_str:sub(i, i))
end

local length_stellen = string.len(length_str)


local vols = {}
for i = 1, length_stellen do
  vols[i] = 1
end


-- Überprüfe, ob die Anzahl der Längen und Akzente gleich ist
if #sequence ~= #vols then
  reaper.ShowMessageBox("The number of lengths and vol must be the same.", "Error", 0)
  return
end

-- Berechne notwendige Variablen

local cursor = reaper.GetCursorPosition()
local bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, cursor)
local bar_length = 120 / bpm
local grid_size = bar_length / grid_division 
local grid_length = bar_length / grid_division
local note_quantity = 1 / grid_division
local qn = note_quantity / 4
local bar_ppq = 3840
local grid_ppq = 3840 / note_quantity
local TIME_SEL_START, TIME_SEL_END = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

-- Funktion zum Erstellen eines MIDI-Items
local function create_midi_item(start_time, length, track, midi_length, vol, mute)

  local midi_item = reaper.CreateNewMIDIItemInProj(track, start_time, start_time + length)
  local take = reaper.GetActiveTake(midi_item)
  
 
  reaper.SetMediaItemSelected(midi_item, true)
  reaper.SetMediaItemInfo_Value(midi_item, "B_MUTE",mute)
  reaper.SetMediaItemInfo_Value(midi_item, "D_VOL",vol)
  reaper.MIDI_InsertNote(take, true, false, 0, midi_length, 0, 60, 126, false)
end

-- Für jede ausgewählte Spur MIDI-Items erstellen
for i=0, reaper.CountSelectedTracks()-1 do
  local track = reaper.GetSelectedTrack(0, i)
  local note_idx = 1
  local start_time = TIME_SEL_START
  local prev_item_end = start_time
  while start_time < TIME_SEL_END do
    local length = sequence[note_idx] == 0 and 1*grid_size or sequence[note_idx] * grid_size
    local midi_length = sequence[note_idx] == 0 and grid_ppq or sequence[note_idx] * grid_ppq
    local vol = 127
    if vols[note_idx] then
      if vols[note_idx] == 0 then vol = 0.7 else vol = 1 end
    end
    local mute = false
        if sequence[note_idx] == 0 then mute = 1 else mute=0 end
    local midi_item = create_midi_item(prev_item_end, length, track, midi_length, vol, mute)
    prev_item_end = start_time + length
    note_idx = note_idx % #sequence + 1
    start_time = prev_item_end
  end
end

end
--============================================================================================================================
--======================================= DETECT_MIDI_CHORDS =================================================================
--============================================================================================================================
-- Notation Events Chords to Regions
-- juliansader https://forum.cockos.com/member.php?u=14710
function detect_midi_chords()
function CreateTextItem(track, position, length, text, color)

  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end


function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

 ctrack = getTrackByName("chordtrack")
 if ctrack == nil then 
 
-- create chordtrack 
create_track = reaper.NamedCommandLookup("_SWS_CREATETRK1")
reaper.Main_OnCommand(create_track,0)
 ctrack = reaper.GetTrack( 0, 0 )
 reaper.GetSetMediaTrackInfo_String(ctrack, 'P_NAME', 'chordtrack', true)
 reaper.SetMediaTrackInfo_Value( ctrack, "I_WNDH", 50 )
 reaper.SetMediaTrackInfo_Value(ctrack, "I_HEIGHTOVERRIDE", 32)
 reaper.SetMediaTrackInfo_Value(ctrack, "B_HEIGHTLOCK", 1)
 reaper.SetMediaTrackInfo_Value( ctrack, "I_RECARM", 1 )
 reaper.SetMediaTrackInfo_Value( ctrack, "I_RECINPUT", 4096 | 0 | (62 << 5) )
 color = reaper.ColorToNative(95,175,178)
 reaper.SetTrackColor(ctrack, color)

end 
 
reaper.Undo_BeginBlock2(0)
reaper.Main_OnCommand(40644,0)
reaper.Main_OnCommand(42432,0)
--reaper.Main_OnCommand(40421,0) --Item: Select all items in track 40421
sel_item =  reaper.GetSelectedMediaItem( 0, 0 )
--if not sel_item then reaper.MB("Selct Item", "Attention",0) end
if not sel_item then return end
item_length = reaper.GetMediaItemInfo_Value( sel_item, "D_LENGTH" )
item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION" )
end_pos = item_pos + item_length
reaper.Main_OnCommand(40153,0) --Item: Open in built-in MIDI editor (set default behavior in preferences) 40153
hwnd = reaper.MIDIEditor_GetActive()
--reaper.MIDIEditor_OnCommand( hwnd, 40954 ) --Mode: Notation3
reaper.MIDIEditor_OnCommand( hwnd, 41281 ) --Notation: Identify chords on editor grid

reaper.SN_FocusMIDIEditor()
reaper.MIDIEditor_OnCommand(40954,0) --Mode: Notation3
reaper.MIDIEditor_OnCommand(41281,0) --Notation: Identify chords on editor grid

  
take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
if take == nil then return end
reaper.MIDI_Sort(take)
MIDIOK, MIDI = reaper.MIDI_GetAllEvts(take, "")
tChords = {}
stringPos, ticks = 1, 0
while stringPos < MIDI:len() do
    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDI, stringPos)
    ticks = ticks + offset
    if msg:byte(1) == 0xFF then
    chord = msg:match("text (.+)")
    if chord then
    tChords[#tChords+1] = {chord = chord, ticks = ticks}
    end
    end
end
midi_note_end = 0
_, notecnt = reaper.MIDI_CountEvts( take )
for i = 1, notecnt do
  local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )

  if endppqpos > midi_note_end then
   midi_note_end = endppqpos
  end
end
midi_note_end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, midi_note_end )


tChords[#tChords+1] = {ticks = ticks}
for i = 1, #tChords do
    tChords[i].time = reaper.MIDI_GetProjTimeFromPPQPos(take, tChords[i].ticks)
end
for i = 1, #tChords-1 do
    -- Set Region Color RGB > reaper.ColorToNative(55,118,235)
  if tChords[i].chord ~= last_chord then
   chord_name = tChords[i].chord
   if chord_name == "C6" then chord_name = "Am" end
   if chord_name == "C#6" then chord_name = "A#m" end
   if chord_name == "D6" then chord_name = "Bm" end
  if chord_name == "D#6" then chord_name = "Cm" end
   if chord_name == "E6" then chord_name = "C#m" end
   if chord_name == "F6" then chord_name = "Dm" end
   if chord_name == "F#6" then chord_name = "D#m" end
   if chord_name == "G6" then chord_name = "Em" end
   if chord_name == "G#6" then chord_name = "Fm" end
   if chord_name == "A6" then chord_name = "F#m" end
  if chord_name == "A#6" then chord_name = "Gm" end
   if chord_name == "B6" then chord_name = "G#m" end
   
   time_end = tChords[i+1].time
   
   if tChords[i+1].time > midi_note_end_time then time_end = midi_note_end_time end
   
   CreateTextItem(ctrack,tChords[i].time,time_end - tChords[i].time,chord_name)
   
   last_chord = tChords[i].chord
    end
end     


commandID2 = reaper.NamedCommandLookup("_SWSMARKERLIST13")
--reaper.Main_OnCommand(commandID2, 0) -- SWS: Convert markers to regions
reaper.Undo_EndBlock2(0, "Chords from midi item", -1)
reaper.MIDIEditor_OnCommand( hwnd, 2 ) --File: Close window
end

-- =================================================================================
--============================== REVERSE_ITEMS ======================================
--=====================================================================================

function reverse_items()

reverse_item = reaper.NamedCommandLookup("_XENAKIOS_REVORDSELITEMS")

reaper.Main_OnCommand(reverse_item,0)  -- reverse item

-- Xenakios/SWS: Reposition selected items.
-- Convert to Lua from SWS C++


function GetSelectedMediaItemsOnTrack(tr)
  items = {}
  for j = 0, reaper.GetTrackNumMediaItems(tr)-1 do
    local item = reaper.GetTrackMediaItem(tr, j)
    if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then items[#items+1] = item end
  end
  return items
end

function main()


  bEnd = true   -- Start = false, End = true

  for i = 0, reaper.CountTracks(0)-1 do
    track = reaper.CSurf_TrackFromID(i + 1, false)
    items = GetSelectedMediaItemsOnTrack(track)
    for j = 2, #items do
      dPrevItemStart = reaper.GetMediaItemInfo_Value(items[j-1], "D_POSITION")
      dNewPos = dPrevItemStart 
      if (bEnd) then
        dNewPos = dNewPos + reaper.GetMediaItemInfo_Value(items[j-1], "D_LENGTH")
      end
      reaper.SetMediaItemInfo_Value(items[j], "D_POSITION", dNewPos)
    end
  end
end

main()

end

--================================================================================================================================
--======================================== CREATE_REGION =========================================================================
--================================================================================================================================
-- @description Rename region at edit cursor after the first selected item
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showpost.php?p=2358410&postcount=20
-- @donation https://www.paypal.me/amagalma
function create_region()
reaper.Main_OnCommand(40348,0)
reaper.Main_OnCommand(40318,0)


local msg = "Please, select an item "

local item = reaper.GetSelectedMediaItem( 0, 0 )
if not item then
  reaper.MB( msg, "No item selected!", 0 )
  return
end

local _, rg_idx = reaper.GetLastMarkerAndCurRegion( 0,  reaper.GetCursorPositionEx( 0 ) )
if rg_idx == -1 then
  reaper.MB( msg, "Edit cursor not inside a region!", 0 )
  return
end

local it_name
local take = reaper.GetActiveTake( item )
if take then
  it_name = reaper.GetTakeName( take )
else
  it_name = ({reaper.GetSetMediaItemInfo_String( item, "P_NOTES", "", false )})[2]
end
local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, rg_idx )
--if name == it_name then return end
col_blu = reaper.ColorToNative(55,55, 55)|0x1000000
local ok = reaper.SetProjectMarker4( 0, markrgnindexnumber, isrgn, pos, rgnend, "",col_blu, 0)
if ok then
  reaper.Undo_OnStateChangeEx2( 0, "Name region after selected item", 8, -1 )
end
reaper.Main_OnCommand(40616,0)
end

--========================================================================================================================
--==================================== chordsymbol_trans_up ====================================================================
--========================================================================================================================
function chordsymbol_trans_up()

    -- function Msg(m)                         --  function: console output alias for debugging
 --    reaper.ShowConsoleMsg(tostring(m) .. '\n')
   --    end
    
   
   function getTrackByName(name)
     for trackIndex = 0, reaper.CountTracks(0) - 1 do
        tracko = reaper.GetTrack(0, trackIndex)
       local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)
   
       if ok and trackName == name then
         return tracko -- found it! stopping the search here
       end 
     end
   end  
   
   
   function chord_up(item_notes)
     chord, p = nil, 0
     root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
     switches = string.match( item_notes, "-%a.*")
     
     if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
     if item_notes == "" then root = "" chord = "" i=i +1 end
     if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
    
     var = chord
   
     if     root == "C"  then root_up = "C#"
     elseif root == "C#" then root_up = "D"
     elseif root == "Db" then root_up = "D"
     elseif root == "D"  then root_up = "D#"
     elseif root == "D#" then root_up = "E"
     elseif root == "Eb" then root_up = "E"
     elseif root == "E"  then root_up = "F"
     elseif root == "F"  then root_up = "F#"
     elseif root == "F#" then root_up = "G"
     elseif root == "Gb" then root_up = "G"
     elseif root == "G"  then root_up = "G#"
     elseif root == "G#" then root_up = "A"
     elseif root == "Ab" then root_up = "A"
     elseif root == "A"  then root_up = "A#"
     elseif root == "A#" then root_up = "B"
     elseif root == "Bb" then root_up = "B"
     elseif root == "B"  then root_up = "C"
     if not root then end
   end  
   end
   
   
                   ctrack = getTrackByName("chordtrack")
             count_chords = reaper.CountTrackMediaItems(ctrack)
     start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
              count_items = reaper.CountSelectedMediaItems(0)
           for  y = 0, count_chords-1 do
               chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
              is_selected = reaper.IsMediaItemSelected(chord_item)
          end
          
    
     if count_items - count_chords >= 0 or count_items == 0 then
   
     for i=0, count_chords -1 do
   
           chord_item = reaper.GetTrackMediaItem(ctrack,i )
          is_selected = reaper.IsMediaItemSelected(chord_item)
        _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
                  pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
               length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
               rgnend = pos+length  
               
             
       if  pos >= start_time and pos < end_time then   
       chord_up(item_notes)
       reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_up..chord, true)
       end
       end
      
       else
      
          for  x = 0, count_chords-1 do
          chord_item = reaper.GetMediaItem(0,x)    
          is_selected = reaper.IsMediaItemSelected(chord_item )
              if is_selected == true then
           
            _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
       
             chord_up(item_notes)
             reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_up..chord, true)
   end
    end 
   end
    
   
     reaper.UpdateArrange()
     
   
                                                                                    
end
-- =======================================================================================
--================== CHORD_LEFT =========================================================
--=========================================================================================
function chordsymbol_left()
    function Msg(m)                         --  function: console output alias for debugging
  reaper.ShowConsoleMsg(tostring(m) .. '\n')
    end
 

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end  


function chord_up(item_notes)
  chord, p = nil, 0
  root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
  switches = string.match( item_notes, "-%a.*")
  
  if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
  if item_notes == "" then root = "" chord = "" i=i +1 end
  if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
 
 var = chord
 
                if chord == "maj7"     then chord_left =  ""
          elseif chord == "maj9" then chord_left ="maj7"
           elseif chord == "maj13"then chord_left ="maj9"
           elseif chord == "maj+4"then chord_left ="maj13"
            elseif chord == "7"then chord_left ="maj+4"
             elseif chord == "9"then chord_left ="7"
              elseif chord == "11"then chord_left ="9"
              elseif chord == "13"then chord_left ="11"
              elseif chord == "7aug"then chord_left ="13"
            elseif chord == "7b9"then chord_left ="7aug"
             elseif chord == "7alt"then chord_left ="7b9"
            elseif chord == "7b5"then chord_left ="7alt"
              elseif chord == "dim"then chord_left ="7b5" 
             elseif chord == "m"then chord_left ="dim"
               elseif chord == "m7"then chord_left ="m"
               elseif chord == "m9"then chord_left ="m7"
              elseif chord == "m11"then chord_left ="m9"
             elseif chord == "m13"then chord_left ="m11" 
              elseif chord == "m(maj7)"then chord_left ="m13"
          elseif chord == ""then chord_left ="m(maj7)"
         
         
         elseif chord == nil then return end 
         
         if not root then end
         end


                ctrack = getTrackByName("chordtrack")
          count_chords = reaper.CountTrackMediaItems(ctrack)
  start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
           count_items = reaper.CountSelectedMediaItems(0)
        for  y = 0, count_chords-1 do
            chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
           is_selected = reaper.IsMediaItemSelected(chord_item)
       end
       
 
  if count_items - count_chords >= 0 or count_items == 0 then

  for i=0, count_chords -1 do

        chord_item = reaper.GetTrackMediaItem(ctrack,i )
       is_selected = reaper.IsMediaItemSelected(chord_item)
     _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
               pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
            length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
            rgnend = pos+length  
            
          
    if  pos >= start_time and pos < end_time then   
    chord_up(item_notes)
    reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root..chord_left, true)
    end
    end
   
    else
   
       for  x = 0, count_chords-1 do
       chord_item = reaper.GetMediaItem(0,x)    
       is_selected = reaper.IsMediaItemSelected(chord_item )
           if is_selected == true then
        
         _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
    
          chord_up(item_notes)
          if chord_right == nil then return end 
          reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root..chord_left, true)
end
 end 
end
 

  reaper.UpdateArrange()
  
end

-- =======================================================================================
--================== CHORD_RIGHT =========================================================
--=========================================================================================
function chordsymbol_right()
    function Msg(m)                         --  function: console output alias for debugging
  reaper.ShowConsoleMsg(tostring(m) .. '\n')
    end
 

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
     tracko = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)

    if ok and trackName == name then
      return tracko -- found it! stopping the search here
    end 
  end
end  


function chord_up(item_notes)
  chord, p = nil, 0
  root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
  switches = string.match( item_notes, "-%a.*")
  
  if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
  if item_notes == "" then root = "" chord = "" i=i +1 end
  if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
 
  var = chord

        if     chord == ""        then chord_right = "maj7"
        elseif chord == "maj7"    then chord_right = "maj9"
        elseif chord == "maj9"    then chord_right = "maj13"
        elseif chord == "maj13"   then chord_right = "maj+4"
        elseif chord == "maj+4"   then chord_right = "7"
        elseif chord == "7"       then chord_right = "9"
        elseif chord == "9"       then chord_right = "11"
        elseif chord == "11"      then chord_right = "13"
        elseif chord == "13"      then chord_right = "7aug"
        elseif chord == "7aug"    then chord_right = "7b9"
        elseif chord == "7b9"     then chord_right = "7alt"
        elseif chord == "7alt"    then chord_right = "7b5"
        elseif chord == "7b5"     then chord_right = "dim"
        elseif chord == "dim"     then chord_right = "m"
        elseif chord == "m"       then chord_right = "m7"
        elseif chord == "m7"      then chord_right = "m9"
        elseif chord == "m9"      then chord_right = "m11"
        elseif chord == "m11"     then chord_right = "m13"
        elseif chord == "m13"     then chord_right = "m(maj7)"
        elseif chord == "m(maj7)" then chord_right = ""
        
        
        elseif chord == nil then return end 
        
        if not root then end
        end


                ctrack = getTrackByName("chordtrack")
          count_chords = reaper.CountTrackMediaItems(ctrack)
  start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
           count_items = reaper.CountSelectedMediaItems(0)
        for  y = 0, count_chords-1 do
            chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
           is_selected = reaper.IsMediaItemSelected(chord_item)
       end
       
 
  if count_items - count_chords >= 0 or count_items == 0 then

  for i=0, count_chords -1 do

        chord_item = reaper.GetTrackMediaItem(ctrack,i )
       is_selected = reaper.IsMediaItemSelected(chord_item)
     _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
               pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
            length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
            rgnend = pos+length  
            
          
    if  pos >= start_time and pos < end_time then   
    chord_up(item_notes)
    reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root..chord_right, true)
    end
    end
   
    else
   
       for  x = 0, count_chords-1 do
       chord_item = reaper.GetMediaItem(0,x)    
       is_selected = reaper.IsMediaItemSelected(chord_item )
           if is_selected == true then
        
         _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
    
          chord_up(item_notes)
          if chord_right == nil then return end 
          reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root..chord_right, true)
end
 end 
end
 

  reaper.UpdateArrange()
  
end
--========================================================================================
--====================== create_chordtrack ===============================================
--========================================================================================
function create_chordtrack()
-- cliffon track by name
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

local track = getTrackByName("chordtrack")

if track  then 

selected_track = reaper.GetSelectedTrack(0,0 )
IDX_ctrack = reaper.CSurf_TrackToID(track, 0 )
if selected_track then
 IDX = reaper.CSurf_TrackToID(selected_track, 0 )
reaper.Main_OnCommand(40297,0) --Track: Unselect (clear selection of) all tracks
ctrack = getTrackByName("chordtrack")
IDX_ctrack = reaper.CSurf_TrackToID(ctrack, 0 )

reaper.SetOnlyTrackSelected( ctrack )
reaper.ReorderSelectedTracks(IDX-1, 0 )
IDX_ctrack = reaper.CSurf_TrackToID(track, 0 )

elseif  IDX_ctrack >1 then
ctrack = getTrackByName("chordtrack")
reaper.SetOnlyTrackSelected( ctrack )
reaper.ReorderSelectedTracks(0, 0 )

else
ctrack = getTrackByName("chordtrack")
reaper.SetOnlyTrackSelected( ctrack )
reaper.Main_OnCommand(40913,0) --Track: Vertical scroll selected tracks into view

end
end
local track = getTrackByName("chordtrack")
if track == nil then do


--if ctrack == nil then
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_CREATETRK1"),0)-- insert track at top
ctrack=reaper.GetSelectedTrack( 0, 0 )
reaper.GetSetMediaTrackInfo_String(ctrack, "P_NAME", "chordtrack", true)
reaper.SetMediaTrackInfo_Value( ctrack, "I_WNDH", 50 )
if ctrack then 
reaper.SetMediaTrackInfo_Value(ctrack, "I_HEIGHTOVERRIDE", 32)
reaper.SetMediaTrackInfo_Value(ctrack, "B_HEIGHTLOCK", 1)
reaper.SetMediaTrackInfo_Value( ctrack, "I_RECARM", 1 )
reaper.SetMediaTrackInfo_Value( ctrack, "I_RECINPUT", 4096 | 0 | (62 << 5) )

  color = reaper.ColorToNative(95,175,178)
  reaper.SetTrackColor(ctrack, color)


  
end
end
end

reaper.Main_OnCommand(40297,0)
reaper.PreventUIRefresh(1)
end
--========================================================================================================================
--==================================== chordsymbol_trans_down ====================================================================
--========================================================================================================================
function chordsymbol_trans_down()
        function Msg(m)                         --  function: console output alias for debugging
      reaper.ShowConsoleMsg(tostring(m) .. '\n')
        end
     
    
    function getTrackByName(name)
      for trackIndex = 0, reaper.CountTracks(0) - 1 do
         tracko = reaper.GetTrack(0, trackIndex)
        local ok, trackName = reaper.GetSetMediaTrackInfo_String(tracko, 'P_NAME', '', false)
    
        if ok and trackName == name then
          return tracko -- found it! stopping the search here
        end 
      end
    end  
    
    
    function chord_up(item_notes)
      chord, p = nil, 0
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$")
      switches = string.match( item_notes, "-%a.*")
      
      if string.match( item_notes, "@.*") then root = "" chord = "" i=i +1 end -- skip region marked @ ignore
      if item_notes == "" then root = "" chord = "" i=i +1 end
      if string.find(item_notes, "-%a.*")  == 1 then root = "" chord = "" end  
     
      var = chord
    
     if     root == "C"  then root_down = "B"
            elseif root == "C#" then root_down = "C"
            elseif root == "Db" then root_down = "C"
            elseif root == "D"  then root_down = "Db"
            elseif root == "D#" then root_down = "D"
            elseif root == "Eb" then root_down = "D"
            elseif root == "E"  then root_down = "Eb"
            elseif root == "F"  then root_down = "E"
            elseif root == "F#" then root_down = "F"
            elseif root == "Gb" then root_down = "F"
            elseif root == "G"  then root_down = "Gb"
            elseif root == "G#" then root_down = "G"
            elseif root == "Ab" then root_down = "G"
            elseif root == "A"  then root_down = "Ab"
            elseif root == "A#" then root_down = "A"
            elseif root == "Bb" then root_down = "A"
            elseif root == "B"  then root_down = "Bb"
            if not root then end
            end
    end
    
    
                    ctrack = getTrackByName("chordtrack")
              count_chords = reaper.CountTrackMediaItems(ctrack)
      start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
               count_items = reaper.CountSelectedMediaItems(0)
            for  y = 0, count_chords-1 do
                chord_item =  reaper.GetTrackMediaItem(ctrack, y )  
               is_selected = reaper.IsMediaItemSelected(chord_item)
           end
           
     
      if count_items - count_chords >= 0 or count_items == 0 then
    
      for i=0, count_chords -1 do
    
            chord_item = reaper.GetTrackMediaItem(ctrack,i )
           is_selected = reaper.IsMediaItemSelected(chord_item)
         _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
                   pos = reaper.GetMediaItemInfo_Value( chord_item, "D_POSITION" )
                length = reaper.GetMediaItemInfo_Value( chord_item, "D_LENGTH" )
                rgnend = pos+length  
                
              
        if  pos >= start_time and pos < end_time then   
        chord_up(item_notes)
        reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_down..chord, true)
        end
        end
       
        else
       
           for  x = 0, count_chords-1 do
           chord_item = reaper.GetMediaItem(0,x)    
           is_selected = reaper.IsMediaItemSelected(chord_item )
               if is_selected == true then
            
             _, item_notes = reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", "", false) 
        
              chord_up(item_notes)
              reaper.GetSetMediaItemInfo_String(chord_item, "P_NOTES", root_down..chord, true)
    end
     end 
    end
     
    
      reaper.UpdateArrange()
      
    
                                                                                       
                                                                                   
end
--==========================================================================================================
--========================== create_random_chord ===========================================================
--==========================================================================================================
--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end
function random_chord()

--function Msg(variable)
--  reaper.ShowConsoleMsg(tostring(variable).."\n")
--end


chords = {[1]={"C","G","Am","F"},
          [2]={"C","F","G","F"},
          [3]={"Dm7","G7","Cmaj7"},
          [4]={"C","Am","F","G"},
          [5]={"C","Am","Dm","G"},
          [6]={"C","F","Am","G"},
          [7]={"C","Em","F","G"},
          [8]={"C","F","C","G"},
          [9]={"C","F","Dm","G"}}

cursor = reaper.GetCursorPosition()
bar = 4*(reaper.TimeMap_QNToTime_abs(0, 1 ))
 
function create_region(region_name1,region_name2,region_name3,region_name4)
   color = reaper.ColorToNative(55,55, 55)|0x1000000 
   
  reaper.AddProjectMarker2(0, true, cursor, (cursor+bar),  region_name1, -1, color)
  reaper.AddProjectMarker2(0, true, (cursor+bar), (cursor+2*bar),  region_name2, -1, color)
  if region_name3 == nil then return
      else
  reaper.AddProjectMarker2(0, true, (cursor+2*bar), (cursor+3*bar), region_name3, -1, color)
  if region_name4 == nil then return
    else
  reaper.AddProjectMarker2(0, true, (cursor+3*bar),(cursor+4*bar), region_name4, -1, color)
  
end  
end
end
math.randomseed(os.time())
a = math.random(1,9)


create_region(chords[a][1],chords[a][2],chords[a][3],chords[a][4])

--Msg(chords[1][1])

end
--====================================================================
--================ CT _ create_subdominant ===================================
--====================================================================

function create_subdominant()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end



function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 1 then return end
           
           if sel_item == nil then return end  
               item1 = reaper.GetSelectedMediaItem(0,1) 
               item0 =  reaper.GetSelectedMediaItem(0,0)
               length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
               reaper.SetMediaItemInfo_Value( item0, "D_LENGTH", length/2 )
               reaper.Main_OnCommand(41295,0) -- duplicate item
               reaper.Main_OnCommand(41128,0) -- select previous item
 
  
      get_chord_notes(item0)
      
         
                if root == "C"  then sub_dominant = "Bb"
            elseif root == "C#" then sub_dominant = "B"
            elseif root == "Db" then sub_dominant = "Cb"
            elseif root == "D"  then sub_dominant = "C"
            elseif root == "D#" then sub_dominant = "C#"
            elseif root == "Eb" then sub_dominant = "Db"
            elseif root == "E"  then sub_dominant = "D"
            elseif root == "F"  then sub_dominant = "Eb"
            elseif root == "F#" then sub_dominant = "E"
            elseif root == "Gb" then sub_dominant = "Fb"
            elseif root == "G"  then sub_dominant = "F"
            elseif root == "G#" then sub_dominant = "F#"
            elseif root == "Ab" then sub_dominant = "Gb"
            elseif root == "A"  then sub_dominant = "G"
            elseif root == "A#" then sub_dominant = "G#"
            elseif root == "Bb" then sub_dominant = "Ab"
            elseif root == "B"  then sub_dominant = "A"
            if not root then end
            end
       
        
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
          itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES",sub_dominant, true)
      reaper.Main_OnCommand(40289,0)
      end

  
main() 

end

--======================================================================================
--=============================== CT _ minor subdominant ================================
--===========================================================================================

-- Variantische Modulation über MollSubDominante
function minor_subdominant()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end


function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end

      if root == "C"  then circle = 1
  elseif root == "C#" then circle = 8
  elseif root == "Db" then circle = 8
  elseif root == "D"  then circle = 3
  elseif root == "D#" then circle = 10
  elseif root == "Eb" then circle = 10
  elseif root == "E"  then circle = 5
  elseif root == "F"  then circle = 12
  elseif root == "F#" then circle = 7
  elseif root == "Gb" then circle = 7
  elseif root == "G"  then circle = 2
  elseif root == "G#" then circle = 9
  elseif root == "Ab" then circle = 9
  elseif root == "A"  then circle = 4
  elseif root == "A#" then circle = 11
  elseif root == "Bb" then circle = 11
  elseif root == "B"  then circle = 6
  if not root then end
  end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 2 then return end
             if sel_item == nil then return end  
               item1 =  reaper.GetSelectedMediaItem(0,1) 
               item0 =  reaper.GetSelectedMediaItem(0,0)
               
      get_chord_notes(item0) 
            if root == "C"  then circle0 = 1
        elseif root == "C#" then circle0 = 8
        elseif root == "Db" then circle0 = 8
        elseif root == "D"  then circle0 = 3
        elseif root == "D#" then circle0 = 10
        elseif root == "Eb" then circle0 = 10
        elseif root == "E"  then circle0 = 5
        elseif root == "F"  then circle0 = 12
        elseif root == "F#" then circle0 = 7
        elseif root == "Gb" then circle0 = 7
        elseif root == "G"  then circle0 = 2
        elseif root == "G#" then circle0 = 9
        elseif root == "Ab" then circle0 = 9
        elseif root == "A"  then circle0 = 4
        elseif root == "A#" then circle0 = 11
        elseif root == "Bb" then circle0 = 11
        elseif root == "B"  then circle0 = 6
        if not root then end
        end
        
      get_chord_notes(item1)
            if root == "C"  then circle1 = 1 
        elseif root == "C#" then circle1 = 8
        elseif root == "Db" then circle1 = 8
        elseif root == "D"  then circle1 = 3
        elseif root == "D#" then circle1 = 10
        elseif root == "Eb" then circle1 = 10
        elseif root == "E"  then circle1 = 5
        elseif root == "F"  then circle1 = 12
        elseif root == "F#" then circle1 = 7
        elseif root == "Gb" then circle1 = 7
        elseif root == "G"  then circle1 = 2
        elseif root == "G#" then circle1 = 9
        elseif root == "Ab" then circle1 = 9
        elseif root == "A"  then circle1 = 4
        elseif root == "A#" then circle1 = 11
        elseif root == "Bb" then circle1 = 11
        elseif root == "B"  then circle1 = 6
        if not root then end
        end
      
     xxx = circle1 - circle0
   -- Msg(xxx)
     if xxx==1 or xxx==2 or xxx==10 or xxx==11 or xxx==-1  or xxx==-2 or xxx==-10 or xxx==-11 or xxx==6 or xxx==-6 then Msg("Chords not suitable \nFor keys that are more than 3 fifths apart.")return end
     yyy = 0
     
         if xxx == 3 then  yyy = circle1
     elseif xxx == 4 then  yyy = circle1
     elseif xxx == 5 then  yyy = circle1
     elseif xxx == 7 then  yyy = circle0
     elseif xxx == 8 then  yyy = circle0
     elseif xxx == 9 then  yyy = circle0
     elseif xxx == -3 then  yyy = circle0
     elseif xxx == -4 then  yyy = circle0
     elseif xxx == -5 then  yyy = circle0
     elseif xxx == -7 then  yyy = circle1
     elseif xxx == -8 then  yyy = circle1
     elseif xxx == -9 then  yyy = circle1
     end 
     
   -- Msg(yyy)
         
                if yyy == 1 then root = "C"
            elseif yyy == 2 then root = "G"
            elseif yyy == 3 then root = "D"
            elseif yyy == 4 then root = "A"
            elseif yyy == 5 then root = "E"
            elseif yyy == 6 then root = "B"
            elseif yyy == 7 then root = "F#"
            elseif yyy == 8 then root = "Db"
            elseif yyy == 9 then root = "Ab"
            elseif yyy == 10 then root = "Eb"
            elseif yyy == 11 then root = "Bb"
            elseif yyy == 12 then root = "F"
            
            end
              
         
                if root == "C"  then moll_sub_dom = "F"
            elseif root == "C#" then moll_sub_dom = "F#"
            elseif root == "Db" then moll_sub_dom = "Gb"
            elseif root == "D"  then moll_sub_dom = "G"
            elseif root == "D#" then moll_sub_dom = "G#"
            elseif root == "Eb" then moll_sub_dom = "Ab"
            elseif root == "E"  then moll_sub_dom = "A"
            elseif root == "F"  then moll_sub_dom = "Bb"
            elseif root == "F#" then moll_sub_dom = "B"
            elseif root == "Gb" then moll_sub_dom = "Cb"
            elseif root == "G"  then moll_sub_dom = "C"
            elseif root == "G#" then moll_sub_dom = "C#"
            elseif root == "Ab" then moll_sub_dom = "Db"
            elseif root == "A"  then moll_sub_dom = "D"
            elseif root == "A#" then moll_sub_dom = "D#"
            elseif root == "Bb" then moll_sub_dom = "Eb"
            elseif root == "B"  then moll_sub_dom = "E"
            if not root then end
            end
       
     --  Msg(root)
          item0 =  reaper.GetSelectedMediaItem(0,0)
                    length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
                   reaper.SetMediaItemInfo_Value( item0, "D_LENGTH", length/2 ) 
          item1 =  reaper.GetSelectedMediaItem(0,1)
                   reaper.SetMediaItemInfo_Value( item1, "B_UISEL",0)
                   reaper.Main_OnCommand(41295,0) -- duplicate item
            
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
          itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES", moll_sub_dom.."m", true)
      end
   
 
  
main() 


end



--====================================================================
--================ CT _ create_parallel ===================================
--====================================================================

function create_parallel()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end



function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 1 then return end
             if sel_item == nil then return end  
             
               item0 =  reaper.GetSelectedMediaItem(0,0)
             
  
      get_chord_notes(item0)
      
               if chord == "" or chord == "maj" or chord == "maj7" or chord == "Maj" or chord == "m" or chord == "m7" or chord == "-" or chord == "-7" then 
      
                if chord == "" or chord == "maj" or chord == "maj7" or chord == "Maj" then pa_chord = "m" 
         
                if root == "C"  then parallel = "A"
            elseif root == "C#" then parallel = "A#"
            elseif root == "Db" then parallel = "Cb"
            elseif root == "D"  then parallel = "B"
            elseif root == "D#" then parallel = "B#"
            elseif root == "Eb" then parallel = "C"
            elseif root == "E"  then parallel = "C#"
            elseif root == "F"  then parallel = "D"
            elseif root == "F#" then parallel = "D#"
            elseif root == "Gb" then parallel = "Eb"
            elseif root == "G"  then parallel = "E"
            elseif root == "G#" then parallel = "E#"
            elseif root == "Ab" then parallel = "F"
            elseif root == "A"  then parallel = "F#"
            elseif root == "A#" then parallel = "G"
            elseif root == "Bb" then parallel = "G"
            elseif root == "B"  then parallel = "G#"
            if not root then end
            end
            end
            
            if chord == "m" or chord == "m7" or chord == "-" or chord == "-7" then pa_chord = "" 
                     
                            if root == "A"  then parallel = "C"
                        elseif root == "A#" then parallel = "C#"
                        elseif root == "Cb" then parallel = "Db"
                        elseif root == "B"  then parallel = "D"
                        elseif root == "B#" then parallel = "D#"
                        elseif root == "C"  then parallel = "Eb"
                        elseif root == "C#" then parallel = "E"
                        elseif root == "D"  then parallel = "F"
                        elseif root == "D#" then parallel = "F#"
                        elseif root == "Eb" then parallel = "Gb"
                        elseif root == "E"  then parallel = "G"
                        elseif root == "E#" then parallel = "G#"
                        elseif root == "F" then parallel = "Ab"
                        elseif root == "F#"  then parallel = "A"
                        elseif root == "G" then parallel = "Bb"
                        elseif root == "G#"  then parallel = "B"
                        if not root then end
                        end
                        end
       
        
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
         itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES",parallel..pa_chord, true)
      reaper.UpdateArrange()
  
else return end    
end


main() 

end

--====================================================================
--================ CT _ sudden dominant ===================================
--====================================================================

function sudden_dominant()
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n") 
  
end



function get_chord_notes(item0) 
       if item0 == nil then return end      
    _, item_notes = reaper.GetSetMediaItemInfo_String(item0, "P_NOTES", "", false) 
  if string.match( item_notes, "@.*") then next_region() end -- skip region marked @ ignore     
   if string.find(item_notes, "/") then
      root, chord, slash = string.match(item_notes, "(%w[#b]?)(.*)(/%a[#b]?)$")
   else
      root, chord = string.match(item_notes, "(%w[#b]?)(.*)$") slashnote = 0 slash = ""
   end
     
     if not chord or #chord == 0 then chord = "Maj" end
     if not slash then slash = "" end

  note1 = 0
  -- 60 = C3
  if root == "C" then note1 = 0
  elseif root == "C#" then note1 = 1
  elseif root == "Db" then note1 = 1
  elseif root == "D"  then note1 = 2
  elseif root == "D#" then note1 = 3
  elseif root == "Eb" then note1 = 3
  elseif root == "E"  then note1 = 4
  elseif root == "F"  then note1 = -7
  elseif root == "F#" then note1 = -6
  elseif root == "Gb" then note1 = -6
  elseif root == "G"  then note1 = -5
  elseif root == "G#" then note1 = -4
  elseif root == "Ab" then note1 = -4
  elseif root == "A"  then note1 = -3
  elseif root == "A#" then note1 = -2
  elseif root == "Bb" then note1 = -2
  elseif root == "B"  then note1 = -1
  if not root then end
  end
  
  slashnote = 255
  -- 48 = C2

  if slash == "/C" then slashnote = -12
  elseif slash == "/C#" then slashnote = -11
  elseif slash == "/Db" then slashnote = -11
  elseif slash == "/D" then slashnote = -10
  elseif slash == "/D#" then slashnote = -9
  elseif slash == "/Eb" then slashnote = -9
  elseif slash == "/E" then slashnote = -8
  elseif slash == "/F" then slashnote = -7
  elseif slash == "/F#" then slashnote = -6
  elseif slash == "/Gb" then slashnote = -6
  elseif slash == "/G" then slashnote = -5
  elseif slash == "/G#" then slashnote = -4
  elseif slash == "/Ab" then slashnote = -4
  elseif slash == "/A" then slashnote = -3
  elseif slash == "/A#" then slashnote = -2
  elseif slash == "/Bb" then slashnote = -2
  elseif slash == "/B" then slashnote = -1
  if not slash then slashnote = 255 end
  end

  note2 = 255
  note3 = 255
  note4 = 255
  note5 = 12
  note6 = 12
  note7 = 12

    if string.find(",Maj,maj7,", ","..chord..",", 1, true) then note2=4  note3=7 note4=12 end      
    if string.find(",m,min,-,", ","..chord..",", 1, true) then note2=3  note3=7 note4=12 end      
    if string.find(",dim,m-5,mb5,m(b5),0,", ","..chord..",", 1, true) then note2=3  note3=6 note4=12 end   
    if string.find(",aug,+,+5,(#5),", ","..chord..",", 1, true) then note2=4  note3=8 end   
    if string.find(",-5,(b5),", ","..chord..",", 1, true) then note2=4  note3=6 end   
    if string.find(",sus2,", ","..chord..",", 1, true) then note2=2  note3=7 end   
    if string.find(",sus4,sus,(sus4),", ","..chord..",", 1, true) then note2=5  note3=7 end   
    if string.find(",5,", ","..chord..",", 1, true) then note2=7 note3=12 end   
    if string.find(",5add7,5/7,", ","..chord..",", 1, true) then note2=7  note3=10 note4=10 end   
    if string.find(",add2,(add2),", ","..chord..",", 1, true) then note2=2  note3=4  note4=7 end   
    if string.find(",add4,(add4),", ","..chord..",", 1, true) then note2=4  note3=5  note4=7 end   
    if string.find(",madd4,m(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7 end   
    if string.find(",11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",11sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",m11,min11,-11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17 end  
    if string.find(",Maj11,maj11,M11,Maj7(add11),M7(add11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=17 end     
    if string.find(",mMaj11,minmaj11,mM11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17 end  
    if string.find(",aug11,9+11,9aug11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",augm11, m9#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",11b5,11-5,11(b5),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",11#5,11+5,11(#5),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",11b9,11-9,11(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",11#9,11+9,11(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",11b5b9,11-5-9,11(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17 end  
    if string.find(",11#5b9,11+5-9,11(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17 end  
    if string.find(",11b5#9,11-5+9,11(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17 end  
    if string.find(",11#5#9,11+5+9,11(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5,m11-5,m11(b5),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17 end  
    if string.find(",m11#5,m11+5,m11(#5),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17 end  
    if string.find(",m11b9,m11-9,m11(b9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17 end  
    if string.find(",m11#9,m11+9,m11(#9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17 end  
    if string.find(",m11b5b9,m11-5-9,m11(b5b9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17 end
    if string.find(",m11#5b9,m11+5-9,m11(#5b9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17 end
    if string.find(",m11b5#9,m11-5+9,m11(b5#9),", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17 end
    if string.find(",m11#5#9,m11+5+9,m11(#5#9),", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17 end
    if string.find(",Maj11b5,maj11b5,maj11-5,maj11(b5),", ","..chord..",", 1, true)    then note2=4  note3=6  note4=11  note5=14  note6=17 end
    if string.find(",Maj11#5,maj11#5,maj11+5,maj11(#5),", ","..chord..",", 1, true)    then note2=4  note3=8  note4=11  note5=14  note6=17 end
    if string.find(",Maj11b9,maj11b9,maj11-9,maj11(b9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#9,maj11#9,maj11+9,maj11(#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15  note6=17 end
    if string.find(",Maj11b5b9,maj11b5b9,maj11-5-9,maj11(b5b9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=13  note6=17 end
    if string.find(",Maj11#5b9,maj11#5b9,maj11+5-9,maj11(#5b9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=13  note6=17 end
    if string.find(",Maj11b5#9,maj11b5#9,maj11-5+9,maj11(b5#9),", ","..chord..",", 1, true)   then note2=4  note3=6  note4=11  note5=15  note6=17 end
    if string.find(",Maj11#5#9,maj11#5#9,maj11+5+9,maj11(#5#9),", ","..chord..",", 1, true)   then note2=4  note3=8  note4=11  note5=15  note6=17 end
    if string.find(",13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13,min13,-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13,maj13,M13,Maj7(add13),M7(add13),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",mMaj13,minmaj13,mM13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",13b5,13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13#5,13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13b9,13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#9,13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13b5b9,13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13#5b9,13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13b5#9,13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13#5#9,13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13b9#11,13-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",m13b5,m13-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13#5,m13+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",m13b9,m13-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#9,m13+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13b5b9,m13-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13#5b9,m13+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",m13b5#9,m13-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",m13#5#9,m13+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5,maj13b5,maj13-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13#5,maj13#5,maj13+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14  note6=17  note7=21 end  
    if string.find(",Maj13b9,maj13b9,maj13-9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#9,maj13#9,maj13+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13b5b9,maj13b5b9,maj13-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13#5b9,maj13#5b9,maj13+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13  note6=17  note7=21 end  
    if string.find(",Maj13b5#9,maj13b5#9,maj13-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#5#9,maj13#5#9,maj13+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15  note6=17  note7=21 end  
    if string.find(",Maj13#11,maj13#11,maj13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18  note7=21 end  
    if string.find(",13#11,13+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",m13#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",6,M6,Maj6,maj6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9 end   
    if string.find(",m6,min6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9 end   
    if string.find(",6add4,6/4,6(add4),Maj6(add4),M6(add4),", ","..chord..",", 1, true)    then note2=4  note3=5  note4=7  note5=9 end   
    if string.find(",m6add4,m6/4,m6(add4),", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=9 end   
    if string.find(",69,6add9,6/9,6(add9),Maj6(add9),M6(add9),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=14 end  
    if string.find(",m6add9,m6/9,m6(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",6sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=9 end   
    if string.find(",6sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=9 end   
    if string.find(",6add11,6/11,6(add11),Maj6(add11),M6(add11),", ","..chord..",", 1, true)   then note2=4  note3=7  note4=9  note5=17 end  
    if string.find(",m6add11,m6/11,m6(add11),m6(add11),", ","..chord..",", 1, true)    then note2=3  note3=7  note4=9  note5=17 end  
    if string.find(",7,dom,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=12 note6=16 note7=19 end   
    if string.find(",7add2,", ","..chord..",", 1, true) then note2=2  note3=4  note4=7  note5=10 end  
    if string.find(",7add4,", ","..chord..",", 1, true) then note2=4  note3=5  note4=7  note5=10 end  
    if string.find(",m7,min7,-7,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10 note5=12 note6=15 note7=19 end  
    if string.find(",m7add4,", ","..chord..",", 1, true) then note2=3  note3=5  note4=7  note5=10 end  
    if string.find(",Maj7,maj7,Maj7,M7,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11 end   
    if string.find(",dim7,07,", ","..chord..",", 1, true) then note2=3  note3=6  note4=9 end   
    if string.find(",mMaj7,minmaj7,mmaj7,min/maj7,mM7,m(addM7),m(+7),-(M7),m(maj7),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11 end    
    if string.find(",7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=10 end   
    if string.find(",7sus4,7sus,7sus11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10 end   
    if string.find(",Maj7sus2,maj7sus2,M7sus2,", ","..chord..",", 1, true) then note2=2  note3=7  note4=11 end    
    if string.find(",Maj7sus4,maj7sus4,M7sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11 end    
    if string.find(",aug7,+7,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",7b5,7-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 end   
    if string.find(",7#5,7+5,7+,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10 end   
    if string.find(",m7b5,m7-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10 end   
    if string.find(",m7#5,m7+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10 end   
    if string.find(",Maj7b5,maj7b5,maj7-5,M7b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11 end   
    if string.find(",Maj7#5,maj7#5,maj7+5,M7+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11 end   
    if string.find(",7b9,7-9,7(addb9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13 end  
    if string.find(",7#9,7+9,7(add#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",m7b9, m7-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13 end  
    if string.find(",m7#9, m7+9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15 end  
    if string.find(",Maj7b9,maj7b9,maj7-9,maj7(addb9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=13 end 
    if string.find(",Maj7#9,maj7#9,maj7+9,maj7(add#9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=15 end 
    if string.find(",7b9b13,7-9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",m7b9b13, m7-9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=13  note6=20 end
    if string.find(",7b13,7-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",m7b13,m7-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",7#9b13,7+9-13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",m7#9b13,m7+9-13,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7b5b9,7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=13 end  
    if string.find(",7b5#9,7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15 end  
    if string.find(",7#5b9,7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13 end  
    if string.find(",7#5#9,7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18 end  
    if string.find(",7add6,7/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10 end  
    if string.find(",7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=17 end  
    if string.find(",7add13,7/13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=21 end  
    if string.find(",m7add11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=17 end  
    if string.find(",m7b5b9,m7-5-9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=13 end  
    if string.find(",m7b5#9,m7-5+9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=15 end  
    if string.find(",m7#5b9,m7+5-9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=13 end  
    if string.find(",m7#5#9,m7+5+9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=15 end  
    if string.find(",m7#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=18 end  
    if string.find(",Maj7b5b9,maj7b5b9,maj7-5-9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=13 end 
    if string.find(",Maj7b5#9,maj7b5#9,maj7-5+9,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=15 end 
    if string.find(",Maj7#5b9,maj7#5b9,maj7+5-9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=13 end 
    if string.find(",Maj7#5#9,maj7#5#9,maj7+5+9,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=15 end 
    if string.find(",Maj7add11,maj7add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=17 end  
    if string.find(",Maj7#11,maj7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=18 end  
    if string.find(",9,7(add9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=16  note7=19 end
    if string.find(",m9,min9,-9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=10  note5=14 end  
    if string.find(",Maj9,maj9,M9,Maj7(add9),M7(add9),", ","..chord..",", 1, true)    then note2=4  note3=7  note4=11  note5=14 end 
    if string.find(",Maj9sus4,maj9sus4,", ","..chord..",", 1, true) then note2=5  note3=7  note4=11  note5=14 end  
    if string.find(",mMaj9,minmaj9,mmaj9,min/maj9,mM9,m(addM9),m(+9),-(M9),", ","..chord..",", 1, true)  then note2=3  note3=7  note4=11  note5=14 end 
    if string.find(",9sus4,9sus,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 end  
    if string.find(",aug9,+9,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15 end  
    if string.find(",9add6,9/6,", ","..chord..",", 1, true) then note2=4  note3=7  note4=9  note5=10  note6=14 end  
    if string.find(",m9add6,m9/6,", ","..chord..",", 1, true) then note2=3  note3=7  note4=9  note5=14 end  
    if string.find(",9b5,9-5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14 end  
    if string.find(",9#5,9+5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14 end  
    if string.find(",m9b5,m9-5,", ","..chord..",", 1, true) then note2=3  note3=6  note4=10  note5=14 end  
    if string.find(",m9#5,m9+5,", ","..chord..",", 1, true) then note2=3  note3=8  note4=10  note5=14 end  
    if string.find(",Maj9b5,maj9b5,", ","..chord..",", 1, true) then note2=4  note3=6  note4=11  note5=14 end  
    if string.find(",Maj9#5,maj9#5,", ","..chord..",", 1, true) then note2=4  note3=8  note4=11  note5=14 end  
    if string.find(",Maj9#11,maj9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=11  note5=14  note6=18 end  
    if string.find(",b9#11,-9+11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",add9,2,", ","..chord..",", 1, true) then note2=4  note3=7  note4=14 end   
    if string.find(",madd9,m(add9),-(add9),", ","..chord..",", 1, true) then note2=3  note3=7  note4=14 end   
    if string.find(",add11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=17 end   
    if string.find(",madd11,m(add11),-(add11),", ","..chord..",", 1, true) then note2=3  note3=7  note4=17 end    
    if string.find(",(b9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=13 end   
    if string.find(",(#9),", ","..chord..",", 1, true) then note2=4  note3=7  note4=15 end   
    if string.find(",(b5b9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=13 end   
    if string.find(",(#5b9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=13 end   
    if string.find(",(b5#9),", ","..chord..",", 1, true) then note2=4  note3=6  note4=15 end   
    if string.find(",(#5#9),", ","..chord..",", 1, true) then note2=4  note3=8  note4=15 end   
    if string.find(",m(b9), mb9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=13 end   
    if string.find(",m(#9), m#9,", ","..chord..",", 1, true) then note2=3  note3=7  note4=15 end   
    if string.find(",m(b5b9), mb5b9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=13 end   
    if string.find(",m(#5b9), m#5b9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=13 end   
    if string.find(",m(b5#9), mb5#9,", ","..chord..",", 1, true) then note2=3  note3=6  note4=15 end   
    if string.find(",m(#5#9), m#5#9,", ","..chord..",", 1, true) then note2=3  note3=8  note4=15 end   
    if string.find(",m(#11), m#11,", ","..chord..",", 1, true) then note2=3  note3=7  note4=18 end   
    if string.find(",(#11),", ","..chord..",", 1, true) then note2=4  note3=7  note4=18 end   
    if string.find(",m#5,", ","..chord..",", 1, true) then note2=3  note3=8 end   
    if string.find(",maug,augaddm3,augadd(m3),", ","..chord..",", 1, true) then note2=3  note3=7 note4=8 end  
    if string.find(",13#9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",13susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=17  note7=21 end  
    if string.find(",13susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=21 end  
    if string.find(",13susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=17  note6=21 end  
    if string.find(",13sus#5b9,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=17  note7=21 end  
    if string.find(",13sus#5b9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=13  note6=18  note7=21 end  
    if string.find(",13sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",13sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end
    if string.find(",13sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=17  note7=21 end  
    if string.find(",13sus#9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=21 end  
    if string.find(",13sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14  note6=18  note7=21 end  
    if string.find(",7b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10 note5=17  note6=20 end   
    if string.find(",7b5#9b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=18 end  
    if string.find(",7#5#9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7#5b9#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=13  note6=18 end  
    if string.find(",7#9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=15  note6=18 note7=20 end  
    if string.find(",7#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10 note5=18 end   
    if string.find(",7#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",7susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10 end   
    if string.find(",7susb5b9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13 end  
    if string.find(",7b5b9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=13  note6=20 end  
    if string.find(",7susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",7susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15 end  
    if string.find(",7susb5#9b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=15  note6=20 end  
    if string.find(",7susb9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13 end  
    if string.find(",7susb9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=20 end  
    if string.find(",7susb9#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18 end  
    if string.find(",7susb9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=13  note6=18  note7=20 end  
    if string.find(",7susb13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=20 end  
    if string.find(",7sus#5,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10 end   
    if string.find(",7sus#5#9#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=15  note6=18 end  
    if string.find(",7sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=18 end  
    if string.find(",7sus#9,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15 end  
    if string.find(",7sus#9b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=20 end  
    if string.find(",7sus#9#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=15  note6=18  note7=20 end  
    if string.find(",7sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18 end  
    if string.find(",7sus#11b13,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=18  note6=20 end  
    if string.find(",9b5b13,", ","..chord..",", 1, true) then note2=4  note3=6  note4=10  note5=14  note6=20 end  
    if string.find(",9b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=20 end  
    if string.find(",9#5#11,", ","..chord..",", 1, true) then note2=4  note3=8  note4=10  note5=14  note6=18 end  
    if string.find(",9#11,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18 end  
    if string.find(",9#11b13,", ","..chord..",", 1, true) then note2=4  note3=7  note4=10  note5=14  note6=18  note7=20 end  
    if string.find(",9susb5,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  end  
    if string.find(",9susb5b13,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14 note6=20 end  
    if string.find(",9sus#11,", ","..chord..",", 1, true) then note2=5  note3=7  note4=10  note5=14 note6=18 end  
    if string.find(",9susb5#9,", ","..chord..",", 1, true) then note2=5  note3=6  note4=10  note5=14  note6=15 end  
    if string.find(",9sus#5#11,", ","..chord..",", 1, true) then note2=5  note3=8  note4=10  note5=14  note6=18 end   
    if string.find(",quartal,", ","..chord..",", 1, true) then note2=5  note3=10  note4=15 end
    if string.find(",sowhat,", ","..chord..",", 1, true) then note2=5  note3=10  note4=16 end     

  
end


--MAIN---------------------------------------------------------------
function main()
       
             sel_item = reaper.CountSelectedMediaItems(0)
             
             if sel_item ~= 2 then return end
           
           if sel_item == nil then return end  
               item1 = reaper.GetSelectedMediaItem(0,1) 
               item0 =  reaper.GetSelectedMediaItem(0,0)
               length = reaper.GetMediaItemInfo_Value( item0, "D_LENGTH" )
               reaper.SetMediaItemInfo_Value( item0, "D_LENGTH", length/2 )
 
     -- get_chord_notes(item0) 
      get_chord_notes(item1)
      
          
          
      
         item1 =  reaper.GetSelectedMediaItem(0,1)
         reaper.SetMediaItemInfo_Value( item1, "B_UISEL",0)
         reaper.Main_OnCommand(41295,0) -- duplicate item
         
                if root == "C"  then root_dominant = "G"
            elseif root == "C#" then root_dominant = "G#"
            elseif root == "Db" then root_dominant = "Ab"
            elseif root == "D"  then root_dominant = "A"
            elseif root == "D#" then root_dominant = "A#"
            elseif root == "Eb" then root_dominant = "Bb"
            elseif root == "E"  then root_dominant = "B"
            elseif root == "F"  then root_dominant = "C"
            elseif root == "F#" then root_dominant = "C#"
            elseif root == "Gb" then root_dominant = "Db"
            elseif root == "G"  then root_dominant = "D"
            elseif root == "G#" then root_dominant = "D#"
            elseif root == "Ab" then root_dominant = "Eb"
            elseif root == "A"  then root_dominant = "E"
            elseif root == "A#" then root_dominant = "E#"
            elseif root == "Bb" then root_dominant = "F"
            elseif root == "B"  then root_dominant = "F#"
            if not root then end
            end
       
        
               
          sel_itemx = reaper.CountSelectedMediaItems(0)
          itemx = reaper.GetSelectedMediaItem(0,0)
          
      reaper.GetSetMediaItemInfo_String(itemx, "P_NOTES", root_dominant.."7", true)
      end

  
main() 

end
--==================================================================================================================
--================== BIAB SONG IMPORT ============================================================================
--=============================================================================================================
function import_biab_song()

function print(value)
  
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
  
end


rootNames = { "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B", "C#", "D#", "F#", "G#", "A#" }

--pad the rest of rootNames with ? for unknown types
for j = 18,26 do 
  rootNames[j] = "?"
end
--add in any unusual chord types

rootNames[27] ="Ab/A"
rootNames[28] ="A/Bb"
rootNames[29] ="Bb/B"
rootNames[30] ="B/C"
rootNames[31] ="C#/Db"
rootNames[32] ="D#/D"
rootNames[33] ="F#/Eb"
rootNames[34] ="G#/E"
rootNames[35] ="A#/F"
rootNames[36] ="A#/Db"
rootNames[37] ="C/D"
rootNames[38] ="Db/Eb"
rootNames[39] ="D/E"
rootNames[40] ="Eb/F"
rootNames[41] ="E/Gb"
rootNames[42] ="F/G"
rootNames[43] ="Gb/Ab"
rootNames[44] ="G/A"
rootNames[45] ="Ab/Bb"
rootNames[46] ="A/B"
rootNames[47] ="Bb/C"
rootNames[48] ="B/Db"
rootNames[49] ="C#/D"
rootNames[50] ="D#/Eb"
rootNames[51] ="F#/E"
rootNames[52] ="G#/F"
rootNames[53] ="A#/Gb"
rootNames[54] ="A#/D"
rootNames[55] ="C/Eb"
rootNames[56] ="Db/E"
rootNames[57] ="D/F"
rootNames[58] ="Eb/Gb"
rootNames[59] ="E/G"
rootNames[60] ="F/Ab"
rootNames[61] ="Gb/A"
rootNames[62] ="G/Bb"
rootNames[63] ="Ab/B"
rootNames[64] ="A/C"
rootNames[65] ="Bb/Db"
rootNames[66] ="B/D"
rootNames[67] ="C#/Eb"
rootNames[68] ="D#/E"
rootNames[69] ="F#/F"
rootNames[70] ="G#/Gb"
rootNames[71] ="A#/G"
rootNames[72] ="A#/Eb"
rootNames[73] ="C/E"
rootNames[74] ="Db/F"
rootNames[75] ="D/Gb"
rootNames[76] ="Eb/G"
rootNames[77] ="E/Ab"
rootNames[78] ="F/A"
rootNames[79] ="Gb/Bb"
rootNames[80] ="G/B"
rootNames[81] ="Ab/C"
rootNames[82] ="A/Db"
rootNames[83] ="Bb/D"
rootNames[84] ="B/Eb"
rootNames[85] ="C#/E"
rootNames[86] ="D#/F"
rootNames[87] ="F#/Gb"
rootNames[88] ="G#/G"
rootNames[89] ="A#/Ab"
rootNames[90] ="A#/E"
rootNames[91] ="C/F"
rootNames[92] ="Db/Gb"
rootNames[93] ="D/G"
rootNames[94] ="Eb/Ab"
rootNames[95] ="E/A"
rootNames[96] ="F/Bb"
rootNames[97] ="Gb/B"
rootNames[98] ="G/C"
rootNames[99] ="Ab/Db"
rootNames[100] ="A/D"
rootNames[101] ="Bb/Eb"
rootNames[102] ="B/E"
rootNames[103] ="C#/F"
rootNames[104] ="D#/Gb"
rootNames[105] ="F#/G"
rootNames[106] ="G#/Ab"
rootNames[107] ="A#/A"
rootNames[108] ="A#/F"
rootNames[109] ="C/Gb"
rootNames[110] ="Db/G"
rootNames[111] ="D/Ab"
rootNames[112] ="Eb/A"
rootNames[113] ="E/Bb"
rootNames[114] ="F/B"
rootNames[115] ="Gb/C"
rootNames[116] ="G/Db"
rootNames[117] ="Ab/D"
rootNames[118] ="A/Eb"
rootNames[119] ="Bb/E"
rootNames[120] ="B/F"
rootNames[121] ="C#/Gb"
rootNames[122] ="D#/G"
rootNames[123] ="F#/Ab"
rootNames[124] ="G#/A"
rootNames[125] ="A#/Bb"
rootNames[126] ="A#/Gb"
rootNames[127] ="C/G"
rootNames[128] ="Db/Ab"
rootNames[129] ="D/A"
rootNames[130] ="Eb/Bb"
rootNames[131] ="E/B"
rootNames[132] ="F/C"
rootNames[133] ="Gb/Db"
rootNames[134] ="G/D"
rootNames[135] ="Ab/Eb"
rootNames[136] ="A/E"
rootNames[137] ="Bb/F"
rootNames[138] ="B/Gb"
rootNames[139] ="C#/G"
rootNames[140] ="D#/Ab"
rootNames[141] ="F#/A"
rootNames[142] ="G#/Bb"
rootNames[143] ="A#/B"
rootNames[144] ="A#/G"
rootNames[145] ="C/Ab"
rootNames[146] ="Db/A"
rootNames[147] ="D/Bb"
rootNames[148] ="Eb/B"
rootNames[149] ="E/C"
rootNames[150] ="F/Db"
rootNames[151] ="Gb/D"
rootNames[152] ="G/Eb"
rootNames[153] ="Ab/E"
rootNames[154] ="A/F"
rootNames[155] ="Bb/Gb"
rootNames[156] ="B/G"
rootNames[157] ="C#/Ab"
rootNames[158] ="D#/A"
rootNames[159] ="F#/Bb"
rootNames[160] ="G#/B"
rootNames[161] ="A#/C"
rootNames[162] ="A#/Ab"
rootNames[163] ="C/A"
rootNames[164] ="Db/Bb"
rootNames[165] ="D/B"
rootNames[166] ="Eb/C"
rootNames[167] ="E/Db"
rootNames[168] ="F/D"
rootNames[169] ="Gb/Eb"
rootNames[170] ="G/E"
rootNames[171] ="Ab/F"
rootNames[172] ="A/Gb"
rootNames[173] ="Bb/G"
rootNames[174] ="B/Ab"
rootNames[175] ="C#/A"
rootNames[176] ="D#/Bb"
rootNames[177] ="F#/B"
rootNames[178] ="G#/C"
rootNames[179] ="A#/Db"
rootNames[180] ="A#/A"
rootNames[181] ="C/Bb"
rootNames[182] ="Db/B"
rootNames[183] ="D/C"
rootNames[184] ="Eb/Db"
rootNames[185] ="E/D"
rootNames[186] ="F/Eb"
rootNames[187] ="Gb/E"
rootNames[188] ="G/F"
rootNames[189] ="Ab/Gb"
rootNames[190] ="A/G"
rootNames[191] ="Bb/Ab"
rootNames[192] ="B/A"
rootNames[193] ="C#/Bb"
rootNames[194] ="D#/B"
rootNames[195] ="F#/C"
rootNames[196] ="G#/Db"
rootNames[197] ="A#/D"
rootNames[198] ="A#/Bb"
rootNames[199] ="C/B"
rootNames[200] ="Db/C"
rootNames[201] ="D/Db"
rootNames[202] ="Eb/D"
rootNames[203] ="E/Eb"
rootNames[204] ="F/E"
rootNames[205] ="Gb/F"
rootNames[206] ="G/Gb"
rootNames[207] ="Ab/G"
rootNames[208] ="A/Ab"
rootNames[209] ="Bb/A"
rootNames[210] ="B/Bb"
rootNames[211] ="C#/B"
rootNames[212] ="D#/C"
rootNames[213] ="F#/Db"
rootNames[214] ="G#/D"
rootNames[215] ="A#/Eb"
rootNames[216] ="A#/B"

--pad the rest of unknown types with ?
for j = 217,255 do 
  rootNames[j] = "?"
end

typeNames = {
  "",  -- 1 
  "Maj",  -- 2 
  "b5",  -- 3 
  "aug",  -- 4 
  "6",  -- 5 
  "Maj7",  -- 6 
  "Maj9",  -- 7 
  "Maj9#11",  -- 8 
  "Maj13#11",  -- 9 
  "Maj13",  -- 10 
  "Maj9(no 3)",  -- 11 
  "+",  -- 12 
  "Maj7#5",  -- 13 
  "69",  -- 14 
  "2",  -- 15 
  "m",  -- 16 
  "maug",  -- 17 
  "mMaj7",  -- 18 
  "m7",  -- 19 
  "m9",  -- 20 
  "m11",  -- 21 
  "m13",  -- 22 
  "m6",  -- 23 
  "m#5",  -- 24 
  "m7#5",  -- 25 
  "?",  -- 26 
  "?",  -- 27 
  "?",  -- 28 
  "?",  -- 29 
  "?",  -- 30 
  "?",  -- 31 
  "m7b5",  -- 32 
  "dim",  -- 33 
  "?",  -- 34 
  "?",  -- 35 
  "?",  -- 36 
  "?",  -- 37 
  "?",  -- 38 
  "?",  -- 39 
  "5",  -- 40 
  "?",  -- 41 
  "?",  -- 42 
  "?",  -- 43 
  "?",  -- 44 
  "?",  -- 45 
  "?",  -- 46 
  "?",  -- 47 
  "?",  -- 48 
  "?",  -- 49 
  "?",  -- 50 
  "?",  -- 51 
  "?",  -- 52 
  "?",  -- 53 
  "?",  -- 54 
  "?",  -- 55 
  "7+",  -- 56 
  "9+",  -- 57 
  "13+",  -- 58 
  "?",  -- 59 
  "?",  -- 60 
  "?",  -- 61 
  "?",  -- 62 
  "?",  -- 63 
  "7",  -- 64 
  "13",  -- 65 
  "7b13",  -- 66 
  "7#11",  -- 67 
  "13#11",  -- 68 
  "7#11b13",  -- 69 
  "9",  -- 70 
  "?",  -- 71 
  "9b13",  -- 72 
  "9#11",  -- 73 
  "13#11",  -- 74 
  "9#11b13",  -- 75 
  "7b9",  -- 76 
  "13b9",  -- 77 
  "7b9b13",  -- 78 
  "7b9#11",  -- 79 
  "13b9#11",  -- 80 
  "7b9#11b13",  -- 81 
  "7#9",  -- 82 
  "13#9",  -- 83 
  "7#9b13",  -- 84 
  "9#11",  -- 85 
  "13#9#11",  -- 86 
  "7#9#11b13",  -- 87 
  "7b5",  -- 88 
  "13b5",  -- 89 
  "7b5b13",  -- 90 
  "9b5",  -- 91 
  "9b5b13",  -- 92 
  "7b5b9",  -- 93 
  "13b5b9",  -- 94 
  "7b5b9b13",  -- 95 
  "7b5#9",  -- 96 
  "13b5#9",  -- 97 
  "7b5#9b13",  -- 98 
  "7#5",  -- 99 
  "13#5",  -- 100 
  "7#5#11",  -- 101 
  "13#5#11",  -- 102 
  "9#5",  -- 103 
  "9#5#11",  -- 104 
  "7#5b9",  -- 105 
  "13#5b9",  -- 106 
  "7#5b9#11",  -- 107 
  "13#5b9#11",  -- 108 
  "7#5#9",  -- 109 
  "13#5#9#11",  -- 110 
  "7#5#9#11",  -- 111 
  "13#5#9#11",  -- 112 
  "7alt",  -- 113 
  "?",  -- 114 
  "?",  -- 115 
  "?",  -- 116 
  "?",  -- 117 
  "?",  -- 118 
  "?",  -- 119 
  "?",  -- 120 
  "?",  -- 121 
  "?",  -- 122 
  "?",  -- 123 
  "?",  -- 124 
  "?",  -- 125 
  "?",  -- 126 
  "?",  -- 127 
  "7sus",  -- 128 
  "13sus",  -- 129 
  "7susb13",  -- 130 
  "7sus#11",  -- 131 
  "13sus#11",  -- 132 
  "7sus#11b13",  -- 133 
  "9sus",  -- 134 
  "?",  -- 135 
  "9susb13",  -- 136 
  "9sus#11",  -- 137 
  "13sus#11",  -- 138 
  "9sus#11b13",  -- 139 
  "7susb9",  -- 140 
  "13susb9",  -- 141 
  "7susb913",  -- 142 
  "7susb9#11",  -- 143 
  "13susb9#11",  -- 144 
  "7susb9#11b13",  -- 145 
  "7sus#9",  -- 146 
  "13sus#9",  -- 147 
  "7sus#9b13",  -- 148 
  "9sus#11",  -- 149 
  "13sus#9#11",  -- 150 
  "7sus#9#11b13",  -- 151 
  "7susb5",  -- 152 
  "13susb5",  -- 153 
  "7susb5b13",  -- 154 
  "9susb5",  -- 155 
  "9susb5b13",  -- 156 
  "7susb5b9",  -- 157 
  "13susb5b9",  -- 158 
  "7susb5b9b13",  -- 159 
  "7susb5#9",  -- 160 
  "13susb5#9",  -- 161 
  "7susb5#9b13",  -- 162 
  "7sus#5",  -- 163 
  "13sus#5",  -- 164 
  "7sus#5#11",  -- 165 
  "13sus#5#11",  -- 166 
  "9sus#5",  -- 167 
  "9sus#5#11",  -- 168 
  "7sus#5b9",  -- 169 
  "13sus#5b9",  -- 170 
  "7sus#5b9#11",  -- 171 
  "13sus#5b9#11",  -- 172 
  "7sus#5#9",  -- 173 
  "13sus#5#9#11",  -- 174 
  "7sus#5#9#11",  -- 175 
  "13sus#5#9#11",  -- 176 
  "4",  -- 177 
  "?",  -- 178 
  "?",  -- 179 
  "?",  -- 180 
  "?",  -- 181 
  "?",  -- 182 
  "?",  -- 183 
  "sus"}  -- 184 


function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


function round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end





function GetFilename(path)   
    local start, finish = path:find('[%w%s!-={-|]+[_%.].+')   
    return path:sub(start,#path) 
end 

function chords_34()
    retval, filetxt = reaper.GetUserFileNameForRead("", "Import Chords from SGU,MGU...", "")
    
    --print(GetFilename(filetxt))
    
    f = assert(io.open(filetxt, "rb"))
    
    local first_byte_sig = f:read(1)
    local name_bytes = f:read(1)
    --print("First byte = "..tostring(first_byte_sig))
    name_len = string.byte(name_bytes)
    --print("Name_length =" ..name_len)
    local bytes = f:read(name_len)
    --print("Name: "..tostring(bytes))
    local meter_denominator = 4
    --print("Meter: "..tostring(4).."/"..tostring(meter_denominator))
    local byte1 = string.byte(f:read(1))
    local byte2 = string.byte(f:read(1))
    local byte3 = string.byte(f:read(1))
    local keyByte = string.byte(f:read(1)) --read 
    local tempoByte = string.byte(f:read(1)) --read tempo byte
    
    if keyByte <= 17 then
      key = rootNames[keyByte]
      isMinor = false 
    else key = rootNames[keyByte - 17]
      isMinor = true
    end
    if isMinor then
      --print("Key : " ..key.. "m")
    else --print("Key: " ..key)
    end
    --print("Tempo: " ..tempoByte)
    reaper.Main_OnCommand( 40042, 0 ) -- Transport: Go to start of project
    reaper.SetCurrentBPM( 0, tempoByte, 0 ) -- 0 no undo points 1 undo points
    
    
    reaper.SetTempoTimeSigMarker( 0, -1, 0, -1, -1, -1, 3, 4, false )
    
    local bar = string.byte(f:read(1)) --read start bar number
    --print("Start bar: " ..bar)
    
    local types = {}
    local roots = {}
    local beats = {}
    local partm = {}
    numberOfChords = 1

-- count through the bars and bar types to find section boundaries
    
    while bar < 255 do -- maximum of 255 bars
      local barType = string.byte(f:read(1)) --read bar type
      
      if barType == 0 then
        duration = string.byte(f:read(1))
        bar = bar + duration
      else bar = bar + 1
      end
    

      partm[bar] = barType
       
    end
    
    total_bars = bar - duration -1
    --print("Total number of bars =" ..total_bars)
-- count through the chord type/duration section recording the beat count where chord changes occur in table beats[] and the chord type in types[] 
    local beat = 1 --start at beat 1
    while beat < 1020 do --maximum of 1020 beats (= 255 bars x 4 beats)
      local chordType = string.byte(f:read(1))
      if chordType == 0 then
        local duration = string.byte(f:read(1))
        beat = beat + duration
      else types[numberOfChords] = chordType
        --print("Chord change number "..tostring(numberOfChords).." to "..tostring(chordType).." ["..typeNames[chordType].."] at beat count "..tostring(beat))
        beats[numberOfChords] = beat
        numberOfChords = numberOfChords + 1
        last_beat = beat
        beat = beat + 1
      end
    end
  total_beats = last_beat - 1


  local i=1
  beat = 1 --start at beat 1
  
  while beat < 1020 do --maximum of 1020 beats
    
    local chordRoot = string.byte(f:read(1))
    if chordRoot == 0 then 
      local duration = string.byte(f:read(1))
      beat = beat + duration
    else roots[i] = chordRoot
      if beat ~= beats[i] then
        --print("Inconsistent chord type and root beat")
      end
      

      i = i + 1
      beat = beat + 1
    end
 
  end


  if i ~= numberOfChords then
    print("Inconsistent number of chord types and roots")
  end


  beats_no = (last_beat +15) / 4 * 3
  --print("Toatal 3/4 Beats ".. beats_no  )
  waltz_bars = 0
  
  
  chord_name = {}
  beat_count = {}
  part_marker = {}
  part_marker_beats = {}
  
  for i = 1, tablelength(roots)  do
  
    waltz_beats = ((beats[i] / 4) * 3) +.75 --+.25 
    beat_number = 1
    --print("waltz_beats ".. waltz_beats)
    
    
    waltz_bars = (waltz_beats / 3) + .66666666666667
    --if waltz_bars ~= math.floor(waltz_bars) then
      
      waltz_bars2 = round(waltz_bars,0)
      --print("waltz_bars ".. waltz_bars .." floor ".. waltz_bars2)
      if tostring(waltz_bars2) == tostring(waltz_bars) then
        beat_number = 1 --print("Is Equal")
      
      elseif waltz_bars2 < waltz_bars then
        beat_number = 2 --print("Is Less")
       
      elseif waltz_bars2 > waltz_bars then 
        beat_number = 3 --print("Is Greater")
      end 
     
     waltz_beats2 = math.floor(waltz_beats)
     
     
  --end
   --print("Beat ".. waltz_beats2 .." Bar ".. math.floor(waltz_bars) .."[" .. beat_number .."]".." " ..tostring(rootNames[roots[i]]) ..tostring(typeNames[types[i]]))
 
  --end
  

  
  
    --print("Beat ".. waltz_beats2 .." " ..tostring(rootNames[roots[i]]) ..tostring(typeNames[types[i]]))
    
    chord_name[i] = tostring(rootNames[roots[i]]) ..tostring(typeNames[types[i]])
    beat_count[i] = waltz_beats2
    
  
  end
  

  
  part_marker_count = 0
  for i = 2, total_bars +1 do --tablelength(roots) do --total_bars +1 do
    if partm[i] and partm[i] > 0 then
      --print("PartM ".. (i*3 )-5  .. " " ..tostring(partm[i]))
      part_marker[i] = tostring(partm[i])
      part_marker_beats[i] = (i*3 )-5
    end
    part_marker_count = part_marker_count +1
  end   
  
  for i = 1, part_marker_count +1 do
    if part_marker_beats[i] then
      --print("part_marker_beats ".. part_marker_beats[i] .." type ".. part_marker[i])
    --print("beat_count ".. beat_count[3] .." ".. chord_name[3])
  
    --print("Toatal Bars ".. total_bars+3)
    end
  end
  
  for i = 1, tablelength(roots) +1 do --total_bars +1 do
  
    --chord_name[i]
    --beat_count[i]
    
    for m = 1, part_marker_count +1 do
      if part_marker_beats[m] then
        --print("PM Color ".. beat_count[i] .." ".. part_marker_beats[m])
        if beat_count[i] == part_marker_beats[m] then
          --print("FOUND part_marker_beats ".. part_marker_beats[m])
          if part_marker[m] == "1" then
            --print("BLUE")
            color = reaper.ColorToNative(55,118,235)|0x1000000
          end
          if part_marker[m] == "2" then
            --print("GREEN")
            color = reaper.ColorToNative(17,174,59)|0x1000000
          end      
        end
      end  
      
    end  
    
    if beat_count[i] then
      --print("REG START beat_count[i] ".. beat_count[i] .." " ..tostring(rootNames[roots[i]]) ..tostring(typeNames[types[i]]))
      reg_start = reaper.TimeMap2_beatsToTime( 0, beat_count[i]+5 )
      reg_start = reaper.SnapToGrid( 0, reg_start )
      --print("TIME reg_start "..reg_start)
    end  
    --reg_start = reaper.SnapToGrid( 0, reg_start )
    --print("reg_start "..reg_start)
   
    -- ADD 2 bar for count-in
    if i < tablelength(roots) then
      --print("REG END beat_count[i] ".. beat_count[i+1])
      reg_end = reaper.TimeMap2_beatsToTime( 0, beat_count[i+1]+5 )
      reg_end = reaper.SnapToGrid( 0, reg_end )
      --print("TIME reg_end "..reg_end)
      reaper.AddProjectMarker2( 0, true, reg_start, reg_end, chord_name[i], 1, color )
    end
    if i == tablelength(roots) then
      ending_bars = reaper.TimeMap2_beatsToTime( 0, 12)
      ending_bars = reaper.SnapToGrid( 0, ending_bars )
      reaper.AddProjectMarker2( 0, true, reg_start, reg_start+ending_bars, chord_name[i], 1, color )
    end
  end
  
  --reaper.Main_OnCommand( 40898, 0 ) -- Markers: Renumber all markers in timeline order
  reaper.SNM_SetIntConfigVar( "projmeasoffs", -2) -- offset measures
  
  
  
end  

function chords_44()
    retval, filetxt = reaper.GetUserFileNameForRead("", "Import Chords from SGU,MGU...", "")
    
    --print(GetFilename(filetxt))
    
    f = assert(io.open(filetxt, "rb"))
    
    local first_byte_sig = f:read(1)
    local name_bytes = f:read(1)
    --print("First byte = "..tostring(first_byte_sig))
    name_len = string.byte(name_bytes)
    --print("Name_length =" ..name_len)
    local bytes = f:read(name_len)
    --print("Name: "..tostring(bytes))
    local meter_denominator = 4
    --print("Meter: "..tostring(4).."/"..tostring(meter_denominator))
    local byte1 = string.byte(f:read(1))
    local byte2 = string.byte(f:read(1))
    local byte3 = string.byte(f:read(1))
    local keyByte = string.byte(f:read(1)) --read 
    local tempoByte = string.byte(f:read(1)) --read tempo byte
    
    if keyByte <= 17 then
      key = rootNames[keyByte]
      isMinor = false 
    else key = rootNames[keyByte - 17]
      isMinor = true
    end
    if isMinor then
      --print("Key : " ..key.. "m")
    else --print("Key: " ..key)
    end
    --print("Tempo: " ..tempoByte)
    reaper.Main_OnCommand( 40042, 0 ) -- Transport: Go to start of project
    reaper.SetCurrentBPM( 0, tempoByte, 0 ) -- 0 no undo points 1 undo points
    
    
    reaper.SetTempoTimeSigMarker( 0, -1, 0, -1, -1, -1, 4, 4, false )
    
    local bar = string.byte(f:read(1)) --read start bar number
    --print("Start bar: " ..bar)
    
    local types = {}
    local roots = {}
    local beats = {}
    local partm = {}
    numberOfChords = 1

-- count through the bars and bar types to find section boundaries
    
    while bar < 255 do -- maximum of 255 bars
      local barType = string.byte(f:read(1)) --read bar type
      
      if barType == 0 then
        duration = string.byte(f:read(1))
        bar = bar + duration
      else bar = bar + 1
      end
    

      partm[bar] = barType
       
    end
    
    total_bars = bar - duration -1
    --print("Total number of bars =" ..total_bars)
-- count through the chord type/duration section recording the beat count where chord changes occur in table beats[] and the chord type in types[] 
    local beat = 1 --start at beat 1
    while beat < 1020 do --maximum of 1020 beats (= 255 bars x 4 beats)
      local chordType = string.byte(f:read(1))
      if chordType == 0 then
        local duration = string.byte(f:read(1))
        beat = beat + duration
      else types[numberOfChords] = chordType
        --print("Chord change number "..tostring(numberOfChords).." to "..tostring(chordType).." ["..typeNames[chordType].."] at beat count "..tostring(beat))
        beats[numberOfChords] = beat
        numberOfChords = numberOfChords + 1
        last_beat = beat
        beat = beat + 1
      end
    end
  total_beats = last_beat - 1


  local i=1
  beat = 1 --start at beat 1
  
  while beat < 1020 do --maximum of 1020 beats
    
    local chordRoot = string.byte(f:read(1))
    if chordRoot == 0 then 
      local duration = string.byte(f:read(1))
      beat = beat + duration
    else roots[i] = chordRoot
      if beat ~= beats[i] then
        --print("Inconsistent chord type and root beat")
      end
      

      i = i + 1
      beat = beat + 1
    end
 
  end


  if i ~= numberOfChords then
    print("Inconsistent number of chord types and roots")
  end


  beats_no = (last_beat +15) / 4 * 4
  --print("Toatal 3/4 Beats ".. beats_no  )
  waltz_bars = 0

  
    --types = {}
    --roots = {}
    --beats = {}
    --partm = {}  
  
  chord_name = {}
  beat_count = {}
  part_marker = {}
  part_marker_beats = {}
  
  for i = 1, tablelength(roots) do
  
    nom_beats = beats[i] --((beats[i] / 4) * 4) 
    beat_number = 1
    
    nom_bars = (nom_beats / 4) 
    
    nom_bars  = math.floor(nom_bars)
    --nom_bars2 = round(nom_bars,0)
     
     
    nom_beats2 = math.floor(nom_beats)
     
    --print("BAR ".. math.floor(nom_beats2 /4))
    --end
    --print("Beat ".. nom_beats2 .." " ..tostring(rootNames[roots[i]]) ..tostring(typeNames[types[i]]))
    
    chord_name[i] = tostring(rootNames[roots[i]]) ..tostring(typeNames[types[i]])
    beat_count[i] = nom_beats2
    
  
  end
  part_marker_count = 0
  for i = 2, total_bars +1 do --tablelength(roots) do --total_bars +1 do
    if partm[i] and partm[i] > 0 then
      --print("PartM ".. (i*4 )-7  .. " " ..tostring(partm[i]))
      part_marker[i] = tostring(partm[i])
      part_marker_beats[i] = (i*4 )-7
    end
    part_marker_count = part_marker_count +1
  end   
  
  for i = 1, part_marker_count +1 do
    if part_marker_beats[i] then
      --print("part_marker_beats ".. part_marker_beats[i] .." type ".. part_marker[i])
    --print("beat_count ".. beat_count[3] .." ".. chord_name[3])

    --print("Toatal Bars ".. total_bars+3)
    end
  end
  
  for i = 1, tablelength(roots) +1 do --total_bars +1 do
  
    --chord_name[i]
    --beat_count[i]
    
    for m = 1, part_marker_count +1 do
      if part_marker_beats[m] then
        --print("PM Color ".. beat_count[i] .." ".. part_marker_beats[m])
        if beat_count[i] == part_marker_beats[m] then
          --print("FOUND part_marker_beats ".. part_marker_beats[m])
          if part_marker[m] == "1" then
            --print("BLUE")
            color = reaper.ColorToNative(55,118,235)|0x1000000
          end
          if part_marker[m] == "2" then
            --print("GREEN")
            color = reaper.ColorToNative(17,174,59)|0x1000000
          end      
        end
      end  
      
    end  
    
    if beat_count[i] then
      reg_start = reaper.TimeMap2_beatsToTime( 0, beat_count[i]+7 )
    end  
    reg_start = reaper.SnapToGrid( 0, reg_start )
    --print("reg_start "..reg_start)
   
    -- ADD 2 bar for count-in
    if i < tablelength(roots) then
      reg_end = reaper.TimeMap2_beatsToTime( 0, beat_count[i+1]+7 )
      reg_end = reaper.SnapToGrid( 0, reg_end )
      --print("reg_end "..reg_end)
      reaper.AddProjectMarker2( 0, true, reg_start, reg_end, chord_name[i], 1, color )
    end
    if i == tablelength(roots) then
      ending_bars = reaper.TimeMap2_beatsToTime( 0, 16)
      ending_bars = reaper.SnapToGrid( 0, ending_bars )
      reaper.AddProjectMarker2( 0, true, reg_start, reg_start+ending_bars, chord_name[i], 1, color )
    end
  end
  
  --reaper.Main_OnCommand( 40898, 0 ) -- Markers: Renumber all markers in timeline order
  reaper.SNM_SetIntConfigVar( "projmeasoffs", -2) -- offset measures
  
end

 retval = reaper.MB( "Yes the Song 4/4 or No for 3/4", "Time Signature", 4 ) 
 if retval == 6 then
   chords_44()
 end
 if retval == 7 then
   chords_34()
 end 

-- Get the number of markers
local num_markers = reaper.CountProjectMarkers(0)
function CreateTextItem(track, position, length, text, color)
   if track ==  nil then return end
  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end

function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

 ctrack = getTrackByName("chordtrack")
 if ctrack == nil then Msg("no chordtrack") end

if ctrack then -- if a track named "Structure" was found
  reaper.SetOnlyTrackSelected(ctrack)
end
-- Iterate through all markers
local markers = {}
for i = 0, num_markers - 1 do
  local retval, isrgn, pos, regend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers(i)

  table.insert(markers, {pos = pos, name = name, regend = regend})
end

-- Create a new text item for each marker
for i , marker  in ipairs(markers) do
   length = (markers[i].regend)-(markers[i].pos)
--  local text_item = reaper.CreateNewMIDIItemInProj(first_track, marker.pos, end_time, false)
  
  CreateTextItem(ctrack,marker.pos,length,marker.name)
--  reaper.ULT_SetMediaItemNote(text_item, marker.name)
--  if color ~= nil then
 --    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
 --  end
end

for i = 1, num_markers do
reaper.DeleteProjectMarker( 0, i, true )
end
end
--==============================================================================================
--================================== convert ChordPro to empty_item_notes ======================
--==============================================================================================
function convert_chordpro()


local function Msg(str)
reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


local ret, fn = reaper.GetUserFileNameForRead(reaper.GetProjectPath("").."\\*.*", "Project path:", "")
if ret then
local file = io.open(fn, "r")
   chords = {}
   count = 1

 -- read each line of the file
 for line in file:lines() do
   -- look for lines that contain chord symbols
   for chord_symbol in line:gmatch("%[(%w+)%]") do
     -- add the chord symbol to the table
     chords[count] = chord_symbol
     count = count + 1
   end
 end
 
 -- close the file
 file:close()

 
 

  -- ...
end
function CreateTextItem(track, position, length, text, color)
   if track ==  nil then return end
  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end

start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, start_time )
reaper.SetEditCurPos(start_time, false, false )
reaper.Main_OnCommand(41042,0) -- move cursor one measure
one_bar = tonumber((reaper.GetCursorPosition()-start_time))
bar = math.floor(one_bar*10000000000)/10000000000


-- find the chord track
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

 ctrack = getTrackByName("chordtrack")
 if ctrack == nil then Msg("no chordtrack") end

if ctrack then -- if a track named "Structure" was found
  reaper.SetOnlyTrackSelected(ctrack)
end

-- loop through each chord symbol in the table
for i, chord_symbol in ipairs(chords) do
  -- create an empty item with the length of one bar on the chord track
  
  track = ctrack
  -- add the chord symbol as a note in the item
  text = chords[i]
  CreateTextItem(ctrack,(((i-1)*bar)+start_time),bar,text)
end

end
--==========================================================================================================
--========================== chord_progression ===========================================================
--==========================================================================================================

function chord_progression(ca)

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end
reaper.Undo_BeginBlock2(0)

-- x-raym create text item
function CreateTextItem(track, position, length, text, color)
   if track ==  nil then return end
  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end

--cfillion track by name
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

 ctrack = getTrackByName("chordtrack")
 if ctrack == nil then Msg("no chordtrack") end

if ctrack then -- if a track named "Structure" was found
  reaper.SetOnlyTrackSelected(ctrack)
end

reaper.Main_OnCommand(40289,0) -- Item: Unselect (clear selection of) all items
reaper.Main_OnCommand(40718,0) -- Item: Select all items on selected tracks in current time selection
reaper.Main_OnCommand(40006,0) -- Item: Remove selected area of items
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if ctrack then
count_items = reaper.CountTrackMediaItems(ctrack)
end


bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, start_time )
reaper.SetEditCurPos(start_time, false, false )
reaper.Main_OnCommand(41042,0) -- move cursor one measure
one_bar = tonumber((reaper.GetCursorPosition()-start_time))
bar = math.floor(one_bar*10000000000)/10000000000


     c = {[1]={"C",1,"G",1,"Am",1,"Em",1,"F",1,"C",1,"F",1,"G",1}, -- Pachelbel`s Canon progression 
          [2]={"C",1,"Am",1,"F",1,"G",1}, -- 50s progression - I-vi-IV-V
          [3]={"Dm",1,"G",1,"C",1,"C",1}, -- Cadence progression - ii-V-I
          [4]={"C",1,"C",1,"F",1,"G",1},  -- Happy progression - I-I-IV-V
          [5]={"Am",1,"F",1,"C",1,"G",1}, -- Sad 1 progression  vi-IV-I-V
          [6]={"Am",1,"Em",1,"G",1,"F",1}, -- Sad 2 progression  vi-iii-V-IV
          [7]={"Cm",1,"Gm",1,"Bb",1,"Fm",1}, -- Sad 3 progression  i-v-bVII-iv
          [8]={"Cm",1,"Gm",1,"Bb",1,"F",1}, -- sadder progression  i-v-bVII-IV
          [9]={"Am",1,"G",1,"F",1,"G",1}, -- Uplifting progression vi-V-IV-V
         [10]={"C",1,"Bb",1,"Ab",1,"G",1},-- Andalusian Cadence progression I-bVII-BVI-V
         [11]={"C",1,"F",1,"Am",1,"G",1},-- Storyteller progression vi-V-IV-V
         [12]={"C",1,"Dm",1,"C",1,"F",1},-- Bass Player progression
         [13]={"F",1,"C",1,"G",1,"G",1}, -- Journey progression 
         [14]={"F",1,"G",1,"E",1,"Am",1},-- Secondary Dominants progression
         [15]={"Am",1,"Dm",1,"G",1,"C",1},-- Circle progression 
         [16]={"F",1,"Fm",1,"C",1,"C",1},-- Minor Change progression 
         [17]={"C",1,"F",1,"G",1,"G",1},-- La Bamba progression 
         [18]={"C",1,"Ab",1,"Am",1,"G",1},-- Epic progression 
         [19]={"C",4,"F",2,"C",2,"G",1,"F",1,"C",1,"G",1},-- Blues 12-bar progression 
         [20]={"C",1,"F",1,"C",2,"F",2,"C",2,"G",1,"F",1,"C",1,"G",1},-- Blues 12-bar V2 progression vi-V-IV-V
         [21]={"C",1,"Am",1,"Em",1,"D",1},-- Pop 1 progression 
         [22]={"C",1,"G",1,"Am",1,"F",1},-- Pop 2 progression 
         [23]={"C",1,"F",1,"C",1,"G+",1},-- Rock 1 progression 
         [24]={"Cm",1,"Ab",1,"Fm",1,"Fm",1},-- Rock 2 progression 
         [25]={"F",1,"G",1,"Am",1,"C",1},-- Rock 3 progression 
         [26]={"C",1,"C",1,"Bb",1,"F",1},-- Rock 4 progression 
         [27]={"C",1,"G",1,"Dm",1,"F",1},-- Rock 5 progression 
         [28]={"Dm7",1,"G7",1,"Cmaj7",2},-- Jazz 1 
         [29]={"Dm7b5",1,"G7",1,"Cm7",2},-- Jazz 2
         [30]={"Cmaj7",1,"Am7",1,"Dm7",1,"G7",1},-- Jazz 3
         [31]={"Cm7",1,"Am7b5",1,"Dm7b5",1,"G7",1},-- Jazz 4
         [32]={"Em7",1,"A7",1,"Dm7",1,"G7",1},-- Jazz 5
         [33]={"Cmaj7",1,"C#dim7",1,"Dm7",1,"G7",1},-- Jazz 6
         [34]={"Cmaj7",1,"F7",1,"Em7",1,"A7",1},-- Jazz 7
         [35]={"Ebm7",1,"Ab7",1,"Dm7",1,"G7",1,"Cmaj7",2},-- Jazz 8
         [36]={"Dm7",1,"Db7",1,"Cmaj7",2},-- Jazz 9
         [37]={"Cm",1,"Ab",1,"Cm",1,"Gm",1}, -- Trap progression
         [38]={"G",0.5,"Eb",0.5,"C",1}}-- Würm progression 

       
        
        c_name_1 = c[ca][1]
        st1 = start_time
        length1 = bar*(c[ca][2])
        CreateTextItem(ctrack,st1,length1,c_name_1)
      
        
        c_name_2 = c[ca][3]
        st2 = start_time+bar*(c[ca][2])
        length2 = bar*(c[ca][4])
        CreateTextItem(ctrack,st2,length2,c_name_2)
        
        if c[ca][6] == nil then return
        else
                  
        c_name_3 = c[ca][5]
        st3 = start_time+bar*(c[ca][2]+c[ca][4])
        length3 = bar*(c[ca][6])
        CreateTextItem(ctrack,st3,length3,c_name_3)
        
        if c[ca][8] == nil then return
        else
        
        c_name_4 = c[ca][7]
        st4 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6])
        length4 = bar*(c[ca][8])
        CreateTextItem(ctrack,st4,length4,c_name_4)
        
        if c[ca][10] == nil then return
        else
        
        c_name_5 = c[ca][9]
        st5 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8])
        length5 = bar*(c[ca][10])
        CreateTextItem(ctrack,st5,length5,c_name_5)
        
        if c[ca][12] == nil then return
        else
        
        c_name_6 = c[ca][11]
        st6 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10])
        length6 = bar*(c[ca][12])
        CreateTextItem(ctrack,st6,length6,c_name_6)
        
        if c[ca][14] == nil then return
        else
        
        
        c_name_7 = c[ca][13]
        st7 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10]+c[ca][12])
        length7 = bar*(c[ca][14])
        CreateTextItem(ctrack,st7,length7,c_name_7)
        
        if c[ca][16] == nil then return
        else
        
        
        c_name_8 = c[ca][15]
        st8 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10]+c[ca][12]+c[ca][14])
        length8 = bar*(c[ca][16])
        CreateTextItem(ctrack,st8,length8,c_name_8)
        
        if c[ca][18] == nil then return
        else
        
        c_name_9 = c[ca][18]
        st9 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10]+c[ca][12]+c[ca][14]+c[ca][16])
        length9 = bar*(c[ca][18])
        CreateTextItem(ctrack,st9,length9,c_name_9)
        
        if c[ca][20] == nil then return
        else       
        
        c_name_10 = c[ca][21]
        st10 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10]+c[ca][12]+c[ca][14]+c[ca][16]+c[ca][18])
        length10 = bar*(c[ca][20])
        CreateTextItem(ctrack,st10,length10,c_name_10)
        
        if c[ca][22] == nil then return
        else      
        
        
        c_name_11 = c[ca][23]
        st11 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10]+c[ca][12]+c[ca][14]+c[ca][16]+c[ca][18]+c[ca][20])
        length11 = bar*(c[ca][22])
        CreateTextItem(ctrack,st11,length11,c_name_11)
        
        if c[ca][24] == nil then return
        else          
        
        
        c_name_12 = c[ca][25]
        st12 = start_time+bar*(c[ca][2]+c[ca][4]+c[ca][6]+c[ca][8]+c[ca][10]+c[ca][12]+c[ca][14]+c[ca][16]+c[ca][18]+c[ca][20]+c[ca][22])
        length12 = bar*(c[ca][24])
        CreateTextItem(ctrack,st12,length12,c_name_12)
        
        reaper.Main_OnCommand(40718,0)
        chord_prog = ca
end        
end
end
end
end
end
end
end
end
end
reaper.Main_OnCommand(40718,0)

commandID2 = reaper.NamedCommandLookup("_SWSMARKERLIST13")
--reaper.Main_OnCommand(commandID2, 0) -- SWS: Convert markers to regions
reaper.Undo_EndBlock2(0, "Chords from midi item", -1)
reaper.MIDIEditor_OnCommand( hwnd, 2 ) --File: Close window

end
--==============================================================================================
--================================== metadata entries in render region =========================
--==============================================================================================
-- @description Rename region at edit cursor 
--with "Timer","Date created","rating","finished","genre", "deadline" 
--for deadline you need "archie counter timer(auto)" script from reapack
-- https://forum.cockos.com/showthread.php?t=259165

function metadata_entries_2_region()
local _, rg_idx = reaper.GetLastMarkerAndCurRegion( 0,  reaper.GetCursorPositionEx( 0 ) )
if rg_idx == -1 then
  reaper.ShowConsoleMsg( "Edit cursor not inside a region!" )
  return
end

local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, rg_idx )

-----Project started------------

function restore_proj_started() 
  local ret, proj_started = reaper.GetProjExtState(0, "ARC_COUNTER_TIMER_IN_PROJ_WIN", "PROJECT_STARTED")
  return proj_started
end

proj_started = restore_proj_started()
if proj_started ~= "" then -- if not empty string
  -- only store date, discard the rest
  day = string.sub(proj_started, 1,2) 
  month = string.sub(proj_started, 4,5) 
  year = string.sub(proj_started, 7,10) 
  
end

local start =  year .. "-" .. month .. "-" .. day

-------------Work Timer----------
function restore_time() 
  local ret, saved_time_sec = reaper.GetProjExtState(0, "ARC_COUNTER_TIMER_IN_PROJ_WIN", "TIME_SEC_AFK_SESSION")
  if saved_time_sec ~= "" then
    return saved_time_sec
  else
    return 0
  end
end

function sec_to_ddhhmm(time_sec)
  local days = math.floor(time_sec/(60*60*24))
  local hours = math.floor(time_sec/(60*60)%24)
  local minutes = math.floor(time_sec/60%60) 
  return string.format("%02d:%02d:%02d",days,hours,minutes)
end

restored_time_sec = restore_time()
local timer =  sec_to_ddhhmm(restored_time_sec)

------------------------------------------------------------------
--rating, genre, finished, deadline---- Get User Input------------
------------------------------------------------------------------
 retval, author = reaper.GetSetProjectInfo_String( 0, "PROJECT_AUTHOR", "", false )
title=string.gsub(string.gsub(reaper.GetProjectName( 0, "" ), ".rpp", ""), ".RPP", "")
comment = reaper.GetSetProjectNotes( 0,false, 0 )
if comment =="" then comment = "no comment" end
if title=="" then title="project unsaved" end

retval, string_all_ohne = reaper.GetProjExtState( 0, "MARK", "COLUMN" )
string_all = ""..string_all_ohne..","..comment..""

if string_all_ohne=="" 
then
string_all=""..title..",★,Mark,album,genre,key,no,11.11.2111,"..comment..""
end



retval, retvals_csv = reaper.GetUserInputs( '', 9, "Title:,Rating:,Author:,Album:,Genre:,Key:,Finished:,Deadline:,Comment:,extrawidth=240",string_all)
if not retval then return end



title,rating,artist,album,genre,key,finished,deadline,comment1 = retvals_csv:match("(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.-),(.*)")


title=string.gsub(string.gsub(reaper.GetProjectName( 0, "" ), ".rpp", ""), ".RPP", "")

string_all=""..title..","..rating..","..artist..","..album..","..genre..","..key..","..finished..","..deadline..""



reaper.SetProjExtState(0, "MARK", "COLUMN", string_all )
notes = reaper.GetSetProjectNotes( 0,true , comment1 )
author = reaper.GetSetProjectAuthor( 0,true , artist )


local deadlineTimestamp = retvals_csv

local function dateToTime(s)
  local xDay, xMonth, xYear = s:match("(%d+)%.(%d+)%.(%d+)")
  return os.time({year = xYear, month = xMonth, day = xDay, hour = 0, min = 0, sec = 0})
end

local today = os.time()
local deadlineDate = dateToTime(deadlineTimestamp)
local daysLeft = deadlineDate - today

deadline = math.floor(daysLeft/86400)
if deadline >  400 then deadline=""
elseif deadline ==  tostring("no deadline") then deadline=""
end


-------write to region name------
local ok = reaper.SetProjectMarker4( 0, markrgnindexnumber, isrgn, pos, rgnend,
                                          " Title="..title.. 
                                          ";   Comment="..comment1..
                                          ";   Rating="..rating..
                                          ";   Author="..author..
                                          ";   Album="..album..
                                          ";   Start_time="..start..
                                          ";   Deadline="..deadline..
                                          ";   Key="..key..
                                          ";   Genre="..genre..
                                          ";   Finished="..finished..
                                          ";   WorkTimer="..timer..
                                          ";", color, tr_name == "" and 1 or 0 )
if ok then
  reaper.Undo_OnStateChangeEx2( 0, "Timer to Region", 8, -1 )
end

end
--===========================================================================================================================
--=============================== renderregion ===============================================================================
--======================================================================================================================





function create_render_region()

a_start,b_end = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false) -- start and end from time selection

reaper.Main_OnCommand(40182,0) -- select all itemns
reaper.Main_OnCommand(40290,0) -- create time selection
reaper.Main_OnCommand(40323,0) -- nudge right edge right 
reaper.Main_OnCommand(40323,0) -- nudge right edge right
reaper.Main_OnCommand(40323,0) -- nudge right edge right
reaper.Main_OnCommand(40320,0) -- nudge left edge left
reaper.Main_OnCommand(40320,0) -- nudge left edge left 

time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)

reaper.AddProjectMarker2( 0, true, time_sel_start, time_sel_end, "render region",0, reaper.ColorToNative( 150,150,150 )|0x1000000  )

reaper.GetSet_LoopTimeRange(true, true, a_start, b_end, false) -- reset time selection

reaper.Main_OnCommand(40289,0) -- deselect all items

end

--------------------------------------------------------------------------------------------------------------
-----------------------------------OTHERS import XML --------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-------- imports suitable xml for the audio track---------
-- script by dragonetti and jkooks ----
function import_xml()
selItemsCount = reaper.CountSelectedMediaItems(0)
if selItemsCount == nil then return end
function bla() end 
  function nothing() reaper.defer(bla) end
reaper.Main_OnCommand(40421,0) -- select all items of the selected track

selItemsTable = {}

selItemsCount = reaper.CountSelectedMediaItems(0)

for i = 0, selItemsCount - 1 do

 local item = reaper.GetSelectedMediaItem(0, i)
 local take = reaper.GetActiveTake(item)
 if take == nil then return end
 local source = reaper.GetMediaItemTake_Source( take )
  src_bpm = tonumber(({reaper.CF_GetMediaSourceMetadata( source, "BPM", "" )})[2]) or
   tonumber(({reaper.CF_GetMediaSourceMetadata( source, "bpm", "" )})[2])
 local nameandpath = reaper.GetMediaSourceFileName(source, "",512 )
 local name =   string.sub(nameandpath,1, -5) ..".musicxml"  
 
   
 
  tableIdx = i + 1 -- 1-based table in Lua
  selItemsTable[tableIdx] = {}
  selItemsTable[tableIdx].name = name
  selItemsTable[tableIdx].pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
  selItemsTable[tableIdx].playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  selItemsTable[tableIdx].startoffs = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
  selItemsTable[tableIdx].position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  selItemsTable[tableIdx].length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  
  
end
if selItemsCount ~= nil then 
reaper.Main_OnCommand(40289,0) --unselect all items
reaper.Main_OnCommand(40001,0) --insert new track
end
 
    
for tableIdx,v in pairs(selItemsTable) do
 reaper.InsertMedia(selItemsTable[tableIdx].name,8)

CountMusicxml = reaper.CountSelectedMediaItems(0) 

end
if selItemsCount ~= nil then
SelTrack = reaper.GetSelectedTrack(0,0)
reaper.GetSetMediaTrackInfo_String(SelTrack, "P_NAME", "musicxml", true)
reaper.SetMediaTrackInfo_Value(SelTrack, "I_HEIGHTOVERRIDE", 100)  
end 

CountXml = reaper.CountSelectedMediaItems(0)

XmlItemCount = reaper.CountTrackMediaItems(SelTrack)             
for i = 0, XmlItemCount - 1 do

ItemXml = reaper.GetTrackMediaItem(SelTrack, i)
TakeXml = reaper.GetMediaItemTake( ItemXml,0 ) 

----------------------------------------------------------------------



reaper.BR_SetMidiTakeTempoInfo( TakeXml, true, src_bpm, src_bpm, 0 ) 

---------------------------------------------------------------------------

--i + 1 cause your array is based on 1

reaper.SetMediaItemTakeInfo_Value(TakeXml, "D_PITCH",selItemsTable[i+1].pitch)
reaper.SetMediaItemTakeInfo_Value(TakeXml, "D_PLAYRATE",selItemsTable[i+1].playrate)
reaper.SetMediaItemTakeInfo_Value(TakeXml, "D_STARTOFFS",selItemsTable[i+1].startoffs)
reaper.SetMediaItemInfo_Value(ItemXml, "D_POSITION",selItemsTable[i+1].position )
reaper.SetMediaItemInfo_Value(ItemXml, "D_LENGTH",selItemsTable[i+1].length )
reaper.SetMediaItemSelected(ItemXml, true)

end
if selItemsCount ~= nil then 
reaper.Main_OnCommand(41737,0) 
reaper.Main_OnCommand(41588,0) ---glue items----
end
local start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) -- focus to time selection

if start_time ~= end_time then
  reaper.SetEditCurPos2(0, start_time, 1, 0)
end
end

--==================================================================================================================
--============================== OTHER_Generate_MIDI_NOTE ===========================================================
--===================================================================================================================

--end
function generate_midi()


--function generate_midi()
for i=0, reaper.CountSelectedTracks(0) do
--  track = reaper.GetSelectedTrack(0, i)





colors = {0x01000000, 0x01ffffff, 0x01ff0000, 0x0100ffff, 0x01ff00ff, 0x0100ff00,
          0x010000ff, 0x01ffff00, 0x01ff7f00, 0x017f3f00, 0x01ff7f7f, 0x013f3f3f,
          0x017f7f7f, 0x017fff7f, 0x017f7fff, 0x01bfbfbf}

starttime, endtime = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

_, grid, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)
qnotetime = 240*grid / reaper.Master_GetTempo()
factor = (endtime - starttime)/qnotetime

if starttime == endtime then -- no time selection exists

   -- check if a mediaItem is selected, and if so take its start & end times and delete it
   if reaper.CountSelectedMediaItems() == 0 then
      starttime = reaper.GetCursorPosition()
      endtime = starttime + qnotetime
   else
      selectedItem = reaper.GetSelectedMediaItem(0, 0)
      starttime = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
      endtime = starttime + reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
      reaper.DeleteTrackMediaItem(track, selectedItem)
   end      
end

length = (endtime - starttime)
track =  reaper.GetSelectedTrack2( 0, i, 0 )
if track == nil then
    return
    end
cursor = reaper.GetCursorPosition()
midiItem = reaper.CreateNewMIDIItemInProj(track, starttime, starttime+grid)
midiTake = reaper.GetActiveTake(midiItem)
cursor = reaper.GetCursorPosition()
reaper.MIDI_InsertNote(midiTake, true, false, 0, 960*grid*4, 1, 72, 127)

reaper.SetMediaItemInfo_Value(midiItem, "B_LOOPSRC", 1)
reaper.SetMediaItemInfo_Value(midiItem, "B_UISEL", 1)
reaper.SetMediaItemLength(midiItem, length, false)
reaper.GetSetMediaItemTakeInfo_String(midiTake, 'P_NAME',72, true)

reaper.SetMediaItemInfo_Value(midiItem, 'I_CUSTOMCOLOR', reaper.ColorToNative(201,3,57)|0x1000000  )
reaper.Main_OnCommand(40932,0) --split at grod
end

   -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------

 
    -------------------------------------------------------
    local function DeleteMediaItem(item);
        if item then;
            local tr = reaper.GetMediaItem_Track(item);
            reaper.DeleteTrackMediaItem(tr,item);
        end;
    end;
    -------------------------------------------------------


    local CountSelItem = reaper.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;


    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0); -- В Аранже
    if timeSelStart == timeSelEnd then no_undo() return end;

    local Undo;

    for i = CountSelItem-1,0,-1 do;

        local SelItem = reaper.GetSelectedMediaItem(0,i);
        local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION");
        local LenIt = reaper.GetMediaItemInfo_Value(SelItem,"D_LENGTH");
        local EndIt = PosIt + LenIt;

        if PosIt < timeSelEnd and EndIt > timeSelStart then;

            if not Undo then reaper.Undo_BeginBlock()Undo=1 end;

            if PosIt < timeSelEnd and EndIt > timeSelEnd then;
                local Right = reaper.SplitMediaItem(SelItem,timeSelEnd);
                if Right then
                    DeleteMediaItem(Right);
                end
            end

            if PosIt < timeSelStart and EndIt > timeSelStart then;
                local Left = reaper.SplitMediaItem(SelItem,timeSelStart);
                if Left then
                    DeleteMediaItem(SelItem);
                end
            end;
        else;
            if not Undo then reaper.Undo_BeginBlock()Undo=1 end;
            DeleteMediaItem(SelItem);
        end;
    end;


    if Undo then;
        reaper.Undo_EndBlock("Delete selected items outside time selection",-1);
    else;
        no_undo();
    end;
    reaper.UpdateArrange();
Msg(track)
::ending::



end

