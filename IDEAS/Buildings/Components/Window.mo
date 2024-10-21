within IDEAS.Buildings.Components;
model Window "Multipane window"
  replaceable IDEAS.Buildings.Data.Interfaces.Glazing glazing
    constrainedby IDEAS.Buildings.Data.Interfaces.Glazing "Glazing type"
    annotation (choicesAllMatching=true,
        Dialog(group=
          "Construction details"));

  extends IDEAS.Buildings.Components.Interfaces.PartialSurface(
    dT_nominal_a=-3,
    intCon_a(final A=
           A*(1 - frac),
           linearise=linIntCon_a or sim.linearise,
           dT_nominal=dT_nominal_a),
    QTra_design(fixed=false),
    Qgai(y=if sim.computeConservationOfEnergy then
                                                  (gain.propsBus_a.surfCon.Q_flow +
        gain.propsBus_a.surfRad.Q_flow + gain.propsBus_a.iSolDif.Q_flow + gain.propsBus_a.iSolDir.Q_flow) else 0),
    E(y=0),
    layMul(
      A=A_glass,
      nLay=glazing.nLay,
      mats=glazing.mats,
      energyDynamics=if windowDynamicsType == IDEAS.Buildings.Components.Interfaces.WindowDynamicsType.Normal then energyDynamics else Modelica.Fluid.Types.Dynamics.SteadyState,
      dT_nom_air=5,
      linIntCon=true,
      checkCoatings=glazing.checkLowPerformanceGlazing),
    setArea(A=A_glass*nWin),
    q50_zone(v50_surf=q50_internal*A_glass),
    res1(A=if sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.TwoPorts then A_glass/2 else A_glass),
    res2(A=A_glass/2));
  parameter Boolean linExtCon=sim.linExtCon
    "= true, if exterior convective heat transfer should be linearised (uses average wind speed)"
    annotation(Dialog(tab="Convection"));
  parameter Boolean linExtRad=sim.linExtRadWin
    "= true, if exterior radiative heat transfer should be linearised"
    annotation(Dialog(tab="Radiation"));

  parameter Real frac(
    min=0,
    max=1) = 0.15 "Area fraction of the window frame";
  parameter IDEAS.Buildings.Components.Interfaces.WindowDynamicsType
    windowDynamicsType=IDEAS.Buildings.Components.Interfaces.WindowDynamicsType.Two
    "Type of dynamics for glazing and frame: using zero, one combined or two states"
    annotation (Dialog(tab="Dynamics", group="Equations", enable = not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState));
  parameter Real fraC = frac
    "Ratio of frame and glazing thermal masses"
    annotation(Dialog(tab="Dynamics", group="Equations", enable= not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and windowDynamicsType == IDEAS.Buildings.Components.Interfaces.WindowDynamicsType.Two));
  parameter Boolean controlled = shaType.controlled
    " = true if shaType has a control input (see e.g. screen). Can be set to false manually to force removal of input icon."
    annotation(Dialog(tab="Advanced",group="Icon"));

  replaceable parameter IDEAS.Buildings.Data.Frames.None fraType
    constrainedby IDEAS.Buildings.Data.Interfaces.Frame "Window frame type"
    annotation (choicesAllMatching=true, Dialog(group=
          "Construction details"));
  replaceable IDEAS.Buildings.Components.Shading.None shaType
    constrainedby Shading.Interfaces.PartialShading(
      haveFrame=fraType.present and A*frac > 0,
      A_frame = A * frac,
      A_glazing = A * (1 - frac),
      Tenv_nom = sim.Tenv_nom,
      epsLw_frame = fraType.mat.epsLw,
      epsLw_glazing = layMul.parEpsLw_b,
      epsSw_frame = fraType.mat.epsSw,
      g_glazing=glazing.g_value,
      inc = incInt,
      linCon = linExtCon or sim.linearise,
      linRad = linExtRad or sim.linearise,
      final azi=aziInt) "First shading type" annotation (
    Placement(visible = true, transformation(origin = {-63, -49.4895}, extent = {{-11, -13.9877}, {11, 27.9754}}, rotation = 0)),
      choicesAllMatching=true, Dialog(group="Construction details"));

  Modelica.Blocks.Interfaces.RealInput Ctrl if controlled
    "Control signal between 0 and 1, i.e. 1 is fully closed" annotation (
      Placement(visible = true,transformation(
        origin={-50,-110},extent={{20,-20},{-20,20}},
        rotation=-90), iconTransformation(
        origin={-40,-100},extent={{10,-10},{-10,10}},
        rotation=-90)));



  parameter Real coeffsCp[:,:]=[0,0.4; 45,0.1; 90,-0.3; 135,-0.35; 180,-0.2; 225,
      -0.35; 270,-0.3; 315,0.1; 360,0.4]
      "Cp at different angles of attack"
      annotation(Dialog(tab="Airflow",group="Wind"));
  parameter Real Cs=sim.Cs
                       "Wind speed modifier"
    annotation (Dialog(tab="Airflow", group="Wind"));

  parameter Real Habs=1
    "Absolute height of boundary for correcting the wind speed"
    annotation (Dialog(tab="Airflow", group="Wind"));


  parameter Boolean use_trickle_vent = false
    "= true, to enable trickle vent"
    annotation(Dialog(group="Trickle vent", tab="Airflow"));
  parameter SI.MassFlowRate m_flow_nominal = 0
    "Nominal mass flow rate of trickle vent"
    annotation(Dialog(group="Trickle vent", tab="Airflow", enable=use_trickle_vent));
  parameter SI.PressureDifference dp_nominal(displayUnit="Pa") = 5
    "Pressure drop at nominal mass flow rate of trickle vent"
    annotation(Dialog(group="Trickle vent", tab="Airflow", enable=use_trickle_vent));
  Modelica.Blocks.Math.Gain gainDir(k=A*(1 - frac))
    "Gain for direct solar irradiation"
    annotation (Placement(visible = true, transformation(extent = {{-30, -46}, {-26, -42}}, rotation = 0)));
  Modelica.Blocks.Math.Gain gainDif(k=A*(1 - frac))
    "Gain for diffuse solar irradiation"
    annotation (Placement(transformation(extent={{-36,-50},{-32,-46}})));

  IDEAS.Airflow.Multizone.TrickleVent trickleVent(
    redeclare package Medium = Medium,
    final allowFlowReversal=true,
    m_flow_nominal=m_flow_nominal,
    dp_nominal=dp_nominal) if use_trickle_vent and sim.interZonalAirFlowType <> IDEAS.BoundaryConditions.Types.InterZonalAirFlow.None "Trickle vent"
    annotation (Placement(transformation(extent={{20,-88},{40,-68}})));
  replaceable
  IDEAS.Buildings.Components.BaseClasses.RadiativeHeatTransfer.SwWindowResponse
    solWin(
    final nLay=glazing.nLay,
    final SwAbs=glazing.SwAbs,
    final SwTrans=glazing.SwTrans,
    final SwTransDif=glazing.SwTransDif,
    final SwAbsDif=glazing.SwAbsDif)
    annotation (Placement(transformation(extent={{-10,-60},{10,-40}})));

  IDEAS.Buildings.Components.BaseClasses.ConvectiveHeatTransfer.InteriorConvection
    iConFra(final A=A*frac, final inc=incInt,
    linearise=linIntCon_a or sim.linearise)
                     if fraType.present
    "convective surface heat transimission on the interior side of the wall"
    annotation (Placement(transformation(extent={{20,60},{40,80}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor layFra(final G=(if
        fraType.briTyp.present then fraType.briTyp.G else 0) + (fraType.U_value)
        *A*frac)                if fraType.present  annotation (Placement(transformation(extent={{10,60},
            {-10,80}})));

  BoundaryConditions.SolarIrradiation.RadSolData radSolData(
    inc=incInt,
    azi=aziInt)
    annotation (Placement(transformation(extent={{-100,-60},{-80,-40}})));
protected
  final parameter Real U_value=glazing.U_value*(1-frac)+fraType.U_value*frac
    "Average window U-value";
  final parameter Boolean addCapGla =  windowDynamicsType == IDEAS.Buildings.Components.Interfaces.WindowDynamicsType.Two and not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState
    "Add lumped thermal capacitor for window glazing";
  final parameter Boolean addCapFra =  fraType.present and not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState
    "Added lumped thermal capacitor for window frame";
  final parameter Modelica.Units.SI.HeatCapacity Cgla=layMul.C
    "Heat capacity of glazing state";
  final parameter Modelica.Units.SI.HeatCapacity Cfra=layMul.C*fraC
    "Heat capacity of frame state";
  final parameter Modelica.Units.SI.Area A_glass=A*(1 - frac);
  Modelica.Blocks.Routing.RealPassThrough Tdes
    "Design temperature passthrough since propsBus variables cannot be addressed directly";
  Modelica.Thermal.HeatTransfer.Components.HeatCapacitor heaCapGlaInt(C=Cgla/2,
      T(fixed=energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial,
        start=T_start))                                                                             if addCapGla
    "Heat capacitor for glazing at interior"
    annotation (Placement(transformation(extent={{6,-12},{26,-32}})));
  Modelica.Thermal.HeatTransfer.Components.HeatCapacitor heaCapFraIn(C=Cfra/2,
      T(fixed=energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial,
        start=T_start))                                                                             if addCapFra
    "Heat capacitor for frame at interior"
    annotation (Placement(transformation(extent={{4,100},{24,120}})));
  Modelica.Blocks.Math.Add solDif(final k1=1, final k2=1)
    "Sum of ground and sky diffuse solar irradiation"
    annotation (Placement(visible = true, transformation(origin = {-42, -44}, extent = {{-4, -4}, {4, 4}}, rotation = 0)));
  Modelica.Thermal.HeatTransfer.Components.HeatCapacitor heaCapFraExt(C=Cfra/2,
      T(fixed=energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial,
        start=T_start))                                                                             if addCapFra
    "Heat capacitor for frame at exterior"
    annotation (Placement(transformation(extent={{-20,100},{0,120}})));
  Modelica.Thermal.HeatTransfer.Components.HeatCapacitor heaCapGlaExt(C=Cgla/2,
      T(fixed=energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial,
        start=T_start))                                                                             if addCapGla
    "Heat capacitor for glazing at exterior"
    annotation (Placement(transformation(extent={{-20,-12},{0,-32}})));
  Fluid.Sources.OutsideAir       outsideAir(
    redeclare package Medium = Medium,
    Cs=Cs,
    Habs=Habs, azi = aziInt,
    nPorts=if sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.OnePort
         then (if use_trickle_vent then 2 else 1) else (if use_trickle_vent then 3 else 2), table = coeffsCp, use_TDryBul_in = true)
 if sim.interZonalAirFlowType <> IDEAS.BoundaryConditions.Types.InterZonalAirFlow.None
    "Outside air model"
    annotation (Placement(transformation(extent={{-40,-100},{-20,-80}})));
initial equation
  QTra_design = (U_value*A + (if fraType.briTyp.present then fraType.briTyp.G else 0)) *(TRefInt - Tdes.y);

  assert(not use_trickle_vent or sim.interZonalAirFlowType <> IDEAS.BoundaryConditions.Types.InterZonalAirFlow.None,
    "In " + getInstanceName() + ": Trickle vents can only be enabled when sim.interZonalAirFlowType is not None.");

  assert(not (not fraType.present and frac > 0), "In " + getInstanceName() +
    ": You may have intended to model a frame since the parameter 'frac' is larger than zero. However, no frame type is configured such that no frame will be modelled. This may be a mistake. Set frac=0 to avoid this warning if this is intentional.",
    level=AssertionLevel.warning);
equation
  connect(solWin.iSolDir, propsBusInt.iSolDir) annotation (
    Line(points = {{-2, -60}, {-2, -70}, {56.09, -70}, {56.09, 19.91}}, color = {191, 0, 0}, smooth = Smooth.None));
  connect(solWin.iSolDif, propsBusInt.iSolDif) annotation (
    Line(points = {{2, -60}, {2, -70}, {56.09, -70}, {56.09, 19.91}}, color = {191, 0, 0}, smooth = Smooth.None));
  connect(solWin.iSolAbs, layMul.port_gain) annotation (
    Line(points = {{0, -40}, {0, -10}}, color = {191, 0, 0}, smooth = Smooth.None));
  connect(shaType.Ctrl, Ctrl) annotation (
    Line(points={{-63,-63.4772},{-50, -63.4772},{-50, -110}},
                                                         color = {0, 0, 127}));
  connect(iConFra.port_b, propsBusInt.surfCon) annotation (
    Line(points = {{40, 70}, {46, 70}, {46, 19.91}, {56.09, 19.91}}, color = {191, 0, 0}, smooth = Smooth.None));
  connect(layFra.port_a, iConFra.port_a) annotation (
    Line(points = {{10, 70}, {20, 70}}, color = {191, 0, 0}, smooth = Smooth.None));
  connect(radSolData.angInc, shaType.angInc) annotation (
    Line(points={{-79.4,-54},{-72.7,-54},{-72.7,-55.0846},{-68.5,-55.0846}},color = {0, 0, 127}));
  connect(radSolData.angAzi, shaType.angAzi) annotation (
    Line(points={{-79.4,-58},{-74.95,-58},{-74.95,-60.6797},{-68.5,-60.6797}},color = {0, 0, 127}));
  connect(radSolData.angZen, shaType.angZen) annotation (
    Line(points={{-79.4,-56},{-74,-56},{-74,-57.8821},{-68.5,-57.8821}},
                                                color = {0, 0, 127}));
  connect(Tdes.u, radSolData.Tdes);
  connect(shaType.iAngInc, solWin.angInc) annotation (
    Line(points={{-57.5,-55.0846},{-34,-55.0846},{-34,-54},{-10,-54}},color = {0, 0, 127}));
  connect(heaCapGlaInt.port, layMul.port_a) annotation (
    Line(points = {{16, -12}, {16, 0}, {10, 0}}, color = {191, 0, 0}));
  connect(heaCapFraIn.port, layFra.port_a) annotation (
    Line(points = {{14, 100}, {14, 70}, {10, 70}}, color = {191, 0, 0}));
  connect(gainDir.y, solWin.solDir) annotation (
    Line(points={{-25.8,-44},{-10,-44}},    color = {0, 0, 127}));
  connect(gainDif.y, solWin.solDif) annotation (
    Line(points = {{-31.8, -48}, {-22, -48}, {-10, -48}}, color = {0, 0, 127}));
  connect(radSolData.HDirTil, shaType.HDirTil) annotation (
    Line(points={{-79.4,-46},{-78,-46},{-78,-41.0969},{-68.5,-41.0969}},color = {0, 0, 127}));
  connect(radSolData.HSkyDifTil, shaType.HSkyDifTil) annotation (
    Line(points={{-79.4,-48},{-73.2,-48},{-73.2,-43.8944},{-68.5,-43.8944}},color = {0, 0, 127}));
  connect(radSolData.HGroDifTil, shaType.HGroDifTil) annotation (
    Line(points={{-79.4,-50},{-73.2,-50},{-73.2,-46.692},{-68.5,-46.692}},  color = {0, 0, 127}));
  connect(shaType.HShaGroDifTil, solDif.u2) annotation (
    Line(points={{-57.5,-46.692},{-52.25,-46.692},{-52.25,-46.4},{-46.8,-46.4}},
                                                                            color = {0, 0, 127}));
  connect(solDif.u1, shaType.HShaSkyDifTil) annotation (
    Line(points={{-46.8,-41.6},{-50,-41.6},{-50,-42},{-52,-42},{-52,-43.8944},{
          -57.5,-43.8944}},                   color = {0, 0, 127}));
  connect(gainDif.u, solDif.y) annotation (
    Line(points={{-36.4,-48},{-37.6,-48},{-37.6,-44}},    color = {0, 0, 127}));
  connect(gainDir.u, shaType.HShaDirTil) annotation (
    Line(points={{-30.4,-44},{-30.95,-44},{-30.95,-41.0969},{-57.5,-41.0969}},
                                                                            color = {0, 0, 127}));
  connect(layFra.port_b, heaCapFraExt.port) annotation (
    Line(points = {{-10, 70}, {-10, 100}}, color = {191, 0, 0}));
  connect(heaCapGlaExt.port, layMul.port_b) annotation (
    Line(points = {{-10, -12}, {-10, 0}}, color = {191, 0, 0}));
  connect(res1.port_a, outsideAir.ports[1]) annotation (
    Line(points = {{20, -40}, {16, -40}, {16, -90}, {-20, -90}}, color = {0, 127, 255}));
  connect(res2.port_a, outsideAir.ports[2]) annotation (
    Line(points = {{20, -60}, {16, -60}, {16, -90}, {-20, -90}}, color = {0, 127, 255}));
  connect(trickleVent.port_a, outsideAir.ports[if sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.OnePort then 2 else 3]) annotation (
    Line(points = {{20, -78}, {16, -78}, {16, -92}, {-2, -92}, {-2, -90}, {-20, -90}}, color = {0, 127, 255}));
  connect(trickleVent.port_b, propsBusInt.port_1) annotation (
    Line(points = {{40, -78}, {50, -78}, {50, 19.91}, {56.09, 19.91}}, color = {0, 127, 255}));
  connect(radSolData.Te, shaType.Te) annotation (
    Line(points={{-79.4,-64},{-68.5,-64},{-68.5,-29.9067}}, color = {0, 0, 127}));
  connect(shaType.port_frame, layFra.port_b) annotation (
    Line(points={{-57.5,-24.3116},{-44,-24.3116},{-44,70},{-10,70}},color = {191, 0, 0}));
  connect(shaType.port_glazing, layMul.port_b) annotation (
    Line(points={{-57.5,-29.9067},{-40,-29.9067},{-40,0},{-10,0}},color = {191, 0, 0}));
  connect(radSolData.Tenv, shaType.TEnv) annotation (
    Line(points={{-79.4,-52},{-76,-52},{-76,-35.5018},{-68.5,-35.5018}},
                                                                      color = {0, 0, 127}));
  connect(shaType.hForcedConExt, radSolData.hForcedConExt) annotation (
    Line(points={{-68.5,-32.7043},{-76,-32.7043},{-76,-62.2},{-79.4,-62.2}},
                                                                    color = {0, 0, 127}));
  connect(outsideAir.TDryBul_in, shaType.TDryBul) annotation(
    Line(points = {{-42, -90}, {-46, -90}, {-46, -48}, {-58, -48}}, color = {0, 0, 127}));
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-60,-100},{60,100}}),
        graphics={Rectangle(fillColor = {255, 255, 255}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-50, -90}, {50, 100}}),
        Polygon(fillColor = {255, 255, 170}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-46, 60}, {50, 24}, {50, -50}, {-30, -20}, {-46, -20}, {-46, 60}}),
        Line(
          points={{-50,60},{-30,60},{-30,80},{50,80}},
          color={175,175,175}),
        Line(
          points={{-50,-20},{-30,-20},{-30,-70},{-30,-70},{52,-70}},
          color={175,175,175}),
        Line(
          points={{-50,60},{-50,66},{-50,100},{50,100}},
          color={175,175,175}),
        Line(
          points={{-50,-20},{-50,-90},{50,-90}},
          color={175,175,175}),
        Line(points = {{-46, 60}, {-46, -20}}, thickness = 0.5)}),
    Diagram(coordinateSystem(preserveAspectRatio=false,extent={{-100,-100},{100,
            100}})),
    Documentation(info="<html>
<p>
This model should be used to model windows or other transparant surfaces.
See <a href=modelica://IDEAS.Buildings.Components.Interfaces.PartialSurface>IDEAS.Buildings.Components.Interfaces.PartialSurface</a> 
for equations, options, parameters, validation and dynamics that are common for all surfaces and windows.
</p>
<h4>Typical use and important parameters</h4>
<p>
Parameter <code>A</code> is the total window surface area, i.e. the
sum of the frame surface area and the glazing surface area.
</p>
<p>
Parameter <code>frac</code> may be used to define the surface
area of the frame as a fraction of <code>A</code>. 
</p>
<p>
Parameter <code>glazing</code>  must be used to define the glass properties.
It contains information about the number of glass layers,
their thickness, thermal properties and emissivity.
</p>
<p>
Optional parameter <code>briType</code> may be used to compute additional line losses
along the edges of the glazing.
</p>
<p>
Optional parameter <code>fraType</code> may be used to define the frame thermal properties.
If <code>fraType = None</code> then the frame is assumed to be perfectly insulating.
</p>
<p>
Optional parameter <code>shaType</code> may be used to define the window shading properties.
</p>
<p>
The parameter <code>n</code> may be used to scale the window to <code>n</code> identical windows.
For example, if a wall has 10 identical windows with identical shading, this parameter
can be used to simulate 10 windows by scaling the model of a single window.
</p>
<p>
The parameter tab Airflow lists optional parameters for adding a self regulating trickle vent.
</p>
<h4>Validation</h4>
<p>
To verify the U-value of your glazing system implementation,
see <a href=\"modelica://IDEAS.Buildings.Components.Validations.WindowEN673\">
IDEAS.Buildings.Components.Validations.WindowEN673</a>
</p>
</html>", revisions="<html>
<ul>
<li>
May 22, 2022, by Filip Jorissen:<br/>
Fixed Modelica specification compatibility issue.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1254\">
#1254</a>
</li>
<li>
September 21, 2021 by Filip Jorissen:<br/>
Added trickle vent support.
<a href=\"https://github.com/open-ideas/IDEAS/issues/1232\">#1232</a>.
</li>
<li>
August 12, 2020 by Filip Jorissen:<br/>
No longer using connector and initial equation for <code>epsSw</code>.
<a href=\"https://github.com/open-ideas/IDEAS/issues/1162\">#1162</a>.
</li>
<li>
July 2020, 2020, by Filip Jorissen:<br/>
Added a list of default glazing systems.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1114\">
#1114</a>
</li>
<li>
April 26, 2020, by Filip Jorissen:<br/>
Refactored <code>SolBus</code> to avoid many instances in <code>PropsBus</code>.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1131\">
#1131</a>
</li>
<li>
November 28, 2019, by Ian Beausoleil-Morrison:<br/>
<code>inc</code> and <code>azi</code> of surface now passed as parameters to ExteriorConvection.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1089\">
#1089</a>
</li>
<li>
December 2, 2019, by Filip Jorissen:<br/>
Split heat capacitor to interior and exterior part 
to avoid non-linear algebraic loops.
<a href=\"https://github.com/open-ideas/IDEAS/issues/1092\">#1092</a>.
</li>
<li>
October 13, 2019, by Filip Jorissen:<br/>
Refactored the parameter definition of <code>inc</code> 
and <code>azi</code> by adding the option to use radio buttons.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1067\">
#1067</a>
</li>
<li>
September 9, 2019, by Filip Jorissen:<br/>
Added <code>checkCoatings</code> for issue
<a href=\"https://github.com/open-ideas/IDEAS/issues/1038\">#1038</a>.
</li>
<li>
August 10, 2018 by Damien Picard:<br/>
Add scaling to propsBus_a to allow simulation of n windows instead of 1
See <a href=\"https://github.com/open-ideas/IDEAS/issues/888\">
#888</a>.
</li>
<li>
January 21, 2018 by Filip Jorissen:<br/>
Changed implementation such that control input is visible.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/761\">
#761</a>.
</li>
<li>
May 26, 2017 by Filip Jorissen:<br/>
Revised implementation for renamed
ports <code>HDirTil</code> etc.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/735\">
#735</a>.
</li>
<li>
March 6, 2017, by Filip Jorissen:<br/>
Added option for using 'normal' dynamics for the window glazing.
Removed the option for having a combined state for 
window and frame this this is non-physical.
This is for 
<a href=https://github.com/open-ideas/IDEAS/issues/678>#678</a>.
</li>
<li>
January 10, 2017, by Filip Jorissen:<br/>
Removed declaration of 
<code>A</code> since this is now declared in 
<a href=modelica://IDEAS.Buildings.Components.Interfaces.PartialSurface>
IDEAS.Buildings.Components.Interfaces.PartialSurface</a>.
This is for 
<a href=https://github.com/open-ideas/IDEAS/issues/609>#609</a>.
</li>
<li>
January 10, 2017 by Filip Jorissen:<br/>
Set <code>linExtRad = sim.linExtRadWin</code>.
See <a href=https://github.com/open-ideas/IDEAS/issues/615>#615</a>.
</li>
<li>
December 19, 2016, by Filip Jorissen:<br/>
Added solar irradiation on window frame.
</li>
<li>
December 19, 2016, by Filip Jorissen:<br/>
Removed briType, which had default value LineLoss.
briType is now part of the Frame model and has default
value None.
</li>
<li>
February 10, 2016, by Filip Jorissen and Damien Picard:<br/>
Revised implementation: cleaned up connections and partials.
</li>
<li>
December 17, 2015, Filip Jorissen:<br/>
Added thermal connection between frame and glazing state. 
This is required for decoupling steady state thermal dynamics
without adding a second state for the window.
</li>
<li>
July 14, 2015, Filip Jorissen:<br/>
Removed second shading device since a new partial was created
for handling this.
</li>
<li>
June 14, 2015, Filip Jorissen:<br/>
Adjusted implementation for computing conservation of energy.
</li>
<li>
February 10, 2015 by Filip Jorissen:<br/>
Adjusted implementation for grouping of solar calculations.
</li>
</ul>
</html>"));
end Window;
