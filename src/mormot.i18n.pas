﻿/// internationalization (i18n) routines and classes for mORMot v2.2
// - this unit is adapted from Synopse mORMot framework version 1.18
//   to work with mORMot v2.2.
// - this file is not officially part of the Synopse mORMot 2 Framework
// - it is open source and available on GitHub under the MPL/GPL/LGPL tri-license

unit mormot.i18n;

{$ifdef FPC}
  {$MODE Delphi}
{$endif}

(*
  Synopse mORMot framework. Copyright (C) 2024 Arnaud Bouchez
    Synopse Informatique - https://synopse.info
  Original tri-license: MPL 1.1/GPL 2.0/LGPL 2.1

  see: https://github.com/synopse/mORMot2/blob/master/LICENCE.md
*)  

interface

{.$D-,L-}
          
{$I mormot.defines.inc} // define HASINLINE CPU32 CPU64 OWNNORMTOUPPER

{$ifdef CPUX64}
  {$define PUREPASCAL}
{$endif}

{.$define EXTRACTALLRESOURCES}
// must be set globally for the whole application

{.$define ENHANCEDRTL}
{ define this if you DID install our Enhanced Runtime library: it has already
  hacked the "legacy" LoadResString() procedure and added a LoadResStringTranslate()
  - it will be unset automaticaly (see below) for Delphi 2009 and up, since
    no version of our Enhanced RTL exists for these compilers
  - this conditional must be defined in both mORMot.pas and mORmoti18n.pas units,
    or (even better) globally in the Project options }

{.$define USESHARP}
// if defined, $$,$$$,$$$ are replaced with some globals in _()

{$ifndef NOI18N}
  // with this global define, you can use the unit procs, without the UI i18n
  {$define USEFORMCREATEHOOK}
  // if defined, all forms will be auto-translated, even 3rd party ones
  // just before an OnCreate handler would be called
{$endif}

{.$undef USEFORMCREATEHOOK}

uses
  {$I mormot.uses.inc}
  
{$ifdef MSWINDOWS}
  Windows,
  {$ifdef LCL}
  LCLIntf,
  {$endif}
{$else MSWINDOWS}
  {$ifdef FPC_POSIX}
    BaseUnix,
  {$endif FPC_POSIX}
{$endif MSWINDOWS}
  Classes,
  SysUtils,
  {$ifdef HASINLINE}
    Types,
    {$ifdef LCL}
      LCLType,
    {$endif}
  {$endif HASINLINE}
{$ifndef NOVARIANTS}
  Variants,
{$endif NOVARIANTS}
  {$ifdef USEFORMCREATEHOOK}
  {$ifdef LCL}
  Menus,StdCtrls,DateUtils,
  {$else}
  Vcl.Menus,
  {$endif}
  {$endif USEFORMCREATEHOOK}
  {$ifndef LCL}
  vcl.Forms,Vcl.StdCtrls,Vcl.ExtCtrls,
  {$else}
  Interfaces, LResources, Forms, Dialogs, ImgList,
  {$endif}
  mormot.core.base,
  mormot.core.os,
  mormot.core.unicode,
  mormot.core.datetime,
  mormot.core.rtti,
  mormot.core.interfaces,
  mormot.core.text,
  mormot.core.data,
  mormot.orm.core,
  mormot.orm.base,
  mormot.rest.core;
  
{$ifdef UNICODE}
{$undef ENHANCEDRTL} // no version of our Enhanced RTL exists for Delphi 2009 and up
{$endif}

{$ifdef LCL}
type
  TMyResStringRec = record
    Identifier: Integer;
    Module: PLongint;
  end;
  PMyResStringRec = ^TMyResStringRec;
{$endif}

{$ifdef CPUINTEL}
type
  /// small memory buffer used to backup a RedirectCode() redirection hook
  TPatchCode = array[0..4] of byte;
  /// pointer to a small memory buffer used to backup a RedirectCode() hook
  PPatchCode = ^TPatchCode;

/// self-modifying code - add an asm JUMP to a redirected function
// - if Backup is not nil, it should point to a TPatchCode buffer, ready
// to contain the overridden code buffer, for further hook disabling
procedure RedirectCode(Func, RedirectFunc: Pointer; Backup: PPatchCode=nil);

/// self-modifying code - restore a code from its RedirectCode() backup
procedure RedirectCodeRestore(Func: pointer; const Backup: TPatchCode);
{$endif CPUINTEL}

type
  /// languages handled by this mORMoti18n unit
  // - include all languages known by WinXP SP2 without some unicode-only very
  // rare languages; total count is 60
  // - some languages (Japanase, Chinese, Arabic) may need specific language
  // pack installed on western/latin version of windows
  // - lngEnglish is the default language of the executable, used as reference
  // for all other translation, and included into executable (no EN.msg file
  // will never be loaded)
  TLanguages = (
    lngHebrew, lngGreek, lngLatin, lngDari, lngBosnian, lngCatalan,
    lngCorsican, lngCzech, lngCoptic, lngSlavic, lngWelsh, lngDanish,
    lngGerman, lngArabic, lngEnglish, lngSpanish, lngFarsi, lngFinnish,
    lngFrench, lngIrish, lngGaelic, lngAramaic, lngCroatian, lngHungarian,
    lngArmenian, lngIndonesian, lngInterlingue, lngIcelandic, lngItalian,
    lngJapanese, lngKorean, lngTibetan, lngLituanian, lngMalgash, lngNorwegian,
    lngOccitan, lngPortuguese, lngPolish, lngRomanian, lngRussian, lngSanskrit,
    lngSlovak, lngSlovenian, lngAlbanian, lngSerbian, lngSwedish, lngSyriac,
    lngTurkish, lngTahitian, lngUkrainian, lngVietnamese, lngChinese, lngDutch,
    lngThai, lngBulgarian, lngBelarusian, lngEstonian, lngLatvian, lngMacedonian,
    lngPashtol {$ifdef FPC},lngDummy{$endif});

const
  /// value stored into a TLanguages enumerate to mark no language selected yet
  {$ifdef FPC} // can't get rid of range checking with laz/fpc[-2_2]
  LANGUAGE_NONE = TLanguages(lngDummy);
  {$else}
  LANGUAGE_NONE = TLanguages(255);
  {$endif}

  /// ISO 639-1 compatible abbreviations (not to be translated):
  LanguageAbr: packed array[TLanguages] of RawByteString { 4bytes-aligned }
   = ('he','gr','la','ad','bs','ca','co','cs','cp','cu','cy','da','de','ar',
      'en','es','fa','fi','fr','ga','gd','am','hr','hu','hy','id','ie','is',
      'it','ja','ko','bo','lt','mg','no','oc','pt','pl','ro','ru','sa','sk',
      'sl','sq','sr','sv','sy','tr','ty','uk','vi','zh','nl', { end of Ictus3 values }
      'th','bg','be','et','lv','mk','ap' {$ifdef FPC},'--'{$endif});

  /// to sort in alphabetic order : LanguageAbr[TLanguages(LanguageAlpha[lng])]
  // - recreate these table with ModifiedLanguageAbr if LanguageAbr[] changed
  LanguageAlpha: packed array[TLanguages] of byte =
  (3, 21, 59, 13, 55, 54, 31, 4, 5, 6, 8, 7, 9, 10, 11, 12, 14, 15, 56, 16, 17,
   18, 19, 20, 1, 0, 22, 23, 24, 25, 26, 27, 28, 29, 30, 2, 32, 57, 33, 58, 52,
   34, 35, 37, 36, 38, 39, 40, 41, 42, 43, 44, 45, 46, 53, 47, 48, 49, 50, 51
   {$ifdef FPC},60{$endif});

  /// US English Windows LCID, i.e. standard international settings
  LCID_US = $0409;

{$ifdef WITHUXTHEME}
var
  /// international settings from US English $0409
  // - useful in any software, if you want to save some content
  // with the default english encoding (e.g. floating point values with '.')
  SettingsUS: TFormatSettings;
{$endif}

var
  /// true if this program is running on Windows Vista (tm)
  // - used to customize on the fly any TTreeView component, to meet Vista
  // and Seven expectations
  isVista: boolean = false;

type
  /// a common record to identify a language
  {$ifdef USERECORDWITHMETHODS}TLanguage = record
    {$else}TLanguage = object{$endif}
  public
    /// as in LanguageAbr[index], LANGUAGE_NONE before first SetLanguageLocal()
    Index: TLanguages;
    /// the corresponding Char Set
    CharSet: integer;
    /// the corresponding Code Page
    CodePage: cardinal;
    /// the corresponding Windows LCID
    LCID: cardinal;
    /// initializes all TLanguage object fields for a specific language
    procedure Fill(Language: TLanguages);
    /// returns two-chars long language abreviation ('HE' e.g.)
    function Abr: RawByteString;
    /// returns fully qualified language name ('Hebrew' e.g.),
    // using current UI language
    // - return "string" type, i.e. UnicodeString for Delphi 2009 and up
    function Name: string;
  end;

var
  /// the global Language used by the User Interface,
  // as updated by the last SetCurrentLanguage() call
  CurrentLanguage: TLanguage = (
    Index:    LANGUAGE_NONE;
    CharSet:  DEFAULT_CHARSET;
    CodePage: CODEPAGE_US;
    LCID:     LCID_US
  );

{$ifndef NOI18N}
{$ifdef USEFORMCREATEHOOK} // language is read from registry once at startup:
const
  /// the sub-entry used to store the i18n settings in the registry;
  // change this value to your company's name, with a trailing backslash
  // ('WorldCompany\' e.g.). the key is
  // HKEY_CURRENT_USER\Software\[RegistryCompanyName]i18n\programname
  RegistryCompanyName = '';

/// add strings items, for all available languages on disk
// - it will search in MsgPath for all *.msg available
// - if MsgPath is not set, the current executable directory will be used for searching
// - new items are added to List: Strings[] will contain a caption text, ready
// to be displayed, and PtrInt(Objects[]) will be the corresponding language ID
// - return the current language index in List.Items[]
function i18nAddLanguageItems(MsgPath: TFileName; List: TStrings): integer;

/// add sub-menu items to the Menu, for all available languages on disk
// - uses internaly i18nAddLanguageItems() function above
// - current language is checked
// - all created MenuItem.OnClick event will launch Language.LanguageClick to
// change the current language in the registry
procedure i18nAddLanguageMenu(const MsgPath: TFileName; Menu: TMenuItem);

/// add combo-box items, for all available languages on disk
// - uses internaly i18nAddLanguageItems() function above
// - current language is selected by default
// - the OnClick event will launch Language.LanguageClick to
// change the current language in the registry
procedure i18nAddLanguageCombo(const MsgPath: TFileName; Combo: TComboBox);

/// save the default language to the registry
// - language will be changed at next startup
// - return a message ready to be displayed on the screen
// - return "string" type, i.e. UnicodeString for Delphi 2009 and up
function i18nLanguageToRegistry(const Language: TLanguages): string;

/// get the default language from the registry
function i18nRegistryToLanguage: TLanguages;

resourcestring
  /// this message will be displayed on the screen when the user change the
  // current language, together with its english version
  SHaveToRestart = 'You have to restart the application to apply these language changes.';

{$else} { only called once in Initialization.LangInit: }

/// resets all translation and locale-specific variables via SetThreadLocale()
// - by default, if the supplied language does not have a corrrespondig .msg
// local file, it will fallback to lngEnlish for the whole application
// - you may set aForceEnglishIfNoMsgFile=false to change the application
// localization code, even if there is no matching .msg file
procedure SetCurrentLanguage(aLanguage: TLanguages; aForceEnglishIfNoMsgFile: boolean=true); overload;

/// resets all translation and locale-specific variables via SetThreadLocale()
// - by default, if the supplied language does not have a corrrespondig .msg
// local file, it will fallback to lngEnlish for the whole application
// - you may set aForceEnglishIfNoMsgFile=false to change the application
// localization code, even if there is no matching .msg file
procedure SetCurrentLanguage(const value: RawUTF8; aForceEnglishIfNoMsgFile: boolean=true); overload;
{$endif}
{$endif}

/// Return the language text, ready to be displayed (after translation if
// necessary)
// - e.g. LanguageName(lngEnglish)='English'
// - return "string" type, i.e. UnicodeString for Delphi 2009 and up
function LanguageName(aLanguage: TLanguages): string;

/// LanguageAbrToIndex('GR')=1, e.g.
// - return LANGUAGE_NONE if not found
function LanguageAbrToIndex(const value: RawUTF8): TLanguages; overload;

/// LanguageAbrToIndex('GR')=1, e.g.
// - return LANGUAGE_NONE if not found
function LanguageAbrToIndex(p: pAnsiChar): TLanguages; overload;

/// convert a i18n language index into a Windows LCID
function LanguageToLCID(Language: TLanguages): integer;

/// convert a Windows LCID into a i18n language
function LCIDToLanguage(LCID: integer): TLanguages;

{$ifdef USESHARP}
var
  /// customize this 3 values for $$ $$$ and $$$$ replacement
  sharp: string = '';
  sharp2: string = '';
  sharp3: string = '';
{$endif}

/// translate the 'Text' term into current language, with no || nor $$[$[$]]
// - LoadResStringTranslate of our customized system.pas points to this procedure
// - therefore, direct use of LoadResStringTranslate() is better in apps
// - expect "string" type, i.e. UnicodeString for Delphi 2009 and up
procedure GetText(var Text: string);

/// translate the 'English' term into current language
// - you should use resourcestring instead of this function
// - call interenaly GetText() procedure, i.e. LoadResStringTranslate()
function _(const English: WinAnsiString): string;

var
  /// a table used for fast conversion to lowercase, according to the current language
  // - can NOT be used for MBCS strings (with such code pages, you should use windows
  // slow but accurate API)
  i18nToLower,
  /// a table used for fast conversion to uppercase, according to the current language
  // - can NOT be used for MBCS strings (with such code pages, you should use windows
  // slow but accurate API)
  i18nToUpper: TNormTable;
  /// a table used for fast conversion to lowercase, according to the current language
  // - can NOT be used for MBCS strings (with such code pages, you should use windows
  // slow but accurate API)
  i18nToLowerByte: TNormTableByte absolute i18nToLower;
  /// a table used for fast conversion to uppercase, according to the current language
  // - can NOT be used for MBCS strings (with such code pages, you should use windows
  // slow but accurate API)
  i18nToUpperByte: TNormTableByte absolute i18nToUpper;

