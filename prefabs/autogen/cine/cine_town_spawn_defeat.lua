-- Generated by CineEditor and loaded by cine_autogen.lua
return {
  __displayName="cine_town_spawn_defeat",
  pause_role_sg={  },
  scene_duration=150.0,
  scene_init={  },
  subactors={  },
  timelines={
    cameradist={
      { 0, 1, { eventtype="cameradist", param={ cut=true, dist=22.0, duration=1,},},},
      {
        95,
        150,
        {
          eventtype="cameradist",
          param={
            curve={
              0.0,
              0,
              0.14285714924335,
              0.049515571445227,
              0.28571429848671,
              0.1882551163435,
              0.4285714328289,
              0.38873952627182,
              0.57142859697342,
              0.61126053333282,
              0.71428573131561,
              0.81174492835999,
              0.85714286565781,
              0.95048445463181,
              1.0,
              1.0,
            },
            duration=55,
          },
        },
      },
    },
    camerapitch={
      { 0, 1, { eventtype="camerapitch", param={ cut=true, duration=1, pitch=16.0,},},},
      {
        109,
        150,
        {
          eventtype="camerapitch",
          param={
            curve={
              0.0,
              0,
              0.14285714924335,
              0.040816329419613,
              0.28571429848671,
              0.16326531767845,
              0.4285714328289,
              0.36734694242477,
              0.57142859697342,
              0.63265311717987,
              0.71428573131561,
              0.83673471212387,
              0.85714286565781,
              0.95918369293213,
              1.0,
              1.0,
            },
            duration=41,
            pitch=23.578178405762,
          },
        },
      },
    },
    cameratargetbegin={
      {
        0,
        1,
        {
          eventtype="cameratargetbegin",
          param={ cut=true, duration=1,},
          target_role="players",
        },
      },
    },
    cameratargetend={
      {
        95,
        150,
        {
          apply_to_all_players=false,
          eventtype="cameratargetend",
          param={
            curve={
              0.0,
              0,
              0.14285714924335,
              0.040816329419613,
              0.28571429848671,
              0.16326531767845,
              0.4285714328289,
              0.36734694242477,
              0.57142859697342,
              0.63265311717987,
              0.71428573131561,
              0.83673471212387,
              0.85714286565781,
              0.95918369293213,
              1.0,
              1.0,
            },
            duration=55,
          },
          target_role="players",
        },
      },
    },
    disableplayinput={ { 0, 150, { eventtype="disableplayinput", param={  },},},},
    fade={
      {
        0,
        16,
        { eventtype="fade", param={ duration=16, fade_in=true, fade_type="black",},},
      },
    },
    gotostate={
      {
        81,
        91,
        {
          apply_to_all_players=true,
          eventtype="gotostate",
          param={ duration=10, statename="knockdown_getup",},
          target_role="players",
        },
      },
    },
    letterbox={ { 0, 110, { eventtype="letterbox", param={ duration=110,},},},},
    musicstart={ { 140, 150, { eventtype="musicstart", is_unedited=true, param={  },},},},
    playsound={
      {
        0,
        6,
        {
          eventtype="playsound",
          param={ autostop=true, duration=6, soundevent="flying_machine", stopatexitstate=true,},
        },
      },
      {
        61,
        79,
        {
          eventtype="playsound",
          param={
            autostop=true,
            duration=18,
            name="ratchet2",
            soundevent="flying_machine_Ratchet_LP",
            stopatexitstate=true,
          },
        },
      },
      {
        46,
        54,
        {
          eventtype="playsound",
          param={ autostop=true, duration=8, soundevent="Dirt_bodyfall", stopatexitstate=true,},
        },
      },
      {
        5,
        41,
        {
          eventtype="playsound",
          param={
            autostop=true,
            duration=36,
            name="ratchet1",
            soundevent="flying_machine_Ratchet_LP",
            stopatexitstate=true,
          },
        },
      },
    },
    pushanim={
      {
        1,
        10,
        {
          apply_to_all_players=true,
          eventtype="pushanim",
          param={ anim="claw_blank", duration=9, interrupt=true,},
          target_role="players",
        },
      },
      {
        10,
        71,
        {
          apply_to_all_players=true,
          eventtype="pushanim",
          param={ anim="claw_drop", duration=61,},
          target_role="players",
        },
      },
      {
        71,
        81,
        {
          apply_to_all_players=true,
          eventtype="pushanim",
          param={ anim="knockdown_idle", duration=10,},
          target_role="players",
        },
      },
    },
    spawnimpactfx={
      {
        48,
        56,
        {
          eventtype="spawnimpactfx",
          param={ duration=8, impact_size=3, impact_type=1, offx=0, offz=0,},
          target_role="players",
        },
      },
    },
    stopsound={
      { 39, 44, { eventtype="stopsound", param={ duration=5, name="ratchet",},},},
      { 94, 150, { eventtype="stopsound", param={ name="ratchet2",},},},
    },
    uihidehud={ { 0, 101, { eventtype="uihidehud", param={ duration=101,},},},},
  },
}
