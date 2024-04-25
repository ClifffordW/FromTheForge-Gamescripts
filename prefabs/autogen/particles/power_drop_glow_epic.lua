-- Generated by ParticleEditor and loaded by particles_autogen_data
return {
  __displayName="power_drop_glow_epic",
  emitters={
    {
      bake_time=2.0,
      blendmode=1,
      bloom=1.0,
      burst_amt=0.0,
      curves={
        color={
          data={ 1207303937, 2314665854, 1757199616,},
          num=3,
          time={ 0, 0.4991789819376, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.5,
            1.0,
            1.0,
            -1.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
          },
          enabled=true,
          max=2.0,
          min=0.0,
        },
        velocityAspect={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
      },
      emission_rate_time=5,
      emit_rate=0.5,
      erode_bias=0.0,
      max_particles=100.0,
      name="glow",
      spawn={
        box={ 0.0, 0.0, 0.0, 0.0,},
        color=3831692799,
        emit_on_grid=false,
        shape_alignment=0.0,
        size={ 1.5, 1.5,},
        ttl={ 2.0, 2.0,},
        vel={ 0, 0, 0.0, 0.0, 0, 0,},
      },
      texture={ "particles2.xml", "glow.tex",},
      use_bounce=false,
      use_local_ref_frame=true,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      bake_time=2.0,
      blendmode=1,
      bloom=1.0,
      burst_amt=0.0,
      curves={
        color={
          data={ 3254583046, 2281242430, 1207303937,},
          num=3,
          time={ 0, 0.64309210526316, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.019999980926514,
            1.0,
            1.0,
            -1.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
          },
          enabled=true,
          max=2.0,
          min=0.0,
        },
        velocityAspect={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
      },
      emission_rate_time=5,
      emit_rate=8.0,
      erode_bias=0.0,
      max_particles=50.0,
      name="flares",
      spawn={
        aspect=4.4120001792908,
        box={ 0.0, 0.0, 0.0, 0.0,},
        color=3831692799,
        emit_arc_max=360.0,
        emit_on_grid=false,
        random_position=0.0,
        rot={ -6.2831853071796, 6.2831853071796,},
        rotvel={ 0, 0,},
        shape_alignment=0.0,
        size={ 0.25, 0.5,},
        ttl={ 1.0, 3.0,},
        vel={ 0, 0, 0.0, 0.0, 0, 0,},
      },
      texture={ "particles2.xml", "lightray_offset.tex",},
      use_bounce=false,
      use_local_ref_frame=true,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      blendmode=1,
      bloom=1.0,
      burst_amt=0.0,
      curves={
        color={
          data={ 3791519743, 2478823167, 1207303939,},
          num=3,
          time={ 0, 0.70114942528736, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            1.0,
            0.78333336114883,
            0.99500000476837,
            0.93500000238419,
            0.70500004291534,
            1.0,
            0.0099999904632568,
            -1.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
          },
          enabled=true,
          max=0.30000001192093,
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
          max=3.1579999923706,
          min=0.38299998641014,
          speedMax=10.0,
        },
      },
      emission_rate_time=5,
      emit_rate=3.0,
      erode_bias=0.0,
      friction_max=6.0,
      friction_min=3.0,
      gravity_x=0.0,
      gravity_y=0.25,
      gravity_z=0.0,
      max_particles=20.0,
      name="spores",
      spawn={
        box={ -0.5, 0.5, -0.5, 0.5,},
        color=4290797823,
        emit_arc_max=360.0,
        emit_grid_colums=10.0,
        emit_grid_rows=10.0,
        emit_on_grid=false,
        fps=24.0,
        rot={ -2.7467992620098, 2.4377013343025,},
        rotvel={ -3.1415926535898, 3.1415926535898,},
        shape=1,
        size={ 0.20000000298023, 0.60000002384186,},
        ttl={ 1.0, 3.0,},
        vel={ -2.0, 2.0, 0.0, 5.0, 0, 0,},
      },
      texture={ "particles.xml", "shape_hexagon2.tex",},
      use_bounce=false,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      bake_time=0.0,
      blendmode=1,
      bloom=1.0,
      burst_amt=0.0,
      burst_time=0.0,
      curves={
        color={
          data={ 3573415681, 3084178942, 1889181953,},
          num=3,
          time={ 0, 0.50410509031199, 0.99343185550082,},
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
      emit_rate=8.0,
      emit_world_space=false,
      erode_bias=0.0,
      friction_max=5.0,
      friction_min=4.0,
      gravity_x=0.0,
      gravity_y=0.5,
      gravity_z=0.0,
      max_particles=100.0,
      name="dotsshape",
      r=0.0,
      spawn={
        aspect=1.0,
        box={ -1.0, 1.0, -1.0, 1.0,},
        color=4294901503,
        emit_on_grid=false,
        fps=24.0,
        rot={ 0.0, 0.0,},
        rotvel={ -6.2831853071796, 6.2831853071796,},
        shape=1,
        size={ 0.10000000149012, 0.30000001192093,},
        ttl={ 0.30000001192093, 0.60000002384186,},
        vel={ -1.0, 1.0, -1.0, 1.0, 0, 0,},
      },
      texture={ "particles.xml", "shape_hexagon2.tex",},
      use_bounce=false,
      use_local_ref_frame=true,
      velocity_inherit=0.0,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      blendmode=1,
      bloom=1.0,
      burst_amt=0.0,
      curves={
        color={
          data={ 3690724614, 2969041724, 2309597955,},
          num=3,
          time={ 0.0082236842105263, 0.19704433497537, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.0,
            0.14285714924335,
            0.26530614495277,
            0.28571429848671,
            0.48979592323303,
            0.4285714328289,
            0.6734693646431,
            0.57142859697342,
            0.81632655858994,
            0.71428573131561,
            0.91836738586426,
            0.85714286565781,
            0.97959184646606,
            1.0,
            1.0,
          },
          enabled=true,
          max=1.2000000476837,
          min=0.0,
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
      emit_rate=2.0,
      erode_bias=0.0,
      friction_max=1.597000002861,
      friction_min=1.597000002861,
      gravity_x=0.0,
      gravity_y=0.0,
      gravity_z=0.0,
      max_particles=500.0,
      name="rings_hexagon",
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
        rot={ 0.0, 0.0,},
        rotvel={ 0.0, 0.0,},
        size={ 3.0, 3.0,},
        ttl={ 2.0, 2.0,},
        vel={ 0.0, 0.0, 0.0, 0.0, 0, 0,},
      },
      texture={ "particles.xml", "shape_hexagon.tex",},
      use_bounce=false,
      use_local_ref_frame=true,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      blendmode=1,
      bloom=1.0,
      burst_amt=0.0,
      curves={
        color={
          data={ 3690724614, 2616917803, 2309597955,},
          num=3,
          time={ 0.0082236842105263, 0.19572368421053, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            1.0,
            0.14285714924335,
            0.85714286565781,
            0.28571429848671,
            0.71428573131561,
            0.4285714328289,
            0.57142853736877,
            0.57142859697342,
            0.42857140302658,
            0.71428573131561,
            0.28571426868439,
            0.85714286565781,
            0.14285713434219,
            1.0,
            0.0,
          },
          enabled=true,
          max=1.2000000476837,
          min=0.30000001192093,
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
      emit_rate=120.0,
      erode_bias=0.0,
      friction_max=1.597000002861,
      friction_min=1.597000002861,
      gravity_x=0.0,
      gravity_y=0.0,
      gravity_z=0.0,
      max_particles=500.0,
      name="rings_hexagon_trail",
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
        rot={ 0.0, 0.0,},
        rotvel={ 0.0, 0.0,},
        size={ 1.5, 1.5,},
        ttl={ 0.20000000298023, 0.20000000298023,},
        vel={ 0.0, 0.0, 0.0, 0.0, 0, 0,},
      },
      texture={ "particles.xml", "shape_hexagon.tex",},
      use_bounce=false,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      bake_time=0.0,
      blendmode=1,
      bloom=2.0,
      burst_amt=0.0,
      burst_time=0.0,
      curves={
        color={
          data={ 3573415681, 3084178942, 1889181953,},
          num=3,
          time={ 0, 0.50410509031199, 0.99343185550082,},
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
      emit_rate=15.0,
      emit_world_space=false,
      erode_bias=0.0,
      friction_max=5.0,
      friction_min=4.0,
      gravity_x=0.0,
      gravity_y=0.5,
      gravity_z=0.0,
      max_particles=100.0,
      name="dotsshape_trail",
      r=0.0,
      spawn={
        aspect=1.0,
        box={ -0.44999998807907, 0.44999998807907, -0.44999998807907, 0.44999998807907,},
        color=4294901503,
        emit_on_grid=false,
        fps=24.0,
        rot={ 0.0, 0.0,},
        rotvel={ -6.2831853071796, 6.2831853071796,},
        size={ 0.10000000149012, 0.30000001192093,},
        ttl={ 0.30000001192093, 0.60000002384186,},
        vel={ 0.0, 0.0, 0.0, 0.0, 0, 0,},
      },
      texture={ "particles.xml", "shape_hexagon2.tex",},
      use_bounce=false,
      velocity_inherit=0.0,
      x=0.0,
      y=0.0,
      z=0.0,
    },
  },
  group="environment",
  mode_2d=false,
}
