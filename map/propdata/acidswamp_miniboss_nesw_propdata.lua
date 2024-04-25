return {
  room_loot={ { x=1.5, z=-0.5,},},
  spawner_creature={
    { script_args={ creature_spawner_type="perimeter",}, x=12.96, z=14.19,},
    { script_args={ creature_spawner_type="perimeter",}, x=23.39, z=-5.48,},
    { script_args={ creature_spawner_type="perimeter",}, x=-14.27, z=13.92,},
    { script_args={ creature_spawner_type="battlefield",}, x=-9.64, z=7.1,},
    { script_args={ creature_spawner_type="battlefield",}, x=6.49, z=-13.17,},
    { script_args={ creature_spawner_type="battlefield",}, x=14.29, z=-5.62,},
    { script_args={ creature_spawner_type="battlefield",}, x=-11.31, z=-2.89,},
    { script_args={ creature_spawner_type="battlefield",}, x=-11.18, z=5.92,},
    { script_args={ creature_spawner_type="battlefield",}, x=12.4, z=2.71,},
    { script_args={ creature_spawner_type="battlefield",}, x=5.54, z=6.58,},
    { script_args={ creature_spawner_type="battlefield",}, x=3.95, z=5.41,},
    { script_args={ creature_spawner_type="miniboss",}, x=-1.06, z=-1.84,},
  },
  spawner_propdestructible={ { x=-8.0, z=-6.0,}, { x=10.0, z=-6.0,}, { x=-6.0, z=9.0,}, { x=2.0, z=-10.0,},},
  spawner_stationaryenemy={
    { script_args={  }, x=3.0, z=-3.0,},
    { script_args={  }, x=2.0, z=11.0,},
    { script_args={  }, x=-5.0, z=-11.0,},
    { script_args={  }, x=15.0, z=2.0,},
  },
  spawner_trap={
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=-18.5,
      z=14.5,
    },
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=10.5,
      z=18.5,
    },
  },
}