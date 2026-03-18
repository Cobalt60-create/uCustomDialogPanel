{
  *****************************************************************************
  ** МОДУЛЬ: uCustomDialogPanel.pas
  ** ВЕРСИЯ: 2.0
  ** ДАТА: 13.03.2026
  ** Автор: Николай Николаевич Колесников
  **
  ** НАЗНАЧЕНИЕ:
  **   Модуль предоставляет класс TCustomDialogPanel для создания современных,
  **   анимированных диалоговых окон внутри формы FMX. Диалоги отображаются
  **   поверх основного интерфейса с затемнением фона и поддерживают
  **   асинхронные callback-функции для обработки результата.
  **
  ** ОСОБЕННОСТИ:
  **   - Асинхронная работа (не блокирует поток)
  **   - Анимация появления/исчезновения
  **   - Кастомизация под разные типы сообщений (инфо, подтверждение, ошибка)
  **   - Callback-функции для обработки выбора пользователя
  **   - Автоматическое центрирование на форме
  **   - Тень и визуальные эффекты
  **
  ** ЗАВИСИМОСТИ:
  **   - FMX.Forms - для работы с родительской формой
  **   - FMX.Ani - для анимации
  **   - FMX.Effects - для теней
  *****************************************************************************
}

unit uCustomDialogPanel;

interface

uses
  { Стандартные модули Delphi }
  System.SysUtils,        // Исключения, строковые функции
  System.UITypes,         // TAlphaColor, TModalResult
  System.Classes,         // TComponent, TList
  System.Types,           // TPoint, TRect

  { Модули FMX для визуальных компонентов }
  FMX.Types,              // Базовые типы FMX: TAlignLayout, TTextAlign
  FMX.Memo,               // TMemo - многострочное поле для сообщений
  FMX.Controls,           // Базовые классы контролов
  FMX.Forms,              // TForm - родительская форма
  FMX.StdCtrls,           // TLabel, TSpeedButton - стандартные контролы
  FMX.Layouts,            // TLayout - для организации интерфейса
  FMX.Objects,            // TRectangle, TCircle - графические примитивы
  FMX.Graphics,           // TBrushKind, TCanvas - графические операции
  FMX.Ani,                // TFloatAnimation - анимация свойств
  FMX.Effects;            // TShadowEffect - эффект тени

