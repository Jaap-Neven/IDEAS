within IDEAS.Buildings.Components.Interfaces;
partial model PartialSurface "Partial model for building envelope component"

  outer IDEAS.BoundaryConditions.SimInfoManager sim
    "Simulation information manager for climate data"
    annotation (Placement(transformation(extent={{30,-100},{50,-80}})));
  parameter Integer incOpt = 4
    "Tilt angle option from simInfoManager, or custom using inc"
    annotation(choices(__Dymola_radioButtons=true, choice=1 "Wall", choice=2 "Floor", choice=3 "Ceiling", choice=4 "Custom"));
  parameter Modelica.SIunits.Angle inc = sim.incOpts[incOpt]
    "Custom inclination (tilt) angle of the wall, default wall"
    annotation(Dialog(enable=incOpt==4));
  parameter Integer aziOpt = 5
    "Azimuth angle option from simInfoManager, or custom using azi"
    annotation(choices(__Dymola_radioButtons=true, choice=1 "South", choice=2 "West", choice=3 "North", choice=4 "East", choice=5 "Custom"));
  parameter Modelica.SIunits.Angle azi=sim.aziOpts[aziOpt]
    "Custom azimuth angle of the wall, default south"
    annotation(Dialog(enable=aziOpt==5));
  parameter Modelica.SIunits.Area A
    "Component surface area";
  parameter Real nWin = 1
    "Use this factor to scale the component to nWin identical components"
    annotation(Evaluate=true);
  parameter Modelica.SIunits.Power QTra_design
    "Design heat losses at reference temperature of the boundary space"
    annotation (Dialog(group="Design power",tab="Advanced"));
  parameter Modelica.SIunits.Temperature T_start=293.15
    "Start temperature for each of the layers"
    annotation(Dialog(tab="Dynamics", group="Initial condition"));

  parameter Modelica.SIunits.Temperature TRef_a=291.15
    "Reference temperature of zone on side of propsBus_a, for calculation of design heat loss"
    annotation (Dialog(group="Design power",tab="Advanced"));
  parameter Boolean linIntCon_a=sim.linIntCon
    "= true, if convective heat transfer should be linearised"
    annotation (Dialog(tab="Convection"));
  parameter Modelica.SIunits.TemperatureDifference dT_nominal_a=1
    "Nominal temperature difference used for linearisation, negative temperatures indicate the solid is colder"
    annotation (Dialog(tab="Convection"));
  parameter Modelica.Fluid.Types.Dynamics energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial
    "Static (steady state) or transient (dynamic) thermal conduction model"
    annotation(Evaluate=true, Dialog(tab = "Dynamics", group="Equations"));

  replaceable package Medium = IDEAS.Media.Air
    "Medium in the component"
    annotation(Dialog(enable=use_custom_q50,tab="Airflow", group="Airtightness"));
  parameter Boolean use_custom_q50=false
    "set to true to disable the default q50 computation and to assign a custom q50 value"
    annotation (Dialog(tab="Airflow", group="Airtightness"), Evaluate=true);
  parameter Real custom_q50(unit="m3/(h.m2)") = 2
    "Envelope air tightness"
    annotation (Dialog(enable=use_custom_q50,tab="Airflow", group="Airtightness"));
  final parameter Real q50_internal(unit="m3/(h.m2)",fixed=false)
    "Envelope air tightness";

  final parameter Real hzone_a( fixed=false);//connected with propsbus in inital equation
  final parameter Real hfloor_a( fixed=false);
  parameter Real hVertical=if inc==Modelica.Constants.pi or inc==0 then 0 else hzone_a "Vertical surface height, height of the surface projected to the vertical, 0 for floors and ceilings" annotation(Evaluate=true);
  parameter Real hRef_a= if inc==0 then hzone_a else 0  "Height above the zone floor at propsbus_a. Height where the surface starts. e.g. 0 for walls at floor level and floors.  "
                                                                                                                                                                                   annotation(Evaluate=true);

  //TO CHECK: default should be zone height only when it is the ceiling at propsbus


  IDEAS.Buildings.Components.Interfaces.ZoneBus propsBus_a(
    redeclare final package Medium = Medium,
    numIncAndAziInBus=sim.numIncAndAziInBus, outputAngles=sim.outputAngles,
    final use_port_1=sim.interZonalAirFlowType <> IDEAS.BoundaryConditions.Types.InterZonalAirFlow.None,
    final use_port_2=sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.TwoPorts)
                                             "If inc = Floor, then propsbus_a should be connected to the zone above this floor.
    If inc = ceiling, then propsbus_a should be connected to the zone below this ceiling.
    If component is an outerWall, porpsBus_a should be connect to the zone."
    annotation (Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=-90,
        origin={100,20}), iconTransformation(
        extent={{-20,-20},{20,20}},
        rotation=-90,
        origin={50,20})));

  IDEAS.Buildings.Components.BaseClasses.ConvectiveHeatTransfer.InteriorConvection intCon_a(
    linearise=linIntCon_a or sim.linearise,
    dT_nominal=dT_nominal_a,
    final inc=incInt,
    A=A)
    "Convective heat transfer correlation for port_a"
    annotation (Placement(transformation(extent={{20,-10},{40,10}})));

  IDEAS.Buildings.Components.BaseClasses.ConductiveHeatTransfer.MultiLayer
    layMul(
    energyDynamics=energyDynamics,
    linIntCon=linIntCon_a or sim.linearise,
    A=A,
    final inc=incInt)
    "Multilayer component for simulating walls, windows and other surfaces"
    annotation (Placement(transformation(extent={{10,-10},{-10,10}})));

  PowerLaw_q50_stack res1(
  redeclare package Medium = Medium,
    A=if sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.TwoPorts
         then A/2 else A,
    h_b= -0.5*hzone_a + 0.25*hVertical +hRef_a,
    final q50=q50_internal) if
        add_cracks and sim.interZonalAirFlowType <> IDEAS.BoundaryConditions.Types.InterZonalAirFlow.None
    "Middle or bottom crack "
    annotation (Placement(transformation(extent={{20,-46},{40,-26}})));


  PowerLaw_q50_stack res2(
  redeclare package
  Medium = Medium,
    A=A/2,
  h_b= -0.5*hzone_a + 0.75*hVertical +hRef_a,
    final q50=q50_internal) if
       add_cracks and sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.TwoPorts
    "Top crack"
    annotation (Placement(transformation(extent={{20,-70},{40,-50}})));


  Q50_parameterToConnector q50_zone(
    q50_inp=q50_internal,
    v50_surf=q50_internal*A,
    use_custom_q50=use_custom_q50)
    annotation (Placement(transformation(extent={{80,-60},{100,-40}})));



