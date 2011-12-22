within IDEAS.Electric.Photovoltaic.Components.Elements;
model PV5 "5-parameter model according to Duffie & Beckman (1991)"

// Modelica.Blocks.Interfaces.BlockIcon;

parameter Integer n_s=60 "number of cells on the PV panel";
parameter Modelica.SIunits.Efficiency eff=0.166 "Solar cell efficiency";

//The 5 main parameters
parameter Modelica.SIunits.ElectricCurrent I_phr=7.2206
    "Light current under reference conditions";
parameter Modelica.SIunits.ElectricCurrent I_or=9.5489*10^(-9)
    "Diode reverse saturation current under reference conditions";
parameter Modelica.SIunits.Resistance R_sr=0.3709
    "Series resistance under reference conditions";
parameter Modelica.SIunits.Resistance R_shr=4694.1
    "Shunt resistance under reference conditions";
parameter Modelica.SIunits.ElectricPotential V_tr=0.0345
    "modified ideality factor under reference conditions";

//Other parameters for Sanyo HIP-230HDE1
parameter Modelica.SIunits.ElectricCurrent I_scr=7.22
    "Short circuit current under reference conditions";
parameter Modelica.SIunits.ElectricPotential V_ocr=42.3
    "Open circuit voltage under reference conditions";
parameter Modelica.SIunits.ElectricCurrent I_mpr=6.71
    "Maximum power point current under reference conditions";
parameter Modelica.SIunits.ElectricPotential V_mpr=34.3
    "Maximum power point voltage under reference conditions";
parameter Modelica.SIunits.LinearTemperatureCoefficient kV=-0.106
    "Temperature coefficient for open circuit voltage";
parameter Modelica.SIunits.LinearTemperatureCoefficient kI=0.00217
    "Temperature coefficient for short circuit current";
parameter Modelica.SIunits.Temperature T_ref=298.15
    "Reference temperature in Kelvin";

parameter Modelica.SIunits.Irradiance solRef = 1000
    "radiation under reference conditions";
parameter Real K = 4 "glazing extinction coefficient, /m";
parameter Modelica.SIunits.Length d = 2*10^(-3) "pane thickness, m";
final parameter Modelica.SIunits.Irradiance solAbsRef = solRef * exp(-K*d);

  Modelica.Blocks.Interfaces.RealInput solAbs
    annotation (Placement(transformation(extent={{-120,40},{-80,80}})));
  Modelica.Blocks.Interfaces.RealInput T
    annotation (Placement(transformation(extent={{-120,0},{-80,40}})));
  Modelica.Electrical.Analog.Interfaces.Pin pin
    annotation (Placement(transformation(extent={{90,50},{110,70}})));

protected
    Modelica.SIunits.ElectricCurrent I(start=0);
                                  //start=I_scr
    Modelica.SIunits.ElectricPotential V(start=V_ocr);
                                        //start=V_ocr

    Modelica.SIunits.ElectricCurrent I_ph(start=I_phr);
    Modelica.SIunits.ElectricCurrent I_o(start=I_or);
    Modelica.SIunits.Resistance R_s(start=R_sr);
    Modelica.SIunits.Resistance R_sh(start=R_shr);
    Modelica.SIunits.ElectricPotential V_t(start=V_tr);
    Modelica.SIunits.ElectricPotential V_ocg(start=V_ocr);
    Modelica.SIunits.ElectricPotential V_oc(start=V_ocr);
    Modelica.SIunits.ElectricCurrent I_sc(start=I_scr);

equation
//Open circuit voltage under non-reference condition
exp(V_ocg/(n_s*V_tr)) = ((I_phr*(solAbs/solAbsRef))*R_shr - V_oc)/(I_or*R_shr);
V_oc = V_ocg + kV*(T - T_ref);
//Short circuit current under non-reference condition
I_sc = (I_scr*(solAbs/solAbsRef))*(1 + kI/100*(T - T_ref));

//Junction thermal voltage at new temperature
V_t = V_tr*(T/T_ref);

//Dark saturation curren under non-reference condition
I_o = (I_sc - ((V_oc - I_sc*R_s)/(R_shr)))*exp(-(V_oc)/(n_s*V_t));

//Light current under non-reference condition
I_ph = I_o*exp((V_oc)/(n_s*V_t)) + (V_oc)/(R_shr);

//  if S>0 then
//    R_sh = R_shr*S_r/S;                      //"The shunt resistance was assumed to be independent of temperature
//  else
R_sh = R_shr;
//  end if;

R_s = R_sr;
//Rs is assumed constant...(for now)

//I-V curve equation
I = I_ph - I_o*(exp((V + I*R_s)/(n_s*V_t)) - 1) - (V + I*R_s)/(R_sh);

//Finding the maximum power point
0 = I + V*(-(((I_sc*R_sh - V_oc + I_sc*R_s)*exp((V + I*R_s - V_oc)/(n_s*V_t)))/(n_s*V_t*R_sh)) - (1/R_sh))/(1 + ((((I_sc*R_sh - V_oc + I_sc*R_s)*exp((V + I*R_s - V_oc)/(n_s*V_t)))/(n_s*V_t*R_sh))) + (R_s/R_sh));

pin.v = V;
pin.i = I;

  annotation (Icon(graphics={
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
          smooth=Smooth.None)}));
end PV5;
