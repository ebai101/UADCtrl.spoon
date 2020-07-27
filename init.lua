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

function uadctrl:set(dev, cat, num, param, value)
    local cmdString = string.format('set /devices/%d/%s/%d/%s/value/ %s\0', dev, cat, num, param, value)
    log.d(cmdString)
    uadctrl.socket:write(cmdString)
end

function uadctrl:init()
    print('dothisiscalled')
    log.i('initializing UADCtrl')
    uadctrl.socket = hs.socket.new():connect('127.0.0.1', 4710)
    uadctrl.state = {
        mixToMono = 0,
        mute = { 0, 0 },
        solo = { 0, 0 }
    }
end

-----------------------------------------------
-- actions
-----------------------------------------------

local function mixToMono()
    uadctrl.state.mixToMono = 1 - uadctrl.state.mixToMono
    uadctrl:set(0, 'outputs', 0, 'MixToMono', uadctrl.state.mixToMono)
    uadctrl:set(0, 'outputs', 4, 'MixToMono', uadctrl.state.mixToMono)
    log.i(string.format('mixToMono = %s', tostring(uadctrl.state.mixToMono)))
end

local function muteChannel(chan)
    return function()
        uadctrl.state.mute[chan] = 1 - uadctrl.state.mute[chan]
        uadctrl:set(0, 'inputs', chan-1, 'Mute', uadctrl.state.mute[chan])
        log.i(string.format('mute[%d] = %s', chan, tostring(uadctrl.state.mute[chan])))
    end
end

local function soloChannel(chan)
    return function()
        uadctrl.state.solo[chan] = 1 - uadctrl.state.solo[chan]
        uadctrl:set(0, 'inputs', chan-1, 'Solo', uadctrl.state.solo[chan])
        log.i(string.format('solo[%d] = %s', chan, tostring(uadctrl.state.solo[chan])))
    end
end

local function panChannelsLR(chan1, chan2)
    return function()
        uadctrl:set(0, 'inputs', chan1-1, 'Pan', -1.0)
        uadctrl:set(0, 'inputs', chan2-1, 'Pan', 1.0)
        log.i(string.format('chans %d,%d panned LR', chan1, chan2))
    end
end

local function panChannelsCenter(chan1, chan2)
    return function()
        uadctrl:set(0, 'inputs', chan1-1, 'Pan', 0)
        uadctrl:set(0, 'inputs', chan2-1, 'Pan', 0)
        log.i(string.format('chans %d,%d panned center', chan1, chan2))
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
--     activate = {hyper, 'i'}
-- })
-----------------------------------------------

function uadctrl:bindHotkeys(mapping)
    hs.hotkey.bind(mapping.activate[1], mapping.activate[2], mixToMono)
end

return uadctrl