type
  /// function prototype for comparing two Ansi strings
  // - used for comparison within the current selected language
  TCompareFunction = function(const S1, S2: AnsiString): Integer;

var
  /// use this function to compare string with case sensitivity for the UI
  // - use current language for comparison
  // - can be used for MBCS strings (with such code pages, it will use windows
  // slow but accurate API)
  i18nCompareStr: TCompareFunction = nil;
  /// use this function to compare string with no case sensitivity for the UI
  // - use current language for comparison
  // - can be used for MBCS strings (with such code pages, it will use windows
  // slow but accurate API)
  i18nCompareText: TCompareFunction = nil;


type
  TCustomFormDynArray = array of TCustomForm;

  /// class to load and handle translation files (fr.msg, de.msg, ja.msg.. e.g.)
  // - This standard .msg text file contains all the program resources translated
  // into any language.
  // - Unicode characters (Chinese or Japanese) can be used.
  // - The most important part of this file is the [Messages] section, which
  // contain all the text to be displayed in NumericValue=Text pairs.
  // The numeric value is a hash (i.e. unique identifier) of the Text.
  // To make a new translation, the "Text" part of these pairs must be translated,
  // but the NumericValue must remain the same.
  // - In the "Text" part, translator must be aware of some important characters,
  // which must NOT be modified, and appears in exactly the same place inside
  // the translated text:\line
  // 1. | indicates a CR (carriage return) character;\line
  // 2. ~ indicates a LF (line feed) character;\line
  // 3. , sometimes is a comma inside a sentence, but is also used some other times
  // as a delimiter between sentences; \line
  // 4. %s will be replaced by a textual value before display;\line
  // 5. %d will be replaced by a numerical value before display;\line
  // some HTML code may appear (e.g. <br><font color="clnavy">...) and all text
  // between < and > must NOT be modified;\line
  // 6. no line feed or word wrap is to be used inside the "Text" part; the whole
  // NumericValue=Text pair must be contained in an unique line, even if it is huge.
  // - Some other sections appears before the [Messages] part, and does apply to
  // windows as they are displayed on screen. By default, the text is replaced by
  // a _ with a numerical value pointing to a text inside the [Messages] section.
  // On some rare occasion, this default translation may be customized: in such
  // cases, the exact new text to be displayed can be used instead of the
  // _1928321 part. At the end of every line, the original text (never used,
  // only put there for translator convenience) was added.
  // - In order to add a new language, the steps are to be performed:\line
  // 0. Extract all english message into a .txt ansi file, by calling the
  // ExtractAllResources() procedure in the main program\line
  // 1. Use the latest .txt original file, containing the original English messages\line
  // 2. Open this file into a text editor (not Microsoft Word, but a real text editor,
  // like the Windows notepad)\line
  // 3. Translate the English text into a new language; some Unicode characters may be used\line
  // 4. Save this new file, with the ISO two chars corresponding to the new language
  // as file name, and .msg as file extension (e.g. FR.msg for French or RU.msg for Russian).\line
  // 5. By adding this .msg file into the PhD.exe folder, the PC User software
  // will automatically find and use it to translate the User Interface on the fly.
  // Each user is able to select its own preferred translation.\line
  // 6. The translator can perform the steps 3 to 5 more than once, to see in real
  // time its modifications: he/she just has to restart the PC software to
  // reload the updated translations.
  TLanguageFile = class
  protected
    /// the content of the .msg file, translated into generic VCL string
    // - [Messages] section is expanded into Messages TStringList (see below)
    // - for Forms translations: [FormName] sections, with Properties=UI Text pairs
    // - is either an AnsiString in the current code page, or an UnicodeString
    // (in case of Delphi 2009 and up, that is a UNICODE compiler)
    Text: string;
    /// copy of translated strings from [Messages] section
    // - Objects[] contain pointer(Hash32(WinAnsiEncodedMessage))
    // - Strings[] contain Message text, in UnicodeString for Delphi 2009 and up
    Messages: TStringList;
{$ifndef LVCL} { LCL will use always the ISO 8601 generic text format }
    /// format string used to convert a date value to a text
    // - the expected format is the one used by the FormatDateTime() function
    // - the current system format, depending on the current language, is used,
    // then overridden by a DateFmt= entry in the .msg file content
    DateFmt: string;
    /// format string used to convert a time value to a text
    // - the expected format is the one used by the FormatDateTime() function
    // - the current system format, depending on the current language, is used,
    // then overridden by a TimeFmt= entry in the .msg file content
    TimeFmt: string;
    /// format string used to convert a date and time value to a text
    // - the expected format is the one used by the FormatDateTime() function
    // - the current system format, depending on the current language, is used,
    // then overridden by a DateTimeFmt= entry in the .msg file content
    DateTimeFmt: string;
    /// string used for displaying boolean values
    fBooleanToString: array[boolean] of string;
{$endif}
{$ifndef USEFORMCREATEHOOK}
    /// list of TForm sent to FormTranslate([....])
    AlreadyTranslated: TCustomFormDynArray;
{$else}
    /// set a language ID to change the UI into the registry
    // - TComboBox(Sender).Items.Objects[TComboBox(Sender).ItemIndex] is the
    // language ID
    // - TMenuItem(Sender).Tag is the language ID
    procedure LanguageClick(Sender: TObject);
{$endif USEFORMCREATEHOOK}
    /// get corresponding *.msg translation text file name from current exe directory
    // - e.g. return 'C:\Program Files\MyApplication\FR.msg'
    class function FileName(aLanguageLocale: TLanguages): TFileName;
    /// return a translated text from a Hash32(WinAnsiString) value
    // - search is very fast (use binary search algorithm)
    // - return a generic VCL string (i.e. UnicodeString for Delphi 2009 and up)
    function FindMessage(Hash: cardinal): string;
  public
    /// identify the current language
    Language: TLanguage;
    /// specify a text file containing the translation messages for a language
    constructor Create(const aFileName: TFileName; aLanguageLocale: TLanguages); overload;
    /// load corresponding *.msg translation text file from the current exe directory
    constructor Create(aLanguageLocale: TLanguages); overload;
    /// free translation tables memory
    destructor Destroy; override;
    /// fill translation tables from text file containing the translation messages
    // - handle on the fly UTF-8 and UNICODE decode into the corresponding ANSI
    // CHARSET, or into UnicodeString for Delphi 2009 and up (checking UTF-8 or
    // Unicode BOM marker is available)
    procedure LoadFromFile(const aFileName: TFileName);
    /// translate an English string into a localized string
    // - English is case-sensitive (same as standard gettext)
    // - translations are stored in Messages[] and Text properties
    // - expect parameter as generic VCL string (i.e. UnicodeString for Delphi 2009 and up)
    procedure Translate(var English: string);
    /// translate the english captions of a TForm into the current UI language
    // - must be called once with english captions
    // - call automaticaly if conditional USEFORMCREATEHOOK is defined
    procedure FormTranslateOne(aForm: TComponent);
{$ifndef USEFORMCREATEHOOK}
    procedure FormTranslate(Forms: array of TCustomForm);
{$endif USEFORMCREATEHOOK}
    /// read a parameter, stored in the .msg file before any [Section]
    function ReadParam(const ParamName: RawUTF8): string;
    /// convert the supplied boolean constant into ready to be displayed text
    // - by default, returns 'No' for false, and 'Yes' for true
    // - returns the text as generic string type, ready to be used in the VCL
    function BooleanToString(Value: boolean): string;
    /// convert a TSQLRecord published property value into ready to be displayed text
    // - will convert any sftUTF8Text/sftAnsiText into ready to be displayed text
    // - will convert any sftInteger/sftFloat/sftCurrency into its textual value
    // - will convert any sftBoolean, sftEnumerate, sftDateTime, sftUnixTime or
    // sftTimeLog/sftModTime/sftCreateTime into the corresponding text, depending
    // on the current language
    // - will convert a sftSet property value to a list of all set enumerates,
    // separated by #13#10
    // - will convert any sftID to 'Record Name', i.e. the value of the main
    // property (mostly 'Name') of the referenced record
    // - will convert any sftRecord to 'Table Name: Record Name'
    // - will ignore sftBlob field
    // - returns the text as generic string type, ready to be used in the VCL
    function PropToString(Prop: TOrmPropInfo; Instance: TOrm; Client: TRest): string;
    /// convert a date into a ready to be displayed text on the screen
    function DateToText(const DateTime: TDateTime): string; overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a date into a ready to be displayed text on the screen
    function DateToText(const Time: TTimeLogBits): string; overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a date into a ready to be displayed text on the screen
    function DateToText(const Time: TTimeLog): string; overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a date and time into a ready to be displayed text on the screen
    function DateTimeToText(const DateTime: TDateTime): string;
      overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a date and time into a ready to be displayed text on the screen
    function DateTimeToText(const Time: TTimeLogBits): string; overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a date and time into a ready to be displayed text on the screen
    function DateTimeToText(const Time: TTimeLog): string; overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a time into a ready to be displayed text on the screen
    function TimeToText(const DateTime: TDateTime): string;
      overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a time into a ready to be displayed text on the screen
    function TimeToText(const Time: TTimeLogBits): string; overload; {$ifdef HASINLINE}inline;{$endif}
    /// convert a time into a ready to be displayed text on the screen
    function TimeToText(const Time: TTimeLog): string; overload; {$ifdef HASINLINE}inline;{$endif}
  end;

{
/// export the translation file into a .PO format
// - the .PO format is used by the GNU gettext tool, and allow to use some
// very useful translation tools
// (see @http://www.gnu.org/software/hello/manual/gettext/PO-Files.html
// for documentation about the .PO format itself)
//  - the .PO is created from two .msg files, both contained in the SourceMsgPath
// directory: the original EN.msg file and the specified SourceLanguage.msg
// translated file; the resulting POFileName will be created for this language
// - if not SourceMsgPath is supplied, the current directory is used (not
// necessary the executable directory)
procedure POExport(const SourceMsgPath, POFileName: TFileName; SourceLanguage: TLanguages);
}

/// generic US/English date/time to VCL text conversion
// - not to be used in your programs: it's just here to allow inlining of
// TLanguageFile.DateTimeToText/DateToText/TimeToText
function DateTimeToIso(const DateTime: TDateTime; DateOnly: boolean): string;

var
  /// global variable set by SetCurrentLanguage(), used for translation
  // - use this object, and its Language property, to retrieve current UI settings
  Language: TLanguageFile = nil;

  /// global event to be assigned for component translation override
  // - the method implementing this event must return true if the
  // translation was handled, or false if the translation must be done
  // by the framework
  OnTranslateComponent: function(C: TComponent): boolean of object = nil;


{$ifdef EXTRACTALLRESOURCES}
/// save all forms and resourcestring of the current exe to a .messages file
// following the .msg format (WinAnsi text file, since it should be in english)
// call this procedure once in your program in order to create a template
// to be used later for translation (don't call it in release executable)
// - only parameter is the used enumerations to be displayed (after uncamel)
procedure ExtractAllResources(const EnumTypeInfo: array of pointer;
  const Objects: array of TObject; const Records: array of TClass;
  const CustomCaptions: array of WinAnsiString);
{$endif}

{$ifndef ENHANCEDRTL}
/// our hooked procedure for reading a string resource
// - the default one in System.pas unit is replaced by this one
// - this function add caching and on the fly translation (if LoadResStringTranslate
// is defined in SynCommons.pas unit)
// - use "string" type, i.e. UnicodeString for Delphi 2009 and up
{$ifndef LCL}
function LoadResString(ResStringRec: PResStringRec): string;
{$else}
function LoadResString(ResStringRec: PMyResStringRec): string;
{$endif}
{$endif}


/// convert any generic VCL Text into an UTF-8 encoded String
// - same as SynCommons.StringToUTF8()
function S2U(const Text: string): RawUTF8;
  {$ifdef HASINLINE}inline;{$endif}

/// convert an UTF-8 encoded text into a VCL-ready string
// - same as SynCommons.UTF8ToString()
function U2S(const Text: RawUTF8): string;
  {$ifdef HASINLINE}inline;{$endif}

/// convert a custom date/time into a VCL-ready string
// - this function must be assigned to i18nDateText global var of SynCommons.pas
// - wrapper to Language.DateTimeToText(Iso) method
function Iso2S(const Iso: TTimeLog): string;

/// convert a custom date/time into a VCL-ready string
// - this function must be assigned to i18nDateTimeText global var of SynCommons.pas
// - wrapper to Language.DateTimeToText(DateTime) method
function DateTime2S(const DateTime: TDateTime): string;


/// From SynCommons
///
{$ifndef ENHANCEDRTL}
var
  /// these procedure type must be defined if a default system.pas is used
  // - mORMoti18n.pas unit will hack default LoadResString() procedure
  // - already defined in our Extended system.pas unit
  // - needed with FPC, Delphi 2009 and up, i.e. when ENHANCEDRTL is not defined
  // - expect generic "string" type, i.e. UnicodeString for Delphi 2009+
  // - not needed with the LCL framework (we should be on server side)
  LoadResStringTranslate: procedure(var Text: string) = nil;

  /// current LoadResString() cached entries count
  // - i.e. resourcestring caching for faster use
  // - used only if a default system.pas is used, not our Extended version
  // - defined here, but resourcestring caching itself is implemented in the
  // mORMoti18n.pas unit, if the ENHANCEDRTL conditional is not defined
  CacheResCount: integer = -1;
{$endif}

implementation

uses
{$ifdef LCL}
  Controls,
  ExtCtrls,
  Graphics
{$else}
  vcl.ComCtrls,
  vcl.Controls,
  vcl.Graphics
  {$ifdef WITHUXTHEME}
  ,UxTheme
  {$endif}
{$endif}
  ;

var
  // to speed up search in LanguageAbrToIndex():
  LanguageAbrWord: array[TLanguages] of word; // copy of LanguageAbr[]

{$ifdef FPC}
const
  LCID_INSTALLED = $00000001;  { installed locale ids }
  LCID_SUPPORTED = $00000002;  { supported locale ids }
  CP_INSTALLED   = $00000001;  { installed code page ids }
  CP_SUPPORTED   = $00000002;  { supported code page ids }