protected
  parameter Boolean add_cracks = true
    "Add cracks";
  final parameter Modelica.SIunits.Angle aziInt=
    if aziOpt==5
    then azi
    else sim.aziOpts[aziOpt]
      "Azimuth angle";
  final parameter Modelica.SIunits.Angle incInt=
    if incOpt==4
    then inc
    else sim.incOpts[incOpt]
      "Inclination angle";
  Modelica.Blocks.Sources.RealExpression QDesign(y=QTra_design);

  Modelica.Blocks.Sources.RealExpression aziExp(y=aziInt)
    "Azimuth angle expression";
  Modelica.Blocks.Sources.RealExpression incExp(y=incInt)
    "Inclination angle expression";
  Modelica.Blocks.Sources.RealExpression E
    "Model internal energy";
  IDEAS.Buildings.Components.BaseClasses.ConservationOfEnergy.PrescribedEnergy prescribedHeatFlowE
    "Component for computing conservation of energy";
  Modelica.Blocks.Sources.RealExpression Qgai
    "Heat gains across model boundary";
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow prescribedHeatFlowQgai
    "Component for computing conservation of energy";

  IDEAS.Buildings.Components.Interfaces.ZoneBusVarMultiplicator gain(redeclare
      package Medium = Medium,                                       k=nWin)
    "Gain for all propsBus variable to represent nWin surfaces instead of 1"
    annotation (Placement(transformation(extent={{70,6},{88,36}})));
  IDEAS.Buildings.Components.Interfaces.ZoneBus propsBusInt(
    redeclare final package Medium = Medium,
    numIncAndAziInBus=sim.numIncAndAziInBus,
    outputAngles=sim.outputAngles,
    final use_port_1=sim.interZonalAirFlowType <> IDEAS.BoundaryConditions.Types.InterZonalAirFlow.None,
    final use_port_2=sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.TwoPorts)
    annotation (Placement(transformation(
        extent={{-18,-18},{18,18}},
        rotation=-90,
        origin={56,20}),  iconTransformation(
        extent={{-20,-20},{20,20}},
        rotation=-90,
        origin={50,20})));
  IDEAS.Buildings.Components.Interfaces.SetArea setArea(A=0, use_custom_q50=
        use_custom_q50)
    "Block that contributes surface area to the siminfomanager"
    annotation (Placement(transformation(extent={{80,-100},{100,-80}})));