type
  /// <summary>
  ///   Результат диалога. Возвращается в callback-функцию.
  /// </summary>
  /// <remarks>
  ///   Используется для определения, какую кнопку нажал пользователь:
  ///   drNone - диалог закрыт без выбора (например, через Hide)
  ///   drOk - нажата кнопка OK/Да
  ///   drCancel - нажата кнопка Отмена/Нет
  /// </remarks>
  TDialogResult = (drNone, drOk, drCancel);

  /// <summary>
  ///   Callback-функция для асинхронного получения результата диалога.
  /// </summary>
  /// <param name="Result">
  ///   Результат выбора пользователя (drOk или drCancel)
  /// </param>
  /// <remarks>
  ///   Вызывается после закрытия диалога в контексте главного потока.
  ///   Позволяет выполнить код в зависимости от выбора пользователя.
  /// </remarks>
  TDialogCallback = reference to procedure(Result: TDialogResult);

  /// <summary>
  ///   Тип диалога. Определяет внешний вид и набор кнопок.
  /// </summary>
  /// <remarks>
  ///   dtInfo - информационное сообщение (синий круг с 'i', только OK)
  ///   dtConfirm - подтверждение действия (оранжевый '?', кнопки Да/Нет)
  ///   dtWarning - предупреждение (желто-оранжевый '!', только OK)
  ///   dtError - сообщение об ошибке (красный '✗', только OK)
  /// </remarks>
  TDialogType = (dtInfo, dtConfirm, dtWarning, dtError);

  /// <summary>
  ///   Основной класс для управления кастомными диалогами.
  /// </summary>
  /// <remarks>
  ///   Класс наследуется от TComponent, что позволяет размещать его на форме
  ///   или создавать динамически. Содержит все необходимые визуальные
  ///   компоненты и методы для отображения диалогов.
  /// </remarks>
  TCustomDialogPanel = class(TComponent)
  private
    {--- Родительская форма ---}
    FParentForm: TForm;  // Форма, на которой отображается диалог

    {--- Визуальные компоненты ---}
    FOverlay: TRectangle;        // Затемняющий фон поверх всей формы
    FPanel: TPanel;              // Основная панель диалога
    FTitleLabel: TLabel;         // Заголовок диалога
    FMemoInfo: TMemo;            // Текст сообщения (многострочный)
    FBtnOk: TSpeedButton;        // Кнопка OK/Да
    FBtnCancel: TSpeedButton;    // Кнопка Отмена/Нет
    FIconCircle: TCircle;        // Круг для иконки
    FIconText: TLabel;           // Текст на иконке (i, ?, !, ✗)
    FShadow: TShadowEffect;      // Эффект тени для панели
    FAnimation: TFloatAnimation; // Анимация для плавного появления/исчезновения

    {--- Состояние диалога ---}
    FCallback: TDialogCallback;  // Функция обратного вызова
    FResult: TDialogResult;      // Результат выбора пользователя

    {--- Приватные методы для создания компонентов ---}
    procedure CreateOverlay;
    { Создает затемняющий фон. Вызывается в конструкторе. }

    procedure CreatePanel;
    { Создает основную панель диалога. Вызывается в конструкторе. }

    procedure CreateControls;
    { Создает все элементы управления внутри панели. Вызывается в конструкторе. }

    procedure SetupLayout;
    { Настраивает начальное расположение элементов. Вызывается в конструкторе. }

    procedure SetupColors(DialogType: TDialogType);
    { Настраивает цвета в зависимости от типа диалога.
      @param DialogType - тип диалога (определяет цвет и иконку) }

    procedure PositionPanel;
    { Центрирует панель относительно родительской формы.
      Вызывается перед показом диалога. }

    {--- Обработчики событий ---}
    procedure OkClick(Sender: TObject);
    { Обработчик нажатия на кнопку OK/Да.
      Закрывает диалог с результатом drOk. }

    procedure CancelClick(Sender: TObject);
    { Обработчик нажатия на кнопку Отмена/Нет.
      Закрывает диалог с результатом drCancel. }

    procedure CloseDialog(Result: TDialogResult);
    { Закрывает диалог с указанным результатом.
      Запускает анимацию закрытия и вызывает callback.
      @param Result - результат выбора пользователя }

    procedure AnimationFinish(Sender: TObject);
    { Обработчик завершения анимации закрытия.
      Скрывает компоненты и вызывает callback. }

  public
    {--- Конструктор / Деструктор ---}
    constructor Create(AOwner: TComponent); override;
    { Конструктор класса.
      @param AOwner - владелец компонента (должен быть TForm)
      @raises Exception - если AOwner не является формой }

    destructor Destroy; override;
    { Деструктор. Освобождает созданные компоненты. }

    {--- Основные методы для отображения диалогов ---}
    procedure Show(const ATitle, AMessage: string;
                   ADialogType: TDialogType = dtInfo;
                   ACallback: TDialogCallback = nil);
    { Основной метод для показа диалога с полной настройкой.
      @param ATitle - заголовок диалога
      @param AMessage - текст сообщения
      @param ADialogType - тип диалога (определяет внешний вид)
      @param ACallback - callback-функция для обработки результата }

    procedure ShowConfirm(const ATitle, AMessage: string;
                          ACallback: TDialogCallback = nil);
    { Показывает диалог подтверждения с кнопками Да/Нет.
      @param ATitle - заголовок
      @param AMessage - сообщение
      @param ACallback - callback для получения результата }

    procedure ShowInfo(const ATitle, AMessage: string;
                       ACallback: TDialogCallback = nil);
    { Показывает информационное сообщение с кнопкой OK.
      @param ATitle - заголовок
      @param AMessage - сообщение
      @param ACallback - опциональный callback }

    procedure ShowWarning(const ATitle, AMessage: string;
                          ACallback: TDialogCallback = nil);
    { Показывает предупреждение с кнопкой OK.
      @param ATitle - заголовок
      @param AMessage - сообщение
      @param ACallback - опциональный callback }

    procedure ShowError(const ATitle, AMessage: string;
                        ACallback: TDialogCallback = nil);
    { Показывает сообщение об ошибке с кнопкой OK.
      @param ATitle - заголовок
      @param AMessage - сообщение
      @param ACallback - опциональный callback }

    procedure Hide;
    { Закрывает диалог без результата (drNone). }

    function IsVisible: Boolean;
    { Проверяет, видим ли диалог в данный момент.
      @return True - диалог открыт, False - закрыт }
  end;

