-- Copyright (c) 2020 Ethan Bailey
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this 
-- software and associated documentation files (the "Software"), to deal in the Software 
-- without restriction, including without limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.

local uadctrl = {}
local log = hs.logger.new('uadctrl', 'debug')

uadctrl.__index = uadctrl
uadctrl.name = "UADCtrl"
uadctrl.version = "1.0"
uadctrl.author = "Ethan Bailey <ehb282@nyu.edu>"
uadctrl.homepage = "https://github.com/ebai101/UADCtrl.spoon"
uadctrl.license = "MIT - https://opensource.org/licenses/MIT"

-----------------------------------------------
-- utility functions
-----------------------------------------------

function uadctrl:showAlerts(a)
    uadctrl._alerts = a
end

function uadctrl:info(msg)
    if uadctrl._alerts then
        hs.alert.closeAll()
        hs.alert.show(msg)
    end
    log.i(msg)
end

function uadctrl:set(dev, cat, num, param, value)
    local cmdString = string.format('set /devices/%d/%s/%d/%s/value/ %s\0', dev, cat, num, param, value)
    log.d(cmdString)
    uadctrl._socket:write(cmdString)
end

function uadctrl:init()
    print('dothisiscalled')
    log.i('initializing UADCtrl')
    uadctrl._socket = hs.socket.new():connect('127.0.0.1', 4710)
    uadctrl._alerts = true
    uadctrl._state = {
        mono = 0,
        mute = { 0, 0 },
        solo = { 0, 0 },
        panned = 0,
    }
end

-----------------------------------------------
-- actions
-----------------------------------------------

local function mixToMono()
    uadctrl._state.mono = 1 - uadctrl._state.mono
    uadctrl:set(0, 'outputs', 0, 'MixToMono', uadctrl._state.mono)
    uadctrl:set(0, 'outputs', 4, 'MixToMono', uadctrl._state.mono)
    uadctrl:info(string.format('mono = %s', tostring(uadctrl._state.mono)))
    uadctrl.mainMode:exit()
end

local function muteChannel(chan)
    return function()
        uadctrl._state.mute[chan] = 1 - uadctrl._state.mute[chan]
        uadctrl:set(0, 'inputs', chan-1, 'Mute', uadctrl._state.mute[chan])
        uadctrl:info(string.format('mute[%d] = %s', chan, tostring(uadctrl._state.mute[chan])))
        uadctrl.muteMode:exit()
        uadctrl.mainMode:exit()
    end
end

local function soloChannel(chan)
    return function()
        uadctrl._state.solo[chan] = 1 - uadctrl._state.solo[chan]
        uadctrl:set(0, 'inputs', chan-1, 'Solo', uadctrl._state.solo[chan])
        uadctrl:info(string.format('solo[%d] = %s', chan, tostring(uadctrl._state.solo[chan])))
        uadctrl.soloMode:exit()
        uadctrl.mainMode:exit()
    end
end

local function panChannels(chan1, chan2)
    return function()
        uadctrl._state.panned = 1 - uadctrl._state.panned
        if uadctrl._state.panned == 1 then -- pan LR
            uadctrl:set(0, 'inputs', chan1-1, 'Pan', -1.0)
            uadctrl:set(0, 'inputs', chan2-1, 'Pan', 1.0)
            uadctrl:info(string.format('chans %d,%d panned LR', chan1, chan2))
        else -- pan center
            uadctrl:set(0, 'inputs', chan1-1, 'Pan', 0)
            uadctrl:set(0, 'inputs', chan2-1, 'Pan', 0)
            uadctrl:info(string.format('chans %d,%d panned center', chan1, chan2))
        end
        uadctrl.mainMode:exit()
    end
end

-----------------------------------------------
-- keybinds
-- just map the key to enter the proper mode,
-- the rest is automatic
-- 
-- mapping example: 
-- local hyper = {'ctrl', 'alt', 'cmd'}
-- spoon.UADCtrl:bindHotkeys({
--     enter  = { hyper,  'u' },
--     mute   = { {},     'm' },
--     solo   = { {},     's' },
--     mono   = { {},     'o' },
--     pan    = { {},     'p' }
-- })
-----------------------------------------------

function uadctrl:bindHotkeys(m)
    uadctrl.mainMode = hs.hotkey.modal.new(m.enter[1], m.enter[2])
    uadctrl.muteMode = hs.hotkey.modal.new(nil, nil)
    uadctrl.soloMode = hs.hotkey.modal.new(nil, nil)

    -- downmix to mono
    uadctrl.mainMode:bind(m.mono[1], m.mono[2], mixToMono)

    -- pan channels 1 and 2 LR or center
    uadctrl.mainMode:bind(m.pan[1], m.pan[2], panChannels(1,2))

    -- mute mode
    for i = 1, 2 do
        uadctrl.muteMode:bind({}, string.format('%d',i), muteChannel(i))
    end

    -- solo mode
    for i = 1, 2 do
        uadctrl.soloMode:bind({}, string.format('%d',i), soloChannel(i))
    end

    -- mode entry keybinds
    uadctrl.mainMode:bind(m.mute[1], m.mute[2], function()
        uadctrl.muteMode:enter()
        log.d('entering mute mode')
    end)

    uadctrl.mainMode:bind(m.solo[1], m.solo[2], function()
        uadctrl.soloMode:enter()
        log.d('entering solo mode')
    end)

    uadctrl.mainMode:bind({}, 'escape', function()
        uadctrl.muteMode:exit()
        uadctrl.soloMode:exit()
        uadctrl.mainMode:exit()
        log.d('exiting all modes')
    end)
end

return uadctrl
