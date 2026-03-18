# uCustomDialogPanel
Кастомные диалоги для Delphi

# Руководство по подключению и использованию модуля
## 1. Способы подключения модуля
### 1.1. Статическое размещение на форме (через uses)

~~~)
uses
  uCustomDialogPanel;  // Подключаем модуль

type
  TMainForm = class(TForm)
  private
    FDialog: TCustomDialogPanel;  // Объявляем поле
  end;

implementation

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Создаем диалог (Owner = Self - освободится автоматически)
  FDialog := TCustomDialogPanel.Create(Self);
end;

// Использование
procedure TMainForm.ButtonClick(Sender: TObject);
begin
  FDialog.ShowInfo('Заголовок', 'Текст сообщения');
end;
~~~)

### 1.2. Динамическое создание по требованию

~~~)
procedure TMainForm.ShowMessage(const Msg: string);
var
  Dialog: TCustomDialogPanel;
begin
  Dialog := TCustomDialogPanel.Create(Self); // Self должен быть формой
  try
    Dialog.ShowInfo('Информация', Msg);
    // Не освобождаем сразу - диалог работает асинхронно
    // Компонент освободится вместе с формой
  except
    Dialog.Free;
    raise;
  end;
end;
~~~)

### 1.3. Размещение на форме через Object Inspector (если зарегистрировать компонент)
#### Для регистрации компонента на палитре добавьте в отдельный модуль:

~~~)
unit RegisterDialog;

interface

procedure Register;

implementation

uses
  System.Classes,
  uCustomDialogPanel;

procedure Register;
begin
  RegisterComponents('Custom Controls', [TCustomDialogPanel]);
end;

end.
~~~)

## 2. Использование в коде
### 2.1. Простое информационное сообщение

~~~)
procedure TMainForm.btnInfoClick(Sender: TObject);
begin
  FDialog.ShowInfo(
    'Информация',
    'Исследование успешно сохранено.' + sLineBreak +
    'ID: 12345'
  );
end;
~~~)

### 2.2. Диалог подтверждения с обработкой результата

~~~)
procedure TMainForm.btnDeleteClick(Sender: TObject);
begin
  FDialog.ShowConfirm(
    'Подтверждение удаления',
    'Вы действительно хотите удалить исследование №12345?' + sLineBreak +
    'Это действие нельзя отменить.',
    procedure(Result: TDialogResult)
    begin
      if Result = drOk then
      begin
        // Пользователь нажал "Да"
        DeleteStudy(12345);
        FDialog.ShowInfo('Успех', 'Исследование удалено');
      end
      else
      begin
        // Пользователь нажал "Нет"
        FDialog.ShowInfo('Отмена', 'Удаление отменено');
      end;
    end
  );
end;
~~~)

### 2.3. Предупреждение

~~~)
procedure TMainForm.CheckBeforeExit;
begin
  if FIsModified then
  begin
    FDialog.ShowWarning(
      'Несохраненные изменения',
      'Есть несохраненные данные.' + sLineBreak +
      'Сохранить перед выходом?',
      procedure(Result: TDialogResult)
      begin
        if Result = drOk then
          SaveAndExit
        else
          ExitWithoutSaving;
      end
    );
  end
  else
    Close;
end;
~~~)

### 2.4. Обработка ошибок

~~~)
procedure TMainForm.HandleError(const ErrorMsg: string);
begin
  FDialog.ShowError(
    'Ошибка операции',
    'Произошла ошибка при выполнении:' + sLineBreak +
    ErrorMsg + sLineBreak +
    'Проверьте подключение оборудования.'
  );
end;
~~~)

### 2.5. Последовательные диалоги (Chain)

~~~)
procedure TMainForm.ConfirmAndDelete;
begin
  FDialog.ShowConfirm(
    'Удаление',
    'Удалить запись?',
    procedure(Result1: TDialogResult)
    begin
      if Result1 = drOk then
      begin
        FDialog.ShowConfirm(
          'Подтверждение',
          'Вы уверены? Это действие необратимо.',
          procedure(Result2: TDialogResult)
          begin
            if Result2 = drOk then
              PerformDelete;
          end
        );
      end;
    end
  );
end;
~~~)

## 3. Интеграция с существующим кодом
### 3.1. Замена ShowMessage
~~~)
// Вместо
ShowMessage('Текст сообщения');

// Используйте
FDialog.ShowInfo('Сообщение', 'Текст сообщения');
~~~)

### 3.2. Замена MessageDlg (синхронного)

