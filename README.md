# ANDERFIT

Aplicativo Flutter para Android e web. Uma única base de código, visual preto e laranja e as mesmas contas e dados no Supabase.

## Recursos

- Login individual, troca obrigatória da senha temporária e bloqueio de cinco minutos após três erros.
- Primeiro acesso com altura, peso e objetivo; perfil editável.
- Treino individual com exercícios, séries, repetições, descanso, vídeo e conclusão diária.
- Medidas e gráficos de evolução, metas, histórico de treinos e hidratação.
- Painel do personal para cadastrar/excluir alunos, redefinir senhas, montar treinos e acompanhar resultados.
- Biblioteca organizada com 59 PDFs; leitor interno com zoom e botões de página.
- Contato pelo WhatsApp e atualização dos dados ao retornar ao app ou puxar a tela.
- Navegação inferior no celular e menu lateral em telas grandes.

Fotos de evolução estão indisponíveis. A versão web não solicita nem recebe notificações do navegador. O personal pode enviar notificações pelo painel web para os aparelhos Android autorizados.

## Executar

Use Flutter **3.47.0** ou uma versão compatível com o arquivo de dependências.

```sh
flutter pub get
flutter run -d chrome
```

Para Android, configure `android/app/google-services.json` a partir do projeto Firebase do proprietário e execute `flutter run` com um aparelho ou emulador conectado. O arquivo de configuração Android e a assinatura privada não estão no repositório.

## Testar e compilar o site

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-source-maps
node scripts/check-web.mjs
```

O resultado fica em `build/web`. Os PDFs são baixados quando abertos, sem baixar toda a biblioteca na entrada. A versão web precisa de conexão e não promete acesso offline. No Android, os PDFs são incorporados ao APK.

## Publicação

O workflow `.github/workflows/web.yml` analisa, testa e compila cada alteração. O pacote `anderfit-web` fica disponível nos artefatos da execução. A publicação em Cloudflare Pages será ativada quando os dados da conta forem configurados; nenhuma hospedagem é criada automaticamente.

Veja [o passo a passo de publicação](docs/PUBLICAR_WEB.md) e [a hierarquia visual](docs/ESTRUTURA.md).

## Serviços e acesso

O Supabase armazena contas, perfis, treinos, medidas, hidratação e histórico. As migrações e as Edge Functions estão em `supabase/`. O projeto remoto já está configurado; não execute novamente as migrações iniciais no banco existente.

O Firebase é utilizado apenas pelo Android e pelo servidor para notificações. O site não inicializa o Firebase no navegador.

A URL e a chave publicável do Supabase no cliente são configurações públicas; a proteção depende de autenticação e regras de acesso do servidor. Chaves administrativas, senhas de usuários, contas de serviço e arquivos de assinatura não devem entrar no Git. O workflow confere os arquivos rastreados antes da compilação.

Para releases Android, mantenha a chave de assinatura original em `.release/`. O projeto não gera uma chave substituta.

## Validação no iPhone

Antes de distribuir o site, conferir no Safari real: login, primeiro acesso, treino, medidas, hidratação, leitor PDF, vídeos, WhatsApp e retorno ao aplicativo. É possível adicionar o site à Tela de Início; isso não habilita notificações web.
