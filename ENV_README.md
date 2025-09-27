Environment variables

This project uses `flutter_dotenv` to load environment variables from a `.env` file at project root. A `.env.example` is provided—copy it to `.env` and fill in your real API keys before running.

Steps:

1. Copy the example file:

   cp .env.example .env

2. Edit `.env` and replace placeholders with your real API keys (do not commit `.env`).

3. The app already loads `.env` in `lib/main.dart` using `dotenv.load(fileName: '.env')`.

4. Run the app as usual:

```powershell
flutter pub get; flutter run
```

Notes:
- `.env` is already present in `.gitignore` in this repo, so it will not be committed.
- The code falls back to the previous hardcoded API key if `OPENWEATHER_API_KEY` is missing; however for production please set a valid key in `.env`.