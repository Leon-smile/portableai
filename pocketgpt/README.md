# PocketGPT (Phase 1 starter)

Free, offline, local-only chat assistant. This drop contains the Flutter app
(shared UI, engine interface, Windows/web engine, simple storage), the
flash-drive launcher, and one unit test.

**Not done yet:** the Android on-device engine (Phase 7), SQLite multi-chat
history (Phase 6), RAM-based model tiers (Phase 9). On Android the app shows
"engine not built yet" instead of faking answers.

## 1. Create the Flutter project (PowerShell)

```powershell
flutter create --platforms=windows,android,web pocketgpt
```

Copy this folder's `pubspec.yaml`, `lib/` and `test/` over the new project,
then:

```powershell
cd pocketgpt
flutter pub get
flutter analyze
flutter test
```

## 2. Build the web UI (works offline)

```powershell
flutter build web --release --no-web-resources-cdn
```

## 3. Lay out the flash drive (format it exFAT)

```
E:\PocketGPT\
  Start-PocketGPT.bat
  App\llama-server.exe        (+ the DLLs that came with it)
  App\web\                    <- copy everything from build\web here
  Models\<your-model>.gguf
  Data\  Config\  Logs\
```

- **Get llama.cpp:** download the latest Windows CPU build from the
  llama.cpp GitHub releases page and copy `llama-server.exe` and its DLLs
  into `App\`.
- **Get a model:** download a Qwen3 4B Instruct GGUF at Q4_K_M from
  Hugging Face into `Models\`. For a 12GB laptop keep `-c 4096` or lower
  it to `-c 2048` in the .bat.

## 4. Run

Double-click `Start-PocketGPT.bat`. It starts the engine on 127.0.0.1,
waits until the model is loaded, then opens the browser.

## Windows desktop app (optional)

Start the engine with the .bat, then `flutter run -d windows`.

## Notes

- Threads are set to 6 (your CPU's physical cores). Benchmark 6 vs 8 later.
- Use an Instruct variant that does not print `<think>` blocks, or the
  reasoning text will show up in the chat.
