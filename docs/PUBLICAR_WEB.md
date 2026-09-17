# Publicar ANDERFIT Web no GitHub Pages

Endereço de produção: https://yoyoziyo.github.io/anderfitt/

## Configuração

Em Settings → Pages → Build and deployment → Source, escolha **GitHub Actions**. O site é compilado e publicado pelo workflow ANDERFIT Web; não publique a raiz de main, pois ela contém o código-fonte.

Não é necessário token de hospedagem nem conta Cloudflare. O workflow usa o token temporário fornecido pelo próprio GitHub, com permissão de publicação apenas no job deploy.

## Publicação automática

1. Cada alteração em main executa análise, testes, compilação e conferência do pacote.
2. O Flutter compila com `--base-href /anderfitt/` para o endereço deste repositório.
3. Somente `src/build/web/` é enviado como pacote do Pages.
4. O job deploy publica após o build passar.

Pull requests são verificados e compilados, mas não publicam. Também é possível executar Actions → ANDERFIT Web → Run workflow.

## Compilar manualmente

```sh
cd src
flutter pub get
flutter build web --release --base-href /anderfitt/ --no-web-resources-cdn --no-source-maps
cd ..
node scripts/check-web.mjs /anderfitt/
```

O pacote contém seu próprio index.html. Não mova o HTML de src/web para a raiz, pois ele é um modelo que precisa da compilação Flutter.

## Antes de distribuir

- Testar login, primeiro acesso, treino, medidas e hidratação.
- Conferir os resultados no painel do personal.
- Abrir PDFs, avançar e voltar páginas, inclusive no livro de receitas.
- Conferir vídeos, WhatsApp, teclado e retorno ao site.
- Validar no Safari de um iPhone real.

O site não solicita notificações web. Os dados dos alunos ficam no Supabase com autenticação e regras de acesso. Os PDFs são arquivos estáticos públicos por URL. Pastas de servidor, testes, código-fonte e credenciais não são incluídas na publicação.

GitHub Pages não aplica o arquivo `_headers`; a proteção dos dados dos alunos depende da autenticação e das regras do Supabase, e o site usa HTTPS.