(*
 *  Language IDs.
 *
 *  The following two combinations of primary language ID and
 *  sublanguage ID have special semantics:
 *
 *    Primary Language ID   Sublanguage ID      Result
 *    -------------------   ---------------     ------------------------
 *    LANG_NEUTRAL          SUBLANG_NEUTRAL     Language neutral
 *    LANG_NEUTRAL          SUBLANG_DEFAULT     User default language
 *    LANG_NEUTRAL          SUBLANG_SYS_DEFAULT System default language
 *)
{ Primary language IDs. }
  LANG_NEUTRAL                         = $00;
  LANG_AFRIKAANS                       = $36;
  LANG_ALBANIAN                        = $1c;
  LANG_ARABIC                          = $01;
  LANG_BASQUE                          = $2d;
  LANG_BELARUSIAN                      = $23;
  LANG_BULGARIAN                       = $02;
  LANG_CATALAN                         = $03;
  LANG_CHINESE                         = $04;
  LANG_CROATIAN                        = $1a;
  LANG_CZECH                           = $05;
  LANG_DANISH                          = $06;
  LANG_DUTCH                           = $13;
  LANG_ENGLISH                         = $09;
  LANG_ESTONIAN                        = $25;
  LANG_FAEROESE                        = $38;
  LANG_FARSI                           = $29;
  LANG_FINNISH                         = $0b;
  LANG_FRENCH                          = $0c;
  LANG_GERMAN                          = $07;
  LANG_GREEK                           = $08;
  LANG_HEBREW                          = $0d;
  LANG_HUNGARIAN                       = $0e;
  LANG_ICELANDIC                       = $0f;
  LANG_INDONESIAN                      = $21;
  LANG_ITALIAN                         = $10;
  LANG_JAPANESE                        = $11;
  LANG_KOREAN                          = $12;
  LANG_LATVIAN                         = $26;
  LANG_LITHUANIAN                      = $27;
  LANG_NORWEGIAN                       = $14;
  LANG_POLISH                          = $15;
  LANG_PORTUGUESE                      = $16;
  LANG_ROMANIAN                        = $18;
  LANG_RUSSIAN                         = $19;
  LANG_SERBIAN                         = $1a;
  LANG_SLOVAK                          = $1b;
  LANG_SLOVENIAN                       = $24;
  LANG_SPANISH                         = $0a;
  LANG_SWEDISH                         = $1d;
  LANG_THAI                            = $1e;
  LANG_TURKISH                         = $1f;
  LANG_UKRAINIAN                       = $22;
  LANG_VIETNAMESE                      = $2a;
{$endif}

const
  {$ifdef FPC}
  LANG_NONE = Byte(lngDummy);
  {$endif}
  LANG_MACEDONIAN = $2f;
  LANG_DARI = $8c;
  LANG_PASHTO = $63;
  sPriLang: array[TLanguages] of byte =
   (LANG_HEBREW,LANG_GREEK,0,LANG_DARI,0,LANG_CATALAN,0,LANG_CZECH,0,0,0,
    LANG_DANISH,LANG_GERMAN,LANG_ARABIC,LANG_ENGLISH,LANG_SPANISH,LANG_FARSI,
    LANG_FINNISH,LANG_FRENCH,0,0,0,0,LANG_HUNGARIAN,0,LANG_INDONESIAN,0,
    LANG_ICELANDIC,LANG_ITALIAN,LANG_JAPANESE,LANG_KOREAN,0,LANG_LITHUANIAN,0,
    LANG_NORWEGIAN,0,LANG_PORTUGUESE,LANG_POLISH,LANG_ROMANIAN,LANG_RUSSIAN,0,
    LANG_SLOVAK,LANG_SLOVENIAN,LANG_ALBANIAN,LANG_SERBIAN,LANG_SWEDISH,0,
    LANG_TURKISH,0,LANG_UKRAINIAN,LANG_VIETNAMESE,LANG_CHINESE,LANG_DUTCH,
    LANG_THAI,LANG_BULGARIAN,LANG_BELARUSIAN,LANG_ESTONIAN,LANG_LATVIAN,
    LANG_MACEDONIAN,LANG_PASHTO {$ifdef FPC},LANG_NONE{$endif});

function LanguageToLCID(Language: TLanguages): integer;
begin
  if Language=LANGUAGE_NONE then
    result := LCID_US else
  case sPriLang[Language] of
    LANG_CHINESE: result := $0804; // Chinese (PRC) if not $0404
    else
    result := LANG_USER_DEFAULT or sPriLang[Language]; // Process Default Language ($0400)
  end; // leave Sort order to $0 = default
end;

var LastLCID: integer;
    LastLCIDLanguage: TLanguages = LANGUAGE_NONE;

function LCIDToLanguage(LCID: integer): TLanguages;
// compares sPriLang[] values with sysLocale.PriLangID to set current language
// return LanguageUS if this LCID is not known
var b: byte;
    lng: TLanguages;
begin
  if LCID=LastLCID then begin
    result := LastLCIDLanguage;
    exit;
  end;
  b := LCID and 255;
  case b of
    $1A: // ambigious PriLangID -> get it by full LCID
    case LCID of
      $141a, $201a: result := lngBosnian;
      $041a, $101a: result := lngCroatian;
      else          result := lngSerbian; // by default - don't call UN again
    end; // case SysLocale
  else begin
    result := lngEnglish;
    for lng := low(lng) to high(lng) do
      if b=sPriLang[lng] then begin
        result := lng;
        break;
      end;
  end;
  end;
  LastLCID := LCID;
  LastLCIDLanguage := Result;
end;


function LanguageAbrToIndex(const value: RawUTF8): TLanguages;
// LanguageAbrToIndex('GR')=1
begin
  if length(value)>=2 then
    result := LanguageAbrToIndex(pointer(Value)) else
    result := LANGUAGE_NONE;
end;

function LanguageAbrToIndex(P: PAnsiChar): TLanguages; overload;
var ndx: integer;
begin
  if P=nil then
    ndx := -1 else
    ndx := WordScanIndex(@LanguageAbrWord,Length(LanguageAbrWord),
      NormToLowerByte[ord(P[0])]+NormToLowerByte[ord(P[1])] shl 8);
  if ndx<0 then
    result := LANGUAGE_NONE else
    result := TLanguages(ndx);
end;


procedure PatchCode(Old,New: pointer; Size: integer; Backup: pointer;
  LeaveUnprotected: boolean);
{$ifdef MSWINDOWS}
var RestoreProtection, Ignore: DWORD;
    i: integer;
begin
  if VirtualProtect(Old, Size, PAGE_EXECUTE_READWRITE, RestoreProtection) then
  begin
    if Backup<>nil then
      for i := 0 to Size-1 do  // do not use Move() here
        PByteArray(Backup)^[i] := PByteArray(Old)^[i];
    for i := 0 to Size-1 do    // do not use Move() here
      PByteArray(Old)^[i] := PByteArray(New)^[i];
    if not LeaveUnprotected then
      VirtualProtect(Old, Size, RestoreProtection, Ignore);
    FlushInstructionCache(GetCurrentProcess, Old, Size);
    if not CompareMemFixed(Old,New,Size) then
      raise ESynException.Create('PatchCode?');
  end;
end;
{$else}
var PageSize: PtrUInt;
    AlignedAddr: pointer;
    i: PtrInt;
    ProtectedResult: boolean;
    ProtectedMemory: boolean;
begin
  if Backup<>nil then
    for i := 0 to Size-1 do // do not use Move() here
      PByteArray(Backup)^[i] := PByteArray(Old)^[i];
  PageSize := SystemInfo.dwPageSize;
  AlignedAddr := Pointer((PtrUInt(Old) DIV SystemInfo.dwPageSize) * SystemInfo.dwPageSize);
  while PtrUInt(Old)+PtrUInt(Size)>=PtrUInt(AlignedAddr)+PageSize do
    Inc(PageSize,SystemInfo.dwPageSize);
  ProtectedResult := SynMProtect(AlignedAddr,PageSize,PROT_READ or PROT_WRITE or PROT_EXEC) = 0;
  ProtectedMemory := not ProtectedResult; 
  if ProtectedMemory then
    ProtectedResult := SynMProtect(AlignedAddr,PageSize,PROT_READ or PROT_WRITE) = 0;
  if ProtectedResult then
    try
      for i := 0 to Size-1 do // do not use Move() here
        PByteArray(Old)^[i] := PByteArray(New)^[i];
    if not LeaveUnprotected and ProtectedMemory then
      SynMProtect(AlignedAddr,PageSize,PROT_READ or PROT_EXEC);
    except
    end;
end;
{$endif MSWINDOWS}

procedure PatchCodePtrUInt(Code: PPtrUInt; Value: PtrUInt;
  LeaveUnprotected: boolean);
begin
  PatchCode(Code,@Value,SizeOf(Code^),nil,LeaveUnprotected);
end;

{$ifdef CPUINTEL}

procedure RedirectCode(Func, RedirectFunc: Pointer; Backup: PPatchCode);
var NewJump: packed record
    Code: byte;        // $e9 = jmp {relative}
    Distance: integer; // relative jump is 32-bit even on CPU64
  end;
begin
  if (Func=nil) or (RedirectFunc=nil) then
    exit; // nothing to redirect to
  assert(SizeOf(TPatchCode)=SizeOf(NewJump));
  NewJump.Code := $e9;
  NewJump.Distance := integer(PtrUInt(RedirectFunc)-PtrUInt(Func)-SizeOf(NewJump));
  PatchCode(Func,@NewJump,SizeOf(NewJump),Backup,true);
  {$ifndef LCL}
  assert(pByte(Func)^=$e9);
  {$endif}
end;

procedure RedirectCodeRestore(Func: pointer; const Backup: TPatchCode);
begin
  PatchCode(Func,@Backup,SizeOf(TPatchCode),nil,true);
end;

{$endif CPUINTEL}


const
  // default character set for a specific language (for GUI i18n)
  // list taken from http://www.webheadstart.org/xhtml/encoding
  // see also http://msdn2.microsoft.com/en-us/library/ms776260.aspx
  // DEFAULT_CHARSET is set if not known -> Win32 will take care as default locale
  // ANSI_CHARSET is iso-8859-1, windows-1252
  LanguageCharSet: packed array[TLanguages] of byte // byte-aligned
     = (HEBREW_CHARSET, // 'he' CP1255 iso-8859-8
        GREEK_CHARSET, // 'gr' CP1253 iso-8859-7
        ANSI_CHARSET, // 'la' Latin
        ARABIC_CHARSET, // 'ad' Dari (Afghanistan)
        EASTEUROPE_CHARSET, // 'bs' bosnian CP1250 iso-8859-2
        ANSI_CHARSET, // 'ca' catalan
        ANSI_CHARSET, // 'co' corsican
        EASTEUROPE_CHARSET, // 'cs' czech CP1250 iso-8859-2
        DEFAULT_CHARSET, // 'cp' Coptic is Unicode-UTF8 only
        EASTEUROPE_CHARSET, // 'cu' Slavic
        ANSI_CHARSET, // 'cy' Welsh (gallois)
        ANSI_CHARSET, // 'da' Danish
        ANSI_CHARSET, // 'de' German
        ARABIC_CHARSET, // 'ar' Arabic CP1256, iso-8859-6
        ANSI_CHARSET, // 'en' English (GB+US)
        ANSI_CHARSET, // 'es' Spanish
        ARABIC_CHARSET, // 'fa' Farsi CP1256, iso-8859-6
        ANSI_CHARSET, // 'fi' Finish
        ANSI_CHARSET, // 'fr' French
        ANSI_CHARSET, // 'ga' Irish
        ANSI_CHARSET, // 'gd' Gaelic
        HEBREW_CHARSET, // 'am' Aramaic CP1255, iso-8859-8
        EASTEUROPE_CHARSET, // 'hr' Croatian CP1250 iso-8859-2
        EASTEUROPE_CHARSET, // 'hu' Hungarian CP1250 iso-8859-2
        DEFAULT_CHARSET, // 'hy' Armenian is Unicode-UTF8 only
        ANSI_CHARSET, // 'id' Indonesian
        ANSI_CHARSET, // 'ie' Interlingue
        ANSI_CHARSET, // 'is' Icelandic
        ANSI_CHARSET, // 'it' Italian
        SHIFTJIS_CHARSET, // 'ja' Japanese CP932
        HANGEUL_CHARSET, // 'ko' Korean CP949 (JOHAB is for old Win95+NT4)
        DEFAULT_CHARSET, // 'bo' Tibetan is Unicode-UTF8 only
        BALTIC_CHARSET, // 'lt' Lituanian CP1257, iso-8859-13
        ANSI_CHARSET, // 'mg' Malgash uses latin alphabet
        ANSI_CHARSET, // 'no' Norwegian
        ANSI_CHARSET, // 'oc' Occitan
        ANSI_CHARSET, // 'pt' Portuguese
        EASTEUROPE_CHARSET, // 'pl' Polish CP1250 iso-8859-2
        EASTEUROPE_CHARSET, // 'ro' Romanian CP1250 iso-8859-2
        RUSSIAN_CHARSET, // 'ru' Russian CP1251, iso-8859-5
        DEFAULT_CHARSET, // 'sa' Sanskrit is unicode only
        EASTEUROPE_CHARSET, // 'sk' Slovak CP1250 iso-8859-2
        EASTEUROPE_CHARSET, // 'sl' Slovenian CP1250 iso-8859-2
        ANSI_CHARSET, // 'sq' Albanian
        EASTEUROPE_CHARSET, // 'sr' Serbian - latin alphabet CP1250 iso-8859-2
        ANSI_CHARSET, // 'sv' Swedish
        DEFAULT_CHARSET, // 'sy' Syriac ISO 639-3 is Unicode-UTF8 only
        TURKISH_CHARSET, // 'tr' Turkish iso-8859-9, windows-1254
        ANSI_CHARSET, // 'ty' Tahitian
        RUSSIAN_CHARSET, // 'uk' Ukrainian iso-8859-5 CP1251
        VIETNAMESE_CHARSET, // 'vi' Vietnamese CP1258
        GB2312_CHARSET, // 'zh' Chinese EUC-CN CP936, gb2312.1980-0 = simplified
        ANSI_CHARSET,  // 'nl' Dutch
        THAI_CHARSET, // 'th' Thai CP874 iso-8859-11 tis620
        RUSSIAN_CHARSET, // 'bg' Bulgarian CP1251, iso-8859-5
        RUSSIAN_CHARSET, // 'be' Byelorussian CP1251, iso-8859-5
        BALTIC_CHARSET, // 'et' Estonian CP1257 iso-8859-15
        BALTIC_CHARSET, // 'lv' Latvian CP1257 iso-8859-15
        RUSSIAN_CHARSET, // 'mk' Macedonian CP1251, iso-8859-5
        ARABIC_CHARSET // 'ap' Pashto (Afghanistan)
        {$ifdef FPC}
        ,DEFAULT_CHARSET // dummy - fix {R-}
        {$endif}
     );

