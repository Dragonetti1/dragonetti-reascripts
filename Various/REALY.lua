-- @version 0.1.2
-- @author Dragonetti
-- @changelog
--    + in the background glue item
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' ('0.9.2')
-- Erzeuge den ImGui-Kontext, falls noch nicht geschehen
local ctx = reaper.ImGui_CreateContext("My ImGui Window")

-- Setze die Flags für das Fenster
local window_flags = reaper.ImGui_WindowFlags_AlwaysAutoResize() |
                     reaper.ImGui_WindowFlags_NoCollapse() |
                     reaper.ImGui_WindowFlags_TopMost()
-- Erstellen des ImGui-Kontexts
local ctx = ImGui.CreateContext('ReaLy')
local styleBuf = "Nick Cave"  -- Standardwert für den Stil
local showStyleAndCopyButtons = false
-- Tabellen zum Speichern der Texteingaben und Button-Status
local widgets = {
    input = {
        field1 = { text = "text" }, -- Beispieltext für Textfeld 1
        field2 = { text = "" }, -- Ausgabe der Zählung für Textfeld 1
        field3 = { text = "" }, -- Ausgabe der Zählung für Textfeld 4
        field4 = { text = "" }, -- Textfeld 4 für die Silbenzählung
    },
    buttons = { placeholders = {} } -- Speichern der Placeholder-Buttons
}

function ToolTip(is_tooltip, text)
    if is_tooltip and reaper.ImGui_IsItemHovered(ctx) then
        -- Beginne den Tooltip
        reaper.ImGui_BeginTooltip(ctx)
        -- Text mit Umbruch (hier auf 200px festgelegt)
        reaper.ImGui_PushTextWrapPos(ctx, 200)
        -- Textinhalt des Tooltips
        reaper.ImGui_Text(ctx, text)
        -- Pop TextWrapPos und beende den Tooltip
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end


-- Funktion zum Zählen der Silben in jeder Zeile
local function countSyllablesPerLine(text)
    local lines = {}
    for line in text:gmatch("([^\r\n]*)\r?\n?") do
        if line == "" then
            table.insert(lines, "") -- Preserve empty line
        else
            local syllableCount = 0
            -- Count words and hyphens in each word
            for word in line:gmatch("%S+") do
                local hyphenCount = select(2, word:gsub("%-", ""))
                syllableCount = syllableCount + 1 + hyphenCount
            end
            table.insert(lines, tostring(syllableCount)) -- Insert syllable count
        end
    end
    return table.concat(lines, "\n") -- Join results as text
end



-- Funktion, um einen Track anhand des Namens zu finden
function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    if ok and trackName == name then
      return track -- Track gefunden
    end
  end
  return nil -- Track nicht gefunden
end



function merge_empty_items()
-- Get the number of selected media items
local itemCount = reaper.CountSelectedMediaItems(0)

-- Check if there are selected items
if itemCount == 0 then
    reaper.ShowMessageBox("No items selected!", "Error", 0)
    return
end

-- Variables to hold the last item's end position and notes
local lastItemEndPos = 0
local allNotes = ""

-- Loop through selected items
for i = 0, itemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    
    -- Check if the item is empty (no media source)
    local take = reaper.GetActiveTake(item)
    if take == nil then
        -- Get the item's end position
        local itemEndPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        -- Update the last item's end position
        if itemEndPos > lastItemEndPos then
            lastItemEndPos = itemEndPos
        end

        -- Get the item notes (assuming notes are stored in "P_NOTES")
        local itemNotes = reaper.ULT_GetMediaItemNote(item)
        
        -- Append the notes to the collection
        if itemNotes and itemNotes ~= "" then
            allNotes = allNotes .. itemNotes .. "\n"
        end
    end
end

-- Create a new empty item at the end of the last selected item
local track = reaper.GetMediaItemTrack(reaper.GetSelectedMediaItem(0, 0)) -- Use the track of the first selected item
local newItem = reaper.AddMediaItemToTrack(track)

-- Set the position of the new item
reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", lastItemEndPos)

-- Set the length of the new item (just a small value, adjust if needed)
reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", 8.0)

