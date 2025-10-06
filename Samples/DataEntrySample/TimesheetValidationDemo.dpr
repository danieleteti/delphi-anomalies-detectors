// ***************************************************************************
//
// Timesheet Validation Demo
// Demonstrates adaptive learning with user feedback for hours validation
//
// ***************************************************************************

program TimesheetValidationDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  WinAPI.Windows,
  {$ENDIF}
  TimesheetValidator;

const
  {$IFDEF MSWINDOWS}
  COLOR_NORMAL = 7;
  COLOR_ERROR = 12;    // Red
  COLOR_WARNING = 14;  // Yellow
  COLOR_SUCCESS = 10;  // Green
  COLOR_INFO = 11;     // Cyan
  {$ENDIF}

procedure SetConsoleColor(AColor: Word);
begin
  {$IFDEF MSWINDOWS}
  var lHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(lHandle, AColor);
  {$ENDIF}
end;

procedure WriteColoredLine(const AText: string; AColor: Word);
begin
  SetConsoleColor(AColor);
  WriteLn(AText);
  SetConsoleColor(COLOR_NORMAL);
end;

procedure SimulateTimesheetEntry;
var
  Validator: TTimesheetValidator;
  Message: string;
  Level: TValidationLevel;
  Hours: Double;
  Employee: Integer;
