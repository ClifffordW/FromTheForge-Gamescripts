-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_power_drop_generic_4p",
  group="power_drops_group",
  isfinal=true,
  prefab="power_drop_generic_4p",
  stategraphs={
    sg_rotating_drop={
      events={
        idle={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="swap_fx",
              ischild=true,
              offx=0.0,
              offy=0.0,
              offz=0.10000000149012,
              particlefxname="power_drop_generic_circle",
              stopatexitstate=true,
            },
          },
        },
      },
    },
  },
}
