-- Generated by PropEditor and loaded by prop_autogen.lua
return {
  __displayName="weapon_rack_cannon",
  clickable=true,
  gridsize={ { h=2, w=2,},},
  group="town_buildings",
  parallax={
    { anim="front", dist=-0.20000000298023, shadow=true,},
    { anim="mid", shadow=true,},
    { anim="back", dist=0.10000000149012, shadow=true,},
  },
  parallax_use_baseanim_for_idle=true,
  physicssize=1.3,
  physicstype="smdec",
  script="metaprogressstore",
  script_args={
    currency="Meta",
    currency_per_deposit=1.0,
    interact_radius=2.2,
    meta_progress="WEAPON_UNLOCKS",
    player_binding="None",
    purchase_type="Reward",
    status_widget_location="Prop",
    weapon="cannon",
    xp_per_currency=1.0,
  },
}
