# Hierarquia visual

```text
ANDERFIT
├── Abertura: fundo preto, logo e Força, foco, evolução
├── Login: usuário e senha
│   └── Primeiro acesso: nova senha, altura, peso e objetivo
├── Aluno
│   ├── Início: saudação, resumo semanal, meta e água
│   ├── Treino: exercícios, execução, descanso e conclusão
│   ├── Aulas
│   │   ├── Masculino → Iniciante / Intermediário / Avançado
│   │   ├── Feminino → Iniciante / Intermediário / Avançado
│   │   ├── Treino em casa → Masculino / Feminino
│   │   ├── Adaptação
│   │   └── Receitas
│   ├── Evolução: medidas, gráfico, metas e histórico
│   └── Perfil: altura, peso, objetivo e sair
└── Personal
    ├── Painel: selecionar aluno, resumo e atualizar
    ├── Contas: cadastrar, redefinir senha e excluir com confirmação
    ├── Treino: prescrever e editar exercícios e links
    ├── Evolução e Perfil: acompanhar o aluno selecionado
    └── Notificações: enviar aos aparelhos Android
```

Em celulares: navegação inferior, botões largos e conteúdo em uma coluna. Em telas de pelo menos 900 px: menu lateral, conteúdo central com largura controlada e contato acessível. O visual, cores, logo e fontes são compartilhados com o Android.

## Organização do repositório

```text
anderfitt/
├── src/
│   ├── lib/            # Telas e acesso ao Supabase
│   ├── web/            # Entrada HTML, abertura e PDF.js
│   ├── assets/         # Logo, fontes e 59 PDFs
│   ├── test/           # Testes da interface
│   ├── third_party/    # Leitor PDF com licença e ajuste local
│   └── pubspec.yaml    # Dependências da versão web
├── backend/supabase/   # Funções, migrações e testes de acesso
├── docs/               # Desenvolvimento e publicação
├── scripts/            # Verificações de segurança e pacote
├── .github/workflows/  # Validação e publicação automática
└── README.md
```

`src/build/web/` é gerado pela compilação e é a única pasta publicada. Caches, prévias, builds e credenciais são ignorados pelo Git. O projeto Android original não foi movido nem alterado.