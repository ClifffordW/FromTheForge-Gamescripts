-- Generated by ParticleEditor and loaded by particles_autogen_data
return {
  __displayName="heart_weapon_trail",
  emitters={
    {
      blendmode=1,
      bloom=1.0,
      burst_amt=2.0,
      curves={
        color={
          data={ 4286677259, 4286626904, 4281715603, 4009766308, 3791697538, 4286611459,},
          num=6,
          time={
            0,
            0.11330049261084,
            0.21182266009852,
            0.44006568144499,
            0.69622331691297,
            0.99178981937603,
          },
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.0,
            0.14285714924335,
            0.020408153533936,
            0.28571429848671,
            0.081632673740387,
            0.4285714328289,
            0.18367350101471,
            0.57142859697342,
            0.3265306353569,
            0.71428573131561,
            0.51020407676697,
            0.85714286565781,
            0.73469388484955,
            1.0,
            1.0,
          },
          enabled=true,
          max=1.5,
          min=0.69999998807907,
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
      emit_rate=3.0,
      erode_bias=0.0,
      friction_max=3.0,
      friction_min=1.0,
      gravity_x=0.0,
      gravity_y=-0.25,
      gravity_z=0.0,
      max_particles=500.0,
      name="hearts",
      spawn={
        box={ 0.0, 0.0, 0.0, 0.0,},
        color=4290797823,
        emit_arc_max=360.0,
        emit_grid_colums=10.0,
        emit_grid_rows=10.0,
        emit_on_grid=true,
        fps=24.0,
        rot={ -0.17453292519943, 0.17453292519943,},
        rotvel={ -0.78539816339745, 0.78539816339745,},
        size={ 0.40000000596046, 0.80000001192093,},
        ttl={ 0.5, 1.0,},
        vel={ -2.0, 2.0, 4.0, 6.0, 0, 0,},
      },
      texture={ "particles.xml", "heat_outlined.tex",},
      use_bounce=false,
      x=0.0,
      y=0.0,
      z=0.0,
    },
    {
      blendmode=1,
      bloom=0.5,
      burst_amt=0.0,
      curves={
        color={
          data={ 4278190091, 4028071595, 3828004052, 3326171900, 2787479039, 2854429443,},
          num=6,
          time={ 0, 0.12315270935961, 0.21018062397373, 0.44334975369458, 0.69129720853859, 1,},
        },
        emission_rate={ data={ -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,}, enabled=false,},
        scale={
          data={
            0.0,
            0.26499998569489,
            0.16166666150093,
            0.52999997138977,
            0.37000000476837,
            0.875,
            0.58666664361954,
            0.99500000476837,
            0.78333336114883,
            0.99500000476837,
            0.93500000238419,
            0.70500004291534,
            1.0,
            0.0099999904632568,
            -1.0,
            0.0,
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
      emit_rate=3.0,
      erode_bias=0.0,
      friction_max=3.0,
      friction_min=1.0,
      gravity_x=0.0,
      gravity_y=-0.25,
      gravity_z=0.0,
      max_particles=500.0,
      name="hearts2",
      spawn={
        box={ -0.25, 0.25, -0.25, 0.25,},
        color=4290797823,
        emit_arc_max=360.0,
        emit_grid_colums=10.0,
        emit_grid_rows=10.0,
        emit_on_grid=true,
        fps=24.0,
        rot={ -0.17453292519943, 0.17453292519943,},
        rotvel={ -0.78539816339745, 0.78539816339745,},
        size={ 0.5, 1.0,},
        ttl={ 0.5, 1.0,},
        vel={ -1.0, 1.0, 4.0, 6.0, 0, 0,},
      },
      texture={ "particles.xml", "heart_blurry.tex",},
      use_bounce=false,
      x=0.0,
      y=0.0,
      z=0.0,
    },
  },
  group="charm",
  mode_2d=false,
  sound={ autostop=true, sound_max_count=1.0, soundevent="Power_Charm_WeaponTrail_LP",},
}
