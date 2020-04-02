within IDEAS.Buildings.Validation.Tests;
model ConvectionVerification
  "Comparison between linear and non-linear convection"
  extends Modelica.Icons.Example;

  inner BoundaryConditions.SimInfoManager sim
    annotation (Placement(transformation(extent={{-92,68},{-82,78}})));
  IDEAS.Buildings.Validation.Cases.Case900 CaseLin(building(
      roof(linIntCon_a=true),
      wall(each linIntCon_a=true),
      floor(linIntCon_a=true),
      win(each linIntCon_a=true)))
    annotation (Placement(transformation(extent={{-76,4},{-64,16}})));
  IDEAS.Buildings.Validation.Cases.Case900 CaseNonLin(building(
      roof(linIntCon_a=false),
      wall(each linIntCon_a=false),
      floor(linIntCon_a=false),
      win(each linIntCon_a=false)))
    annotation (Placement(transformation(extent={{-76,-16},{-64,-4}})));
  annotation (Documentation(info="<html>
</html>", revisions="<html>
<ul>
<li>
March 31, 2020, by Christina Protopapadaki:<br/>
Parameter <code>linearise_a</code> changed to <code>linIntCon_a</code>, to be in line with change in
<a href=\"modelica://IDEAS.Buildings.Components.Interfaces.PartialSurface\">IDEAS.Buildings.Components.Interfaces.PartialSurface</a> from 
<a href=\"https://github.com/open-ideas/IDEAS/commit/672f0cb\">commit 672f0cb</a>. 
</li>
</ul>
</html>"),
Diagram(graphics={           Text(
          extent={{-78,28},{-40,20}},
          lineColor={85,0,0},
          fontName="Calibri",
          textStyle={TextStyle.Bold},
          textString="BESTEST 900 Series")}),
    experiment(
      StopTime=1000000,
      Interval=3600,
      Tolerance=1e-06,
      __Dymola_Algorithm="Lsodar"),
    __Dymola_experimentSetupOutput,
    __Dymola_Commands(executeCall(ensureSimulated=true) = {createPlot(
        id=1,
        position={0,0,1097,611},
        y={"CaseNonLin.heatingSystem.QHeaSys","CaseLin.heatingSystem.QHeaSys"},
        range={0.0,1000000.0,-4000.0,2000.0},
        grid=true,
        filename="ConvectionVerification.mat",
        colors={{28,108,200},{238,46,47}}),createPlot(
        id=1,
        position={0,0,1097,302},
        y={"CaseLin.building.TSensor[1]","CaseNonLin.building.TSensor[1]"},
        range={0.0,1000000.0,293.0,301.0},
        grid=true,
        subPlot=2,
        colors={{28,108,200},{238,46,47}})} "Simulate and plot"));
end ConvectionVerification;
