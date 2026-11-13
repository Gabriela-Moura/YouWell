# Backend de setores

Os arquivos desta pasta devem ser publicados em
`https://devsbee.com.br/You-Well/controllers/` junto aos demais controllers.

Configure no ambiente PHP:

- `DB_HOST`, `DB_NAME`, `DB_USER` e `DB_PASSWORD`
- `DB_PASSWORD_COLUMN` (opcional; padrão `senha`)
- `CORS_ALLOW_ORIGIN` (opcional; padrão `https://devsbee.com.br`)

O código usa MySQL/MariaDB com as tabelas `setores(id_setor, nome, id_gerente)`
e `usuarios(id_usuario, nome, papel, senha)`. A senha do usuário deve estar
armazenada com `password_hash()`. Os endpoints de alteração exigem `admin_nome`
e `admin_senha` e validam o papel `admin` no servidor.

`buscar_setor.php` mantém as respostas `nome_setor` e `setores` usadas pelo app
e inclui `id_gerente` na listagem. A exclusão verifica as chaves estrangeiras
do banco e recusa a operação quando encontra registros relacionados.
