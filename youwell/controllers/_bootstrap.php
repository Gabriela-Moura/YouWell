<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header(
    'Access-Control-Allow-Origin: ' .
    (getenv('CORS_ALLOW_ORIGIN') ?: 'https://devsbee.com.br')
);
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Accept, Content-Type');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function sendJson(array $data, int $status = 200): void
{
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function requirePost(): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        sendJson(['success' => false, 'mensagem' => 'Método não permitido.'], 405);
    }
}

function database(): PDO
{
    $host = getenv('DB_HOST');
    $name = getenv('DB_NAME');
    $user = getenv('DB_USER');
    $password = getenv('DB_PASSWORD');

    if (!$host || !$name || !$user || $password === false) {
        sendJson(['success' => false, 'mensagem' => 'Banco de dados não configurado.'], 500);
    }

    try {
        return new PDO(
            "mysql:host={$host};dbname={$name};charset=utf8mb4",
            $user,
            $password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
    } catch (PDOException $error) {
        error_log('Falha ao conectar ao banco do YouWell: ' . $error->getMessage());
        sendJson(['success' => false, 'mensagem' => 'Não foi possível conectar ao banco.'], 500);
    }
}

function requireAdmin(PDO $pdo): void
{
    $name = trim((string) ($_POST['admin_nome'] ?? ''));
    $password = (string) ($_POST['admin_senha'] ?? '');
    $passwordColumn = getenv('DB_PASSWORD_COLUMN') ?: 'senha';

    if ($name === '' || $password === '') {
        sendJson(['success' => false, 'mensagem' => 'Confirme a senha do administrador.'], 401);
    }

    if (!preg_match('/\A[a-zA-Z0-9_]+\z/', $passwordColumn)) {
        sendJson(['success' => false, 'mensagem' => 'Coluna de senha inválida.'], 500);
    }

    $statement = $pdo->prepare(
        "SELECT papel, `{$passwordColumn}` AS senha_hash
         FROM usuarios
         WHERE nome = :nome"
    );
    $statement->execute(['nome' => $name]);
    $users = $statement->fetchAll();

    if (
        count($users) !== 1 ||
        strtolower(trim((string) $users[0]['papel'])) !== 'admin' ||
        !password_verify($password, (string) $users[0]['senha_hash'])
    ) {
        sendJson(['success' => false, 'mensagem' => 'Administrador ou senha inválidos.'], 401);
    }
}

function positivePostInt(string $field): int
{
    $value = filter_var($_POST[$field] ?? null, FILTER_VALIDATE_INT);
    if ($value === false || $value === null || $value < 1) {
        sendJson(['success' => false, 'mensagem' => 'Dados do setor inválidos.'], 400);
    }

    return $value;
}
