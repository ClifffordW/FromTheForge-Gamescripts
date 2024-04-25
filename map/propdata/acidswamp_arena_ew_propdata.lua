return {
  room_loot={ { x=0.5, z=-0.5,},},
  spawner_creature={
    { script_args={ creature_spawner_type="perimeter",}, x=11.59, z=12.18,},
    { script_args={ creature_spawner_type="perimeter",}, x=25.78, z=6.82,},
    { script_args={ creature_spawner_type="perimeter",}, x=-14.1, z=12.03,},
    { script_args={ creature_spawner_type="perimeter",}, x=0.06, z=12.08,},
    { script_args={ creature_spawner_type="battlefield",}, x=-9.7, z=2.19,},
    { script_args={ creature_spawner_type="battlefield",}, x=12.07, z=-8.07,},
    { script_args={ creature_spawner_type="battlefield",}, x=13.4, z=-6.1,},
    { script_args={ creature_spawner_type="battlefield",}, x=-5.9, z=-8.57,},
    { script_args={ creature_spawner_type="battlefield",}, x=9.76, z=8.87,},
    { script_args={ creature_spawner_type="battlefield",}, x=-7.1, z=-7.25,},
    { script_args={ creature_spawner_type="battlefield",}, x=-0.84, z=2.4,},
    { script_args={ creature_spawner_type="battlefield",}, x=-11.12, z=0.18,},
  },
  spawner_propdestructible={
    { x=12.0, z=2.0,},
    { x=-17.0, z=6.0,},
    { x=2.0, z=-4.0,},
    { x=-11.0, z=-4.0,},
    { x=16.0, z=-12.0,},
  },
  spawner_stationaryenemy={
    { script_args={  }, x=2, z=8,},
    { script_args={  }, x=-21.0, z=7.0,},
    { script_args={  }, x=-14.0, z=-8.0,},
    { script_args={  }, x=14.0, z=9.0,},
  },
  spawner_trap={
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=16.5,
      z=12.5,
    },
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=-9.5,
      z=12.5,
    },
  },
}