-- Generated by PropEditor and loaded by prop_autogen.lua
return {
  __displayName="bandiforest_bg_tree_vine",
  bank="bandiforest_bg_tree",
  build="bandiforest_bg_tree",
  fade={ bottom=-2.72, top=1.05,},
  group="swamp_props",
  layer="auto",
  parallax={
    { anim="thatfront", dist=-0.25,},
    { anim="thatmid_above", autosortlayer="above",},
    { anim="thatback_above", autosortlayer="above", dist=1.0,},
    {
      anim="thatback_below",
      autosortlayer="below",
      dist=1.0001000165939,
      underground=true,
    },
    {
      anim="thatmid_below",
      autosortlayer="below",
      dist=9.9999997473788e-05,
      underground=true,
    },
  },
  proptype=1,
  randomize=true,
  variations=4,
}
