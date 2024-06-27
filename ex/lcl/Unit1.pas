unit Unit1;

{$MODE Delphi}

// Your text file must be either:
//   - In WinAnsi / 1252 code page
//   - UTF-8 encoded with BOM
//
// For resources, define EXTRACTALLRESOURCES globally

interface

uses
  LCLIntf, LCLType, LMessages, Classes, Forms, Controls, Menus, StdCtrls,
  ///
  mormot.core.base,
  mormot.core.text, 
  mormot.core.os,
  //
  mormot.i18n;
 
type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    Help1: TMenuItem;
    Help2: TMenuItem;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Languages1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure File2Click(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}
  
procedure TForm1.File2Click(Sender: TObject);
begin
  close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  {$ifdef EXTRACTALLRESOURCES}
  // Generate .messages file filed with identifiers
  ExtractAllResources(
    // first, all enumerations to be translated
    [],
    // then some class instances
    [],
    // some custom classes or captions
    [], []);
  Close;
  {$endif}

  i18nAddLanguageCombo('', // use Executable.ProgramFilePath
                       ComboBox1);
  i18nAddLanguageMenu('', Languages1);
end;

end.
