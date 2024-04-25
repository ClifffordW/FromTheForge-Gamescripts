-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="sound_swamp_path_common",
  isfinal=true,
  needSoundEmitter=true,
  prefab={
    "bandiforest_gate_n",
    "bandiforest_gate_e",
    "bandiforest_gate_s",
    "bandiforest_gate_w",
  },
  sg_wildcard=true,
  stategraphs={
    ["*"]={
      sg_events={
        {
          eventtype="playsound",
          name="sfx-open_magic",
          param={ autostop=true, soundevent="swampPath_open_magic",},
        },
        {
          eventtype="playsound",
          name="sfx-open_moan",
          param={ autostop=true, soundevent="swampPath_open_moan",},
        },
        {
          eventtype="playsound",
          name="sfx-open",
          param={ autostop=true, soundevent="swampPath_open",},
        },
      },
    },
  },
}
