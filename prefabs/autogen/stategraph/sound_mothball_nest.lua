-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="sound_mothball_nest",
  isfinal=true,
  needSoundEmitter=true,
  prefab={ "mothball_spawner",},
  stategraphs={
    sg_mothball_spawner={
      events={
        spawn={
          { eventtype="playsound", frame=1, param={ soundevent="mothball_spawner_spawn",},},
          { eventtype="stopsound", frame=1, param={ name="spawn",},},
        },
        spawn_battlefield={
          {
            eventtype="playsound",
            frame=1,
            param={ soundevent="mothball_spawner_spawning",},
          },
        },
        spawn_pre={
          {
            eventtype="playsound",
            frame=1,
            param={ autostop=true, name="spawn", soundevent="mothball_teen_atk_2_LP",},
          },
        },
      },
      sg_events={  },
    },
  },
}
