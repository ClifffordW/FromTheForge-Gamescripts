-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_blarmadillo",
  isfinal=true,
  prefab="blarmadillo",
  stategraphs={
    sg_blarmadillo={
      events={ idle={  }, walk_loop={  },},
      state_events={
        knockdown_pre={
          {
            eventtype="spawnimpactfx",
            name="vfx-ground_impact",
            param={
              impact_size=1,
              impact_type=1,
              inheritrotation=true,
              offx=-0.89999997615814,
              offz=0.0,
            },
          },
        },
      },
    },
  },
}