implementation

const
  { Константы цветов для разных типов диалогов }
  COLOR_INFO = $FF2D9CDB;      // Синий
  COLOR_CONFIRM = $FFF39C12;    // Оранжевый
  COLOR_WARNING = $FFE67E22;    // Оранжевый-красный
  COLOR_ERROR = $FFE74C3C;      // Красный

{===============================================================================
  TCustomDialogPanel
===============================================================================}

{------------------------------------------------------------------------------
  Конструктор
------------------------------------------------------------------------------}
constructor TCustomDialogPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  { Проверяем, что владелец - форма (диалог должен отображаться на форме) }
  if not (AOwner is TForm) then
    raise Exception.Create('TCustomDialogPanel requires a TForm as owner');

  { Сохраняем ссылку на родительскую форму }
  FParentForm := AOwner as TForm;

  { Инициализация переменных состояния }
  FCallback := nil;
  FResult := drNone;

  { Создаем визуальные компоненты в правильном порядке:
    1. Затемнение (самый нижний слой)
    2. Панель диалога (поверх затемнения)
    3. Элементы управления внутри панели }
  CreateOverlay;
  CreatePanel;
  CreateControls;
  SetupLayout;

  { Изначально диалог скрыт }
  FOverlay.Visible := False;
  FPanel.Visible := False;
end;

{------------------------------------------------------------------------------
  Деструктор
------------------------------------------------------------------------------}
destructor TCustomDialogPanel.Destroy;
begin
  { Освобождаем созданные компоненты.
    Важно: Parent-компоненты освободятся автоматически, но мы освобождаем
    корневые элементы для гарантии }
  FreeAndNil(FOverlay);
  FreeAndNil(FPanel);
  inherited;
end;