~~~)
// Было (синхронно - плохо):
if MessageDlg('Вопрос', TMsgDlgType.mtConfirmation,
              [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes then
begin
  // действие
end;

// Стало (асинхронно - хорошо):
FDialog.ShowConfirm(
  'Вопрос',
  'Текст вопроса',
  procedure(Result: TDialogResult)
  begin
    if Result = drOk then
    begin
      // действие
    end;
  end
);
~~~)

### 3.3. Интеграция с TMainAppForm

~~~)
type
  TMainAppForm = class(TForm)
    // ... существующие компоненты ...
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FDialog: TCustomDialogPanel;
    procedure ShowMessage(const Msg: string);
    procedure ShowConfirm(const Msg: string; Callback: TProc<Boolean>);
  end;

implementation

procedure TMainAppForm.FormCreate(Sender: TObject);
begin
  // ... существующий код ...

  // Создаем диалог один раз
  FDialog := TCustomDialogPanel.Create(Self);
end;

// Вспомогательные методы для удобства
procedure TMainAppForm.ShowMessage(const Msg: string);
begin
  FDialog.ShowInfo('Сообщение', Msg);
end;

procedure TMainAppForm.ShowConfirm(const Msg: string; Callback: TProc<Boolean>);
begin
  FDialog.ShowConfirm(
    'Подтверждение',
    Msg,
    procedure(Result: TDialogResult)
    begin
      if Assigned(Callback) then
        Callback(Result = drOk);
    end
  );
end;

// Пример использования в существующем коде
procedure TMainAppForm.SpeedButtonClearFormClick(Sender: TObject);
begin
  if FCurrentStudyID > 0 then
  begin
    ShowConfirm(
      'Форма не пуста',
      'Очистить все поля?',
      procedure(Confirmed: Boolean)
      begin
        if Confirmed then
          ClearAllFields;  // существующий метод очистки
      end
    );
  end
  else
    ClearAllFields;
end;
~~~)

## 4. Расширение функциональности
### 4.1. Добавление таймера автозакрытия

~~~)
// Добавьте в класс TCustomDialogPanel:
private
  FAutoCloseTimer: TTimer;
  FAutoCloseSeconds: Integer;

procedure TCustomDialogPanel.StartAutoClose(Seconds: Integer);
begin
  FAutoCloseSeconds := Seconds;
  if FAutoCloseTimer = nil then
  begin
    FAutoCloseTimer := TTimer.Create(Self);
    FAutoCloseTimer.OnTimer := AutoCloseTimer;
  end;
  FAutoCloseTimer.Interval := Seconds * 1000;
  FAutoCloseTimer.Enabled := True;
end;

procedure TCustomDialogPanel.AutoCloseTimer(Sender: TObject);
begin
  FAutoCloseTimer.Enabled := False;
  CloseDialog(drOk);
end;
~~~)

### 4.2. Кастомизация размеров

~~~)
procedure TCustomDialogPanel.SetSize(AWidth, AHeight: Integer);
begin
  FPanel.Width := AWidth;
  FPanel.Height := AHeight;
  PositionPanel;
  // Пересчитать позиции кнопок и текста
  FBtnOk.Position.X := AWidth - 120;
  FBtnOk.Position.Y := AHeight - 45;
  FMemoInfo.Height := AHeight - 120;
end;
~~~)

### 4.3. Добавление звукового сопровождения

~~~)
uses
  FMX.Media;

procedure TCustomDialogPanel.PlaySoundForType(DialogType: TDialogType);
begin
  case DialogType of
    dtInfo: PlaySound('info.wav');
    dtWarning: PlaySound('warning.wav');
    dtError: PlaySound('error.wav');
    dtConfirm: PlaySound('confirm.wav');
  end;
end;
~~~)

## 5. Рекомендации по использованию:
> 1.  Один экземпляр на форму: Создавайте один экземпляр TCustomDialogPanel в главной форме и используйте его для всех диалогов. Это экономит ресурсы и обеспечивает единообразие.<br>
> 2.  Асинхронность: Всегда используйте callback-функции. Никогда не ждите синхронно результат диалога - это заблокирует интерфейс.<br>
> 3.  Обработка ошибок: В callback-функциях обязательно используйте try-except, так как они выполняются асинхронно.<br>
> 4.  Не злоупотребляйте анимацией: Для критических сообщений об ошибках можно убрать анимацию, чтобы они отображались мгновенно.<br>
> 5.  Локализация: Вынесите тексты кнопок в ресурсы или константы для возможности перевода.<br>

#### Этот модуль готов к использованию в production-окружении и значительно улучшит пользовательский интерфейс вашего приложения.
