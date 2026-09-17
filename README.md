# ANDERFIT Web

Versão web do ANDERFIT, com visual preto e laranja e as mesmas contas e dados do aplicativo Android no Supabase. Este repositório contém apenas o projeto do site. O projeto Android e sua assinatura são mantidos separadamente.

## Organização

- `src/`: interface Flutter Web, recursos, PDFs e testes.
- `backend/supabase/`: regras de acesso, migrações, funções e testes do servidor.
- `docs/`: estrutura visual, desenvolvimento e publicação.
- `scripts/`: verificações do repositório e do pacote publicado.
- `.github/workflows/`: análise, testes, compilação e publicação automática.

O `index.html` fica em `src/web/`. A interface é escrita em Dart em `src/lib/` e compilada para JavaScript. O resultado publicado fica em `src/build/web/`; as pastas de servidor, testes e código-fonte não são publicadas.

## Funcionalidades

- Login individual, troca obrigatória da senha temporária e bloqueio após três erros.
- Primeiro acesso, perfil, treino individual, histórico, medidas, metas e hidratação.
- Painel do personal para cadastrar/excluir alunos, redefinir senhas, prescrever treinos e acompanhar resultados.
- Biblioteca com 59 PDFs e leitor interno com zoom e troca de páginas.
- Layout para celular e computador e contato pelo WhatsApp.

Fotos de evolução estão indisponíveis. O site não inicializa Firebase nem solicita notificações do navegador. O personal pode enviar notificações pelo servidor aos alunos que utilizam Android.

## Desenvolvimento

Use Flutter **3.47.0** e a extensão Flutter do VS Code.

```sh
cd src
flutter pub get
flutter run -d chrome
```

Veja [desenvolvimento](docs/DESENVOLVER.md), [estrutura](docs/ESTRUTURA.md) e [publicação](docs/PUBLICAR_WEB.md).

## Verificar e compilar

Na raiz do repositório:

```sh
node scripts/check-secrets.mjs
cd src
flutter analyze
flutter test
flutter build web --release --base-href /anderfitt/ --no-web-resources-cdn --no-source-maps
cd ..
node scripts/check-web.mjs /anderfitt/
```

Endereço: https://yoyoziyo.github.io/anderfitt/. A publicação utiliza somente `src/build/web/`. O workflow gera o artefato `anderfit-web` e publica automaticamente no GitHub Pages após a validação. O site precisa de conexão; os PDFs são carregados ao abrir cada material.

## Segurança e dados

A autenticação e as regras do Supabase protegem os dados individuais dos alunos. A URL e a chave publicável do cliente são públicas e não concedem acesso administrativo. Chaves administrativas, senhas, tokens, arquivos de assinatura e contas de serviço não pertencem a este repositório.

O projeto remoto já está configurado. Não reaplique as migrações iniciais no banco existente. As funções do servidor ficam em `backend/supabase/`; seus segredos permanecem no ambiente do servidor.

Os PDFs publicados são arquivos estáticos acessíveis por URL. Eles não contêm registros privados de alunos; o login não torna essa biblioteca privada.

Antes de distribuir, valide os fluxos e o leitor PDF no Safari de um iPhone real. Adicionar o site à Tela de Início não habilita notificações web.