{$ifndef ENHANCEDRTL}
// code below is extracted from our Extended System.pas unit, and
// use the generic string type (i.e. UnicodeString for Delphi 2009 and up)
const
  // cache makes it faster, even more when using on the fly translations
  // 512 is a reasonnable value, never reached in practice
  LoadResStringCacheSize = 512;

var  
  CacheResValue: array of string;
  {$ifdef FPC}
  CacheRes: array[0..LoadResStringCacheSize-1] of PMyResStringRec;
  CacheResLast: PMyResStringRec = nil;
  {$else}
  CacheRes: array[0..LoadResStringCacheSize-1] of PResStringRec;
  CacheResLast: PResStringRec = nil;
  {$endif}
  CacheResLastIndex: integer = -1;
  CacheResCriticalSection: TSynLocker;
  LastResModule,
  LastResModuleInst: cardinal;
  BackupLoadResString: TPatchCode;
{$ifndef LCL}
function LoadResString(ResStringRec: PResStringRec): string;
var Buffer: array [0..4095] of Char; // char = use the generic string type
    i: integer;
begin
  if ResStringRec=nil then begin
    result := '';
    Exit;
  end;
  if ResStringRec.Identifier<64*1024 then begin
    if CacheResCount<0 then begin // before initialization or after finalization
      SetString(Result, Buffer, LoadString(FindResourceHInstance(ResStringRec.Module^),
          ResStringRec.Identifier, Buffer, SizeOf(Buffer))); // direct API call
      exit;
    end;
    //EnterCriticalSection(CacheResCriticalSection); // thread-safe and mostly fast
    CacheResCriticalSection.Lock;
    if (ResStringRec=CacheResLast) and
       (CacheRes[CacheResLastIndex].Identifier=ResStringRec.Identifier) and
       (pointer(CacheResValue)<>nil) then begin
      result := CacheResValue[CacheResLastIndex];    // smart cache of values
      //LeaveCriticalSection(CacheResCriticalSection); // manual try..finally = faster
      CacheResCriticalSection.UnLock;
      exit;
    end;
    i := PtrUIntScanIndex(@CacheRes,CacheResCount,PtrUInt(ResStringRec));
    if i>=0 then
    repeat
      if (CacheRes[i].Identifier=ResStringRec.Identifier) and
         (pointer(CacheResValue)<>nil) then begin
        CacheResLast := ResStringRec;
        CacheResLastIndex := i;
        result := CacheResValue[i]; // smart cache of values
        CacheResCriticalSection.UnLock;
        exit;
      end;
      inc(i); // wrong module -> continue search of this Identifier
      if i>=CacheResCount then break;
      i := PtrUIntScanIndex(@CacheRes[i],(CacheResCount-i),PtrUInt(ResStringRec));
    until i<0;
    if ResStringRec.Module^<>LastResModule then begin
      LastResModule := ResStringRec.Module^;
      LastResModuleInst := FindResourceHInstance(ResStringRec.Module^);
    end;
    SetString(Result, Buffer,
      LoadString(LastResModuleInst, ResStringRec.Identifier, Buffer, SizeOf(Buffer)));
    if Assigned(LoadResStringTranslate) then
      LoadResStringTranslate(Result);
    if CacheResCount<LoadResStringCacheSize then begin
      if pointer(CacheResValue)=nil then
        SetLength(CacheResValue,LoadResStringCacheSize);
      CacheResValue[CacheResCount] := Result;
      CacheRes[CacheResCount] := ResStringRec;
      CacheResLast := ResStringRec;
      CacheResLastIndex := CacheResCount;
      inc(CacheResCount);
    end;
    CacheResCriticalSection.UnLock;
  end else begin
    Result := PChar(ResStringRec.Identifier);
    if Assigned(LoadResStringTranslate) then
      LoadResStringTranslate(Result);
  end;
end;
{$else}
function FindResourceHInstance(Module: HMODULE): TFPResourceHandle;
begin
  Result := HInstance;
end;

function PtrUIntScanIndex(P: PPointerArray; Count: PtrUInt; Value: PtrUInt): PtrInt;
begin
  for Result := 0 to Count - 1 do
    if PtrUInt(P^[Result]) = Value then
      Exit;
  Result := -1;
end;

function LoadStringFromResource(Module: TFPResourceHandle; ResID: Integer; Buffer: PChar; BufferSize: Integer): Integer;
var
  ResStream: TResourceStream;
  ResName: string;
begin
  Result := 0;
  ResName := IntToStr(ResID);
  try
    ResStream := TResourceStream.Create(Module, ResName, RT_RCDATA);
    try
      Result := ResStream.Read(Buffer^, BufferSize);
    finally
      ResStream.Free;
    end;
  except
    on E: Exception do
      Result := 0; // Handle resource not found or read errors
  end;
end;

function LoadResString(ResStringRec: PMyResStringRec): string;
var
  Buffer: array[0..4095] of Char;
  i: integer;
begin
  if ResStringRec = nil then
  begin
    Result := '';
    Exit;
  end;

  if ResStringRec^.Identifier < 64 * 1024 then
  begin
    if CacheResCount < 0 then
    begin
      // Before initialization or after finalization
      SetString(Result, Buffer, LoadStringFromResource(FindResourceHInstance(ResStringRec^.Module^), ResStringRec^.Identifier, Buffer, SizeOf(Buffer)));
      Exit;
    end;

    CacheResCriticalSection.Lock;
    try
      if (ResStringRec = CacheResLast) and
         (CacheRes[CacheResLastIndex]^.Identifier = ResStringRec^.Identifier) and
         (Pointer(CacheResValue) <> nil) then
      begin
        Result := CacheResValue[CacheResLastIndex];
        Exit;
      end;

      i := PtrUIntScanIndex(@CacheRes, CacheResCount, PtrUInt(ResStringRec));
      if i >= 0 then
      repeat
        if (CacheRes[i]^.Identifier = ResStringRec^.Identifier) and
           (Pointer(CacheResValue) <> nil) then
        begin
          CacheResLast := ResStringRec;
          CacheResLastIndex := i;
          Result := CacheResValue[i];
          Exit;
        end;
        Inc(i); // Wrong module -> continue search of this Identifier
        if i >= CacheResCount then Break;
        i := PtrUIntScanIndex(@CacheRes[i], (CacheResCount - i), PtrUInt(ResStringRec));
      until i < 0;

      if ResStringRec^.Module^ <> LastResModule then
      begin
        LastResModule := ResStringRec^.Module^;
      end;

      SetString(Result, Buffer, LoadStringFromResource(FindResourceHInstance(ResStringRec^.Module^), ResStringRec^.Identifier, Buffer, SizeOf(Buffer)));
      if Assigned(LoadResStringTranslate) then
        LoadResStringTranslate(Result);

      if CacheResCount < LoadResStringCacheSize then
      begin
        if Pointer(CacheResValue) = nil then
          SetLength(CacheResValue, LoadResStringCacheSize);
        CacheResValue[CacheResCount] := Result;
        CacheRes[CacheResCount] := ResStringRec;
        CacheResLast := ResStringRec;
        CacheResLastIndex := CacheResCount;
        Inc(CacheResCount);
      end;
    finally
      CacheResCriticalSection.Unlock;
    end;
  end
  else
  begin
    Result := PChar(ResStringRec^.Identifier);
    if Assigned(LoadResStringTranslate) then
      LoadResStringTranslate(Result);
  end;
end;
{$endif ENHANCEDRTL}
{$endif LCL}

{$ifdef USEFORMCREATEHOOK}
type
  THookedForm = class(TCustomForm)
    procedure HookedDoCreate;
  end;

  THookedFrame = class(TCustomFrame)
    constructor Create(AOwner: TComponent); override;
  end;

var
  OriginalForm, OriginalFrame: TPatchCode;

procedure PatchCreate;
begin
  if OriginalForm[0]<>0 then
    exit; // patch once
  RedirectCode(@THookedForm.DoCreate,@THookedForm.HookedDoCreate,@OriginalForm);
  RedirectCode(@THookedFrame.Create,@THookedFrame.Create,@OriginalFrame);
end;


// hook logic was inspired from GetText()

{ THookedForm }

procedure THookedForm.HookedDoCreate;
// translate form contents just before an OnCreate handler would be called
begin
  try
  try
    if Language<>nil then begin
      DisableAlign;
      //DisableAutoRange;
      try
        Language.FormTranslateOne(self); // translate form
      finally
        EnableAlign;
        //EnableAutoRange;
      end;
    end;
  finally
    RedirectCodeRestore(@THookedForm.DoCreate,OriginalForm); // disable Hook
    try
      DoCreate;  // call normal DoCreate event
    finally
      RedirectCode(@THookedForm.DoCreate,@THookedForm.HookedDoCreate);
    end;
  end;
  except
    on Exception do; // ignore all raised exception
  end;
end;

{ THookedFrame }

constructor THookedFrame.Create(AOwner: TComponent);
// translate frame contents just after constructor has been called
begin
  RedirectCodeRestore(@THookedFrame.Create,OriginalFrame); // disable Hook
  try
    inherited Create(AOwner); // call normal constructor
  finally
    RedirectCode(@THookedFrame.Create,@THookedFrame.Create);
  end;
  if Language=nil then exit;
  DisableAlign;
  //DisableAutoRange;
  try
    Language.FormTranslateOne(self); // translate frame
  finally
    EnableAlign;
    //EnableAutoRange;
  end;
end;

{$endif USEFORMCREATEHOOK}

{$ifdef PUREPASCAL}

function i18nInnerCompareStr(const S1, S2: AnsiString): Integer;
var Str1, Str2: PByte;
begin
  Str1 := pointer(S1);
  Str2 := pointer(S2);
  if Str1<>Str2 then
  if Str1<>nil then
  if Str2<>nil then begin
    if Str1^=Str2^ then
    repeat
      if (Str1^=0) or (Str2^=0) then break;
      inc(Str1);
      inc(Str2);
    until Str1^<>Str2^;
    result := Str1^-Str2^;
  end else
  result := 1 else  // Str2=''
  result := -1 else // Str1=''
  result := 0;      // Str1=Str2
end;

function i18nInnerCompareText(const S1, S2: AnsiString): Integer;
var Str1, Str2: PByte;
    C1, C2: byte;
    table: {$ifdef CPUX86NOTPIC}TNormTableByte absolute i18nToUpperByte{$else}PNormTableByte{$endif};
begin
  Str1 := pointer(S1);
  Str2 := pointer(S2);
  if Str1<>Str2 then
  if Str1<>nil then
  if Str2<>nil then begin
    {$ifndef CPUX86NOTPIC}table := @i18nToUpperByte;{$endif}
    repeat
      C1 := table[Str1^];
      C2 := table[Str2^];
      if (C1<>C2) or (C1=0) then
        break;
      Inc(Str1);
      Inc(Str2);
    until false;
    Result := C1-C2;
  end else
  result := 1 else  // Str2=''
  result := -1 else // Str1=''
  result := 0;      // Str1=Str2
end;

{$else PUREPASCAL}

{$ifndef ENHANCEDRTL}
function i18nInnerCompareStr(const S1, S2: AnsiString): Integer;
  {$ifdef FPC} nostackframe; assembler; {$endif}
