-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="shake_groak",
  isfinal=true,
  prefab={ "groak", "groak_elite",},
  stategraphs={
    sg_groak={
      sg_events={
        {
          eventtype="shakecamera",
          name="shake-groundpound",
          param={ dist=50, duration=20.0, mode="VERTICAL", speed=0.019999999552965,},
        },
        {
          eventtype="shakecamera",
          name="shake-knockdown",
          param={ dist=50, duration=20.0, mode="FULL", speed=0.019999999552965,},
        },
        {
          eventtype="shakecamera",
          name="shake-groundpound_big",
          param={ dist=50, duration=40.0, mode="FULL", scale=0.25, speed=0.019999999552965,},
        },
        {
          eventtype="shakecamera",
          name="shake-walk",
          param={
            dist=50,
            duration=10.0,
            mode="VERTICAL",
            scale=0.10000000149012,
            speed=0.019999999552965,
          },
        },
        {
          eventtype="shakecamera",
          name="shake-dig",
          param={ dist=50, duration=20.0, mode="VERTICAL", speed=0.019999999552965,},
        },
        {
          eventtype="shakecamera",
          name="shake-dig_final",
          param={ dist=50, duration=45.0, mode="FULL", speed=0.019999999552965,},
        },
      },
    },
  },
}
