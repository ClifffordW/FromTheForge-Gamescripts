-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="fx_player_common_skills",
  isfinal=true,
  prefab={ "player_side",},
  sg_wildcard=true,
  stategraphs={
    ["*"]={
      sg_events={
        {
          eventtype="spawneffect",
          name="vfx-skill_flora_dive_pre",
          param={
            fxname="fx_player_skills_floracrane_dive_pre",
            inheritrotation=true,
            ischild=true,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_flora_dive",
          param={
            detachatexitstate=true,
            fxname="fx_player_skills_floracrane_dive",
            inheritrotation=true,
            ischild=true,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_flora_dive_hold",
          param={
            fxname="fx_player_skills_floracrane_dive_hold",
            inheritrotation=true,
            ischild=true,
            stopatexitstate=true,
          },
        },
        {
          eventtype="spawnimpactfx",
          name="vfx-skill_flora_dive_impactzz",
          param={ impact_size=3, impact_type=1, offx=0, offz=0,},
        },
        {
          eventtype="spawnparticles",
          name="vfx-skill_flora_dive_impact",
          param={ duration=60.0, particlefxname="skill_floracrane_dive_burst",},
        },
        {
          eventtype="spawnimpactfx",
          name="vfx-skill_flora_dive_impactzz",
          param={ impact_size=1, impact_type=1, offx=0, offz=0,},
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_groak_vacuum",
          param={
            fxname="fx_player_skills_groak_vacuum",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=0.0,
            offz=0.0,
            stopatexitstate=true,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_groak_vacuum_pre",
          param={
            fxname="fx_player_skills_groak_pre",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=0.0,
            offz=0.0,
            stopatexitstate=true,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_groak_vacuum_pst",
          param={
            fxname="fx_player_skills_groak_pst",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=0.0,
            offz=0.0,
            scalex=1.0,
            scalez=1.0,
            stopatexitstate=true,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_gourdo_heal_pst",
          param={
            fxname="fx_player_skills_gourdo_loop_pst",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=-0.25,
            offz=-0.10000000149012,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_gourdo_heal_pre",
          param={
            fxname="fx_player_skills_gourdo_pre",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=-0.25,
            offz=-0.10000000149012,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_gourdo_heal_loop",
          param={
            fxname="skill_gourdo_heal_loop_swirl_back",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=0.0,
            offz=0.0099999997764826,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_gourdo_heal_loop",
          param={
            fxname="fx_player_skills_gourdo_loop",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=-0.25,
            offz=-0.12999999523163,
          },
        },
        {
          eventtype="spawneffect",
          name="vfx-skill_gourdo_heal_loop",
          param={
            fxname="skill_gourdo_heal_loop_swirl_frnt",
            inheritrotation=true,
            ischild=true,
            offx=0.0,
            offy=0.0,
            offz=-0.33000001311302,
          },
        },
        {
          eventtype="spawnparticles",
          name="vfx-skill_groak_vacuum-broken",
          param={
            detachatexitstate=true,
            duration=20.0,
            ischild=true,
            particlefxname="groak_air_suck",
            stopatexitstate=true,
            use_entity_facing=true,
          },
        },
      },
      state_events={
        skill_miniboss_floracrane_dive_focus={
          {
            eventtype="spawneffect",
            name="vfx-skill_flora_dive",
            param={
              detachatexitstate=true,
              fxname="fx_player_skills_floracrane_dive_focus_trail",
              inheritrotation=true,
              ischild=true,
            },
          },
          {
            eventtype="spawneffect",
            name="vfx-skill_flora_dive",
            param={
              detachatexitstate=true,
              fxname="fx_player_skills_floracrane_dive_focus",
              inheritrotation=true,
              ischild=true,
            },
          },
          {
            eventtype="spawneffect",
            name="vfx-skill_flora_dive",
            param={
              detachatexitstate=true,
              fxname="fx_player_skills_floracrane_dive_ul_focus",
              inheritrotation=true,
              ischild=true,
              offx=0.0,
              offy=0.0,
              offz=0.029999999329448,
            },
          },
          {
            eventtype="spawneffect",
            name="vfx-skill_flora_dive",
            param={
              detachatexitstate=true,
              fxname="fx_player_skills_floracrane_dive_ol_focus",
              inheritrotation=true,
              ischild=true,
              offx=0.0,
              offy=0.0,
              offz=-0.10000000149012,
            },
          },
        },
      },
    },
  },
}
