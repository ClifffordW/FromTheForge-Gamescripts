return {
  room_loot={ { x=1.5, z=4.5,},},
  spawner_creature={
    { script_args={ creature_spawner_type="perimeter",}, x=-15.85, z=12.58,},
    { script_args={ creature_spawner_type="perimeter",}, x=12.33, z=15.04,},
    { script_args={ creature_spawner_type="perimeter",}, x=15.5, z=-8.64,},
    { script_args={ creature_spawner_type="perimeter",}, x=19.71, z=9.28,},
    { script_args={ creature_spawner_type="battlefield",}, x=-7.0, z=10.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=9.0, z=-10.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=8.0, z=-8.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=-8.0, z=-9.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=-6.0, z=12.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=10.0, z=8.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=9.0, z=10.0,},
    { script_args={ creature_spawner_type="battlefield",}, x=-7.0, z=-7.0,},
  },
  spawner_propdestructible={
    { x=6.0, z=-14.0,},
    { x=-15.0, z=-6.0,},
    { x=10.0, z=-5.0,},
    { x=-10.0, z=9.0,},
  },
  spawner_stationaryenemy={
    { script_args={  }, x=1.0,},
    { script_args={  }, x=5.0, z=14.0,},
    { script_args={  }, x=-6.0, z=-14.0,},
    { script_args={  }, x=13.0, z=3.0,},
  },
  spawner_trap={
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=12.5,
      z=19.5,
    },
    {
      place_anywhere=true,
      script_args={ trap_types={ "trap_acidgeyser",},},
      x=-7.5,
      z=19.5,
    },
  },
}