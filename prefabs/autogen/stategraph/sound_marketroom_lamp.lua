-- Generated by Embellisher and loaded by stategraph_autogen.lua
return {
  __displayName="sound_marketroom_lamp",
  isfinal=true,
  needSoundEmitter=true,
  prefab={ "marketroom_lamp",},
  stategraphs={
    marketroom_lamp={
      events={
        idle={
          {
            eventtype="playsound",
            frame=1,
            param={
              autostop=true,
              soundevent="building_marketroom_lamp_LP",
              stopatexitstate=true,
              volume=66.0,
            },
          },
        },
      },
    },
  },
}