// original name: CompareStr_PLR_IA32_14
asm
  cmp eax, edx
  je @SameString
  test eax, edx // Is either of the strings perhaps nil?
  jz @PossibleNilString
  { Compare the first four characters (there has to be a trailing #0). In random
    AnsiString compares (quicksort, e.g.) this can save a lot of CPU time. }
@BothNonNil: // Compare the first character
  mov ecx, [edx]
  cmp cl, [eax]
  je @FirstCharacterSame
  movzx eax, byte ptr [eax]   // First character differs
  movzx ecx, cl
  sub eax, ecx
  ret
  nop
@FirstCharacterSame:
  push ebx
  mov ebx, [eax]   // Get first four characters
  cmp ebx, ecx
  je @FirstFourSame
  mov eax, [eax - 4]   // Get the AnsiString lengths in eax and edx
  mov edx, [edx - 4]
  cmp ch, bh   // Is the second character the same?
  je @FirstTwoCharactersMatch
  test eax, eax   // Second character differs: Are any of the strings non-nil but zero length?
  jz @ReturnLengthDifference
  test edx, edx
  jz @ReturnLengthDifference
  movzx eax, bh
  movzx edx, ch
@ReturnLengthDifference:
  sub eax, edx
  pop ebx
  ret
@FirstTwoCharactersMatch:
  cmp eax, 2
  jna @ReturnLengthDifference
  cmp edx, 2
  jna @ReturnLengthDifference
  mov eax, ebx   // Swap the bytes into the correct order
  bswap eax
  bswap ecx
  sub eax, ecx
  pop ebx
  ret
@SameString:
  xor eax, eax
  ret
@PossibleNilString:   // Good possibility that at least one of the strings are nil
  test eax, eax
  jz @FirstStringNil
  test edx, edx
  jnz @BothNonNil
  mov eax, [eax - 4]  // Return first AnsiString length: second AnsiString is nil
  ret
@FirstStringNil: // Return 0 - length(S2): first AnsiString is nil
  sub eax, [edx - 4]
  ret
  nop; nop
@FirstFourSame:   // The first four characters are identical
  mov ebx, [eax - 4]   // set ebx = length(S1)
  xor ecx, ecx
  sub ebx, [edx - 4]   // set ebx = length(S1) - length(S2)
  push ebx       // Save the length difference on the stack
  adc ecx, -1    // set esi = 0 if length(S1) < length(S2), $ffffffff otherwise
  and ecx, ebx   // set esi = - min(length(s1), length(s2))
  sub ecx, [eax - 4] // Adjust the pointers to be negative based
  sub eax, ecx
  sub edx, ecx
  nop; nop; nop
@CompareLoop:
  add ecx, 4
  jns @MatchUpToLength
  mov ebx, [eax + ecx]
  xor ebx, [edx + ecx]
  jz @CompareLoop
@Mismatch:
  bsf ebx, ebx
  shr ebx, 3
  add ecx, ebx
  jns @MatchUpToLength
  movzx eax, byte ptr [eax + ecx]
  movzx edx, byte ptr [edx + ecx]
  sub eax, edx
  pop ebx
  pop ebx
  ret
@MatchUpToLength:   // All characters match - return the difference in length
  pop eax
  pop ebx
end;

{$endif}

function i18nInnerCompareText(const S1, S2: AnsiString): Integer;
  {$ifdef FPC} nostackframe; assembler; {$endif}
asm // fast CompareText() version using i18nToUpper[] instead of NormToUpper[]
    cmp eax,edx
    je @2
    test eax,edx // Is either of the strings perhaps nil?
    jz @3
@0: push ebx // Compare the first character (faster quicksort)
    movzx ebx,byte ptr [eax] // ebx=S1[1]
    movzx ecx,byte ptr [edx] // ecx=S2[1]
    cmp ebx,ecx
    je @1
    mov bl,byte ptr [i18nToUpper+ebx]
    mov cl,byte ptr [i18nToUpper+ecx]
    cmp ebx,ecx
    je @1
    mov eax,ebx
    pop ebx
    sub eax,ecx // return S1[1]-S2[1]
    ret
@2: xor eax, eax
    ret
@3: test eax,eax
    jz @4
    test edx,edx
    jnz @0
    mov eax,[eax-4] // Return length(S1): second AnsiString is nil
    ret
@4: sub eax,[edx-4] // Return 0 - length(S2): first AnsiString is nil
    ret
@1: // here, the first character was the same: test the others
    push edx
    push eax // save S1 and S2 for returning length(S1)-length(S2)
@s: inc eax
    inc edx
    mov bl,[eax] // ebx=S1[i]
    mov cl,[edx] // ecx=S2[i]
    or ebx,ebx
    je @z        // end of S1
    cmp ebx,ecx
    je @s
    mov bl,byte ptr [i18nToUpper+ebx]
    mov cl,byte ptr [i18nToUpper+ecx]
    cmp ebx,ecx
    je @s
    mov eax,ebx
    pop ebx
    pop ebx // ignore S1+S2 on stack
    pop ebx
    sub eax,ecx // return S1[i]-S2[i]
    ret
@z: pop eax
    mov eax,[eax-4]
    pop edx
    mov edx,[edx-4]
    pop ebx
    sub eax,edx // return length(S1)-length(S2)
end;

{$endif PUREPASCAL}

function Win32CompareStr(const S1, S2: AnsiString): Integer;
// AnsiCompareStr() replacement using CurrentLanguage.LCID
// (used for Arabic, Japan, Chinese and Korean)
begin
  Result := CompareStringA(CurrentLanguage.LCID, 0, PAnsiChar(pointer(S1)), Length(S1),
    PAnsiChar(pointer(S2)), Length(S2)) - 2;
end;

function Win32CompareText(const S1, S2: AnsiString): Integer;
// AnsiCompareText() replacement using CurrentLanguage.LCID
// (used for Arabic, Japan, Chinese and Korean)
begin
  Result := CompareStringA(CurrentLanguage.LCID, NORM_IGNORECASE, PAnsiChar(pointer(S1)),
    Length(S1), PAnsiChar(pointer(S2)), Length(S2)) - 2;
end;

function LanguageName(aLanguage: TLanguages): string;
begin
  if aLanguage=LANGUAGE_NONE then
    result := '' else
    result := PRttiInfo(TypeInfo(TLanguages))^.EnumBaseType^.GetCaption(aLanguage);
end;

{$ifndef NOI18N}
procedure SetCurrentLanguage(aLanguage: TLanguages; aForceEnglishIfNoMsgFile: boolean); overload;
{$ifndef USEFORMCREATEHOOK}
var i: integer;
    Already: TCustomFormDynArray; // to re-translate all forms
{$endif USEFORMCREATEHOOK}
var c: AnsiChar;
    LanguageForLanguageFile: TLanguages;
begin
  // 1. not already set to this value?
  if CurrentLanguage.Index=aLanguage then
    exit;
// default CurrentLanguage.Index=LANGUAGE_NONE -> force updated english locale if necessary
{$ifdef USEFORMCREATEHOOK}
  if CurrentLanguage.Index<>LANGUAGE_NONE then
    raise Exception.Create('lang unit: language must be set only once');
{$endif USEFORMCREATEHOOK}

  // 2. handle missing .msg file
  LanguageForLanguageFile := aLanguage;
  if LanguageForLanguageFile<>lngEnglish then
    if not FileExists(TLanguageFile.FileName(LanguageForLanguageFile)) then begin
      if aForceEnglishIfNoMsgFile then
        if CurrentLanguage.Index=lngEnglish then
          exit else
          aLanguage := lngEnglish;
      LanguageForLanguageFile := lngEnglish; // no .msg -> no translation
    end;

  // 3. reset all Locale settings + AnsiCompare*() functions
  with CurrentLanguage do begin
    Fill(aLanguage); // init all CurrentLanguage fields for this language
//{$ifndef LCL}
    if GetThreadLocale<>LCID then // force locale settings if different
      if SetThreadLocale(LCID) then
        GetFormatSettings; // resets all locale-specific variables
{$ifdef UNICODE}
    SetMultiByteConversionCodePage(CodePage); // for default AnsiString handling
{$endif}
//{$endif}
    CurrentAnsiConvert := TSynAnsiConvert.Engine(CodePage); // redefine from GetACP
    for c := #0 to #255 do begin
      i18nToUpper[c] := c;
      i18nToLower[c] := c;
    end;
    CharUpperBuffA(i18nToUpper,256); // get values from current user locale
    CharLowerBuffA(i18nToLower,256);
    if not((CharSet in [GB2312_CHARSET,SHIFTJIS_CHARSET,HANGEUL_CHARSET,ARABIC_CHARSET])
        or SysLocale.FarEast) and
      (LanguageCharSet[LCIDToLanguage(GetUserDefaultLCID)]=CharSet) then begin
      // NormToUpper/Lower[] was filled with LOCALE_USER_DEFAULT values
      // -> OK if same CHARSET, and not multi-byte
      i18nCompareStr := // not MBCS strict comparison is always valid
        {$ifdef ENHANCEDRTL}CompareStr{$else}i18nInnerCompareStr{$endif};
      // CompareText in SysUtils.pas uses NormToUpper[], this uses i18nToUpper[]:
      i18nCompareText := i18nInnerCompareText;
    end else begin
      // AnsiCompareStr/Text() replacements using CurrentLanguage.LCID
      i18nCompareStr := Win32CompareStr; // calls Win32 API for MBCS
      i18nCompareText := Win32CompareText;
    end;
    // AnsiUpper/LowerCase use CharUpper/LowerBuff() = NormToUpper/Lower[] values
  end;

  // 4. create Language object from exe directory if not english
{$ifdef USEFORMCREATEHOOK}
  FreeAndNil(Language);
  if LanguageForLanguageFile<>lngEnglish then
    Language := TLanguageFile.Create(LanguageForLanguageFile);
{$else}
  if Language<>nil then begin // save AlreadyTranslated[] forms for translation
    Already := Language.AlreadyTranslated;
    FreeAndNil(Language);
  end;
  if LanguageForLanguageFile<>lngEnglish then
    Language := TLanguageFile.Create(LanguageForLanguageFile);
  for i := 0 to high(Already) do // translate available forms again
  try
    Language.FormTranslateOne(Already[i]);
  except // ignore any exception -> form.Free -> acces violation e.g.
    on Exception do;
  end;
{$endif USEFORMCREATEHOOK}
  // we use our custom system.pas unit, which contains already resourcestring caching
  // (we don't have to use critical section here, since call is thread safe)
{$ifndef LCL}
  LoadResStringTranslate := GetText; // just set translation function
  CacheResCount := 0; // flush LoadResString() cache
{$endif}
end;

procedure SetCurrentLanguage(const value: RawUTF8; aForceEnglishIfNoMsgFile: boolean); overload;
begin
  SetCurrentLanguage(LanguageAbrToIndex(value),aForceEnglishIfNoMsgFile);
end;

{$ifdef USEFORMCREATEHOOK}

function i18nAddLanguageItems(MsgPath: TFileName; List: TStrings): integer;
var SR: TSearchRec;
    lng, index: TLanguages;
    Exists: set of TLanguages;
begin
  if MsgPath='' then
    MsgPath := Executable.ProgramFilePath;
  result := -1; // no language selection if no language available
  fillchar(Exists,sizeof(Exists),0);
  include(Exists,lngEnglish); // English is always present (default built in EXE)
  if FindFirst(MsgPath+'*.msg', faAnyFile, SR)<>0 then
    exit;
  repeat
    lng := LanguageAbrToIndex(
      {$ifdef UNICODE}RawUTF8(SR.Name){$else}pointer(SR.Name){$endif});
    if lng<>LANGUAGE_NONE then
      include(Exists,lng);
  until FindNext(SR)<>0;
  FindClose(SR);
  for lng := low(lng) to high(lng) do begin
    index := TLanguages(LanguageAlpha[lng]); // add languages by LanguageAbr[] alpha order
    if not (index in Exists) then
      continue;
    if index=CurrentLanguage.Index then
      result := List.Count; // current language selection
    List.AddObject(FormatString('% (%)',[LanguageName(index),LanguageAbr[index]]),
      pointer(index));
  end;
end;

procedure i18nAddLanguageCombo(const MsgPath: TFileName; Combo: TComboBox);
var i, index: integer;
    List: TStringList;
begin
  List := TStringList.Create;
  try
    index := i18nAddLanguageItems(MsgPath,List);
    Combo.Items.BeginUpdate;
    Combo.Clear;
    for i := 0 to List.Count-1 do
      Combo.AddItem(List[i],List.Objects[i]);
    Combo.ItemIndex := index;
    Combo.Items.EndUpdate;
    Combo.OnClick := Language.LanguageClick;
  finally
    List.Free;
  end;
end;

procedure i18nAddLanguageMenu(const MsgPath: TFileName; Menu: TMenuItem);
var i, index: integer;
    MenuItem: TMenuItem;
    List: TStringList;
begin
  List := TStringList.Create;
  try
    index := i18nAddLanguageItems(MsgPath,List);
    for i := 0 to List.Count-1 do begin
      MenuItem := TMenuItem.Create(Menu.Owner);
      MenuItem.Caption := List[i];
      MenuItem.Tag := PtrInt(List.Objects[i]);
      MenuItem.OnClick := Language.LanguageClick;
      if i=index then
        MenuItem.Checked := true; // mark current language selection
      Menu.Add(MenuItem);
    end;
  finally
    List.Free;
  end;
  Menu.Visible := true;
end;

function ReadRegString(Key: HKEY; const Path, Value: string): string;
// this version is UNICODE ready, and will call appropriate *W() or *A() Win32API
var l, t: DWORD;
    z: array[byte] of char;
    k: HKey;
begin
  Result := '';
  if RegOpenKeyEx(Key, pointer(Path), 0, KEY_QUERY_VALUE, k)=ERROR_SUCCESS then
  try
    l := sizeof(z);
    t := REG_SZ;
    if RegQueryValueEx(K, pointer(Value), nil, @t, @z, @l)=ERROR_SUCCESS then
      Result := z;
  finally
    RegCloseKey(k);
  end;
end;

function CreateRegKey(RootKey: HKEY; const Key, ValueName, Value: string): boolean;
// this version is UNICODE ready, and will call appropriate *W() or *A() Win32API
var Handle: HKey;
    Disposition: Integer;
begin
  Result := RegCreateKeyEx(RootKey, pointer(Key), 0, '',
    REG_OPTION_NON_VOLATILE, KEY_READ or KEY_WRITE, nil, Handle,
    @Disposition)=0;
  if Result then begin
    Result := RegSetValueEx(Handle, pointer(ValueName), 0, REG_SZ,
      pointer(Value), (Length(Value)+1)*sizeof(char))=0;
    RegCloseKey(Handle);
  end;
end;


function i18nLanguageToRegistry(const Language: TLanguages): string;
// write to HKEY_CURRENT_USER\Software\[CompanyName]i18n\paramstr(0)
begin
  result := '';
  if Language=LANGUAGE_NONE then
    exit;
  CreateRegKey(HKEY_CURRENT_USER,'Software\'+RegistryCompanyName+'i18n',
    SysUtils.lowercase(ExtractFileName(paramstr(0))),string(LanguageAbr[Language]));
  result := SHaveToRestart;  // show it in english + current language
  if CurrentLanguage.Index<>lngEnglish then
    result := 'You have to restart the application to apply these language changes.'#13#10+
      result;
end;

function i18nRegistryToLanguage: TLanguages;
// read from HKEY_CURRENT_USER\Software\[CompanyName]i18n\paramstr(0)
begin
  result := LanguageAbrToIndex(RawUTF8(ReadRegString(HKEY_CURRENT_USER,
    'Software\'+RegistryCompanyName+'i18n',
    SysUtils.lowercase(ExtractFileName(paramstr(0))))));
end;
{$endif}

procedure LangInit;
// do redirection + init user default locale (from Win32 or registry)
var i: TLanguages;
    hKernel32: HMODULE;
begin
  // LanguageAbrInteger[]: to use fast IntegerScanIndex() in LanguageAbrToIndex()
  for i := low(i) to high(i) do
    LanguageAbrWord[i] := PWord(pointer(LanguageAbr[i]))^;
  assert(LanguageAbrToIndex('En')=lngEnglish);
  assert(LanguageAbrToIndex('fR')=lngFrench);
  assert(LanguageAbrToIndex('xx')=LANGUAGE_NONE);
{$ifndef EXTRACTALLRESOURCES}
{$ifdef USEFORMCREATEHOOK}
  // get language from registry, if USEFORMCREATEHOOK
  i := i18nRegistryToLanguage; // from \Software\CompanyName\i18n\paramstr(0)
  // i := LanguageAbrToIndex('FR'); // DEBUG: load FR.MSG
  if i<>LANGUAGE_NONE then
    SetCurrentLanguage(i,false) else
{$endif}
{$endif}
//{$ifndef LCL} // LCL doesn't have any SysLocale defined
    SetCurrentLanguage(LCIDToLanguage(SysLocale.DefaultLCID),false);
//{$endif}
  // LCID_US = $0409 US English = international settings
  hKernel32 := GetModuleHandle('kernel32');
  if (hKernel32 > 0) then
    isVista := GetProcAddress(hKernel32, 'GetLocaleInfoEx')<>nil;
{$ifdef USEFORMCREATEHOOK}
  if Language<>nil then
    PatchCreate; // only patch TForm and TFrame if not english
{$endif USEFORMCREATEHOOK}
end;
{$endif}


{ TLanguageFile }

constructor TLanguageFile.Create(aLanguageLocale: TLanguages);
// FR.msg, DE.msg, JP.msg files must be in the .exe directory
begin
  Create(FileName(aLanguageLocale),aLanguageLocale);
end;

constructor TLanguageFile.Create(const aFileName: TFileName; aLanguageLocale: TLanguages);
begin
  Language.Fill(aLanguageLocale);
  CurrentAnsiConvert := TSynAnsiConvert.Engine(Language.CodePage);
  LoadFromFile(aFileName);
end;

destructor TLanguageFile.Destroy;
begin
  FreeAndNil(Messages);
  inherited;
end;

class function TLanguageFile.FileName(aLanguageLocale: TLanguages): TFileName;
begin
  if aLanguageLocale<>LANGUAGE_NONE then
    result :=  Executable.ProgramFilePath+
      Ansi7ToString(LanguageAbr[aLanguageLocale])+'.msg' else
    result := '';
end;

{$ifndef USEFORMCREATEHOOK}
procedure TLanguageFile.FormTranslate(Forms: array of TCustomForm);
var f: integer;
begin
  SetLength(AlreadyTranslated,length(Forms));
  for f := 0 to high(Forms) do begin
    AlreadyTranslated[f] := Forms[f];
    FormTranslateOne(Forms[f]);
  end;
end;
{$endif USEFORMCREATEHOOK}


{$ifdef UNICODE}
function GetNextLineW(source: PWideChar; out next: PWideChar): string;
begin
  next := source;
  if source=nil then begin
    result := '';
    exit;
  end;
  while not (cardinal(source^) in [0,10,13]) do inc(source);
  SetString(result,PChar(next),source-next);
  if source^=#13 then inc(source);
  if source^=#10 then inc(source);
  if source^=#0 then
    next := nil else
    next := source;
end;

function FindIniNameValueW(P: PWideChar; UpperName: PUTF8Char): string;
var PBeg: PWideChar;
    L: PtrInt;
begin
  while (P<>nil) and (P^<>'[') do begin
    PBeg := P;
    while not (cardinal(P^) in [0,10,13]) do inc(P);
    while cardinal(P^) in [10,13] do inc(P);
    if P^=#0 then P := nil;
    if PBeg^=' ' then repeat inc(PBeg) until PBeg^<>' ';   // trim left ' '
    if IdemPCharW(PBeg,UpperName) then begin
      inc(PBeg,StrLen(UpperName));
      L := 0; while PBeg[L]>=' ' do inc(L); // get line length
      SetString(result,PBeg,L);
      exit;
    end;
  end;
  result := '';
end;

function FindIniEntryW(const Content: string; const Section, Name: RawUTF8): string;
var P: PWideChar;
    UpperSection, UpperName: array[byte] of AnsiChar;
    // possible GPF if length(Section/Name)>255, but should const in code
begin
  result := '';
  P := pointer(Content);
  if P=nil then exit;
  // UpperName := UpperCase(Name)+'=';
  PWord(UpperCopy255(UpperName,Name))^ := ord('=');
  if Section='' then
     // find the Name= entry before any [Section]
    result := FindIniNameValueW(P,UpperName) else begin
     // find the Name= entry in the specified [Section]
    PWord(UpperCopy255(UpperSection,Section))^ := ord(']');
    if FindSectionFirstLineW(P,UpperSection) then
      result := FindIniNameValueW(P,UpperName);
  end;
end;
{$endif UNICODE}  

procedure TLanguageFile.FormTranslateOne(aForm: TComponent);
//{$ifndef LCL}
var DefCharSet: integer;
//{$endif}
{$ifdef UNICODE} // beginning of the [aForm.Name] section in Text
var Section: PWideChar; {$else}
var Section: PUTF8Char; {$endif}

  procedure DoAll(Comp: TComponent; const ParentName: RawUTF8);

    function ReadString(const CompName, Name: RawUTF8): string;
    var UpperName: array[byte] of AnsiChar;
    begin
      if Section=nil then // no [aForm.Name] available -> translate from Hash
        result := '' else begin
        PWord(UpperCopy(UpperCopy(UpperName,CompName),Name))^ := ord('=');
    {$ifdef UNICODE}
        result := FindIniNameValueW(pointer(Section),UpperName); {$else}
        result := FindIniNameValue(Section,UpperName);
    {$endif}
      end;
    end;
    function TranslateOne(const CompName, PropName: RawUTF8): string;
    var i: integer;
    begin
      result := ReadString(CompName,PropName);
      if result='' then
        exit;
      if result[1]='_' then // btnOK.Caption=_78124567 -> from messages: 78124567=OK
    {$ifdef UNICODE}
        result := FindMessage(GetCardinalW(@result[2])) else
      if result[1]='%' then begin // from another [FormName] translation
        i := pos('.',result); // DocEdit.Caption=%MainForm.MenuEditor.Caption
        result := FindIniEntryW(Text,RawUTF8(copy(result,2,i-2)),
          RawUTF8(copy(result,i+1,maxInt)));
      end;
    {$else}
        result := FindMessage(GetCardinal(@result[2])) else
      if result[1]='%' then begin // from another [FormName] translation
        i := pos('.',result); // DocEdit.Caption=%MainForm.MenuEditor.Caption
        result := FindWinAnsiIniEntry(Text,copy(result,2,i-2),copy(result,i+1,maxInt));
      end;
    {$endif}
    end;
    procedure TranslateOneProp(ppi: {PPropInfo}PRttiProp; comp: TPersistent; const CompName: RawUTF8);
    var old: string;
        text: string;
        h:cardinal;
    begin
      //old := ppi^.GetGenericStringValue(comp);
      //.TypeInfo^.Name^;
      old := ppi^.GetValueText(comp); //.NameUtf8;
      if old='' then exit;
      if Section<>nil then
        text := TranslateOne(CompName,ppi^.NameUtf8);
      if text='' then // if not defined in [aForm.Name] section -> direct translate
      begin
        h := Hash32(
        // resourcestring are expected to be in English, that is WinAnsi encoded
        {$ifdef UNICODE}UnicodeStringToWinAnsi{$endif}(old));
        text := FindMessage(Hash32(
        // resourcestring are expected to be in English, that is WinAnsi encoded
        {$ifdef UNICODE}UnicodeStringToWinAnsi{$endif}(old)));
      end;
      if (text<>'') and (old<>text) then
        //ppi^.SetGenericStringValue(comp,text);
        ppi^.SetValueText(comp, text);
    end;
    procedure TranslateObj(O: TPersistent; const CName: RawUTF8);
    var j,k: integer;
        Obj: TObject;
        P: {PPropInfo}PRttiProp;
        CL: TClass;
        s: string;
      {$ifndef LCL} // doesn't allow to change Font during the run
      procedure DoFont(Font: TFont);
      var s: string;
          CharSet: integer;
          siz: integer;
      begin
        s := ReadString(CName,'Font.Name');
        if s<>'' then
          Font.Name := s;
        siz := {$ifdef UNICODE}GetCardinalW{$else}GetCardinal{$endif}
          (pointer(ReadString(CName,'Font.Size')));
        if siz<>0 then
          Font.size := siz;
        s := ReadString(CName,'Font.Charset');
        if s<>'' then // Font.Charset=ANSI_CHARSET to force a charset
          if IdentToCharset(s,Charset) then begin
            Font.Charset := CharSet;
            exit;
          end;
        CharSet := Font.Charset;
        if (CharSet=DEFAULT_CHARSET) and (Language.CharSet<>DEFAULT_CHARSET) then
          CharSet := DefCharSet; // calc real CharSet: don't change good DEFAULT_CHARSET
        if CharSet<>Language.CharSet then
          Font.Charset := Language.CharSet;
      end;
      {$endif}
    begin
      CL := PPointer(O)^;
      while (CL<>nil) and (CL<>TComponent) and (CL<>TObject) do begin
        for k := 1 to {InternalClassPropInfo}GetRttiProp(CL,P) do begin
          // standard properties
          if (P^.NameUtf8='Caption') or (P^.NameUtf8='Hint') or
             (P^.NameUtf8='Title') or (P^.NameUtf8='DisplayLabel') then
            TranslateOneProp(P,O,CName) else
          // class properties
          if P^.TypeInfo^.Kind=rkClass then begin
            Obj := P^.GetObjProp(O);
            if Obj<>nil then
    {$ifndef LCL} // doesn't allow to change Font during the run
            if Obj.InheritsFrom(TFont) then
              // TFont
              DoFont(TFont(Obj)) else
    {$endif}if Obj.InheritsFrom(TStrings) then
              if P^.NameUtf8='Lines' then begin
                // TMemo, TRichEdit
                s := TranslateOne(CName,'Lines.Text');
                if s='' then
                  s := FindMessage(Hash32(
                  // resourcestring are expected to be in English, that is WinAnsi encoded
                  {$ifdef UNICODE}UnicodeStringToWinAnsi{$endif}(TStrings(Obj).Text)));
                if s<>'' then
                  TStrings(Obj).Text := s;
              end else
              // TListBox, TComboBox, TRadioGroup
              for j := 0 to TStrings(Obj).Count-1 do begin
                s := TranslateOne(CName,ShortStringToUTF8(P^.NameUtf8)+'['+Int32ToUtf8(j)+']');
                if s='' then
                  s := FindMessage(Hash32(
                  // resourcestring are expected to be in English, that is WinAnsi encoded
                  {$ifdef UNICODE}UnicodeStringToWinAnsi{$endif}(TStrings(Obj).Strings[j])));
                if s<>'' then
                  TStrings(Obj).Strings[j] := s;
              end else
    //{$ifndef LCL} // LCL doesn't have any TCollection
            // TCollection descendents
            if Obj.InheritsFrom(TCollection) then
            with TCollection(Obj) do begin
              for j := 0 to Count-1 do
                TranslateObj(Items[j],CName+ShortStringToUTF8(P^.NameUtf8)+'['+Int32ToUtf8(j)+'].');
            end else
    //{$endif}// TComponent descendents
            if Obj.InheritsFrom(TComponent) then
              DoAll(TComponent(Obj),CName+ShortStringToUTF8(P^.NameUtf8)+'.');
          end;
          P := P^.Next;
        end;
        CL := GetClassParent(CL); // translate parent published properties
      end;
    end;

  var i: integer;
      C: TComponent;
  begin
    if Comp=nil then
      exit;

    // TForm: not done in the following loop
    if ParentName='' then
      TranslateObj(Comp,'');  // Caption,Hint and all

    // all components of this Form / Component collection
    for i := 0 to Comp.ComponentCount-1 do begin
      // 1. deal with subcomponents, if any
      C := Comp.Components[i];
      if (C.ComponentCount>0)
        {$ifndef LCL}and not C.InheritsFrom(TRadioGroup){$endif} then
        DoAll(C,ParentName+RawUTF8(C.Name)+'.');
      {$ifdef WITHUXTHEME}
      // 2. Vista
      if isVista and C.InheritsFrom(TTreeView) then
        SetWindowTheme(TTreeView(C).Handle, 'explorer', nil);
      {$endif}
      // 3. user-defined translation
      if Assigned(OnTranslateComponent) then
        if OnTranslateComponent(C) then
          exit; // user method returned true, that is already translated
      // 4. ignore components with no name or which names begin with '_'
      if (C.Name='') or (C.Name[1]='_') then
        continue;
      // 5. Translate properties (Caption,Hint,Title,Lines,Items,Font..)
      TranslateObj(C,ParentName+RawUTF8(C.Name)+'.');
    end;
  end;

var UpperSection: array[byte] of AnsiChar;
begin
  if (Self=nil) or (Text='') or (aForm=nil) then
    exit;
//{$ifndef LCL}
  DefCharSet := GetDefFontCharSet;
  DefFontData.Charset := Language.CharSet;
//{$endif}
  Section := pointer(Text);
  PWord(UpperCopy(UpperSection,RawUTF8(aForm.ClassName)))^ := ord(']');
{$ifdef UNICODE}
  if not FindSectionFirstLineW(Section,UpperSection) then {$else}
  if not FindSectionFirstLine(Section,UpperSection) then
{$endif}
    Section := nil; // no [aForm.Name] section -> use Hash32() translation
  DoAll(aForm,'');
  if aForm.InheritsFrom(TCustomForm) then // can be called with TCustomFrame
    if TCustomForm(aForm).Visible then
      TCustomForm(aForm).Refresh;
  Application.ProcessMessages;
end;

{$ifdef USEFORMCREATEHOOK}
procedure TLanguageFile.LanguageClick(Sender: TObject);
// called with MenuItem.Tag = language ID
var LangIndex: TLanguages;
begin
  if Sender.InheritsFrom(TMenuItem) then
    LangIndex := TLanguages(TMenuItem(Sender).Tag) else
  if Sender.InheritsFrom(TComboBox) then
    with TComboBox(Sender) do
    if ItemIndex<0 then
      exit else
      LangIndex := TLanguages(Items.Objects[ItemIndex]) else
    exit;
  if (LangIndex=LANGUAGE_NONE) or (LangIndex=CurrentLanguage.Index) then
    exit;
  // Registry Values for i18n unit
  MessageBox(Application.Handle,pointer(i18nLanguageToRegistry(LangIndex)),
    nil,MB_OK or MB_ICONINFORMATION);
end;
{$endif}

function StringListCompareStrings(List: TStringList; Index1, Index2: integer): Integer;
begin // we need this integer<->cardinal trick to avoid comparison overflow
  Index1 := PtrInt(List.Objects[Index1]);
  Index2 := PtrInt(List.Objects[Index2]);
  if PtrUInt(Index1)<PtrUInt(Index2) then
    result := -1 else
    if Index1=Index2 then
      result := 0 else
      result := 1;
  assert((Index1=Index2) or (Result<>0)); // debug: no hash collision allowed
end;

function TLanguageFile.FindMessage(Hash: cardinal): string;
var L, H, I: Integer;
    V: cardinal; // trick to avoid comparison overflow
begin // finding is very fast, even if Objects[] is called
  if (self<>nil) and (Hash<>0) and (Messages<>nil) then begin
{    for i := 0 to Count-1 do // slower version
      if cardinal(Objects[I])=Hash then begin result := Strings[i]; break; end;
    exit; }
    L := 0;
    H := Messages.Count - 1;
    while L <= H do begin // use fast binary search algorithm
      I := (L + H) shr 1;
      V := cardinal(Messages.Objects[I]); // our custom Classes.pas unit is fast enough
      if V<Hash then
        L := I+1 else
        if V=Hash then begin
          result := Messages.Strings[I]; // UnicodeString on Delphi 2009 and up
          exit;
        end else
          H := I-1;
    end;
  end;
  result := '';
end;

const
  B2SW: array[boolean] of WinAnsiString = ('No','Yes');
  B2SS: array[boolean] of string = ('No','Yes');
  
procedure TLanguageFile.LoadFromFile(const aFileName: TFileName);
var s: string; // either AnsiString either UnicodeString
{$ifdef UNICODE}
    P: PWideChar; {$else}
    P: PUTF8Char; {$endif}
    H: cardinal;
    i: integer;
    tmp: string;
    B: boolean;
begin
  FreeAndNil(Messages);
  //{$ifndef LCL}
  fBooleanToString[false] := B2SS[false];
  fBooleanToString[true] := B2SS[true];
  //{$endif}
  Text := '';
  if not FileExists(aFileName) then
    exit;
  // 1. read .msg file with appropriate UTF8 or Unicode conversion
  Text := AnyTextFileToString(aFileName); // appropriate conversion
  // 2. fill Translation[] and Messages[]
  Messages := TStringList.Create;
  P := pointer(Text);
{$ifdef UNICODE}  
  if FindSectionFirstLineW(P,'MESSAGES]') then     
  while (P<>nil) and (P^<>'[') do begin
    H := GetNextItemCardinalW(P,'=');
    s := GetNextLineW(P, P);
{$else}
  if FindSectionFirstLine(P,'MESSAGES]') then
  while (P<>nil) and (P^<>'[') do begin
    H := GetNextItemCardinal(P,'=');
    s := GetNextLine(P,P);
{$endif}
    if H<>0 then begin
      for i := 1 to length(s) do
        case s[i] of
        '|': s[i] := #13;
        '~': s[i] := #10;
        end;
      Messages.AddObject(s,pointer(H));
    end;
  end;
  Messages.CustomSort(StringListCompareStrings); // sort by Hash32() values
{$ifndef LCL}
  tmp := ReadParam('DateFmt');
  if tmp<>'' then
    DateFmt := tmp else
    DateFmt := {$ifdef ISDELPHIXE}FormatSettings.{$endif}
      ShortDateFormat; // get default value from current locale
  tmp := ReadParam('TimeFmt');
  if tmp<>'' then
    TimeFmt := tmp else
    TimeFmt := 'hh:mm';   // default value for time is 24 hours display
  tmp := ReadParam('DateTimeFmt');
  if tmp<>'' then
    DateTimeFmt := tmp else
    DateTimeFmt := DateFmt+' '+TimeFmt; // default value from current locale
{$endif}
   for B := false to true do begin
     tmp := FindMessage(Hash32(B2SW[B]));
     if tmp<>'' then
       fBooleanToString[B] := tmp;
   end;
end;

function TLanguageFile.ReadParam(const ParamName: RawUTF8): string;
begin
  if self=nil then
    result := '' else
{$ifdef UNICODE}
    result := FindIniEntryW(Text,'',ParamName); {$else}
    result := FindIniEntry(Text,'',ParamName);
{$endif}
end;

procedure TLanguageFile.Translate(var English: string);
// case-sensitive (same as standard gettext)
var result: string;
begin
  result := FindMessage(Hash32(
    // resourcestring are expected to be in English, that is WinAnsi encoded
    {$ifdef UNICODE}StringToWinAnsi{$endif}(English)));
  if result<>'' then
    English := result;
end;

procedure GetText(var Text: string);
// used for System.LoadResStringTranslate case-sensitive (same as standard gettext)
begin
  if Language<>nil then
    Language.Translate(Text);
end;

function _(const English: WinAnsiString): string;
begin
  if Language<>nil then begin
    result := Language.FindMessage(Hash32(English));
    if result<>'' then
      exit;
  end;
  {$ifdef UNICODE}
  result := WinAnsiToUnicodeString(English);
  {$else}
  result := CurrentAnsiConvert.AnsiToAnsi(WinAnsiConvert,English);
  {$endif}
end;

function S2U(const Text: string): RawUTF8;
begin
  {$ifdef UNICODE}
  RawUnicodeToUtf8(PWideChar(pointer(Text)),length(Text),result);
  {$else}
    {$ifdef FPC}
      CurrentAnsiConvert.AnsiBufferToRawUTF8(pointer(Text),length(Text), result);
    {$else}
      result := CurrentAnsiConvert.AnsiBufferToRawUTF8(pointer(Text),length(Text));
    {$endif}
  {$endif}
end;

function U2S(const Text: RawUTF8): string;
begin
  {$ifdef UNICODE}
  result := UTF8DecodeToUnicodeString(pointer(Text),length(Text));
  {$else}
  result := CurrentAnsiConvert.UTF8BufferToAnsi(pointer(Text),length(Text));
  {$endif}
end;

function Iso2S(const Iso: TTimeLog): string;
begin
  if Iso=0 then
    result := '' else
  if Iso and (1 shl (6+6+5)-1)=0 then
    result := Language.DateToText(Iso) else
  if Iso shr (6+6+5)=0 then
    result := Language.TimeToText(Iso) else
    result := Language.DateTimeToText(Iso);
end;

function DateTime2S(const DateTime: TDateTime): string;
begin
  if DateTime=0 then
    result := '' else
    result := Language.DateTimeToText(DateTime);
end;

function TLanguageFile.BooleanToString(Value: boolean): string;
begin
  if self=nil then
    result := B2SS[Value] else begin
    result := fBooleanToString[Value];
    if result='' then
      result := B2SS[Value];
  end;
end;

function TLanguageFile.PropToString(Prop: TOrmPropInfo; Instance: TOrm;
   Client: TRest): string;
var Value: RawUTF8;
    int64ID: int64;
    Time: TTimeLogBits;
    ref: RecordRef;
begin
  Result := '';
  int64ID := 0;
  if (Prop=nil) or (Instance=nil) then
    exit;
  Value := Prop.GetValue(Instance,false);
  case Prop.OrmFieldType of
    oftInteger, oftCurrency, oftFloat, oftUTF8Text, oftAnsiText:
      result := UTF8ToString(Value);
    oftDateTime, oftDateTimeMS:
      result := DateTimeToText(Iso8601ToDateTime(Value));
    oftTimeLog, oftModTime, oftCreateTime: begin
      // need temp Iso to avoid URW699 with Delphi 6
      Time.Value := GetInt64(pointer(Value));
      result := DateTimeToText(Time);
    end;
    oftUnixTime: begin
      Time.FromUnixTime(GetInt64(pointer(Value)));
      result := DateTimeToText(Time);
    end;
    oftUnixMSTime:
      result := DateTimeToText(UnixMSTimeToDateTime(GetInt64(pointer(Value))));
    oftBoolean:
      result := BooleanToString(boolean(GetInteger(pointer(Value))));
    oftEnumerate:
      result := (Prop as TOrmPropInfoRTTIEnum).EnumType^.GetCaption(Value);
    oftSet:
      result := (Prop as TOrmPropInfoRTTISet).SetEnumType^.GetCaptionStrings(@Value);
    oftID:
      if Client<>nil then
        result := UTF8ToString(Client.Orm.MainFieldValue(
          TOrmClass((Prop as TOrmPropInfoRTTIID).ObjectClass),
          GetInt64(pointer(Value)),true));
    oftRecord: if Client<>nil then begin
      //SetID(pointer(Value),ref.Value);
      SetInt64(pointer(Value), int64ID);
      ref.Value := int64ID;
      result := UTF8ToString(Client.Orm.MainFieldValue(ref.Table(Client.Model),ref.ID,true));
      if result='' then
        result := Instance.ClassName else
        result := Instance.ClassName+': '+result;
    end;
  end;
end;

{$ifdef LVCL}
function DateTimeToIso(const DateTime: TDateTime; DateOnly: boolean): string;
var Time: TTimeLogBits;
begin // generic ISO date/time to text conversion
  Iso.From(DateTime);
  if DateOnly then
    Int64Rec(Iso).Lo := Int64Rec(Iso).Lo and not(1 shl (6+6+5)-1);
  result := Iso.Text(true,' ');
end;
{$else}
function DateTimeToIso(const DateTime: TDateTime; DateOnly: boolean): string;
const DATEFMT: array[boolean] of string = ('mmm dd, yyyy hh:mm am/pm','mmm dd, yyyy');
begin // generic US/English date/time to text conversion
  DateTimeToString(Result, DATEFMT[DateOnly], DateTime);
end;
{$endif}

function TLanguageFile.DateToText(const DateTime: TDateTime): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(DateTime,true)
{$ifndef LCL} else
    DateTimeToString(Result,DateFmt,DateTime);
{$endif}
end;

function TLanguageFile.DateToText(const Time: TTimeLogBits): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(Time.ToDate,true)
{$ifndef LCL} else
    DateTimeToString(Result,DateFmt,Time.ToDate);
{$endif}
end;

function TLanguageFile.DateToText(const Time: TTimeLog): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(TTimeLogBits(Time).ToDate,true)
{$ifndef LCL} else
    DateTimeToString(result,DateFmt,TTimeLogBits(Time).ToDate);
{$endif}
end;

function TLanguageFile.DateTimeToText(const DateTime: TDateTime): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(DateTime,false)
{$ifndef LCL} else
    DateTimeToString(result, DateTimeFmt, DateTime);
{$endif}
end;

function TLanguageFile.DateTimeToText(const Time: TTimeLogBits): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(Time.ToDateTime,false)
{$ifndef LCL} else
    DateTimeToString(result,DateTimeFmt,Time.ToDateTime);
{$endif}
end;

function TLanguageFile.DateTimeToText(const Time: TTimeLog): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(TTimeLogBits(Time).ToDateTime,false)
{$ifndef LCL} else
    DateTimeToString(Result,DateTimeFmt,TTimeLogBits(Time).ToDateTime);
{$endif}
end;

function TLanguageFile.TimeToText(const DateTime: TDateTime): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(DateTime,false)
{$ifndef LCL} else
    DateTimeToString(Result, TimeFmt, DateTime);
{$endif}
end;

function TLanguageFile.TimeToText(const Time: TTimeLogBits): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(Time.ToTime,false)
{$ifndef LCL} else
    DateTimeToString(Result,TimeFmt,Time.ToTime);
{$endif}
end;

function TLanguageFile.TimeToText(const Time: TTimeLog): string;
begin
{$ifndef LCL}if Self=nil then{$endif}
    result := DateTimeToIso(TTimeLogBits(Time).ToTime,false)
{$ifndef LCL} else
    DateTimeToString(Result,TimeFmt,TTimeLogBits(Time).ToTime);
{$endif}
end;
{
procedure POExport(const SourceMsgPath, POFileName: TFileName; SourceLanguage: TLanguages);
var English, Source: TLanguageFile;
    SourceDir: TFileName;
    Dest: TFileStream;
    W: TTextWriter;
    i: integer;
    E: string;
begin
  SourceDir := SourceMsgPath;
  if SourceDir='' then exit;
  if SourceDir[length(SourceDir)]<>'\' then
    SourceDir := SourceDir+'\';
  Dest := TFileStream.Create(POFileName,fmCreate);
  English := TLanguageFile.Create(SourceDir+TFileName(LanguageAbr[lngEnglish]+'.msg'),lngEnglish);
  Source := TLanguageFile.Create(SourceDir+TFileName(LanguageAbr[SourceLanguage]+'.msg'),SourceLanguage);
  W := TTextWriter.Create(Dest);
  try
    W.AddLine('"Content-Type: text/plain; charset=UTF-8\n"'#13#10+
      '"Content-Transfer-Encoding: 8bit\n"'#13#10);
    for i := 0 to English.Messages.Count - 1 do begin
      E := English.Messages[i];
      Source.Translate(E);
      W.Add('msgid "%"'#13'msgstr"'#13#13, // #13 will be written as #13#10
        [WinAnsiConvert.StringToUTF8(StringReplace(English.Messages[i],#13#10,'"'#13#10'"',[rfReplaceAll])),
         Source.StringToUTF8(StringReplace(E,#13#10,'"'#13#10'"',[rfReplaceAll]))]);
    end;
  finally
    W.Free;
    Source.Free;
    English.Free;
    Dest.Free;
  end;
end;
}


{ TLanguage }

function TLanguage.Abr: RawByteString;
begin
  if Index=LANGUAGE_NONE then
    result := '' else
    result := LanguageAbr[Index];
end;

procedure TLanguage.Fill(Language: TLanguages);
begin
  if Language=LANGUAGE_NONE then begin
    Index := lngEnglish; // default language = english
    CharSet := ANSI_CHARSET;
    CodePage := CODEPAGE_US;
    LCID := LCID_US;
  end else begin
    Index := Language;
    CharSet := LanguageCharSet[Language];
    CodePage := CharSetToCodePage(CharSet);
    LCID := LanguageToLCID(Language);
  end;
end;

function TLanguage.Name: string;
begin
  result := LanguageName(Index);
end;

{$ifdef EXTRACTALLRESOURCES}
var
  // expect english text, converted into WinAnsi before Hash32()
  // - Delphi 2009 and up will do the implicit codepage conversion
  // (useful for chars with unicode value >255, e.g. '€')
  CB_EnumStrings: TWinAnsiDynArray;
  /// number of items in CB_EnumStrings[]
  CB_EnumStringsCount: integer;
  // store the curently identified Hash32() of each english text
  CB_Enum: TDynArrayHashed;

function Hash32Str(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;
begin
  result := Hash32(pointer(buf),len);
end;

function AddOnceDynArray(const S: WinAnsiString): integer;
var added: boolean;
begin
  if (S='') or (S[1] in ['_','@']) then
    // ignore text beginning with '_' or '@'
    result := -1 else begin
    result := CB_Enum.FindHashedForAdding(S,added);
    if added then
      CB_EnumStrings[result] := S else
      if CB_EnumStrings[result]<>S then
        assert(false,'Hash colision for "'+S+'" and "'+CB_EnumStrings[result]+'"');
  end;
end;

{$I-}
// called within *A() Win32 API -> only english=Ansi text is expected here
function CB_EnumStringProc(hModule: THandle; lpszType, lpszName: PAnsiChar;
  lParam: PtrInt): Boolean; stdcall;
var buf: array[0..4095] of AnsiChar;
    s: WinAnsiString;
    i: PtrInt;
begin
  result := true;
  if (PtrInt(lpszType)<>PtrInt(RT_STRING)) then exit;
  i := (PtrInt(lpszName)-1)shl 4;
  for i := i to i+15 do begin // resourcestrings are stored by groups of 16
    SetString(s,buf,LoadStringA(hInstance,i,buf,sizeof(buf)));
    if s='' then exit; // we reach the end
    AddOnceDynArray(s);
  end;
end;

// called within *A() Win32 API -> only english=Ansi text is expected here
function CB_EnumDFMProc(hModule: THandle; lpszType, lpszName: PAnsiChar;
  lParam: PtrInt): Boolean; stdcall;
// code below use the string generic type, which is prefered for the RTTI
var F: ^Text absolute lparam;
    Reader: TReader;

  procedure ConvertObject(const ParentName, ObjectName: string);
    procedure ConvertValue(const PropName, LastPropName: string);
      procedure WriteProperty(const Value: WinAnsiString);
      // for Delphi 2009 and up, Value: string was converted into a WinAnsiString
      begin
        // ignore components which names begin with '_'
        if (PropName<>LastPropName) and (PropName<>'') then // PropName=Label1.Caption
          if PropName[1]='_' then // ignore _Copyright.Caption
            exit;
        // write value
        if (LastPropName='Caption') or (LastPropName='EditLabel.Caption') or
           (LastPropName='Hint') or (LastPropName='EditLabel.Hint') or
           (LastPropName='Title') or (LastPropName='Items') or
           (LastPropName='DisplayLabel') then begin
          Writeln(F^,PropName,'=_',Hash32(CB_EnumStrings[AddOnceDynArray(Value)]),
            '   ',Value); // add original caption for custom form translation
        end;
      end;
    var I, Count: Integer;
        aPropName, aSubPropName: string;
    begin
      case Reader.NextValue of
        vaList:
          begin
            Reader.ReadValue;
            I := 0;
            while not Reader.EndOfList do begin
              ConvertValue(PropName+'['+IntToStr(I)+']',LastPropName);
              inc(I);
            end;
            Reader.ReadListEnd;
          end;
        vaInt8, vaInt16, vaInt32:
          Reader.ReadInteger;
        vaInt64:
          Reader.ReadInt64;
        vaExtended:
          Reader.ReadFloat;
        vaSingle:
          Reader.ReadSingle;
        vaCurrency:
          Reader.ReadCurrency;
        vaDate:
          Reader.ReadDate;
        {$ifdef UNICODE}
        vaDouble:
          Reader.ReadDouble;
        vaWString, vaUTF8String:
          WriteProperty(StringToWinAnsi(Reader.ReadString));
        {$else}
        vaWString, vaUTF8String:
          WriteProperty(WideStringToWinAnsi(Reader.ReadWideString));
        {$endif}
        vaString, vaLString:
          WriteProperty(StringToWinAnsi(Reader.ReadString));
        vaIdent, vaFalse, vaTrue, vaNil, vaNull:
  {        if (LastPropName='Font.Charset') then begin
            s := Reader.ReadIdent;
            if (s<>'DEFAULT_CHARSET') and (s<>'ANSI_CHARSET') then
              Writeln(F^,PropName,'=',s);
          end else}
            Reader.ReadIdent;
        vaBinary: begin
            Reader.ReadValue;
            Reader.Read(Count, SizeOf(Count));
            Reader.Position := Reader.Position+Count;
          end;
        vaSet: begin
            Reader.ReadValue;
            repeat until Reader.ReadStr=''; // each ReadStr = one Set
          end;
        vaCollection:begin // same as TReader.ReadCollection()
            Reader.ReadValue;
            I := 0;
            while not Reader.EndOfList do begin
              if Reader.NextValue in [vaInt8, vaInt16, vaInt32] then
                 Reader.ReadInteger;
              aPropName := PropName+'['+IntToStr(I)+'].';
              inc(I);
              Reader.ReadListBegin;
              while not Reader.EndOfList do begin
                aSubPropName := Reader.ReadStr;
                ConvertValue(aPropName+aSubPropName,aSubPropName);
              end;
              Reader.ReadListEnd;
            end;
            Reader.ReadListEnd;
          end;
      else
        assert(false,IntToStr(PtrInt(Reader.NextValue)));
      end;
    end;
  var
    Flags: TFilerFlags;
    Position: Integer;
    aObjectName, aClassName, aPropName: string;
  begin // ConvertObject()
    Reader.ReadPrefix(Flags, Position);
    aClassName := Reader.ReadStr;
    aObjectName := Reader.ReadStr;
    if ObjectName='' then begin // first object = new TForm:
      Writeln(F^,#13#10'[',aClassName,']');
      while not Reader.EndOfList do begin
        aPropName := Reader.ReadStr;
        ConvertValue(aPropName,aPropName);
      end;
      Reader.ReadListEnd;
      while not Reader.EndOfList do
        ConvertObject('',aObjectName);
    end else begin // not TForm components:
      while not Reader.EndOfList do begin
        aPropName := Reader.ReadStr;
        if ((aPropName='Lines.Strings') {or (aPropName='Title.Text.Strings')}) and
           (Reader.NextValue=vaList) then begin // TMemo, TRichEdit
          Reader.ReadValue;
          if aObjectName[1]='_' then  begin // ignore _CompName component
            while not Reader.EndOfList do
              case Reader.NextValue of
                {$ifdef UNICODE}
                vaWString, vaUTF8String,
                {$else}
                vaWString, vaUTF8String: Reader.ReadWideString;
                {$endif}
                vaString, vaLString: Reader.ReadString;
                else assert(false);
              end;
          end else begin
            Write(F^,ParentName,aObjectName,'.Lines.Text=');
            if not Reader.EndOfList then
            repeat
              case Reader.NextValue of
              {$ifdef UNICODE}
              vaWString, vaUTF8String,
              {$else}
              vaWString, vaUTF8String:
                Write(F^,Reader.ReadWideString); // will do conversion into Ansi
              {$endif}
              vaString, vaLString:
                Write(F^,Reader.ReadString);
              else assert(false);
              end;
              if Reader.EndOfList then break;
              Write(F^,'|~'); // = CRLF
            until false;
            Writeln(F^);
          end;
          Reader.ReadListEnd;
        end else
        if aPropName='Items.Strings' then // TRadioGroup, TComboBox, TlistBox
          ConvertValue(ParentName+aObjectName+'.Items','Items') else
          ConvertValue(ParentName+aObjectName+'.'+aPropName,aPropName);
      end;
      Reader.ReadListEnd;
      if ffInline in Flags then
        while not Reader.EndOfList do // TFrame: include Parent
          ConvertObject(ParentName+aObjectName+'.',aObjectName) else
        while not Reader.EndOfList do // normal objects are root (as TMenuItem)
          ConvertObject('',aObjectName);
    end;
    Reader.ReadListEnd;
  end;

var RS: TResourceStream;
    Signature: cardinal;
begin
  result := true;
  if PtrInt(lpszType)<>PtrInt(RT_RCDATA) then
    exit;
  RS := TResourceStream.Create(HInstance, string(lpszName), RT_RCDATA);
  try
    if RS.Size<4 then
      exit;
    Reader := TReader.Create(RS, 4096);
    try
      Signature := 0;
      Reader.Read(Signature,4);
      if Signature=$30465054 then // 'TPF0' = DFM resources only
        ConvertObject('','');
    finally
      Reader.Free;
    end;
  finally
    RS.Free;
  end;
end;

procedure ExtractAllResources(const EnumTypeInfo: array of pointer;
  const Objects: array of TObject; const Records: array of TClass;
  const CustomCaptions: array of WinAnsiString);
// save all forms and resourcestring of the current exe to a .messages file
// following the .msg format (winAnsi text file, since it should be in english)
var F: Text;
    buf: RawByteString;
    i, index, j: integer;
    //P: PPropInfo;
    P: PRttiProp;
    s: WinAnsiString;
    ClassList: TList;
    CT: TClass;

  procedure AddEnum(T: PRttiEnumType);
  var index: integer;
  begin
    for index := T^.MinValue to T^.MaxValue do
      AddOnceDynArray(StringToWinAnsi(T^.GetCaption(index)));
      // for Delphi 2009 and up/XE: CaptionName converted into a WinAnsiString
  end;
  procedure AddClass(C: TClass);
  var i: integer;
      P: {PPropInfo}PRttiProp;
  begin
    if (C=nil) or (ClassList.IndexOf(C)>=0) then
      exit; // already done or no RTTI information (e.g. reached TObject level)
    ClassList.Add(C);
    AddClass(GetClassParent(C)); // add parent properties first
    for i := 1 to GetRttiProp(C,P) do begin // add all field names
      AddOnceDynArray(StringToWinAnsi(TOrm.SqlTableName));
      // for Delphi 2009 and up/XE: CaptionName converted into a WinAnsiString
      //with P^.PropType^^ do
      with P^.TypeInfo^ do
      case Kind of
      rkClass:       // add contained objects
        //AddClass(ClassType^.ClassType);
        AddClass(RttiClass^.RttiClass);
      rkEnumeration: // add enumeration values
        AddEnum(EnumBaseType);
      rkSet:
        AddEnum(SetEnumType);
      end;
      P := P^.Next;
    end;
  end;

begin
  // all code below use *A() Win32 API -> only english=Ansi text is expected here
  CB_Enum.Init(TypeInfo(TWinAnsiDynArray),CB_EnumStrings,nil,nil,Hash32Str,@CB_EnumStringsCount);
  ClassList := TList.Create;
  try
    assign(F,ChangeFileExt(Executable.ProgramFileName,'.messages'));
    SetLength(buf,65536);
    settextbuf(F,buf[1],length(buf));
    Rewrite(F);
    // add all resourcestring values
    EnumResourceNamesA(HInstance,PAnsiChar(RT_STRING),@CB_EnumStringProc,0);
    // add all enumerates captions
    for i := 0 to high(EnumTypeInfo) do
      //AddEnum(PTypeInfo(EnumTypeInfo[i])^.EnumBaseType);
      AddEnum(PRttiInfo(TypeInfo(WordBool))^.EnumBaseType);
    // add object instance captions
    for i := 0 to high(Objects) do
      if Objects[i].InheritsFrom(TOrmModel) then begin
        AddOnceDynArray('ID'); // ID property is never published, but always here
        // add custom captions for all tables of a database model
        with TOrmModel(Objects[i]) do
        for index := 0 to high(Tables) do
        with Tables[index] do begin // TSQLRecord.CaptionName() may be overridden
          //AddOnceDynArray(StringToWinAnsi(CaptionName(nil))); // add table name
          AddOnceDynArray(StringToWinAnsi(SqlTableName));
          CT := Tables[index];
          repeat
            for j := 1 to GetRttiProp(CT,P) do begin
               // for Delphi 2009 and up, CaptionName(): string for safety
              AddOnceDynArray(StringToWinAnsi(P^.NameUtf8));
              P := P^.Next;
            end;
            CT := GetClassParent(CT);
          until CT=nil;
        end;
      end else
      // add standard captions for all TPersistent published fields
      if Objects[i].InheritsFrom(TPersistent) then
        AddClass(Objects[i].ClassType);
    // add standard captions for all published fields of these classes
    for i := 0 to high(Records) do
      AddClass(Records[i]);
    // add custom captions
    for i := 0 to high(CustomCaptions) do
      AddOnceDynArray(CustomCaptions[i]);
    // add form properties to be translated, with Property=Hash pairs
    EnumResourceNamesA(HInstance, PAnsiChar(RT_RCDATA), @CB_EnumDFMProc, PtrInt(@F));
    // create message list, with hash=value pairs
    Writeln(F,#13#10'[Messages]');
    for i := 0 to CB_EnumStringsCount-1 do begin
      // CR/LF consistent replace
      s := CB_EnumStrings[i];
      for j := 1 to length(s) do
        case s[j] of
          #13: s[j] := '|';
          #10: s[j] := '~'
        end;
      Writeln(F,Hash32(CB_EnumStrings[i]),'=',s);
    end;
    Close(F);
  finally
    ioresult;
    ClassList.Free;
  end;
end;
{$I+}

{$endif}

{var L,index: TLanguages;
initialization
  AllocConsole;
  for L := low(L) to high(L) do begin
    index := TLanguages(LanguageAlpha[L]);
    writeln(format('|%s|%s|%d|%s',
      [LanguageName(index),LanguageAbr[index],CharSetToCodePage(LanguageCharSet[index]),
        LanguageAbr[index]+'.msg']));
  end;
  readln;
}

initialization
  {$ifdef WITHUXTHEME}
  // standard FormatSettings (US)
  {$WARN SYMBOL_DEPRECATED OFF}
  GetLocaleFormatSettings(LCID_US,SettingsUS);
  {$ifndef NOI18N}
  i18nDateText :=  Iso2S; // for SynCommons.pas unit
  i18nDateTimeText := DateTime2S;
  {$endif}
  {$endif}
  // avoid call nil functions -> set default function to point to
  i18nCompareStr := {$ifdef ENHANCEDRTL}CompareStr{$else}i18nInnerCompareStr{$endif};
  move(NormToUpper,i18nToUpper,sizeof(NormToUpper));
  move(NormToLower,i18nToLower,sizeof(NormToUpper));
  i18nCompareText := i18nInnerCompareText;
{$ifndef ENHANCEDRTL}
  {$ifdef FPC}
  RedirectCode(@LoadResString,@mORmot.i18n.LoadResString,@BackupLoadResString);
  {$else}
  RedirectCode(@System.LoadResString,@mORmot.i18n.LoadResString,@BackupLoadResString);
  CacheResCriticalSection.Init;
  {$endif}
{$endif}
{$ifndef NOI18N}
  LangInit; // do redirection + init user default locale (from Win32 or registry)
  i18nDateText :=  Iso2S; // for SynCommons.pas unit
  i18nDateTimeText := DateTime2S;
{$endif}

finalization
{$ifndef NOI18N}
  FreeAndNil(Language);
{$ifdef USEFORMCREATEHOOK}
  if OriginalForm[0]<>0 then begin
    RedirectCodeRestore(@THookedForm.DoCreate,OriginalForm);
    RedirectCodeRestore(@THookedFrame.Create,OriginalFrame);
  end;
{$endif}
{$endif}
{$ifndef ENHANCEDRTL}
  {$ifdef FPC}
  RedirectCodeRestore(@LoadResString,BackupLoadResString);
  {$else}
  RedirectCodeRestore(@System.LoadResString,BackupLoadResString);
  {$endif}
  CacheResCriticalSection.Done;
{$endif}
end.



