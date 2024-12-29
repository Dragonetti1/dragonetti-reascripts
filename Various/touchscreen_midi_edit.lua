-- Variablen
local is_dragging = false
local initial_mouse_x = nil
local initial_mouse_ppqpos = nil
local initial_positions = {} -- Enthält nur selektierte Noten
local take = nil
local snap_enabled = true -- Flag, ob Rasterung aktiv ist
local pixels_to_ppq = 0.1 -- Verhältnis von Pixel zu PPQ
local editing_start_point = true -- Flag, ob Start- oder Endpunkt bearbeitet wird
local reference_note = nil -- Referenznote zur Bestimmung der Richtung
local drag_factor = 0.5 -- Faktor für die Stärke des Draggens (einstellbar)

-- Funktion: Abrufen des aktuellen Grid-Werts
local function get_dynamic_grid()
    local editor = reaper.MIDIEditor_GetActive()
    if not editor then
        return 0.25 -- Standardwert für 1/4
    end

    local take = reaper.MIDIEditor_GetTake(editor)
    if not take then
        return 0.25 -- Standardwert für 1/4
    end

    local grid = reaper.MIDI_GetGrid(take) -- Grid in Quarter Notes

    -- Sicherheitsprüfung
    if grid == nil or grid <= 0 then
        return 0.25 -- Standardwert für 1/4
    end

    return grid
end

-- Funktion: Snap-to-Grid
local function snap_to_grid(ppq_pos)
    if not take then return ppq_pos end

    local noteLen = get_dynamic_grid()
    local ticks_per_quarter = reaper.SNM_GetIntConfigVar("MidiTicksPerBeat", 960)
    local ppq_per_grid = ticks_per_quarter * noteLen

    if ppq_per_grid <= 0 then return ppq_pos end

    local snapped_ppq = math.floor((ppq_pos / ppq_per_grid) + 0.5) * ppq_per_grid
    return snapped_ppq
end

-- Funktion: Dragging starten
function start_dragging()
    local context = reaper.BR_GetMouseCursorContext()
    if context ~= "midi_editor" then return end

    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return end

    take = reaper.MIDIEditor_GetTake(midi_editor)
    if not take then return end

    local x, _ = reaper.GetMousePosition()
    local mouse_time = reaper.BR_GetMouseCursorContext_Position()
    initial_mouse_ppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouse_time)
    initial_mouse_x = x

    if not initial_mouse_ppqpos then return end

    local _, note_count = reaper.MIDI_CountEvts(take)
    initial_positions = {}
    for i = 0, note_count - 1 do
        local retval, selected, _, startppqpos, endppqpos = reaper.MIDI_GetNote(take, i)
        if selected then
            table.insert(initial_positions, {
                startppqpos = startppqpos,
                endppqpos = endppqpos,
                index = i,
                midpoint = (startppqpos + endppqpos) / 2
            })
        end
    end

    if #initial_positions == 0 then
        is_dragging = false
        return
    end

    local closest_distance = math.huge
    for _, pos in ipairs(initial_positions) do
        local distance_to_mouse = math.abs(initial_mouse_ppqpos - pos.midpoint)
        if distance_to_mouse < closest_distance then
            closest_distance = distance_to_mouse
            reference_note = pos
        end
    end

    if reference_note then
        local midpoint = reference_note.midpoint
        if initial_mouse_ppqpos < midpoint then
            editing_start_point = true
        else
            editing_start_point = false
        end
    end

    is_dragging = true
end

function drag_notes()
    if not is_dragging or not take then return end

    local current_x, _ = reaper.GetMousePosition()
    local mouse_diff = current_x - initial_mouse_x
    local ppq_diff = (mouse_diff / pixels_to_ppq) * drag_factor -- Umrechnung von Pixel in PPQ, multipliziert mit dem Drag-Faktor

    if mouse_diff == 0 then return end -- Keine Bewegung -> keine Anpassung nötig

    for _, pos in ipairs(initial_positions) do
        local new_start = pos.startppqpos
        local new_end = pos.endppqpos

        -- Start- oder Endpunkt bearbeiten?
        if editing_start_point then
            -- Bearbeite nur die Startposition (ohne Raster)
            new_start = pos.startppqpos + ppq_diff
            -- Sicherstellen, dass Startpunkt nicht hinter Endpunkt liegt
            if new_start >= new_end - 1 then
                new_start = new_end - 1
            end
        else
            -- Bearbeite nur die Endposition (ohne Raster)
            new_end = pos.endppqpos + ppq_diff
            -- Sicherstellen, dass Endpunkt nicht vor Startpunkt liegt
            if new_end <= new_start + 1 then
                new_end = new_start + 1
            end
        end

        -- Aktualisierung der Notenposition
        reaper.MIDI_SetNote(take, pos.index, nil, nil,
            new_start, new_end, nil, nil, nil, true)
    end
end

-- Funktion: Dragging beenden
function stop_dragging(raster_after_drag)
    if not is_dragging or not take then return end

    if raster_after_drag then
        for _, pos in ipairs(initial_positions) do
            local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel =
                reaper.MIDI_GetNote(take, pos.index)

            if selected then
                local snapped_start = startppqpos
                local snapped_end = endppqpos

                if editing_start_point then
                    snapped_start = snap_to_grid(startppqpos)
                    if snapped_start >= endppqpos - 1 then
                        snapped_start = endppqpos - 1
                    end
                else
                    snapped_end = snap_to_grid(endppqpos)
                    if snapped_end <= startppqpos + 1 then
                        snapped_end = startppqpos + 1
                    end
                end

                -- Aktualisieren der Note mit gerasterten Positionen
                reaper.MIDI_SetNote(take, pos.index, selected, muted,
                    snapped_start, snapped_end, chan, pitch, vel, true)
            end
        end
    end

    reaper.MIDI_Sort(take)

    -- Variablen zurücksetzen
    is_dragging = false
    initial_mouse_x = nil
    initial_mouse_ppqpos = nil
    initial_positions = {}
    reference_note = nil
    take = nil
end

-- Hauptschleife
function main_loop()
    local mouse_state = reaper.JS_Mouse_GetState(0xFF)
    local ctrl_held = mouse_state & 4 > 0
    local win_held = mouse_state & 0x20 > 0
    local left_button = mouse_state & 1 > 0

    -- Bedingung: Nur aktiv, wenn Ctrl+Win gehalten wird
    local active_drag = ctrl_held and win_held

    if active_drag then
        if left_button then
            if not is_dragging then
                reaper.defer(function()
                    if not is_dragging then
                        start_dragging()
                    end
                end)
            else
                drag_notes()
            end
        elseif is_dragging then
            stop_dragging(true) -- Rasterung, wenn Dragging beendet und Ctrl+Win gehalten
        end
    else
        if is_dragging then
            stop_dragging(false) -- Keine Rasterung, wenn Ctrl+Win nicht gehalten wird
        end
    end

    reaper.defer(main_loop)
end

-- Skript starten
main_loop()
