# Desenvolver o site

Abra a raiz do repositório no VS Code e instale a extensão Flutter. A configuração de execução aponta para `src/` e inicia no Chrome.

No terminal da raiz:

```sh
cd src
flutter pub get
flutter run -d chrome
```

Use Flutter 3.47.0. Para validar mudanças, execute `flutter analyze` e `flutter test` dentro de `src/`.

O projeto é exclusivo da web. Não gere APK a partir desta pasta. O projeto Android original continua separado.

## Dependências do leitor PDF

`src/third_party/pdfx/` contém a biblioteca de leitura com o ajuste utilizado pelo ANDERFIT. A declaração do plugin inclui somente web. Alguns arquivos Dart compartilhados da biblioteca permanecem porque fazem parte dos seus imports; os projetos nativos, ferramentas de geração e testes do fornecedor foram retirados.

`src/web/vendor/pdfjs/` contém PDF.js e seus recursos locais, necessários para renderizar a biblioteca. As licenças dos fornecedores foram preservadas. Não retire esses arquivos apenas por serem numerosos.

## Servidor

`backend/supabase/` documenta o servidor compartilhado com o Android. Reorganizar estas pastas não altera o banco remoto. As migrações iniciais não devem ser reaplicadas no projeto existente.

Não configure Firebase no navegador. O envio de notificações pelo personal continua usando a função do servidor, sem dependência Firebase no cliente web.
