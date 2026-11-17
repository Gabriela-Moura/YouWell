<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';
requirePost();

$pdo = database();
requireAdmin($pdo);

$idSetor = positivePostInt('id_setor');
$idGerente = positivePostInt('id_gerente');
$nome = trim((string) ($_POST['nome'] ?? ''));

if ($nome === '') {
    sendJson(['success' => false, 'mensagem' => 'Informe o nome do setor.'], 400);
}

try {
    $pdo->beginTransaction();

    $setorStatement = $pdo->prepare(
        'SELECT id_setor FROM setores WHERE id_setor = :id_setor FOR UPDATE'
    );
    $setorStatement->execute(['id_setor' => $idSetor]);
    if (!$setorStatement->fetch()) {
        $pdo->rollBack();
        sendJson(['success' => false, 'mensagem' => 'Setor não encontrado.'], 404);
    }

    $gerenteStatement = $pdo->prepare(
        "SELECT id_usuario
         FROM usuarios
         WHERE id_usuario = :id_usuario
           AND LOWER(TRIM(papel)) = 'gerente'"
    );
    $gerenteStatement->execute(['id_usuario' => $idGerente]);
    if (!$gerenteStatement->fetch()) {
        $pdo->rollBack();
        sendJson(['success' => false, 'mensagem' => 'Gerente responsável inválido.'], 422);
    }

    $updateStatement = $pdo->prepare(
        'UPDATE setores
         SET nome = :nome, id_gerente = :id_gerente
         WHERE id_setor = :id_setor'
    );
    $updateStatement->execute([
        'nome' => $nome,
        'id_gerente' => $idGerente,
        'id_setor' => $idSetor,
    ]);

    $pdo->commit();
    sendJson(['success' => true, 'mensagem' => 'Setor atualizado com sucesso.']);
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Falha ao atualizar setor: ' . $error->getMessage());
    sendJson(['success' => false, 'mensagem' => 'Não foi possível atualizar o setor.'], 500);
}
