-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="sound_blarmadillo_elite_alt",
  isfinal=true,
  needSoundEmitter=true,
  prefab={ "blarmadillo_elite",},
  stategraphs={
    sg_blarmadillo={
      events={ trumpet={  },},
      sg_events={
        {
          eventtype="playsound",
          name="sfx-trumpet",
          param={ autostop=true, soundevent="blarmadillo_Elite_trumpet", stopatexitstate=true,},
        },
        {
          eventtype="playsound",
          name="sfx-bounce",
          param={ sound_max_count=10.0, soundevent="blarmadillo_Elite_bounce",},
        },
        {
          eventtype="playsound",
          name="sfx-knockback_vo",
          param={ autostop=true, soundevent="blarmadillo_Elite_knockback",},
        },
        {
          eventtype="playsound",
          name="sfx-knockdown",
          param={ autostop=true, soundevent="Knockdown",},
        },
        {
          eventtype="playsound",
          name="sfx-hit",
          param={ soundevent="blarmadillo_Elite_hit",},
        },
      },
      state_events={ trumpet={  },},
    },
  },
}