<?php

include "conexao.php";

$nome = $_POST["nome"];

$sql = "SELECT setor FROM usuarios WHERE nome = ? AND papel = 'gerente'";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $nome);
$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows > 0) {

    $dados = $resultado->fetch_assoc();

    echo json_encode([
        "sucesso" => true,
        "setor" => $dados["setor"]
    ]);

} else {

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Gerente não encontrado"
    ]);
}
?>