-- Set the collected notes into the new empty item
if allNotes ~= "" then
    reaper.ULT_SetMediaItemNote(newItem, allNotes)
end

-- Update the arrangement to reflect changes
reaper.UpdateArrange()
end



-- Funktion, um einen neuen Track zu erstellen
function createTrack(name)
  reaper.InsertTrackAtIndex(reaper.CountTracks(0), false) -- Neuer Track am Ende hinzufügen
  local newTrack = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
  reaper.GetSetMediaTrackInfo_String(newTrack, 'P_NAME', name, true) -- Namen setzen
  return newTrack
end

-- Funktion, um den Track an die 2. Position zu verschieben
function moveTrackToSecondPosition(track)
  reaper.ReorderSelectedTracks(1, 0) -- Track an die zweite Position verschieben (Index 1)
end

-- Funktion, um ein leeres Item auf dem Track "lyrics" zu erstellen
function create_empty_item_on_lyrics_track(item_start, item_length)
  local lyricsTrack = getTrackByName("lyrics")
  
  -- Falls der "lyrics"-Track nicht existiert, erstelle ihn
  if lyricsTrack == nil then
    lyricsTrack = createTrack("lyrics")
    if lyricsTrack == nil then
      reaper.ShowMessageBox("Track 'lyrics' konnte nicht erstellt werden!", "Fehler", 0)
      return nil
    end
    reaper.SetOnlyTrackSelected(lyricsTrack) -- Den neuen Track auswählen
    moveTrackToSecondPosition(lyricsTrack) -- Track an die 2. Position verschieben
  end
  
  -- Erstelle ein leeres Item auf dem 'lyrics'-Track
  local emptyItem = reaper.AddMediaItemToTrack(lyricsTrack)
  if emptyItem ~= nil then
    reaper.SetMediaItemInfo_Value(emptyItem, "D_POSITION", item_start)
    reaper.SetMediaItemInfo_Value(emptyItem, "D_LENGTH", item_length)
    reaper.UpdateArrange() -- Arrangement aktualisieren
    return emptyItem
  else
    reaper.ShowMessageBox("Leeres Item konnte nicht erstellt werden!", "Fehler", 0)
    return nil
  end
end

-- Funktion zum Schreiben von Text in die Notizen des leeren Items
function write_text_to_item_notes(item, text)
  if item ~= nil then
    reaper.GetSetMediaItemInfo_String(item, "P_NOTES", text, true)
    reaper.UpdateArrange() -- Arrangement aktualisieren
  else
    reaper.ShowMessageBox("Kein leeres Item ausgewählt!", "Fehler", 0)
  end
end




-- Definiere Farben für die verschiedenen Zustände
local stateColors = {
    [0] = { 0.0, 0.3, 0.5, 0.6 },  -- neutral (standard)
    [1] = { 1.0, 0.0, 0.0, 1.0 },  -- rot
    [2] = { 0.0, 1.0, 0.0, 1.0 },  -- grün
    [3] = { 0.0, 0.0, 1.0, 1.0 },  -- blau
    [4] = { 1.0, 1.0, 0.0, 1.0 }   -- gelb
}

-- Funktion zum Packen der RGBA-Werte in einen 32-Bit-Integer (0xRRGGBBAA)
local function packColor(r, g, b, a)
    local r255 = math.floor(r * 255)
    local g255 = math.floor(g * 255)
    local b255 = math.floor(b * 255)
    local a255 = math.floor(a * 255)
    local color = (r255 << 24) | (g255 << 16) | (b255 << 8) | a255
    return color
end

