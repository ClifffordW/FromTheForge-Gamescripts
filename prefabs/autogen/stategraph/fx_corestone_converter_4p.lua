-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_corestone_converter_4p",
  isfinal=true,
  prefab={ "corestone_converter_4p",},
  stategraphs={
    sg_corestone_converter={
      events={
        present={
          {
            eventtype="spawnparticles",
            frame=5,
            param={
              duration=90.0,
              offx=0.0,
              offy=0.0,
              offz=0.0,
              particlefxname="corestone_converter_4p_present",
              render_in_front=true,
            },
          },
        },
      },
    },
    sg_energy_well_pillar={
      events={
        new_heart={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=90.0,
              offx=0.0,
              offy=0.0,
              offz=0.0,
              particlefxname="town_pillar_activate_swamp",
              render_in_front=true,
            },
          },
        },
        powerup={
          {
            eventtype="spawnparticles",
            frame=18,
            param={
              duration=90.0,
              offx=0.0,
              offy=0.0,
              offz=0.0,
              particlefxname="town_pillar_activate_swamp",
              render_in_front=true,
            },
          },
        },
        switch={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=90.0,
              offx=0.0,
              offy=0.0,
              offz=0.0,
              particlefxname="town_pillar_activate_swamp",
              render_in_front=true,
            },
          },
        },
      },
    },
    town_grid_statue={
      events={
        idle={
          {
            eventtype="spawnparticles",
            frame=3,
            param={
              followsymbol="ruins",
              ischild=true,
              offx=5.0,
              offy=-185.0,
              offz=0.0,
              particlefxname="town_statue_sparks_tiny",
            },
          },
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="ruins",
              ischild=true,
              offx=104.0,
              offy=-253.0,
              offz=0.0,
              particlefxname="town_statue_sparks",
            },
          },
        },
      },
    },
  },
}
