-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_energy_well",
  isfinal=true,
  prefab={ "town_energy_well",},
  stategraphs={
    sg_energy_well={
      events={
        activate={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=52.0,
              followsymbol="swap_fx_top",
              ischild=true,
              particlefxname="town_energywell_activate",
              render_in_front=true,
              stopatexitstate=true,
            },
          },
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=30.0,
              followsymbol="swap_fx_gears",
              ischild=true,
              offx=-26.0,
              offy=-36.0,
              offz=0.0,
              particlefxname="town_energy_sparks_excited",
              render_in_front=true,
              stopatexitstate=true,
            },
          },
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              duration=30.0,
              followsymbol="swap_fx_wire",
              ischild=true,
              offx=18.0,
              offy=34.0,
              offz=0.20000000298023,
              particlefxname="town_energy_sparks",
              render_in_front=true,
              stopatexitstate=true,
            },
          },
        },
        excited={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="swap_fx_wire",
              ischild=true,
              name="tinysparks",
              offx=0.0,
              offy=40.0,
              offz=0.20000000298023,
              particlefxname="town_energy_sparks_tiny",
              stopatexitstate=true,
            },
          },
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="swap_fx_top",
              ischild=true,
              name="topglow",
              offx=0.0,
              offy=-20.0,
              offz=-0.10000000149012,
              particlefxname="town_energywell_excited_glow",
              render_in_front=true,
              stopatexitstate=true,
            },
          },
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="swap_fx_gears",
              ischild=true,
              name="manysparks",
              offx=-26.0,
              offy=-36.0,
              offz=0.0,
              particlefxname="town_energy_sparks_excited",
              render_in_front=true,
              stopatexitstate=true,
            },
          },
        },
        excited_transition={
          {
            eventtype="spawnparticles",
            frame=5,
            param={
              duration=20.0,
              followsymbol="swap_fx_gears",
              ischild=true,
              offx=-22.0,
              offy=-29.0,
              offz=0.0,
              particlefxname="town_energy_sparks_transition",
              render_in_front=true,
            },
          },
          {
            eventtype="spawnparticles",
            frame=0,
            param={
              duration=29.0,
              followsymbol="swap_fx_top",
              ischild=true,
              offx=0.0,
              offy=0.0,
              offz=0.0,
              particlefxname="town_energywell_transition_glow",
              render_in_front=true,
            },
          },
        },
        idle={
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="swap_fx_gears",
              ischild=true,
              name="sparks",
              offx=-23.0,
              offy=-24.0,
              offz=0.0,
              particlefxname="town_energy_sparks",
              render_in_front=true,
            },
          },
          {
            eventtype="spawnparticles",
            frame=1,
            param={
              followsymbol="swap_fx_wire",
              name="tinysparks",
              offx=0.0,
              offy=41.0,
              offz=0.20000000298023,
              particlefxname="town_energy_sparks_tiny",
            },
          },
        },
        idle_transition={
          {
            eventtype="spawnparticles",
            frame=10,
            param={
              duration=15.0,
              followsymbol="swap_fx_gears",
              ischild=true,
              offx=-21.0,
              offy=-34.0,
              offz=0.0,
              particlefxname="town_energy_sparks_transition",
              render_in_front=true,
            },
          },
        },
      },
    },
  },
}
