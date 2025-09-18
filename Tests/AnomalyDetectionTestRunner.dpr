// ***************************************************************************
//
// Copyright (c) 2025 Daniele Teti - All Rights Reserved
//
// Test runner for Anomaly Detection Algorithms Library
//
// ***************************************************************************

program AnomalyDetectionTestRunner;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.ConsoleWriter.Base,
  DUnitX.InternalInterfaces,
  DUnitX.Generics,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.Loggers.Xml.xUnit,
  DUnitX.Extensibility,
  DUnitX.TestRunner,
  DUnitX.TestFramework,
  AnomalyDetectionAlgorithmsTests in 'AnomalyDetectionAlgorithmsTests.pas',
  AnomalyDetectionAlgorithms in '..\AnomalyDetectionAlgorithms.pas';

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;

begin
  try
    // Create the runner
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;

    // Tell the runner how we will log things
    logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);

    // Generate NUnit compatible XML output for CI/CD integration
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    // When true, text output will contain more detail
    runner.FailsOnNoAsserts := False;

    // Run the tests
    results := runner.Execute;

    // Report results
    if not results.AllPassed then
      System.ExitCode := 1;

    {$IFNDEF CI}
    // Keep console open if not in CI
    System.Write('Press <Enter> to exit.');
    System.Readln;
    {$ENDIF}
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 2;
    end;
  end;
end.
