<div align="center">

# 📋 ClipManager

**История буфера обмена для macOS — аналог `Win+V`, которого в macOS нет из коробки.**
*Clipboard history manager for macOS — a Win+V alternative for Mac.*

![macOS](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-2396F3?logo=swift&logoColor=white)
![AppKit](https://img.shields.io/badge/AppKit-NSPanel-blue)
![Liquid Glass](https://img.shields.io/badge/style-Liquid%20Glass-7B6CF6)
![No 3rd-party](https://img.shields.io/badge/dependencies-system%20only-success)

</div>

---

## 💡 Зачем

В macOS буфер обмена хранит только **последнее** скопированное. Чтобы перенести несколько фрагментов, приходится повторять «копировать → вставить» по очереди. **ClipManager** хранит историю всего, что ты копируешь, и даёт листать её и вставлять любой прошлый элемент — как `Win+V` в Windows, только мощнее.

Фоновый агент в строке меню: по глобальному хоткею открывает компактное окно в стиле **Liquid Glass** со всей историей (текст, фото, файлы), выбираешь — вставляется в активное приложение. Без сервера, всё локально.

## ✨ Возможности

- 📥 **Захват** — текст, RTF, изображения, файлы из буфера
- 💾 **История на диске** — переживает перезапуск и перезагрузку
- ⌨️ **Глобальный хоткей** (`⌘⇧V`), настраиваемый рекордером
- ⚡ **Авто-вставка** выбранного элемента в активное окно
- 🔢 **Лимит истории 1–100** — ползунком, чтобы не грузить систему
- 🔍 **Поиск** по истории
- 📌 **Избранное** — закреплённые не вытесняются лимитом
- 🧹 **Вставка без формата** (`⌥↵`)
- 🔐 **Пропуск паролей** — игнорирует буфер от менеджеров паролей
- 🎛 **Переключатели фич прямо в окне** + окно **изменяемого размера** (запоминает размер)
- 🚀 **Автозагрузка** при входе в систему
- 🔄 **Живое обновление** списка при открытом окне

## 🏗 Архитектура

Один процесс-агент (`LSUIElement`), MVVM-ish, данные направлены к модели. Только системные фреймворки.

```
ClipManager/ClipManager/
├── ClipManagerApp.swift          точка входа (@main + NSApplicationDelegateAdaptor)
├── AppDelegate.swift             menu bar, хоткей, single-instance, оркестрация вставки
├── AppSettings.swift             настройки (UserDefaults): лимит, хоткей, флаги
├── ClipboardMonitor.swift        опрос NSPasteboard, типы, пропуск паролей
├── ClipboardItem.swift           модель элемента (Codable)
├── HistoryStore.swift            история: дедуп, лимит, pin, onChange
├── Storage.swift                 JSON-метаданные + PNG-блобы в Application Support
├── HotKeyCenter.swift            глобальный хоткей (Carbon)
├── HotKeyRecorder.swift          запись хоткея в настройках
├── PasteService.swift            буфер + авто-вставка (CGEvent), гейт Accessibility
├── PanelController.swift         плавающее изменяемое окно (NSPanel), live-refresh
├── PopupModel.swift              состояние окна (поиск, выбор)
├── PopupView.swift               UI списка, Liquid Glass, переключатели фич
├── SettingsView.swift            окно настроек
├── SettingsWindowController.swift
└── LaunchAtLogin.swift           автозагрузка (SMAppService)
```

**Принципы:** SOLID · DRY · KISS · минимум зависимостей · история только локально.

## 🧰 Технологии

`SwiftUI` · `AppKit (NSPanel / NSStatusItem)` · `Carbon (RegisterEventHotKey)` · `CGEvent` · `NSPasteboard` · `CryptoKit (SHA-256 для дедупа)` · `SMAppService` · `UserDefaults`

## ⌨️ Хоткеи

| Действие | Клавиши |
|---|---|
| Открыть / закрыть окно истории | `⌘⇧V` |
| Навигация по списку | `↑` / `↓` |
| Вставить выбранное | `Enter` |
| Вставить без формата | `⌥Enter` |
| Закрыть окно | `Esc` |
| Закрепить / удалить элемент | правый клик |

> Переключатели фич и шестерёнка настроек — в правом верхнем углу окна.

## 🔐 Разрешения

| Разрешение | Зачем |
|---|---|
| **Accessibility** | только для авто-вставки (эмуляция `⌘V` через `CGEvent`) |

Чтение буфера и хоткей работают без разрешений. Стабильная подпись (Team в Xcode) нужна, чтобы Accessibility не слетал между сборками.

## 🚀 Сборка и запуск

```bash
git clone git@github.com:VladislavEllert/ClipManager.git
cd ClipManager
open ClipManager.xcodeproj
```

В Xcode: target **ClipManager** → **Signing & Capabilities** → выбери **Team** (личный Apple ID) → **Run** (`⌘R`).
Затем выдай **Accessibility**: System Settings → Privacy & Security → Accessibility → включи ClipManager → перезапусти приложение.

## 🗺 Roadmap

- [ ] Превью больших изображений по наведению
- [ ] Опция копировать файлы в хранилище (а не хранить по пути)
- [ ] Экспорт / очистка истории по типам
- [ ] Группировка по источнику (из какого приложения скопировано)

## ⚠️ Ограничения

Личный pet-проект, не публикуется в App Store. Файлы хранятся по пути (не копируются) — перемещённый/удалённый оригинал не вставится; текст и фото не затрагиваются.

---

<div align="center">

Нативный **Swift + SwiftUI/AppKit**, без сторонних зависимостей.

`clipboard manager` · `macOS` · `Mac clipboard history` · `Win+V for Mac` · `pasteboard history` · `menu bar clipboard` · `copy/paste history` · `Swift` · `SwiftUI`

</div>
