<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';
requirePost();

try {
    $pdo = database();

    if (isset($_POST['id_setor']) && trim((string) $_POST['id_setor']) !== '') {
        $idSetor = positivePostInt('id_setor');
        $statement = $pdo->prepare(
            'SELECT id_setor, nome, id_gerente FROM setores WHERE id_setor = :id_setor'
        );
        $statement->execute(['id_setor' => $idSetor]);
        $setor = $statement->fetch();

        if (!$setor) {
            sendJson(['success' => false, 'mensagem' => 'Setor não encontrado.'], 404);
        }

        sendJson([
            'success' => true,
            'nome_setor' => $setor['nome'],
            'setores' => [$setor],
        ]);
    }

    $idUsuario = trim((string) ($_POST['id_usuario'] ?? ''));
    if ($idUsuario !== '') {
        $idUsuario = positivePostInt('id_usuario');
        $userStatement = $pdo->prepare(
            'SELECT papel FROM usuarios WHERE id_usuario = :id_usuario'
        );
        $userStatement->execute(['id_usuario' => $idUsuario]);
        $papel = $userStatement->fetchColumn();

        if ($papel === false) {
            sendJson(['success' => false, 'mensagem' => 'Usuário não encontrado.'], 404);
        }

        $papel = strtolower(trim((string) $papel));
        if ($papel === 'gerente') {
            $statement = $pdo->prepare(
                'SELECT id_setor, nome, id_gerente
                 FROM setores
                 WHERE id_gerente = :id_gerente
                 ORDER BY nome'
            );
            $statement->execute(['id_gerente' => $idUsuario]);
        } elseif ($papel === 'admin') {
            $statement = $pdo->query(
                'SELECT id_setor, nome, id_gerente FROM setores ORDER BY nome'
            );
        } else {
            sendJson(['success' => false, 'mensagem' => 'Acesso não permitido.'], 403);
        }
    } else {
        $statement = $pdo->query(
            'SELECT id_setor, nome, id_gerente FROM setores ORDER BY nome'
        );
    }

    sendJson(['success' => true, 'setores' => $statement->fetchAll()]);
} catch (Throwable $error) {
    error_log('Falha ao buscar setores: ' . $error->getMessage());
    sendJson(['success' => false, 'mensagem' => 'Não foi possível buscar os setores.'], 500);
}