model PowerLaw_q50_stack

    replaceable package Medium = Modelica.Media.Interfaces.PartialMedium  constrainedby
      Modelica.Media.Interfaces.PartialMedium                                                  annotation (
          __Dymola_choicesAllMatching=true);


      parameter Modelica.SIunits.Area A
             "Surface area";

      parameter Real m=0.65;
      final parameter Boolean StackEff= sim.interZonalAirFlowType == IDEAS.BoundaryConditions.Types.InterZonalAirFlow.TwoPorts "True if stack effect is used" annotation(Evaluate=true);


      parameter Real h_a=0 "column height, height at port_a" annotation (Dialog(group="Flow Path"));
      parameter Real h_b=0 "column height, height at port_b" annotation (Dialog(group="Flow Path"));
      parameter Real q50
      "Leaked volume flow rate per unit A at 50Pa";

    Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium =Medium) annotation (Placement(transformation(rotation=0, extent={{-110,-10},
                {-90,10}}), iconTransformation(extent={{-110,-10},{-90,10}})));
    Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare package Medium =Medium) annotation (Placement(transformation(rotation=0, extent={{90,-10},
                {110,10}}),     iconTransformation(extent={{90,-10},{110,10}})));


    PowerLaw_q50 res1(
        redeclare package Medium = Medium,
        final forceErrorControlOnFlow=false,
        m=m,
        useDefaultProperties= not StackEff,
        A=A,
      final q50=q50)
        "Middle or bottom crack "
        annotation (Placement(transformation(extent={{-12,-10},{8,10}})));


      DensityColumn               col_a_pos(
    redeclare package Medium = Medium,
    h=h_a) if                                                                      StackEff
    annotation (Placement(transformation(extent={{-70,-10},{-50,10}})));
      DensityColumn               col_b_pos(
    redeclare package Medium = Medium,
    h=h_b) if                                                                      StackEff
    annotation (Placement(transformation(extent={{50,-10},{70,10}})));

  outer BoundaryConditions.SimInfoManager sim
    annotation (Placement(transformation(extent={{80,-100},{100,-80}})));

  Fluid.FixedResistances.LosslessPipe No_stack_a(
    redeclare package Medium = Medium,
    allowFlowReversal=true,
    m_flow_nominal=q50*1.2/3600) if
                          not StackEff
    annotation (Placement(transformation(extent={{-68,30},{-48,50}})));
  Fluid.FixedResistances.LosslessPipe No_stack_b(
    redeclare package Medium = Medium,
    allowFlowReversal=true,
    m_flow_nominal=q50*1.2/3600) if
                          not StackEff
    annotation (Placement(transformation(extent={{50,30},{70,50}})));

  model PowerLaw_q50

    extends IDEAS.Airflow.Multizone.BaseClasses.PowerLawResistance(
      m=0.5,
      k=A*coeff); //mass flow form of orifice equation

  parameter Modelica.SIunits.Area A
    "Surface area";
  parameter Real q50(unit="m3/(h.m2)")
    "Leaked volume flow rate per unit A at 50Pa";
  final parameter Real coeff = (q50/3600)/(50^m)
    "Conversion coefficient";
  equation
  v= V_flow/A;
  annotation (Icon(graphics={
        Text(
          extent={{-100,100},{-40,60}},
          lineColor={28,108,200},
          fillColor={215,215,215},
          fillPattern=FillPattern.None,
          textString="q50"),
        Rectangle(
          extent={{-20,80},{20,-80}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-60,58},{64,46}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-94,4},{-58,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{54,6},{106,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-64,2},{-46,-6}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-82,4},{-46,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-58,36},{66,24}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-58,-54},{66,-66}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-56,-24},{68,-36}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-38,4},{40,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid)}));
  end PowerLaw_q50;


  model DensityColumn
  "Vertical shaft with no friction and no storage of heat and mass"

  replaceable package Medium =
    Modelica.Media.Interfaces.PartialMedium "Medium in the component"
      annotation (choices(
        choice(redeclare package Medium = IDEAS.Media.Air "Moist air")));
  parameter Modelica.SIunits.Length h= 3 "Height of shaft";


  Modelica.Fluid.Interfaces.FluidPort_a port_a(
    redeclare package Medium = Medium,
    p(start=Medium.p_default))
    "Fluid connector a (positive design flow direction is from port_a to port_b)"
    annotation (Placement(transformation(extent={{-10,90},{10,110}}),
        iconTransformation(extent={{-10,90},{10,110}})));
  Modelica.Fluid.Interfaces.FluidPort_b port_b(
    redeclare package Medium = Medium,
    p(start=Medium.p_default))
    "Fluid connector b (positive design flow direction is from port_a to port_b)"
    annotation (Placement(transformation(extent={{10,-110},{-10,-90}}), iconTransformation(extent={{10,-110},{-10,-90}})));

  Modelica.SIunits.VolumeFlowRate V_flow
    "Volume flow rate at inflowing port (positive when flow from port_a to port_b)";
  Modelica.SIunits.MassFlowRate m_flow
    "Mass flow rate from port_a to port_b (m_flow > 0 is design flow direction)";
  Modelica.SIunits.PressureDifference dp(displayUnit="Pa")
    "Pressure difference between port_a and port_b";
  Modelica.SIunits.Density rho "Density in medium column";

    protected
  Medium.ThermodynamicState sta_b=Medium.setState_phX(
      port_b.p,
      actualStream(port_b.h_outflow),
      actualStream(port_b.Xi_outflow)) "Medium properties in port_a";
  Medium.MassFraction Xi[Medium.nXi] "Mass fraction used to compute density";

  equation
  // Design direction of mass flow rate
  m_flow = port_a.m_flow;

  // Pressure difference between ports
  // Xi is computed first as it is used in two expression, and in one
  // of them only one component is used.
  // We test for Medium.nXi == 0 as Modelica.Media.Air.SimpleAir has no
  // moisture and hence Xi[1] is an illegal statement.
  // We first compute temperature and then invoke a density function that
  // takes temperature as an argument. Simply calling a density function
  // of a medium that takes enthalpy as an argument would be dangerous
  // as different media can have different datum for the enthalpy.

  Xi = inStream(port_b.Xi_outflow);
  rho = IDEAS.Utilities.Psychrometrics.Functions.density_pTX(
  p=Medium.p_default,
  T=Medium.temperature(Medium.setState_phX(port_b.p, inStream(port_b.h_outflow), Xi)),
  X_w=if Medium.nXi == 0 then 0 else Xi[1]);

  V_flow = m_flow/Medium.density(sta_b);

  dp = if h>0 then port_a.p - port_b.p else -port_a.p + port_b.p;
  dp = -abs(h)*rho*Modelica.Constants.g_n;

  // Isenthalpic state transformation (no storage and no loss of energy)
  port_a.h_outflow = inStream(port_b.h_outflow);
  port_b.h_outflow = inStream(port_a.h_outflow);

  // Mass balance (no storage)
  port_a.m_flow + port_b.m_flow = 0;

  // Transport of substances
  port_a.Xi_outflow = inStream(port_b.Xi_outflow);
  port_b.Xi_outflow = inStream(port_a.Xi_outflow);

  port_a.C_outflow = inStream(port_b.C_outflow);
  port_b.C_outflow = inStream(port_a.C_outflow);

  annotation (
    Icon(graphics={
        Line(
          points={{0,100},{0,-100},{0,-98}}),
        Text(
          extent={{24,-78},{106,-100}},
          lineColor={0,0,127},
              textString="Zone/Amb"),
        Text(
          extent={{32,104},{98,70}},
          lineColor={0,0,127},
              textString="FlowElem"),
        Text(
          extent={{36,26},{88,-10}},
          lineColor={0,0,127},
          fillColor={255,0,0},
          fillPattern=FillPattern.Solid,
          textString="h=%h"),
        Rectangle(
          extent={{-16,80},{16,-80}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          visible=densitySelection == IDEAS.Airflow.Multizone.Types.densitySelection.fromTop,
          extent={{-16,80},{16,0}},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          visible=densitySelection == IDEAS.Airflow.Multizone.Types.densitySelection.actual,
          extent={{-16,80},{16,54}},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          visible=densitySelection == IDEAS.Airflow.Multizone.Types.densitySelection.fromBottom,
          extent={{-16,0},{16,-82}},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          visible=densitySelection == IDEAS.Airflow.Multizone.Types.densitySelection.actual,
          extent={{-16,-55},{16,-80}},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0})}),
      defaultComponentName="col",
      Documentation(info=
                   "<html>
<p>
This model describes the pressure difference of a vertical medium
column. It can be used to model the pressure difference caused by
stack effect.
</p>
<h4>Typical use and important parameters</h4>
<p>
The model can be used with the following three configurations, which are
controlled by the setting of the parameter <code>densitySelection</code>:
</p>
<ul>
<li>
<code>top</code>:
Use this setting to use the density from the volume that is connected
to <code>port_a</code>.
</li>
<li>
<code>bottom</code>:
Use this setting to use the density from the volume that is connected
to <code>port_b</code>.
</li>
<li>
<code>actual</code>:
Use this setting to use the density based on the actual flow direction.
</li>
</ul>
<p>
The settings <code>top</code> and <code>bottom</code>
should be used when rooms or different floors of a building are
connected since multizone airflow models assume that each floor is completely mixed.
For these two seetings, this model will compute the pressure between the center of the room
and an opening that is at height <code>h</code> relative to the center of the room.
The setting <code>actual</code> may be used to model a chimney in which
a column of air will change its density based on the flow direction.
</p>
<p>
In this model, the parameter <code>h</code> must always be positive, and the port <code>port_a</code> must be
at the top of the column.
</p>
<h4>Dynamics</h4>
<p>
For a dynamic model, use
<a href=\"modelica://IDEAS.Airflow.Multizone.MediumColumnDynamic\">
IDEAS.Airflow.Multizone.MediumColumnDynamic</a> instead of this model.
</p>
</html>", revisions=
          "<html>
<ul>
<li>
January 18, 2019, by Jianjun Hu:<br/>
Limited the media choice to moist air only.
See <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/1050\">#1050</a>.
</li>
<li>
May 1, 2018, by Filip Jorissen:<br/>
Removed declaration of <code>allowFlowReversal</code>
and changed default density computation such
that it assumes a constant pressure.
See <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/877\">#877</a>.
</li>
<li>
November 3, 2016, by Michael Wetter:<br/>
Removed start values for mass flow rate and pressure difference
to simplify the parameter window.<br/>
This is for
<a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/552\">#552</a>.
</li>
<li>
January 22, 2016, by Michael Wetter:<br/>
Corrected type declaration of pressure difference.
This is
for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/404\">#404</a>.
</li>
<li>
February 24, 2015 by Michael Wetter:<br/>
Changed model to use
<a href=\"modelica://IDEAS.Utilities.Psychrometrics.Functions.density_pTX\">
IDEAS.Utilities.Psychrometrics.Functions.density_pTX</a>
for the density computation
as
<a href=\"modelica://IDEAS.Media.Air.density\">
IDEAS.Media.Air.density</a>
does not depend on temperature.
</li>
<li>
December 22, 2014 by Michael Wetter:<br/>
Removed <code>Modelica.Fluid.System</code>
to address issue
<a href=\"https://github.com/lbl-srg/modelica-buildings/issues/311\">#311</a>.
</li>
<li>October 4, 2014 by Michael Wetter:<br/>
Removed assignment of <code>port_?.p.nominal</code> to avoid a warning in OpenModelica because
alias sets have different nominal values.
</li>
<li>April 17, 2013 by Michael Wetter:<br/>
Reformulated the assert statement that checks for the correct value of <code>densitySelection</code>.
</li>
<li>July 28, 2010 by Michael Wetter:<br/>
Changed sign for pressure difference.
</li>
<li>
July 20, 2010 by Michael Wetter:<br/>
Migrated model to Modelica 3.1 and integrated it into the Buildings library.
Reimplemented assignment of density based on flow direction or based on outflowing state.
</li>
<li>
February 24, 2005 by Michael Wetter:<br/>
Released first version.
</li>
</ul>
</html>"));
  end DensityColumn;


equation

  connect(port_a, No_stack_a.port_a) annotation (Line(points={{-100,0},{-80,0},{
          -80,40},{-68,40}}, color={0,127,255}));
  connect(No_stack_a.port_b, res1.port_a) annotation (Line(points={{-48,40},{-20,
          40},{-20,0},{-12,0}}, color={0,127,255}));
  connect(res1.port_b, No_stack_b.port_a) annotation (Line(points={{8,0},{20,0},
          {20,40},{50,40}}, color={0,127,255}));
  connect(No_stack_b.port_b, port_b) annotation (Line(points={{70,40},{80,40},{80,
          0},{100,0}}, color={0,127,255}));
  connect(port_a, col_a_pos.port_b) annotation (Line(points={{-100,0},{-80,0},{-80,
          -10},{-60,-10}},                                                      color={0,127,255}));
  connect(col_a_pos.port_a, res1.port_a) annotation (Line(points={{-60,10},{-40,
          10},{-40,0},{-12,0}},       color={0,127,255}));
  connect(port_b, col_b_pos.port_b) annotation (Line(points={{100,0},{80,0},{80,
          -10},{60,-10}},                                                     color={0,127,255}));
  connect(col_b_pos.port_a, res1.port_b) annotation (Line(points={{60,10},{34,10},
          {34,0},{8,0}},       color={0,127,255}));

    annotation (Icon(graphics={
        Text(
          extent={{-100,100},{-40,60}},
          lineColor={28,108,200},
          fillColor={215,215,215},
          fillPattern=FillPattern.None,
          textString="q50"),
        Rectangle(
          extent={{-20,80},{20,-80}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-60,58},{64,46}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-94,4},{-58,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{54,6},{106,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-64,2},{-46,-6}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-82,4},{-46,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,127,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-58,36},{66,24}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-58,-54},{66,-66}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-56,-24},{68,-36}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-38,4},{40,-8}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid)}));
