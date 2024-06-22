object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 159
  ClientWidth = 316
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poDesktopCenter
  OnCreate = FormCreate
  DesignSize = (
    316
    159)
  TextHeight = 15
  object Label1: TLabel
    Left = 20
    Top = 35
    Width = 92
    Height = 15
    Alignment = taRightJustify
    Caption = 'Choose language'
  end
  object ComboBox1: TComboBox
    Left = 132
    Top = 32
    Width = 163
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object MainMenu1: TMainMenu
    Left = 24
    Top = 80
    object File1: TMenuItem
      Caption = 'File'
      object File2: TMenuItem
        Caption = 'Quit'
        OnClick = File2Click
      end
    end
    object Languages1: TMenuItem
      Caption = 'Languages'
    end
    object Help1: TMenuItem
      Caption = 'Help'
      object Help2: TMenuItem
        Caption = 'About'
      end
    end
  end
end
