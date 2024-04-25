-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="sound_thatcherswamp_path_common",
  isfinal=true,
  needSoundEmitter=true,
  prefab={
    "thatforest_gate_n",
    "thatforest_gate_e",
    "thatforest_gate_s",
    "thatforest_gate_w",
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