end PowerLaw_q50_stack;




model Q50_parameterToConnector "Converts parameter values into connectors for propsBus"
  extends Modelica.Blocks.Icons.Block;

  parameter Real q50_inp
    "q50 value after applying overrides";
  parameter Real v50_surf( unit="m3/h")
    "Custom v50 value";
  parameter Boolean use_custom_q50=false
    "true if custom q50 value should be considered by the zone";
  Modelica.Blocks.Interfaces.RealInput q50_zone
    "Input for q50 value computed by the zone"
   annotation (Placement(transformation(extent={{-126,50},{-86,90}})));
  Modelica.Blocks.Interfaces.RealOutput v50 = v50_surf
    "Output for v50 value request by the surface"
   annotation (Placement(transformation(extent={{-100,
            -90},{-120,-70}})));
  Modelica.Blocks.Interfaces.BooleanOutput using_custom_q50 = use_custom_q50
    "Output indicating whether a custom q50 value should be considered by the zone"
   annotation (Placement(transformation(extent={{-100,-30},{-120,-10}})));
  Modelica.Blocks.Interfaces.RealInput dummy_h[2]
      "Dummy connectors for hzone and hfloor"
      annotation (Placement(transformation(extent={{-126,14},{-86,54}})));
  annotation (Icon(graphics={Rectangle(
          extent={{-82,80},{78,-80}},
          lineColor={28,108,200},
          fillColor={145,167,175},
          fillPattern=FillPattern.Forward)}));
