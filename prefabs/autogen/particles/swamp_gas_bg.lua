-- Generated by ParticleEditor and loaded by particles_autogen_data
return {
  __displayName="swamp_gas_bg",
  blendmode=1,
  bloom=0,
  curves={  },
  emit_rate=4.0,
  emit_world_space=true,
  emitters={
    {
      bake_time=5.0,
      blendmode=1,
      bloom=0.4990000128746,
      burst_amt=0.0,
      burst_time=0.0,
      curves={
        color={
          data={ 439955715, 793856022, 1298085673, 1231766038, 475676675,},
          num=5,
          time={
            0.0082101806239737,
            0.1576354679803,
            0.36945812807882,
            0.76354679802956,
            0.96059113300493,
          },
        },
        emission_rate={
          data={
            0.0,
            0.49500000476837,
            0.098333336412907,
            0.96499997377396,
            0.27833333611488,
            0.93999999761581,
            0.33000001311302,
            0.26499998569489,
            0.61833333969116,
            0.26499998569489,
            0.7049999833107,
            0.93999999761581,
            0.89833331108093,
            0.25999999046326,
            1.0,
            0.25,
          },
          enabled=true,
        },
        scale={
          data={
            0.0,
            1.0,
            0.14285714924335,
            0.97959184646606,
            0.28666666150093,
            0.95999997854233,
            0.42833334207535,
            0.89999997615814,
            0.58333331346512,
            0.81000000238419,
            0.71833330392838,
            0.7150000333786,
            0.90499997138977,
            0.56499999761581,
            1.0,
            0.47000002861023,
          },
          enabled=true,
          max=1.0,
          min=0.10000000149012,
        },
        velocityAspect={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
      },
      emission_rate_loops=true,
      emission_rate_time=10.0,
      emit_rate=2.0,
      emit_world_space=false,
      erode_bias=0.0,
      friction_max=0.0,
      friction_min=0.0,
      gravity_x=0.0,
      gravity_y=0.0,
      gravity_z=0.0,
      max_particles=50.0,
      name="gasRising",
      r=0.0,
      spawn={
        aspect=1.0,
        box={ -2.397500038147, 2.397500038147, -0.1955000013113, 0.1955000013113,},
        color=4294967295,
        emit_grid_colums=10.0,
        emit_grid_rows=10.0,
        emit_on_grid=true,
        fps=30.0,
        layer=5,
        rot={ 0.0, 6.2831853071796,},
        rotvel={ -0.34906585039887, 0.34906585039887,},
        size={ 3.0, 5.0,},
        sort_order=1,
        ttl={ 5.0, 10.0,},
        vel={ -0.20000000298023, 0.20000000298023, 0.0, 0.5, 0, 0,},
      },
      texture={ "particles.xml", "CloudPart.tex",},
      use_bounce=false,
      use_local_ref_frame=true,
      velocity_inherit=0.0,
      x=0.0,
      y=0.0,
      z=0.0,
    },
  },
  group="fog",
  max_particles=100,
  spawn={
    box={ 0, 0, 0, 0,},
    color=16777215,
    size={ 10, 10,},
    ttl={ 4, 4,},
    vel={ 0, 0, 10, 10, 0, 0,},
  },
  texture={ "particles.xml", "circle.tex",},
}