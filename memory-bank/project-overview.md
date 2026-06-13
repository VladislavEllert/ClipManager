# ClipManager — обзор проекта

## Что это

Менеджер истории буфера обмена для macOS — аналог `Win+V` из Windows (которого в macOS нет).
Фоновый агент в строке меню (`LSUIElement`, без иконки в Dock). По глобальному хоткею
(`⌘⇧V`) открывает компактное окно в стиле Liquid Glass со всей историей копирований
(текст, RTF, изображения, файлы), выбираешь элемент — вставляется в активное приложение.

## Зачем

macOS хранит только последнее скопированное. Перенести несколько фрагментов = повторять
«копировать → вставить». ClipManager хранит историю и даёт листать/вставлять любой элемент.

## Архитектура (файлы `ClipManager/ClipManager/`)

| Файл | Ответственность |
|------|-----------------|
| `ClipManagerApp.swift` | `@main`, App + `NSApplicationDelegateAdaptor` |
| `AppDelegate.swift` | menu bar (`NSStatusItem`), хоткей, single-instance, оркестрация вставки |
| `AppSettings.swift` | `@Observable`, настройки в `UserDefaults` (лимит, хоткей, флаги) |
| `ClipboardMonitor.swift` | опрос `NSPasteboard.changeCount`, классификация типов, пропуск паролей |
| `ClipboardItem.swift` | модель элемента (`Codable`) |
| `HistoryStore.swift` | `@Observable`, дедуп, лимит, pin, `onChange` |
| `Storage.swift` | JSON-метаданные + PNG-блобы в Application Support |
| `HotKeyCenter.swift` | глобальный хоткей через Carbon `RegisterEventHotKey` |
| `HotKeyRecorder.swift` | запись хоткея в настройках (`NSViewRepresentable`) |
| `PasteService.swift` | запись в буфер + авто-вставка через `CGEvent`, гейт Accessibility |
| `PanelController.swift` | плавающее изменяемое окно (`NSPanel`), live-refresh |
| `PopupModel.swift` | состояние окна (поиск, выбор), `@Observable` |
| `PopupView.swift` | SwiftUI список, Liquid Glass, переключатели фич, контекст-меню |
| `SettingsView.swift` | окно настроек |
| `SettingsWindowController.swift` | хост окна настроек |
| `LaunchAtLogin.swift` | автозагрузка через `SMAppService` |

## Стек

`SwiftUI` · `AppKit (NSPanel / NSStatusItem)` · `Carbon (RegisterEventHotKey)` ·
`CGEvent` · `NSPasteboard` · `CryptoKit (SHA-256 для дедупа)` · `SMAppService` · `UserDefaults`.
Без сторонних зависимостей.

## Конфигурация

- Deployment target **macOS 26** (используется Liquid Glass: `.glassEffect`, `.buttonStyle(.glass)`).
- `LSUIElement = YES` (фоновый агент). App Sandbox выключен.
- Подпись: **Team** (Automatic, `DEVELOPMENT_TEAM = 6J6NRLV7AQ`) — стабильна, Accessibility держится.

## Хранение

`~/Library/Application Support/ClipManager/` — `history.json` (метаданные) + `blobs/<uuid>.png`
(картинки). Файлы хранятся **по пути** (не копируются).

## Разрешения

- **Accessibility** — только для авто-вставки (`CGEvent` эмулирует `⌘V`). Чтение буфера и хоткей — без него.

## Окружение разработки

MacBook Air M5, macOS 26.5.1, Xcode 26.5, Swift 6.3.2 (язык-режим Swift 5).