-- Funktion zum Generieren der Buttons basierend auf den Wörtern in Field 1
local function makeButtonsFromWords(text)
    local buttons = {}
    for line in text:gmatch("[^\r\n]+") do
        local buttonLine = {}
        for word in line:gmatch("%S+") do
            -- Splitte das Wort bei Bindestrichen in einzelne Teile
            local parts = {}
            for part in word:gmatch("[^%-]+") do
                table.insert(parts, part)
            end
            
            -- Erstelle Buttons für jedes Teilwort, die direkt nebeneinander liegen
            for i, part in ipairs(parts) do
                local wordLength = reaper.ImGui_CalcTextSize(ctx, part) + 8 -- Passe die Länge des Buttons an die Wortlänge an
                table.insert(buttonLine, { 
                    label = part, 
                    length = wordLength, 
                    placeholder = part, 
                    state = 0  -- Startzustand für den neuen Farb-Button (neutral)
                })
                
                -- Wenn es noch ein weiteres Teil gibt, setze ImGui.SameLine mit einem Abstand von 0
                if i < #parts then
                    reaper.ImGui_SameLine(ctx, nil, 0) -- Kein Abstand zwischen den Buttons
                end
            end
        end
        table.insert(buttons, buttonLine) -- Speichere jede Zeile von Buttons
    end
    return buttons
end

-- Funktion, um den Text aus dem Eingabefeld in die HTML-Datei zu schreiben

function write_text_to_html(text)
    -- Pfad zur HTML-Datei
    local file_path = "C:\\Users\\mark\\AppData\\Roaming\\REAPER\\reaper_www_root\\TEXT.html"

    -- Öffne die Datei im Lesemodus
    local file = io.open(file_path, "r")

    -- Prüfe, ob die Datei existiert
    if not file then
        reaper.ShowMessageBox("Fehler: Die Datei TEXT.html konnte nicht gefunden werden!", "Fehler", 0)
        return
    end

    -- Lese den Inhalt der HTML-Datei
    local html_content = file:read("*all")
    file:close()

    -- Ersetze alle Zeilenumbrüche (\n) durch <br>, damit sie in HTML angezeigt werden
    local text_with_breaks = text:gsub("\n", "<br>")
    
    -- Ersetze den Inhalt des Div mit der ID lyricsContainer
    local new_html_content = html_content:gsub('<div id="lyricsContainer">.-</div>', '<div id="lyricsContainer">' .. text_with_breaks .. '</div>')
    
   
    -- Öffne die Datei im Schreibmodus, um den neuen Inhalt zu schreiben
    file = io.open(file_path, "w")
    if not file then
        reaper.ShowMessageBox("Fehler beim Schreiben in die Datei TEXT.html!", "Fehler", 0)
        return
    end

    -- Schreibe den aktualisierten HTML-Inhalt in die Datei
    file:write(new_html_content)
    file:close()

    -- Zeige eine Bestätigungsmeldung
    reaper.ShowMessageBox("Text erfolgreich in TEXT.html eingefügt!", "Erfolg", 0)
end

-- Callback, wenn der Button 'text_to_html' gedrückt wird
if ImGui.Button(ctx, 'text_to_html') then
    write_text_to_html(widgets.input.field1.text)
end


-- Funktion, um Text aus dem ausgewählten leeren Item in field1 zu importieren
function import_text_from_selected_item()
    -- Hole das erste ausgewählte Media-Item
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    
    -- Prüfen, ob ein Item ausgewählt wurde
    if selectedItem == nil then
        reaper.ShowMessageBox("Kein Item ausgewählt!", "Fehler", 0)
        return
    end
    
    -- Prüfen, ob es ein leeres Item ist (das kann man auch anders validieren)
    local retval, item_notes = reaper.GetSetMediaItemInfo_String(selectedItem, "P_NOTES", "", false)
    
    -- Den Text aus den Notizen in field1 importieren
    if item_notes ~= "" then
        widgets.input.field1.text = item_notes
    else
        reaper.ShowMessageBox("Das ausgewählte Item enthält keine Notizen!", "Fehler", 0)
    end
end

-- Event-Handler für den Button "Import Text"
if ImGui.Button(ctx, 'Import Text from Item') then
    import_text_from_selected_item()
end



