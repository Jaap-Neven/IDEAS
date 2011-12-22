within IDEAS.Electric.Photovoltaic;
model PVSystemGeneral "PV system with separate shut-down controller"

parameter Real amount=30;
parameter Real inc = 34/180*Modelica.Constants.pi "inclination";
parameter Real azi = 0 "azimuth";

parameter Integer prod=1;

parameter Modelica.SIunits.Time timeOff=300;
parameter Modelica.SIunits.Voltage VMax=248
    "Max grid voltage for operation of the PV system";

parameter Integer numPha=1;

IDEAS.Electric.BaseClasses.CNegPin
                               pin[numPha] annotation (Placement(transformation(extent={{92,30},{112,50}},rotation=0)));

  outer Commons.SimInfoManager sim
    annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
  IDEAS.Electric.Photovoltaic.Components.PvArray pvArray(
    amount=amount,
    azi=azi,
    inc=inc)                                     annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={-70,30})));
  IDEAS.Electric.Photovoltaic.Components.SimpleDCAC invertor
    annotation (Placement(transformation(extent={{-40,20},{-20,40}})));
  Modelica.Electrical.Analog.Basic.Ground ground1
    annotation (Placement(transformation(extent={{-40,-24},{-20,-4}})));
  IDEAS.Electric.BaseClasses.OhmsLawGenSym
                                  ohmsLaw(numPha=numPha)
    annotation (Placement(transformation(extent={{60,20},{80,40}})));
  IDEAS.Electric.Photovoltaic.Components.DCGrid dCGrid
                annotation (Placement(transformation(extent={{-6,20},{14,40}})));

  IDEAS.Electric.Photovoltaic.Components.PvVoltageCtrlGeneral pvVoltageCtrl(
    VMax=VMax,
    timeOff=timeOff,
    numPha=numPha)
    annotation (Placement(transformation(extent={{26,20},{46,40}})));
equation

  connect(pvArray.p, invertor.p1) annotation (Line(
      points={{-60,30},{-56,30},{-56,35},{-40,35}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(invertor.n1, ground1.p) annotation (Line(
      points={{-40,25},{-44,25},{-44,6},{-30,6},{-30,-4}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(invertor.n2, ground1.p) annotation (Line(
      points={{-20,25},{-16,25},{-16,6},{-30,6},{-30,-4}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(pvArray.n, ground1.p) annotation (Line(
      points={{-80,30},{-84,30},{-84,6},{-30,6},{-30,-4}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ohmsLaw.vi, pin) annotation (Line(
      points={{80,30},{92,30},{92,40},{102,40}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(invertor.p2, dCGrid.pin) annotation (Line(
      points={{-20,35},{-10,35},{-10,36},{-6,36}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(dCGrid.P, pvVoltageCtrl.PInit) annotation (Line(
      points={{14,36},{26,36}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(dCGrid.Q, pvVoltageCtrl.QInit) annotation (Line(
      points={{14,32},{26,32}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(pvVoltageCtrl.PFinal, ohmsLaw.P) annotation (Line(
      points={{46,36},{53,36},{53,34},{60,34}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(pvVoltageCtrl.QFinal, ohmsLaw.Q) annotation (Line(
      points={{46,32},{54,32},{54,28},{60,28}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(pin, pvVoltageCtrl.pin) annotation (Line(
      points={{102,40},{92,40},{92,4},{42,4},{42,20}},
      color={0,0,255},
      smooth=Smooth.None));
      annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}),
                         graphics={
        Polygon(
          points={{-80,60},{-60,80},{60,80},{80,60},{80,-60},{60,-80},{-60,-80},
              {-80,-60},{-80,60}},
          lineColor={0,0,0},
          smooth=Smooth.None,
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid),
        Line(
          points={{-40,80},{-40,-80}},
          color={0,0,0},
          smooth=Smooth.None),
        Line(
          points={{40,80},{40,-80}},
          color={0,0,0},
          smooth=Smooth.None),
        Text(
          extent={{-100,98},{100,-102}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid,
          textString="#")}),        Diagram(graphics));
end PVSystemGeneral;
