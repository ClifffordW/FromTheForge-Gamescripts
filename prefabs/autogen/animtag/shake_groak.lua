-- Generated by AnimTagger and loaded by animtag_autogen.lua
return {
  __displayName="shake_groak",
  anim_events={
    groak_bank={
      burrow={
        events={
          { frame=8, name="shake-dig",},
          { frame=12, name="shake-dig",},
          { frame=20, name="shake-dig",},
          { frame=26, name="shake-dig_final",},
        },
      },
      groundpound={ events={ { frame=12, name="shake-groundpound_big",},},},
      groundpound_loop={
        events={ { frame=2, name="shake-groundpound",}, { frame=10, name="shake-groundpound",},},
      },
      knockdown_pre={ events={ { frame=9, name="shake-knockdown",},},},
      walk_loop={ events={ { frame=4, name="shake-walk",},},},
    },
  },
  prefab={ { prefab="groak",}, { prefab="groak_elite",},},
}