-- Funktion zum Kopieren der Placeholder-Labels in die Zwischenablage
local function copyPlaceholdersToClipboard()
    -- Verwende den aktuellen Stil aus styleBuf und füge ihn in den zusätzlichen Text ein
    local additionalText = "It's supposed to be a songlyric in the style of " .. styleBuf .. ".\n" ..
                           "Please replace the (monosyllabic) with your own syllables so that the lyrics make sense,\n" ..
                           "Note the frequency of the (monosyllabic) without changing the order!!\n" ..
                           "please translate to german directly below.\n" ..
                           "please 2 attempts.\n" ..
                           "Now the lyric:"

    -- Füge den zusätzlichen Text am Anfang des Clipboard-Textes hinzu
    local clipboardText = additionalText .. "\n"
    
    -- Tabelle, um die Zeilen-States zu sammeln, um Reimhinweise hinzuzufügen
    local lineStates = {}

    -- Iteriere über jede Zeile der Placeholder-Buttons
    for lineIndex, buttonLine in ipairs(widgets.buttons.placeholders) do
        local lineText = ""
        for _, button in ipairs(buttonLine) do
            -- Wenn kein Placeholder-Text vorhanden ist, füge (monosyllabic) hinzu
            if button.placeholder == "" then
                lineText = lineText .. "(monosyllabic) "
            else
                lineText = lineText .. button.placeholder .. " "
            end
        end
        -- Entferne das letzte Leerzeichen und füge die Zeile zum Clipboard-Text hinzu
        clipboardText = clipboardText .. lineText:sub(1, -2) .. "\n"

        -- Sammle den State des ersten Buttons jeder Zeile, aber nur, wenn es nicht neutral ist (state = 0)
        if buttonLine[1].state ~= 0 then
            lineStates[lineIndex] = buttonLine[1].state
        end
    end

    -- Füge Reimhinweise hinzu basierend auf den States
    local rhymeHints = ""
    local checkedLines = {}

    -- Überprüfe Zeilen mit denselben Farben
    for i = 1, #lineStates do
        if not checkedLines[i] then
            local rhymeGroup = { i }

            -- Finde alle weiteren Zeilen mit derselben Farbe (State)
            for j = i + 1, #lineStates do
                if lineStates[i] == lineStates[j] then
                    table.insert(rhymeGroup, j)
                    checkedLines[j] = true -- Markiere als bereits geprüft
                end
            end

            -- Schreibe die Reimhinweise nur, wenn mindestens 2 Zeilen dieselbe Farbe haben
            if #rhymeGroup > 1 then
                rhymeHints = rhymeHints .. "Lines " .. table.concat(rhymeGroup, " and ") .. " should rhyme.\n"
            end
        end
    end

    -- Füge die Reimhinweise zum Clipboard-Text hinzu, aber nur, wenn welche existieren
    if rhymeHints ~= "" then
        clipboardText = clipboardText .. "\n" .. rhymeHints
    end

    -- Kopiere den Text in die Zwischenablage
    reaper.CF_SetClipboard(clipboardText)
end




-- Funktion zum Entfernen nicht relevanter Fehlermeldungen und Bereinigung des Timecodes
function remove_text_before_sprache_and_clean_timecodes(transcribed_text)
    -- Debug: Zeige den ursprünglichen Text in der Konsole
    --reaper.ShowConsoleMsg("Originaler transkribierter Text:\n" .. transcribed_text .. "\n")

    -- Entferne nicht relevante Fehlermeldungen (alles vor dem ersten Timecode)
    local clean_text = transcribed_text:match("%[%d%d:%d%d%.%d%d%d%s*%-%->%s*%d%d:%d%d%.%d%d%d%](.*)")

    

    -- Entferne alle Timecodes im Format [hh:mm:ss.mmm --> hh:mm:ss.mmm] und [hh:mm:ss.mmm], Zeilenumbrüche bleiben erhalten
    clean_text = clean_text:gsub("%[%d%d:%d%d%.%d%d%d%s*%-%->%s*%d%d:%d%d%.%d%d%d%]", "")
    clean_text = clean_text:gsub("%[%d%d:%d%d%.%d%d%d%]", "")

    -- Entferne überflüssige Leerzeichen an den Zeilenenden und am Anfang der ersten Zeile, aber behalte Zeilenumbrüche bei
    clean_text = clean_text:gsub("^%s+", "") -- Entfernt Leerzeichen am Anfang des Texts
    clean_text = clean_text:gsub("%s+\n", "\n"):gsub("\n%s+", "\n") -- Bereinigt Leerzeichen um Zeilenumbrüche

    -- Debug: Zeige den bereinigten Text in der Konsole
   -- reaper.ShowConsoleMsg("Bereinigter Text:\n" .. clean_text .. "\n")

    return clean_text
