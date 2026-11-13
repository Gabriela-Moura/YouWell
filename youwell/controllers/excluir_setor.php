<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';
requirePost();

$pdo = database();
requireAdmin($pdo);
$idSetor = positivePostInt('id_setor');

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

    $referencias = $pdo->query(
        "SELECT TABLE_NAME, COLUMN_NAME
         FROM information_schema.KEY_COLUMN_USAGE
         WHERE TABLE_SCHEMA = DATABASE()
           AND REFERENCED_TABLE_NAME = 'setores'
           AND REFERENCED_COLUMN_NAME = 'id_setor'
           AND TABLE_NAME <> 'setores'"
    )->fetchAll();

    foreach ($referencias as $referencia) {
        $tabela = str_replace('`', '``', (string) $referencia['TABLE_NAME']);
        $coluna = str_replace('`', '``', (string) $referencia['COLUMN_NAME']);
        $relacionado = $pdo->prepare(
            "SELECT 1 FROM `{$tabela}` WHERE `{$coluna}` = :id_setor LIMIT 1"
        );
        $relacionado->execute(['id_setor' => $idSetor]);

        if ($relacionado->fetchColumn() !== false) {
            $pdo->rollBack();
            sendJson([
                'success' => false,
                'mensagem' => 'Não é possível excluir: existem registros relacionados ao setor.',
            ], 409);
        }
    }

    $deleteStatement = $pdo->prepare(
        'DELETE FROM setores WHERE id_setor = :id_setor'
    );
    $deleteStatement->execute(['id_setor' => $idSetor]);

    $pdo->commit();
    sendJson(['success' => true, 'mensagem' => 'Setor excluído com sucesso.']);
} catch (PDOException $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Falha ao excluir setor: ' . $error->getMessage());

    if ($error->getCode() === '23000') {
        sendJson([
            'success' => false,
            'mensagem' => 'Não é possível excluir: existem registros relacionados ao setor.',
        ], 409);
    }

    sendJson(['success' => false, 'mensagem' => 'Não foi possível excluir o setor.'], 500);
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Falha ao excluir setor: ' . $error->getMessage());
    sendJson(['success' => false, 'mensagem' => 'Não foi possível excluir o setor.'], 500);
}
