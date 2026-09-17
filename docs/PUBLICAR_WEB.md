# Publicar ANDERFIT Web

A hospedagem proposta é Cloudflare Pages, com o projeto mantido no GitHub. O Supabase continua sendo o mesmo usado no Android.

## 1. Criar a hospedagem

1. Crie ou acesse uma conta Cloudflare gratuita.
2. Abra Workers & Pages e crie um projeto Pages por **Direct Upload** chamado `anderfit` (ou outro nome disponível). O workflow do GitHub enviará o pacote pronto; a Cloudflare não precisa instalar Flutter.
3. Copie o **Account ID** da conta e o nome exato do projeto.
4. Crie um API Token com permissão **Account / Cloudflare Pages / Edit**, restrita à conta usada.

## 2. Configurar o repositório

Em GitHub → Settings → Secrets and variables → Actions:

**Secret:**

- `CLOUDFLARE_API_TOKEN`: token com permissão para publicar em Pages.

**Variables:**

- `CLOUDFLARE_ACCOUNT_ID`: ID da conta Cloudflare.
- `CLOUDFLARE_PAGES_PROJECT`: nome exato do projeto Pages.

Não é necessário configurar senhas de alunos, chave administrativa do Supabase ou conta de serviço Firebase no GitHub.

## 3. Publicar

1. Abra Actions → ANDERFIT Web → Run workflow → main.
2. A execução analisa, testa, compila e publica se as três configurações estiverem preenchidas.
3. Abra o endereço HTTPS fornecido pela Cloudflare (`https://NOME.pages.dev`).
4. Teste o login do personal e de um aluno de teste no Safari do iPhone.

A cada alteração enviada para main, o mesmo processo será repetido. Pull requests são testados e compilados, mas não publicam a versão de produção.

## 4. Conferir antes de entregar

- As mesmas contas entram no Android e no site.
- As alterações do aluno aparecem no painel do personal ao atualizar.
- Cada aluno vê somente os próprios dados.
- Os 59 PDFs abrem dentro do leitor; testar também o livro de receitas, que é maior.
- Vídeos e WhatsApp abrem após um toque.
- Nenhuma solicitação de notificação é mostrada no navegador.
- Logo, teclado, rolagem e navegação ficam corretos no Safari.

A biblioteca publicada é formada por arquivos estáticos acessíveis por URL; o login protege os dados dos alunos no Supabase, mas não torna os PDFs privados. Se no futuro os materiais precisarem de acesso restrito, usar entrega autenticada no servidor.

## Sem configurar a Cloudflare ainda

A execução continua produzindo o artefato `anderfit-web`. Ele pode ser baixado para revisão ou enviado manualmente por Wrangler. O repositório preparado não equivale a um site já publicado.