end



-- Whisper-Funktionen

-- Definiere die verfügbaren Sprachen und Modelle
local availableLanguages = { "en", "de", "fr", "es", "it", "jp" }  -- Weitere Sprachen können hinzugefügt werden
local availableModels = { "base", "small", "medium", "large", "tiny" }  -- Modelle entsprechend den Whisper-Optionen

-- Standardauswahl für Sprache und Modell
local selectedLanguage = "en"
local selectedModel = "base"

function copy_file(source, destination)
    local source_file = io.open(source, "rb")
    if not source_file then
        -- Console message suppressed
        return false
    end

    local destination_file = io.open(destination, "wb")
    if not destination_file then
        -- Console message suppressed
        source_file:close()
        return false
    end

    local block_size = 2^13  -- 8 KB Blöcke
    while true do
        local data = source_file:read(block_size)
        if not data then break end
        destination_file:write(data)
    end

    source_file:close()
    destination_file:close()
    
    return true
end

function execute_whisper(input_file, language, model)
    -- Überprüfe, ob das Modell korrekt übergeben wurde
    if not model then
        model = "base" -- Standardmodell, falls keines ausgewählt wurde
    end

    local temp_dir = os.getenv("TEMP")
    local batch_file = temp_dir .. "\\whisper_batch.bat"
    local log_file = temp_dir .. "\\whisper_log.txt"

    -- Erstelle das Whisper-Kommando mit den ausgewählten Parametern
    local whisper_cmd = '@echo off\n'
    whisper_cmd = whisper_cmd .. '"C:\\Users\\mark\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\whisper.exe" "' .. input_file .. '" --language ' .. language .. ' --model ' .. model .. ' --output_format txt > "' .. log_file .. '" 2>&1\n'

    local file = io.open(batch_file, "w")
    if file then
        file:write(whisper_cmd)
        file:close()
    else
        -- Wenn die Batchdatei nicht geschrieben werden kann
        return nil
    end

    -- Führe das Kommando aus
    os.execute('cmd.exe /C ' .. batch_file)

    -- Lese die Transkription aus der Log-Datei
    local transcribed_text = ""
    local output_file_handle = io.open(log_file, "r")
    if output_file_handle then
        transcribed_text = output_file_handle:read("*all")
        output_file_handle:close()
    else
        -- Fehler beim Öffnen der Log-Datei
        return nil
    end

    -- Lösche die temporären Dateien
    os.remove(batch_file)
    os.remove(log_file)

    return transcribed_text
end

-- Funktion, um das Item zu kleben und Whisper auszuführen, dann Undo
function glue_and_transcribe_item(item)
    -- Überprüfe, ob das Item existiert
    if not item then
        reaper.ShowMessageBox("Fehler: Kein gültiges Item ausgewählt!", "Fehler", 0)
        return
    end

    -- Beginne einen neuen Undo-Block, um das Kleben und die Whisper-Verarbeitung rückgängig machen zu können
    reaper.Undo_BeginBlock()

    -- Wähle nur das aktuelle Item aus, um es zu kleben
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.SetMediaItemSelected(item, true) -- Select the current item

    -- Glue the selected item (Main_OnCommand 40362)
    reaper.Main_OnCommand(40362, 0)

    -- Jetzt gibt es ein neues geklebtes Item, das an der gleichen Position liegt
    local glued_item = reaper.GetSelectedMediaItem(0, 0)
    if not glued_item then
        reaper.ShowMessageBox("Fehler: Das geklebte Item konnte nicht gefunden werden!", "Fehler", 0)
        reaper.Undo_EndBlock("Glue and Whisper", -1)
        return
    end

    -- Holen Sie den Pfad zur geklebten Audiodatei
    local glued_take = reaper.GetActiveTake(glued_item)
    local glued_source = reaper.GetMediaItemTake_Source(glued_take)
    local glued_file_path = reaper.GetMediaSourceFileName(glued_source, "")

    -- Verarbeite die geklebte Datei mit Whisper
    local transcribed_text = execute_whisper(glued_file_path, selectedLanguage, selectedModel or "base")
    if transcribed_text then
        -- Debug: Zeige den Text vor der Bereinigung
      --  reaper.ShowConsoleMsg("Transkribierter Text (vor Bereinigung):\n" .. transcribed_text .. "\n")
        
        -- Bereinige den Text
        local clean_text = remove_text_before_sprache_and_clean_timecodes(transcribed_text)
        widgets.input.field1.text = clean_text
    else
        reaper.ShowMessageBox("Fehler: Whisper konnte die Datei nicht verarbeiten!", "Fehler", 0)
    end

    -- Nachdem die Whisper-Verarbeitung abgeschlossen ist, führe einen Undo-Schritt aus, um das Original-Item zurückzuholen
    reaper.Undo_EndBlock("Glue and Whisper", -1)  -- Beende den Undo-Block
    reaper.Undo_DoUndo2(0)  -- Führe den Undo-Schritt durch, um das Kleben rückgängig zu machen

    -- Projekt-Arrangement aktualisieren
    reaper.UpdateArrange()
