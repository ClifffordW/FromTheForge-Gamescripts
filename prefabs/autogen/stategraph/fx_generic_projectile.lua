-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_generic_projectile",
  isfinal=true,
  prefab={ "generic_projectile",},
  stategraphs={
    sg_generic_projectile={
      events={
        thrown={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=90.0,
              ischild=true,
              offx=0.0,
              offy=1.2000000476837,
              offz=0.0,
              particlefxname="projectile_generic_trail",
              use_entity_facing=true,
            },
          },
        },
      },
    },
  },
}
