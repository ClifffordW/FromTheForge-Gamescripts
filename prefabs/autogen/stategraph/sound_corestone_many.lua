-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="sound_corestone_many",
  isfinal=true,
  needSoundEmitter=true,
  prefab={ "soul_drop_konjur_soul_lesser_many",},
  stategraphs={
    sg_rotating_drop={
      events={
        idle={
          {
            eventtype="playsound",
            frame=1,
            param={
              autostop=true,
              name="corestone_idle_LP",
              soundevent="corestone_idle_LP",
              stopatexitstate=true,
            },
          },
        },
        spawn={
          {
            eventtype="playsound",
            frame=38,
            param={ name="corestone_spawn", soundevent="corestone_appear_many",},
          },
          { eventtype="stopsound", frame=34, param={ name="sfx-energy",},},
        },
      },
      sg_events={
        {
          eventtype="playsound",
          name="sfx-crystallize",
          param={ sound_max_count=1.0, soundevent="powerCrystal_spawn_crystallize",},
        },
        {
          eventtype="playsound",
          name="sfx-energy",
          param={
            sound_max_count=1.0,
            soundevent="powerCrystal_spawn_energy",
            stopatexitstate=true,
          },
        },
        {
          eventtype="playsound",
          name="sfx-ping",
          param={ sound_max_count=1.0, soundevent="powerCrystal_spawn_impact",},
        },
        {
          eventtype="playsound",
          name="sfx-rattle",
          param={ sound_max_count=2.0, soundevent="powerCrystal_rattle",},
        },
        {
          eventtype="playsound",
          name="sfx-rumble",
          param={ sound_max_count=1.0, soundevent="powerCrystal_rumble",},
        },
        {
          eventtype="playsound",
          name="sfx-shatter_crystal",
          param={ sound_max_count=1.0, soundevent="powerCrystal_shatter_crystal",},
        },
        {
          eventtype="playsound",
          name="sfx-shatter_tail",
          param={ sound_max_count=1.0, soundevent="powerCrystal_shatter_tail",},
        },
      },
    },
    soul_drop_lesser={
      events={
        idle={
          {
            eventtype="playsound",
            frame=1,
            param={
              autostop=true,
              sound_max_count=1.0,
              soundevent="powerCrystal_idle_LP",
              stopatexitstate=true,
            },
          },
        },
      },
    },
  },
}
