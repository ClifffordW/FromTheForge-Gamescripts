return {
  room_loot={ { x=0.5, z=-0.5,},},
  spawner_creature={
    { script_args={ creature_spawner_type="battlefield",}, x=7.55, z=3.01,},
    { script_args={ creature_spawner_type="perimeter",}, x=20.1, z=5.71,},
    { script_args={ creature_spawner_type="perimeter",}, x=-14.83, z=16.53,},
    { script_args={ creature_spawner_type="perimeter",}, x=4.82, z=16.61,},
    { script_args={ creature_spawner_type="battlefield",}, x=-11.9, z=8.4,},
    { script_args={ creature_spawner_type="battlefield",}, x=3.37, z=-11.22,},
    { script_args={ creature_spawner_type="battlefield",}, x=2.58, z=-9.37,},
    { script_args={ creature_spawner_type="battlefield",}, x=-5.7, z=-2.88,},
    { script_args={ creature_spawner_type="battlefield",}, x=6.83, z=0.7,},
    { script_args={ creature_spawner_type="battlefield",}, x=-13.35, z=-8.9,},
    { script_args={ creature_spawner_type="battlefield",}, x=-4.3, z=-0.61,},
    { script_args={ creature_spawner_type="battlefield",}, x=-10.49, z=6.61,},
  },
  spawner_propdestructible={
    { x=-2.0, z=-7.0,},
    { x=-20.0, z=8.0,},
    { x=2.0, z=-1.0,},
    { x=-11.0, z=-2.0,},
    { x=14, z=5,},
  },
  spawner_stationaryenemy={
    { script_args={  }, x=-1.0, z=4.0,},
    { script_args={  }, x=-22.0, z=-13.0,},
    { script_args={  }, x=-14.0, z=-2.0,},
    { script_args={  }, x=6.0, z=-4.0,},
  },
  spawner_trap={
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=10.5,
      z=17.5,
    },
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=-20.5,
      z=17.5,
    },
  },
}