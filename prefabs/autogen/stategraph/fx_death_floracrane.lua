-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_death_floracrane",
  isfinal=true,
  prefab={ "death_floracrane_frnt",},
  stategraphs={
    death_floracrane_frnt={
      events={
        idle={
          {
            eventtype="spawnparticles",
            frame=1,
            param={ detachatexitstate=true, duration=90.0, particlefxname="hit_floracrane",},
          },
        },
      },
    },
  },
}