-- Generated by PropEditor and loaded by prop_autogen.lua
return {
  __displayName="player_base_1",
  clickable=true,
  gridsize={ { expand={ bottom=2,}, h=3, w=3,},},
  group="town_buildings",
  hostspawn=true,
  isminimal=true,
  networked=1,
  parallax={
    { anim="chair_front", dist=-0.8, shadow=true,},
    { anim="chair_back", dist=-0.6, shadow=true,},
    { anim="stone_front", shadow=true,},
    { anim="hay_front", dist=0.30000001192093, shadow=true,},
    { anim="hay_back", dist=0.5, shadow=true,},
    { anim="stone_back", dist=0.69999998807907, shadow=true,},
  },
  parallax_use_baseanim_for_idle=true,
  physicssize=1.5,
  physicstype="dec",
  script="buildings",
  script_args={
    skins={ groups={  }, sets={  }, symbols={  },},
    upgrades={ has_upgrade=true, prefab="forge",},
  },
  sound=true,
}
