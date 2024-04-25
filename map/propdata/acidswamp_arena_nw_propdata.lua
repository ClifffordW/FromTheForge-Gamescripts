return {
  room_loot={ { x=9.5, z=-10.5,},},
  spawner_creature={
    { script_args={ creature_spawner_type="perimeter",}, x=-4.43, z=11.7,},
    { script_args={ creature_spawner_type="perimeter",}, x=19.95, z=11.74,},
    { script_args={ creature_spawner_type="perimeter",}, x=25.71, z=0.91,},
    { script_args={ creature_spawner_type="battlefield",}, x=9.97, z=-12.58,},
    { script_args={ creature_spawner_type="battlefield",}, x=15.64, z=-14.88,},
    { script_args={ creature_spawner_type="battlefield",}, x=16.96, z=-12.71,},
    { script_args={ creature_spawner_type="battlefield",}, x=-0.79, z=-14.85,},
    { script_args={ creature_spawner_type="battlefield",}, x=5.99, z=-16.11,},
    { script_args={ creature_spawner_type="battlefield",}, x=18.02, z=-1.35,},
    { script_args={ creature_spawner_type="battlefield",}, x=9.46, z=3.37,},
    { script_args={ creature_spawner_type="battlefield",}, x=0.45, z=-16.45,},
  },
  spawner_propdestructible={
    { z=1.0,},
    { x=-6.0, z=-15.0,},
    { x=3.0, z=-8.0,},
    { x=22.0, z=-1.0,},
    { x=17.0, z=-8.0,},
  },
  spawner_stationaryenemy={
    { script_args={  }, x=-3.0, z=3.0,},
    { script_args={  }, x=-8.0, z=3.0,},
    { script_args={  }, x=10, z=-4,},
    { script_args={  }, x=21.0, z=7.0,},
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
      x=-8.5,
      z=12.5,
    },
  },
}