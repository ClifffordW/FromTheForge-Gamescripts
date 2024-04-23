-- Generated by ParticleEditor and loaded by particles_autogen_data
return {
  __displayName="item_land_epic",
  emitters={
    {
      blendmode=1,
      bloom=1.0,
      burst_amt=4.0,
      curves={
        color={
          data={ 3650354950, 3158441983, 2768305923,},
          num=3,
          time={ 0, 0.19047619047619, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.49000000953674,
            0.20333333313465,
            0.68000000715256,
            0.36166667938232,
            0.80000001192093,
            0.47166666388512,
            0.86000001430511,
            0.64499998092651,
            0.93500000238419,
            0.78166669607162,
            0.99000000953674,
            0.92166668176651,
            1.0,
            1.0,
            1.0,
          },
          enabled=true,
        },
        velocityAspect={
          data={
            0.0,
            0.10500001907349,
            0.22333332896233,
            0.5,
            0.39333334565163,
            0.69999998807907,
            0.54000002145767,
            0.80000001192093,
            0.66666668653488,
            0.88999998569489,
            0.8116666674614,
            0.94499999284744,
            1.0,
            0.99000000953674,
            -1.0,
            0.0,
          },
          enabled=false,
          max=1.0,
          speedMax=10.0,
        },
      },
      emission_rate_time=5,
      emit_rate=0.0,
      erode_bias=1.0,
      friction_max=1.597000002861,
      friction_min=1.597000002861,
      gravity_x=0.0,
      gravity_y=0.0,
      gravity_z=0.0,
      ground_projected=true,
      max_particles=500.0,
      name="rings",
      spawn={
        box={ 0.0, 0.0, 0.0, 0.0,},
        color=4290797823,
        emit_arc_max=360.0,
        emit_arc_min=-3.9100000858307,
        emit_arc_phase=0.0,
        emit_arc_vel=0.0,
        emit_grid_colums=10.0,
        emit_grid_rows=10.0,
        emit_on_grid=false,
        layer=4,
        rot={ -1.1519173063163, 1.1519173063163,},
        rotvel={ -1.5707963267949, 1.5707963267949,},
        size={ 1.0, 2.0,},
        ttl={ 0.20000000298023, 0.5,},
        vel={ 0.0, 0.0, 0.0, 0.0, 0, 0,},
      },
      texture={ "particles.xml", "ring_eroding.tex",},
      use_bounce=false,
      x=0.0,
      y=0.5,
      z=0.0,
    },
    {
      bake_time=0.0,
      blendmode=1,
      bloom=1.0,
      burst_amt=10.0,
      burst_time=0.0,
      curves={
        color={
          data={ 3753705217, 1510014972, 4286115838, 3432513405, 2264989441,},
          num=5,
          time={ 0, 0.11916264090177, 0.44927536231884, 0.79549114331723, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.064999997615814,
            0.23999999463558,
            0.61500000953674,
            0.48166665434837,
            0.83499997854233,
            0.65333330631256,
            0.71000003814697,
            0.82333332300186,
            0.50499999523163,
            1.0,
            0.0049999952316284,
            -1.0,
            0.0,
            0.0,
            0.0,
          },
          enabled=true,
          max=1.0,
        },
        velocityAspect={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
      },
      emission_rate_loops=false,
      emission_rate_time=1.0,
      emit_rate=0.0,
      emit_world_space=false,
      erode_bias=0.0,
      friction_max=0.0,
      friction_min=0.0,
      gravity_x=0.0,
      gravity_y=-1.5,
      gravity_z=0.0,
      max_particles=100.0,
      r=0.0,
      spawn={
        aspect=1.0,
        box={ -0.050000000745058, 0.050000000745058, -0.050000000745058, 0.050000000745058,},
        color=4294901503,
        emit_on_grid=false,
        fps=20.0,
        rot={ 0.0, 0.0,},
        rotvel={ -6.2831853071796, 6.2831853071796,},
        size={ 0.10000000149012, 0.30000001192093,},
        ttl={ 0.30000001192093, 0.60000002384186,},
        vel={ -3.0, 3.0, 3.0, 6.0, 0, 0,},
      },
      texture={ "particles.xml", "circle_ringed_alpha2.tex",},
      velocity_inherit=0.0,
      x=0.0,
      y=0.0,
      z=0.0,
    },
  },
  group="drops",
  mode_2d=false,
  sound={ sound_max_count=1.0, soundevent="item_land_epic",},
}