end

-- Transkribiere das geklebte Item und mache danach ein Undo
function transcribe_and_update_field1()
    local selected_item = reaper.GetSelectedMediaItem(0, 0)
    if selected_item then
        glue_and_transcribe_item(selected_item) -- Führe die neue Glue- und Whisper-Funktion aus
    else
        reaper.ShowMessageBox("Fehler: Kein Item ausgewählt!", "Fehler", 0)
    end
end

-- GUI-Button zum Transkribieren des ausgewählten Items mit Whisper
if reaper.ImGui_Button(ctx, 'Transcribe Selected Audio Item with "whisper"') then
    transcribe_and_update_field1()
end

-- GUI-Button zum Erstellen von Platzhalter-Buttons
if reaper.ImGui_Button(ctx, 'Make Buttons from text') then
    widgets.buttons.placeholders = makeButtonsFromWords(widgets.input.field1.text)
    showStyleAndCopyButtons = true  -- Zeige die Buttons, wenn sie generiert wurden
end

---------------------------------------------------------------------------------------------------
------------------------------------- GUI --------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Main GUI Loop

local function loop()
    -- Set initial window size
    ImGui.SetNextWindowSize(ctx, 1300, 620)
 
    local visible, open = ImGui.Begin(ctx, 'ReaLy', true, window_flags)
    if visible then
        -- Push style colors for buttons and frame backgrounds
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xE35858F0)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x803232F0)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x803232F0)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xCC6868F0)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x803232F0)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x803232F0)

        -- Button to transcribe the selected audio item
        if ImGui.Button(ctx, 'Transcribe Selected Audio Item with "whisper"') then
            transcribe_and_update_field1()
        end

        -- Language Combo Box
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetNextItemWidth(ctx, 40)
        if ImGui.BeginCombo(ctx, "##language", selectedLanguage) then
            for i, language in ipairs(availableLanguages) do
                local isSelected = (selectedLanguage == language)
                if ImGui.Selectable(ctx, language, isSelected) then
                    selectedLanguage = language
                end
                if isSelected then
                    ImGui.SetItemDefaultFocus(ctx)
                end
            end
            ImGui.EndCombo(ctx)
        end

        -- Model Combo Box
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetNextItemWidth(ctx, 58)
        if ImGui.BeginCombo(ctx, "##model", selectedModel) then
            for i, model in ipairs(availableModels) do
                local isSelected = (selectedModel == model)
                if ImGui.Selectable(ctx, model, isSelected) then
                    selectedModel = model
                end
                if isSelected then
                    ImGui.SetItemDefaultFocus(ctx)
                end
            end
            ImGui.EndCombo(ctx)
        end

        -- Import empty item button
        reaper.ImGui_SameLine(ctx)
        if ImGui.Button(ctx, 'Import empty item') then
            import_text_from_selected_item()
        end

        -- Pop the 5 colors pushed before (button styles and frame backgrounds)
        reaper.ImGui_PopStyleColor(ctx, 6)
        reaper.ImGui_SameLine(ctx)
        ImGui.SetCursorPos(ctx, 604, 26)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444141c6)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x444141c6)
        -- Erster Button: Verarbeitung für Feld 1 -> Ausgabe in Feld 2
        if ImGui.Button(ctx, 'Syl1', 30, 20) then
            widgets.input.field2.text = countSyllablesPerLine(widgets.input.field1.text)
        end
        
        -- Platzierung des zweiten Buttons in der UI sicherstellen
        reaper.ImGui_SameLine(ctx)
        
        -- Zweiter Button: Verarbeitung für Feld 4 -> Ausgabe in Feld 3
        if ImGui.Button(ctx, 'Syl2', 30, 20) then
            widgets.input.field3.text = countSyllablesPerLine(widgets.input.field4.text)
        end
        reaper.ImGui_PopStyleColor(ctx, 2)
        -- Create a scrollable child window for the text fields
        local child_flags = reaper.ImGui_WindowFlags_HorizontalScrollbar() -- Allow horizontal scrolling
        local size_w = 0.0  -- Use remaining window width
        local size_h = 200  -- Set fixed height

        -- Begin child window
        reaper.ImGui_BeginChild(ctx, "TextFieldsScrollableRegion", size_w, size_h, 1, child_flags)

        -- Text Field 1 and 2 (with background color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x444141c6)

        -- Text Field 1
        local rv1, newText1 = ImGui.InputTextMultiline(ctx, '##field1', widgets.input.field1.text, 580, ImGui.GetTextLineHeight(ctx) * 50)
        if rv1 then
            widgets.input.field1.text = newText1
        end

        -- Align Text Field 2 to the right of Text Field 1
        ImGui.SameLine(ctx)
        local rv2, newText2 = ImGui.InputTextMultiline(ctx, '##field2', widgets.input.field2.text, 30, ImGui.GetTextLineHeight(ctx) * 50, reaper.ImGui_InputTextFlags_ReadOnly())
        if rv2 then
            widgets.input.field2.text = newText2
        end

        reaper.ImGui_PopStyleColor(ctx) -- Pop color for the background

        -- Text Field 3 and 4 (with background color)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x444141c6)

        -- Text Field 3
        ImGui.SameLine(ctx)
        local rv3, newText3 = ImGui.InputTextMultiline(ctx, '##field3', widgets.input.field3.text, 30, ImGui.GetTextLineHeight(ctx) * 50)
        if rv3 then
            widgets.input.field3.text = newText3
        end

        -- Align Text Field 4 to the right of Text Field 3
        ImGui.SameLine(ctx)
        local rv4, newText4 = ImGui.InputTextMultiline(ctx, '##field4', widgets.input.field4.text, 580, ImGui.GetTextLineHeight(ctx) * 50)
        if rv4 then
            widgets.input.field4.text = newText4
        end

        reaper.ImGui_PopStyleColor(ctx) -- Pop color for the background

        -- End child window for text fields
        reaper.ImGui_EndChild(ctx)

        -- Button for transferring text to an empty item
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x34D632AA)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x1A6E19AA)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x34D632AA)
        
        if ImGui.Button(ctx, 'text to empty item') then
            if widgets.input and widgets.input.field1 and widgets.input.field1.text then
                local selectedItem = reaper.GetSelectedMediaItem(0, 0)
                if selectedItem then
                    local itemStart = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
                    local itemLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
                    local emptyItem = create_empty_item_on_lyrics_track(itemStart, itemLength)
                    if emptyItem then
                        write_text_to_item_notes(emptyItem, widgets.input.field1.text)
                    end
                else
                    reaper.ShowMessageBox("No item selected!", "Error", 0)
                end
            else
                reaper.ShowMessageBox("No text entered!", "Error", 0)
            end
        end
        
        reaper.ImGui_SameLine(ctx)

        -- Button to transfer text to HTML
        if ImGui.Button(ctx, 'text to html') then
            if widgets.input and widgets.input.field1 and widgets.input.field1.text then
                write_text_to_html(widgets.input.field1.text)
            else
                reaper.ShowMessageBox("No text entered!", "Error", 0)
            end
        end
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PopStyleColor(ctx, 3) -- Pop colors for the buttons
        if reaper.ImGui_Button(ctx, 'merge empty items') then merge_empty_items()
        end
          
        
        -- Push style colors for the next buttons
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444141c6)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x444141c6)

        -- Make buttons from text
        if reaper.ImGui_Button(ctx, 'Make Buttons from text') then
            widgets.buttons.placeholders = makeButtonsFromWords(widgets.input.field1.text)
            showStyleAndCopyButtons = true  -- Display Style and Copy buttons after making buttons
        end
        
        reaper.ImGui_PopStyleColor(ctx, 2) -- Pop colors for the buttons

        -- Display Style and Copy Buttons conditionally
        if showStyleAndCopyButtons then
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Text(ctx, "Style:")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x302F2FC6)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x302F2FC6)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x302F2FC6)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x302F2FC6)
            
            reaper.ImGui_SetNextItemWidth(ctx, 200)
            local styleChanged, newStyle = ImGui.InputText(ctx, "##style_input", styleBuf)
            if styleChanged then
                styleBuf = newStyle
            end

            -- Copy button
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'Copy text buttons to clipboard for chatgpt') then
                copyPlaceholdersToClipboard()
            end
            reaper.ImGui_PopStyleColor(ctx, 4) -- Pop all 4 style colors
        end

        

        -- StyleVars for button spacing and rounding
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 2, 1)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 2)

        -- Scrollable child window for buttons
        local button_child_flags = reaper.ImGui_WindowFlags_HorizontalScrollbar()
        local button_size_w = 0.0
        local button_size_h = 300
        
        reaper.ImGui_BeginChild(ctx, "ButtonScrollableRegion", button_size_w, button_size_h, 1, button_child_flags)
        
        -- Display buttons
        for lineIndex, buttonLine in ipairs(widgets.buttons.placeholders) do
            for buttonIndex, button in ipairs(buttonLine) do
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444141c6)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x444141c6)
                
                if reaper.ImGui_Button(ctx, button.label .. '##' .. lineIndex .. '_' .. buttonIndex, button.length, 18) then
                    -- Button logic if needed
                end
                reaper.ImGui_SameLine(ctx)
                reaper.ImGui_PopStyleColor(ctx, 2) -- Pop style colors for button
            end

            reaper.ImGui_NewLine(ctx)

            -- Display placeholder buttons
            for buttonIndex, button in ipairs(buttonLine) do
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x302F2FC6)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x302F2FC6)
                
                if reaper.ImGui_Button(ctx, button.placeholder .. '##placeholder' .. lineIndex .. '_' .. buttonIndex, button.length, 18) then
                    if button.placeholder == "" then
                        button.placeholder = button.label
                    else
                        button.placeholder = ""
                    end
                end

                if buttonIndex < #buttonLine then
                    reaper.ImGui_SameLine(ctx)
                end
                reaper.ImGui_PopStyleColor(ctx, 2) -- Pop style colors for placeholder button
            end

            -- State button for each line
            reaper.ImGui_SameLine(ctx)
            local color = stateColors[buttonLine[1].state]
            local colorU32 = packColor(color[1], color[2], color[3], color[4])
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), colorU32)

            if reaper.ImGui_Button(ctx, '##stateButton' .. lineIndex, 20, 18) then
                for _, button in ipairs(buttonLine) do
                    button.state = (button.state + 1) % 5
                end
            end
            
            reaper.ImGui_PopStyleColor(ctx, 1) -- Pop style color for state button
            reaper.ImGui_NewLine(ctx)
        end
        
        -- End child window for buttons
        reaper.ImGui_EndChild(ctx)

        -- Pop StyleVars for ItemSpacing and FrameRounding
        reaper.ImGui_PopStyleVar(ctx, 2)

        -- End main GUI window
        ImGui.End(ctx)
    end

    if open then
        reaper.defer(loop)
    end
end

reaper.defer(loop)

