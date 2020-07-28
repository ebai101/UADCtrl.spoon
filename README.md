# UADCtrl.spoon

A simple Hammerspoon Spoon meant for controlling UA Apollo interfaces. Currently only tested on an Apollo Twin.

Much of the reverse engineering of the TCP protocol was originally done by Radu Varga, creator of [this project.](https://github.com/raduvarga/UA-Midi-Control) For more advanced features and MIDI mapping I suggest you check it out.

## Example Config

```lua
hs.loadSpoon('UADCtrl')
spoon.UADCtrl:showAlerts(true) -- show alert popups when commands are executed
spoon.UADCtrl:bindHotkeys({
    enter  = { {'ctrl', 'alt', 'cmd'},  'u' },
    mute   = { {}, 'm' },
    solo   = { {}, 's' },
    mono   = { {}, 'o' },
    pan    = { {}, 'p' }
})
```

In this example, Ctrl-Alt-Cmd-U enters the main UADCtrl mode. After you've entered UADCtrl mode:

- press 'O' to toggle Mono/Stereo output
- press 'P' to toggle the pan position of inputs 1/2 between hard L/R and center
- press 'M' and then a number to toggle mute on that channel
- press 'S' and then a number to toggle solo on that channel