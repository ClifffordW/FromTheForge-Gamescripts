-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_player_potion_common",
  isfinal=true,
  prefab={ "player_side",},
  sg_wildcard=true,
  stategraphs={
    ["*"]={
      events={
        potion_refill={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=80.0,
              offx=0.74000000953674,
              offy=3.0,
              offz=0.0,
              particlefxname="burst_potion_refill",
            },
          },
          {
            eventtype="spawneffect",
            frame=1,
            param={
              fxname="fx_heal_burst_potion",
              inheritrotation=true,
              offx=0.55000001192093,
              offy=3.210000038147,
              offz=0.0,
            },
          },
        },
      },
      sg_events={
        {
          eventtype="spawnparticles",
          frame=0,
          name="vfx-potion_refill_burstx",
          param={
            duration=80.0,
            offx=0.74000000953674,
            offy=3.0,
            offz=0.0,
            particlefxname="burst_potion_refill",
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-potion_refill_burstx",
          param={
            fxname="fx_heal_burst_potion",
            inheritrotation=true,
            offx=0.55000001192093,
            offy=3.210000038147,
            offz=0.0,
          },
        },
      },
      state_events={ idle_blink={  }, potion_refill={  },},
    },
  },
}