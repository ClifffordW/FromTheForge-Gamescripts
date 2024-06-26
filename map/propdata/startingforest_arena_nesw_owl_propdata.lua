return {
  lightspot_circle={
    { script_args={ light_color="4D453FFF" }, variation=1, x=-3.67, z=-1.69 },
    { script_args={ light_color="4D453FFF" }, variation=1, x=-10.65, z=-4.72 },
    { script_args={ light_color="4D453FFF" }, variation=2, x=3.17, z=-8.23 },
    { script_args={ light_color="4D453FFF" }, variation=1, x=10.95, z=0.37 },
    { script_args={ light_color="4D453FFF" }, variation=1, x=-2.21, z=4.64 } 
  },
  room_loot={ { x=8.5, z=2.5 }, { x=-5.5, z=2.5 } },
  spawner_creature={
    { script_args={ creature_spawner_type="perimeter",}, x=6.78, z=21.04 },
    { script_args={ creature_spawner_type="perimeter",}, x=-6.67, z=16.72 },
    { script_args={ creature_spawner_type="perimeter",}, x=-22.77, z=4.9 },
    { script_args={ creature_spawner_type="perimeter",}, x=22.57, z=4.6 },
	{ script_args={ creature_spawner_type="miniboss",}, x=-0.12, z=-1.55 },
    { script_args={ creature_spawner_type="battlefield",}, x=6.0, z=8.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=-11.0, z=9.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=8.0, z=-12.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=-11.0, z=-11.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=-13.0, z=-10.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=-12.0, z=7.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=4.0, z=9.0 },
    { script_args={ creature_spawner_type="battlefield",}, x=10.0, z=-10.0 },
  },
  spawner_propdestructible={
    { x=-8.0, z=-10.0 },
    { x=-16.0, z=-8.0 },
    { x=3.0, z=-5.0 },
    { x=6.0, z=4.0 },
    { x=-4.0, z=8.0 },
    { x=9.0, z=8.0 },
    { x=12.0, z=-10.0 },
    { x=16.0, z=-5.0 },
    { x=16.0, z=4.0 },
    { x=-10.0, z=4.0 } 
  },
  spawner_stationaryenemy={
    { script_args={ spawn_areas={ "battlefield", "left" } }, x=-3.0, z=4.0 },
    { script_args={ spawn_areas={ "battlefield", "left" } }, x=-5.0, z=-4.0 },
    {
      script_args={ spawn_areas={ "perimeter", "right", "battlefield" } },
      x=12.0,
      z=5.0 
    },
    { script_args={ spawn_areas={ "perimeter", "right", "battlefield" } }, x=15.0 },
    {
      script_args={ spawn_areas={ "perimeter", "right", "battlefield" } },
      x=12.0,
      z=-5.0 
    },
    { script_args={ spawn_areas={ "battlefield", "center" } }, x=3.0, z=1.0 },
    { script_args={ spawn_areas={ "battlefield", "bottom" } }, z=-8.0 },
    { script_args={ spawn_areas={ "perimeter", "top" } }, x=-1.0, z=10.0 } 
  },
  spawner_trap={
    { script_args={ trap_types={ "trap_spike" } }, x=6.0, z=-1.0 },
    { script_args={ trap_types={ "trap_exploding", "trap_spike" } }, x=-5.0, z=-1.0 },
    { script_args={ trap_types={ "trap_exploding", "trap_spike" } }, z=4.0 },
    { script_args={ trap_types={ "trap_exploding" } }, x=-2.0, z=-5.0 },
    { script_args={ trap_types={ "trap_exploding" } }, x=-11.0 },
    { script_args={ trap_types={ "trap_exploding" } }, x=-15.0, z=-12.0 },
    { script_args={ trap_types={ "trap_exploding" } }, x=13.0, z=9.0 },
    { script_args={ trap_types={ "trap_exploding" } }, x=-16.0, z=7.0 } 
  } 
}
