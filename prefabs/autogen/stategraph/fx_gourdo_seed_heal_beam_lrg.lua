-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_gourdo_seed_heal_beam_lrg",
  isfinal=true,
  prefab={ "fx_gourdo_seed_heal_beam_lrg",},
  stategraphs={
    fx_gourdo_seed_heal_beam_lrg={
      events={
        idle={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              detachatexitstate=true,
              duration=25.0,
              followsymbol="attach_fx",
              ischild=true,
              particlefxname="gourdo_seed_beam",
            },
          },
        },
      },
    },
    fx_gourdo_seed_heal_beam_sml={
      events={
        idle={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              detachatexitstate=true,
              duration=13.0,
              followsymbol="attach_fx",
              ischild=true,
              particlefxname="gourdo_seed_beam",
            },
          },
        },
      },
    },
  },
}