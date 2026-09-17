# Abrir no VS Code

Abra a pasta raiz do repositório no VS Code e instale a extensão Flutter.

```sh
flutter pub get
flutter devices
flutter run -d chrome
```

Para Android, restaure `android/app/google-services.json` pelo console Firebase do proprietário, conecte o aparelho com depuração USB e execute `flutter run -d ID_DO_APARELHO`.

Veja README.md para recursos e docs/PUBLICAR_WEB.md para publicação. Arquivos privados em `.release/` são necessários somente para tarefas administrativas e assinatura da release Android.
