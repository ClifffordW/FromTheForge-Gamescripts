-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_street_lamp",
  isfinal=true,
  prefab={ "street_lamp",},
  stategraphs={
    street_lamp={
      events={
        idle={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              ischild=true,
              name="idle_street_lamp",
              offx=0.0,
              offy=0.0,
              offz=0.0,
              particlefxname="street_lamp_glow",
            },
          },
        },
      },
      sg_events={  },
      state_events={ idle={  },},
    },
  },
}