begin
  WriteColoredLine('=== TIMESHEET VALIDATION DEMO ===', COLOR_INFO);
  WriteLn('Adaptive learning with user feedback for employee hours');
  WriteLn('Demonstrates per-employee baselines and learning from confirmations');
  WriteLn;

  Validator := TTimesheetValidator.Create(16.0); // Max 16 hours/day
  try
    Employee := 101; // Employee ID

    WriteColoredLine('Scenario: Employee #101 timesheet entries', COLOR_INFO);
    WriteLn;

    // Test 1: Normal hours
    WriteColoredLine('Day 1: Normal working hours', COLOR_INFO);
    WriteLn;

    Hours := 8.0;
    WriteLn(Format('User enters: %.1f hours', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal: WriteColoredLine('  ✓ ' + Message, COLOR_SUCCESS);
      vlWarning: WriteColoredLine('  ⚠ ' + Message, COLOR_WARNING);
      vlError: WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;

    Hours := 7.5;
    WriteLn(Format('User enters: %.1f hours', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal: WriteColoredLine('  ✓ ' + Message, COLOR_SUCCESS);
      vlWarning: WriteColoredLine('  ⚠ ' + Message, COLOR_WARNING);
      vlError: WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;

    Hours := 8.5;
    WriteLn(Format('User enters: %.1f hours', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal: WriteColoredLine('  ✓ ' + Message, COLOR_SUCCESS);
      vlWarning: WriteColoredLine('  ⚠ ' + Message, COLOR_WARNING);
      vlError: WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;

    // Test 2: Overtime
    WriteLn(StringOfChar('-', 70));
    WriteColoredLine('Day 2: Overtime situation', COLOR_INFO);
    WriteLn;

    Hours := 12.0;
    WriteLn(Format('User enters: %.1f hours (overtime)', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal:
        WriteColoredLine('  ✓ ' + Message, COLOR_SUCCESS);
      vlWarning:
        begin
          WriteColoredLine('  ⚠ REQUIRES APPROVAL', COLOR_WARNING);
          WriteLn('  ' + Message);
          WriteLn;
          WriteLn('  System prompts: "12 hours is unusually high. Is this correct?"');
          WriteLn('  User confirms: "Yes, I worked overtime on urgent project"');
          WriteLn;
          WriteColoredLine('  → User confirmed - Teaching the system...', COLOR_INFO);
          Validator.ConfirmNormalHours(Employee, Hours);
          WriteColoredLine('  ✓ System learned: 12 hours can be normal for this employee', COLOR_SUCCESS);
        end;
      vlError:
        WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;

    // Test 3: Now 12 hours should be more acceptable
    WriteLn(StringOfChar('-', 70));
    WriteColoredLine('Day 3: Testing adapted pattern', COLOR_INFO);
    WriteLn('After learning, the same hours should be less suspicious...');
    WriteLn;

    Hours := 12.0;
    WriteLn(Format('User enters: %.1f hours again', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal:
        WriteColoredLine('  ✓ ' + Message + ' (learned from previous confirmation)', COLOR_SUCCESS);
      vlWarning:
        WriteColoredLine('  ⚠ ' + Message, COLOR_WARNING);
      vlError:
        WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;

    // Test 4: Physical impossibility
    WriteLn(StringOfChar('-', 70));
    WriteColoredLine('Day 4: Testing physical limits', COLOR_INFO);
    WriteLn;

    Hours := 18.0;
    WriteLn(Format('User enters: %.1f hours (exceeds physical limit)', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal:
        WriteColoredLine('  ✓ ' + Message, COLOR_SUCCESS);
      vlWarning:
        WriteColoredLine('  ⚠ ' + Message, COLOR_WARNING);
      vlError:
        begin
          WriteColoredLine('  ❌ ENTRY BLOCKED', COLOR_ERROR);
          WriteLn('  ' + Message);
          WriteLn('  → Action: Entry refused, user must correct the value');
          WriteLn('  → Possible causes: Typo, misunderstanding, fraudulent entry');
        end;
    end;
    WriteLn;

    // Test 5: Unusually low hours
    WriteLn(StringOfChar('-', 70));
    WriteColoredLine('Day 5: Part-time or sick day', COLOR_INFO);
    WriteLn;

    Hours := 2.0;
    WriteLn(Format('User enters: %.1f hours (very low)', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    case Level of
      vlNormal:
        WriteColoredLine('  ✓ ' + Message, COLOR_SUCCESS);
      vlWarning:
        begin
          WriteColoredLine('  ⚠ REQUIRES EXPLANATION', COLOR_WARNING);
          WriteLn('  ' + Message);
          WriteLn;
          WriteLn('  System prompts: "Only 2 hours? Please add a comment"');
          WriteLn('  User adds: "Left early - doctor appointment"');
          WriteColoredLine('  ✓ Accepted with explanation', COLOR_SUCCESS);
        end;
      vlError:
        WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;

    // Test 6: Different employee with different pattern
    WriteLn(StringOfChar('-', 70));
    WriteColoredLine('Employee #102: Part-time worker', COLOR_INFO);
    WriteLn('Demonstrating per-employee baselines...');
    WriteLn;

    Employee := 102;
    Hours := 4.0;
    WriteLn(Format('User enters: %.1f hours (part-time)', [Hours]));
    Level := Validator.ValidateHours(Employee, Hours, Message);
    WriteLn('  First entry initializes baseline for part-time pattern');
    case Level of
      vlNormal:
        WriteColoredLine('  ✓ ' + Message + ' for Employee #102', COLOR_SUCCESS);
      vlWarning:
        WriteColoredLine('  ⚠ ' + Message, COLOR_WARNING);
      vlError:
        WriteColoredLine('  ❌ ' + Message, COLOR_ERROR);
    end;
    WriteLn;
    WriteLn(Format('  System now tracks %d employees independently', [Validator.GetEmployeeCount]));

    WriteLn;
    WriteLn(StringOfChar('=', 70));
    WriteColoredLine('KEY INSIGHTS:', COLOR_INFO);
    WriteLn;
    WriteLn('✓ Per-employee learning - each employee has unique patterns');
    WriteLn('✓ Adaptive to changes - learns from user confirmations');
    WriteLn('✓ Three-level validation:');
    WriteLn('  • Normal (✓)   - Auto-accepted');
    WriteLn('  • Warning (⚠)  - Requires confirmation/explanation');
    WriteLn('  • Error (❌)   - Blocked, must be corrected');
    WriteLn('✓ Prevents both fraud AND honest errors');
    WriteLn;
    WriteColoredLine('PREVENTED ISSUES:', COLOR_SUCCESS);
    WriteLn('  • Timesheet fraud (inflated hours)');
    WriteLn('  • Data entry errors (18.0 instead of 8.0)');
    WriteLn('  • Missing explanations for unusual hours');
    WriteLn('  • Inconsistent patterns detection');
    WriteLn;
    WriteColoredLine('ADAPTIVE LEARNING:', COLOR_INFO);
    WriteLn('  • System learns overtime patterns from confirmations');
    WriteLn('  • Adjusts to employees who regularly work different hours');
    WriteLn('  • Reduces false positives over time while maintaining security');

  finally
    Validator.Free;
  end;
end;

begin
  try
    Randomize;

    WriteLn('Timesheet Hours Validation - Adaptive Learning Example');
    WriteLn('Per-employee validation with feedback-based learning');
    WriteLn(StringOfChar('=', 70));
    WriteLn;

    SimulateTimesheetEntry;

    WriteLn;
    WriteLn(StringOfChar('=', 70));
    WriteColoredLine('Demo completed successfully!', COLOR_SUCCESS);
    WriteLn;
    WriteLn('Press ENTER to exit...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteColoredLine('ERROR: ' + E.Message, COLOR_ERROR);
      WriteLn('Press ENTER to exit...');
      ReadLn;
      ExitCode := 1;
    end;
  end;
end.