end Q50_parameterToConnector;

initial equation
  q50_internal=if use_custom_q50 then custom_q50 else q50_zone.q50_zone;
  hzone_a=propsBusInt.hzone;
  hfloor_a=propsBusInt.hfloor;
equation
  connect(prescribedHeatFlowE.port, propsBusInt.E);
  connect(Qgai.y,prescribedHeatFlowQgai. Q_flow);
  connect(prescribedHeatFlowQgai.port, propsBusInt.Qgai);
  connect(E.y,prescribedHeatFlowE. E);
  connect(QDesign.y, propsBusInt.QTra_design);
  connect(propsBusInt.surfCon, intCon_a.port_b) annotation (Line(
      points={{56.09,19.91},{46,19.91},{46,0},{40,0}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(layMul.port_a, propsBusInt.surfRad) annotation (Line(
      points={{10,0},{16,0},{16,19.91},{56.09,19.91}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(layMul.port_a, intCon_a.port_a) annotation (Line(
      points={{10,0},{20,0}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(layMul.iEpsSw_a, propsBusInt.epsSw) annotation (Line(
      points={{10,4},{20,4},{20,19.91},{56.09,19.91}},
      color={0,0,127},
      smooth=Smooth.None), Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(layMul.iEpsLw_a, propsBusInt.epsLw) annotation (Line(
      points={{10,8},{18,8},{18,19.91},{56.09,19.91}},
      color={0,0,127},
      smooth=Smooth.None), Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(layMul.area, propsBusInt.area) annotation (Line(
      points={{0,10},{0,19.91},{56.09,19.91}},
      color={0,0,127},
      smooth=Smooth.None), Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(incExp.y, propsBusInt.inc);
  connect(aziExp.y, propsBusInt.azi);
  connect(propsBus_a, gain.propsBus_b) annotation (Line(
      points={{100,20},{94,20},{94,20.2105},{88,20.2105}},
      color={255,204,51},
      thickness=0.5));
  connect(gain.propsBus_a, propsBusInt) annotation (Line(
      points={{70,20.2105},{60,20.2105},{60,20},{56,20}},
      color={255,204,51},
      thickness=0.5));
  connect(res1.port_b, propsBusInt.port_1) annotation (Line(points={{40,-36},{50,
          -36},{50,19.91},{56.09,19.91}}, color={0,127,255}));
  connect(res2.port_b, propsBusInt.port_2) annotation (Line(points={{40,-60},{50,
          -60},{50,19.91},{56.09,19.91}}, color={0,127,255}));
  connect(setArea.areaPort, sim.areaPort);
  connect(q50_zone.v50, propsBusInt.v50) annotation (Line(points={{79,-58},{56,-58},
          {56,-20},{56.09,-20},{56.09,19.91}},               color={0,0,127}));
  connect(q50_zone.q50_zone, propsBusInt.q50_zone) annotation (Line(points={{79.4,
          -43},{79.4,-44},{56.09,-44},{56.09,19.91}}, color={0,0,127}));
  connect(q50_zone.using_custom_q50, propsBusInt.use_custom_q50) annotation (Line(points={{79,-52},
          {56.09,-52},{56.09,19.91}},      color={0,0,127}));
  connect(setArea.use_custom_n50, propsBusInt.use_custom_n50) annotation (Line(points={{79.4,
          -91},{79.4,-90.5},{56.09,-90.5},{56.09,19.91}},      color={255,0,255}));
  connect(setArea.v50, propsBus_a.v50) annotation (Line(points={{79.4,-83.2},{
          79.4,-82},{56,-82},{56,0},{100.1,0},{100.1,19.9}}, color={0,0,127}));
  connect(q50_zone.dummy_h[1], propsBusInt.hzone) annotation (Line(points={{79.4,
          -47.6},{80,-47.6},{80,-48},{56.09,-48},{56.09,19.91}}, color={0,0,127}));
  connect(q50_zone.dummy_h[2], propsBusInt.hfloor) annotation (Line(points={{79.4,
          -45.6},{80,-45.6},{80,-46},{56.09,-46},{56.09,19.91}}, color={0,0,127}));
  annotation (
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            100,100}})),
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-50,-100},{50,100}})),
    Documentation(revisions="<html>
<ul>
<li>
August 10, 2020, by Filip Jorissen:<br/>
Modifications for supporting interzonal airflow.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1066\">
#1066</a>
</li>
<li>
October 13, 2019, by Filip Jorissen:<br/>
Refactored the parameter definition of <code>inc</code> 
and <code>azi</code> by adding the option to use radio buttons.
See <a href=\"https://github.com/open-ideas/IDEAS/issues/1067\">
#1067</a>
</li>
<li>
August 10, 2018 by Damien Picard:<br/>
Add scaling to propsBus_a to allow simulation of nWin windows instead of 1
See <a href=\"https://github.com/open-ideas/IDEAS/issues/888\">
#888</a>. This factor is not useful for wall and it is set final to 1 
for them.
</li>
<li>
January 26, 2018, by Filip Jorissen:<br/>
Extended documentation.
</li>
<li>
March 21, 2017, by Filip Jorissen:<br/>
Changed bus declarations for JModelica compatibility.
See issue <a href=https://github.com/open-ideas/IDEAS/issues/559>#559</a>.
</li>
<li>
January 10, 2017, by Filip Jorissen:<br/>
Declared parameter <code>A</code> instead of using
<code>AWall</code> in 
<a href=modelica://IDEAS.Buildings.Components.Interfaces.PartialOpaqueSurface>
IDEAS.Buildings.Components.Interfaces.PartialOpaqueSurface</a>.
This is for 
<a href=https://github.com/open-ideas/IDEAS/issues/609>#609</a>.
</li>
<li>
November 15, 2016, by Filip Jorissen:<br/>
Revised documentation for IDEAS 1.0.
</li>
<li>
March 8, 2016, by Filip Jorissen:<br/>
Added energyDynamics parameter.
</li>
<li>
February 10, 2016, by Filip Jorissen and Damien Picard:<br/>
Revised implementation: cleaned up connections and partials.
</li>
<li>
February 6, 2016 by Damien Picard:<br/>
First implementation.
</li>
</ul>
</html>", info="<html>
<p>
Partial model for all surfaces and windows that contains common building blocks such as material layers and parameters.
</p>
<h4>Main equations</h4>
<p>
Submodel <code>layMul</code> contains equations
for simulating conductive (and sometimes radiative) heat transfer
inside material layers.
</p>
<h4>Assumption and limitations</h4>
<p>
This model assumes 1D heat transfer, i.e. edge effects are neglected.
Mass exchange (moisture) is not modelled.
</p>
<h4>Typical use and important parameters</h4>
<p>
Parameters <code>inc</code> and <code>azi</code> may be
used to specify the inclination and azimuth/tilt angle of the surface.
Variables in <a href=modelica://IDEAS.Types.Azimuth>IDEAS.Types.Azimuth</a>
and <a href=modelica://IDEAS.Types.Tilt>IDEAS.Types.Tilt</a>
may be used for this purpose or custom variables may be defined.
Numerical values can be used directly. 
Azimuth angles should be in radians relative to the south orientation, clockwise.
Tilt angles should be in radians where an angle of 0 is the ceiling (upward) orientation
and an angle of Pi is the floor (downward) orientation.
Preferably the azimuth angle is set to zero for horizontal tilt angles, 
since this leads to more efficient code, 
although the model results will not change.
</p>
<p>
The parameter <code>nWin</code> is used in the window model to scale
the window to <code>nWin</code> identical window using the single window
model.
</p>
<h4>Options</h4>
<p>
Convection equations may be simplified (linearised) by setting <code>linIntCon_a = true</code>.
</p>
<h4>Dynamics</h4>
<p>
This model contains multiple state variables for describing the temperature state of the component.
</p>
</html>"));
end PartialSurface;