{------------------------------------------------------------------------------
  Создание затемняющего фона
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.CreateOverlay;
begin
  { TRectangle - прямоугольник с возможностью заливки }
  FOverlay := TRectangle.Create(FParentForm);
  FOverlay.Parent := FParentForm;          // Родитель - главная форма
  FOverlay.Align := TAlignLayout.Contents; // Растягиваем на всю форму
  FOverlay.Fill.Color := TAlphaColors.Black; // Черный цвет
  FOverlay.Fill.Kind := TBrushKind.Solid;    // Сплошная заливка
  FOverlay.Stroke.Kind := TBrushKind.None;   // Без обводки
  FOverlay.Opacity := 0;                      // Прозрачный (появится с анимацией)
  FOverlay.HitTest := True;                   // Перехватывает клики
  FOverlay.Visible := False;                   // Изначально скрыт
end;

{------------------------------------------------------------------------------
  Создание основной панели диалога
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.CreatePanel;
begin
  { TPanel - контейнер для элементов управления }
  FPanel := TPanel.Create(FParentForm);
  FPanel.Parent := FParentForm;           // Родитель - главная форма
  FPanel.Width := 500;                     // Фиксированная ширина
  FPanel.Height := 300;                     // Фиксированная высота
  FPanel.StyleLookup := 'backgroundstyle'; // Стиль из текущей темы
  FPanel.Opacity := 0;                       // Прозрачный (появится с анимацией)
  FPanel.Visible := False;                    // Изначально скрыт

  { Добавляем эффект тени для объема }
  FShadow := TShadowEffect.Create(FPanel);
  FShadow.Parent := FPanel;
  FShadow.Direction := 90;    // Направление тени (вниз)
  FShadow.Distance := 5;       // Смещение тени
  FShadow.Softness := 0.5;     // Мягкость тени
  FShadow.Opacity := 0.5;      // Прозрачность тени
end;

{------------------------------------------------------------------------------
  Создание всех элементов управления внутри панели
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.CreateControls;
begin
  { --- Иконка (круг с текстом) --- }
  FIconCircle := TCircle.Create(FPanel);
  FIconCircle.Parent := FPanel;
  FIconCircle.Width := 50;        // Диаметр круга
  FIconCircle.Height := 50;
  FIconCircle.Position.X := 20;    // Отступ слева
  FIconCircle.Position.Y := 20;    // Отступ сверху
  FIconCircle.Fill.Color := COLOR_INFO; // Цвет по умолчанию
  FIconCircle.Fill.Kind := TBrushKind.Solid;
  FIconCircle.Stroke.Kind := TBrushKind.None; // Без обводки

  { Текст внутри круга }
  FIconText := TLabel.Create(FIconCircle);
  FIconText.Parent := FIconCircle;
  FIconText.Align := TAlignLayout.Contents; // На весь круг
  FIconText.TextSettings.Font.Size := 24;    // Размер шрифта
  FIconText.TextSettings.Font.Style := [TFontStyle.fsBold]; // Жирный
  FIconText.TextSettings.FontColor := TAlphaColors.White;   // Белый цвет
  FIconText.Text := 'i'; // Текст по умолчанию (информация)
  FIconText.TextSettings.HorzAlign := TTextAlign.Center; // По центру по горизонтали
  FIconText.TextSettings.VertAlign := TTextAlign.Center;  // По центру по вертикали

  { --- Заголовок диалога --- }
  FTitleLabel := TLabel.Create(FPanel);
  FTitleLabel.Parent := FPanel;
  FTitleLabel.Position.X := 85;    // Справа от иконки
  FTitleLabel.Position.Y := 25;    // Выровнен по верхнему краю иконки
  FTitleLabel.Width := 395;         // Ширина до правого края
  FTitleLabel.Height := 30;         // Высота
  FTitleLabel.TextSettings.Font.Size := 18;  // Крупный шрифт
  FTitleLabel.TextSettings.Font.Style := [TFontStyle.fsBold]; // Жирный
  FTitleLabel.Text := 'Заголовок';            // Текст по умолчанию

  { --- Текст сообщения (многострочный) --- }
  FMemoInfo := TMemo.Create(FPanel);
  FMemoInfo.Parent := FPanel;
  FMemoInfo.Position.X := 85;
  FMemoInfo.Position.Y := 60;
  FMemoInfo.Width := 395;
  FMemoInfo.Height := 180;          // Оставляем место для кнопок
  FMemoInfo.ReadOnly := True;        // Только для чтения
  FMemoInfo.StyleLookup := 'memostyle'; // Стиль из темы
  FMemoInfo.TextSettings.Font.Size := 12; // Обычный текст

  { --- Кнопка OK (правая нижняя часть) --- }
  FBtnOk := TSpeedButton.Create(FPanel);
  FBtnOk.Parent := FPanel;
  FBtnOk.Position.X := 280;  // 500 - 100 - 20 = 380, но смещаем левее
  FBtnOk.Position.Y := 250;
  FBtnOk.Width := 100;
  FBtnOk.Height := 35;
  FBtnOk.Text := 'OK';
  FBtnOk.StyleLookup := 'okbuttonstyle'; // Стиль из темы
  FBtnOk.OnClick := OkClick; // Назначаем обработчик

  { --- Кнопка Cancel (справа от OK) --- }
  FBtnCancel := TSpeedButton.Create(FPanel);
  FBtnCancel.Parent := FPanel;
  FBtnCancel.Position.X := 390; // 280 + 100 + 10 = 390
  FBtnCancel.Position.Y := 250;
  FBtnCancel.Width := 100;
  FBtnCancel.Height := 35;
  FBtnCancel.Text := 'Отмена';
  FBtnCancel.StyleLookup := 'cancelbuttonstyle'; // Стиль из темы
  FBtnCancel.OnClick := CancelClick; // Назначаем обработчик
end;

{------------------------------------------------------------------------------
  Начальная настройка расположения элементов
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.SetupLayout;
begin
  { По умолчанию показываем только кнопку OK (Cancel скрыта) }
  FBtnCancel.Visible := False;
end;

{------------------------------------------------------------------------------
  Настройка цветов под тип диалога
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.SetupColors(DialogType: TDialogType);
var
  Color: TAlphaColor;
  IconChar: Char;
begin
  { Определяем цвет и символ иконки в зависимости от типа }
  case DialogType of
    dtInfo:
      begin
        Color := COLOR_INFO;
        IconChar := 'i';
      end;
    dtConfirm:
      begin
        Color := COLOR_CONFIRM;
        IconChar := '?';
      end;
    dtWarning:
      begin
        Color := COLOR_WARNING;
        IconChar := '!';
      end;
    dtError:
      begin
        Color := COLOR_ERROR;
        IconChar := '✗';  // Символ "крестик" (U+2717)
      end;
  else
    Color := COLOR_INFO;
    IconChar := 'i';
  end;

  { Применяем цвета }
  FIconCircle.Fill.Color := Color;   // Цвет круга
  FIconText.Text := IconChar;         // Символ на иконке

  { Подсвечиваем кнопку OK цветом диалога }
  FBtnOk.TextSettings.FontColor := Color;
end;

{------------------------------------------------------------------------------
  Центрирование панели на форме
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.PositionPanel;
begin
  { Вычисляем координаты для центрирования }
  FPanel.Position.X := (FParentForm.Width - FPanel.Width) / 2;
  FPanel.Position.Y := (FParentForm.Height - FPanel.Height) / 2;
end;

{------------------------------------------------------------------------------
  Обработчик нажатия кнопки OK
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.OkClick(Sender: TObject);
begin
  { Закрываем диалог с результатом "OK" }
  CloseDialog(drOk);
end;

{------------------------------------------------------------------------------
  Обработчик нажатия кнопки Cancel
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.CancelClick(Sender: TObject);
begin
  { Закрываем диалог с результатом "Cancel" }
  CloseDialog(drCancel);
end;

{------------------------------------------------------------------------------
  Закрытие диалога с указанным результатом
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.CloseDialog(Result: TDialogResult);
begin
  { Сохраняем результат для callback-функции }
  FResult := Result;

  { --- Анимация закрытия панели --- }
  FAnimation := TFloatAnimation.Create(FPanel);
  FAnimation.Parent := FPanel;
  FAnimation.PropertyName := 'Opacity'; // Анимируем прозрачность
  FAnimation.StartValue := 1;            // От непрозрачного
  FAnimation.StopValue := 0;              // До прозрачного
  FAnimation.Duration := 0.2;              // За 200 мс
  FAnimation.OnFinish := AnimationFinish;   // По завершению - скрыть
  FAnimation.Start;

  { --- Анимация закрытия затемнения --- }
  var OverlayAnim: TFloatAnimation := TFloatAnimation.Create(FOverlay);
  OverlayAnim.Parent := FOverlay;
  OverlayAnim.PropertyName := 'Opacity';
  OverlayAnim.StartValue := FOverlay.Opacity; // Текущее значение
  OverlayAnim.StopValue := 0;
  OverlayAnim.Duration := 0.2;
  OverlayAnim.Start;
end;

{------------------------------------------------------------------------------
  Обработчик завершения анимации закрытия
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.AnimationFinish(Sender: TObject);
var
  LocalCallback: TDialogCallback;
  LocalResult: TDialogResult;
begin
  { Скрываем компоненты }
  FOverlay.Visible := False;
  FPanel.Visible := False;

  { Сохраняем callback и результат в локальные переменные,
    чтобы избежать проблем с реентерабельностью }
  LocalCallback := FCallback;
  LocalResult := FResult;

  { Очищаем поля класса }
  FCallback := nil;
  FResult := drNone;

  { Вызываем callback в главном потоке, если он был передан }
  if Assigned(LocalCallback) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        LocalCallback(LocalResult);
      end);
  end;

  { Освобождаем объект анимации }
  if Sender is TFloatAnimation then
    TFloatAnimation(Sender).Free;
end;

{------------------------------------------------------------------------------
  Основной метод показа диалога
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.Show(const ATitle, AMessage: string;
  ADialogType: TDialogType; ACallback: TDialogCallback);
begin
  { Если диалог уже открыт - закрываем его (чтобы не было наложения) }
  if FPanel.Visible then
    Hide;

  { Сохраняем callback }
  FCallback := ACallback;
  FResult := drNone;

  { Устанавливаем текст }
  FTitleLabel.Text := ATitle;
  FMemoInfo.Text := AMessage;

  { Настраиваем внешний вид под тип диалога }
  SetupColors(ADialogType);

  { Настраиваем кнопки в зависимости от типа }
  if ADialogType = dtConfirm then
  begin
    { Для подтверждения показываем обе кнопки }
    FBtnCancel.Visible := True;
    FBtnOk.Text := 'Да';
    FBtnCancel.Text := 'Нет';
  end
  else
  begin
    { Для остальных типов - только OK }
    FBtnCancel.Visible := False;
    FBtnOk.Text := 'OK';
  end;

  { Центрируем панель на форме }
  PositionPanel;

  { Показываем компоненты }
  FOverlay.Visible := True;
  FPanel.Visible := True;

  { --- Анимация появления --- }
  FOverlay.Opacity := 0;
  FPanel.Opacity := 0;

  { Анимация затемнения }
  var OverlayAnim: TFloatAnimation := TFloatAnimation.Create(FOverlay);
  OverlayAnim.Parent := FOverlay;
  OverlayAnim.PropertyName := 'Opacity';
  OverlayAnim.StartValue := 0;
  OverlayAnim.StopValue := 0.5;  // Полупрозрачный черный фон
  OverlayAnim.Duration := 0.2;
  OverlayAnim.Start;

  { Анимация панели }
  var PanelAnim: TFloatAnimation := TFloatAnimation.Create(FPanel);
  PanelAnim.Parent := FPanel;
  PanelAnim.PropertyName := 'Opacity';
  PanelAnim.StartValue := 0;
  PanelAnim.StopValue := 1;  // Полностью непрозрачная
  PanelAnim.Duration := 0.2;
  PanelAnim.Start;
end;

{------------------------------------------------------------------------------
  Удобные методы-обертки для разных типов диалогов
------------------------------------------------------------------------------}

procedure TCustomDialogPanel.ShowConfirm(const ATitle, AMessage: string;
  ACallback: TDialogCallback);
begin
  Show(ATitle, AMessage, dtConfirm, ACallback);
end;

procedure TCustomDialogPanel.ShowInfo(const ATitle, AMessage: string;
  ACallback: TDialogCallback);
begin
  Show(ATitle, AMessage, dtInfo, ACallback);
end;

procedure TCustomDialogPanel.ShowWarning(const ATitle, AMessage: string;
  ACallback: TDialogCallback);
begin
  Show(ATitle, AMessage, dtWarning, ACallback);
end;

procedure TCustomDialogPanel.ShowError(const ATitle, AMessage: string;
  ACallback: TDialogCallback);
begin
  Show(ATitle, AMessage, dtError, ACallback);
end;

{------------------------------------------------------------------------------
  Закрытие диалога без результата
------------------------------------------------------------------------------}
procedure TCustomDialogPanel.Hide;
begin
  CloseDialog(drNone);
end;

{------------------------------------------------------------------------------
  Проверка видимости диалога
------------------------------------------------------------------------------}
function TCustomDialogPanel.IsVisible: Boolean;
begin
  Result := FPanel.Visible;
end;

end.
