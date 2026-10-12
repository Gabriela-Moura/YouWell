// BANCO DE DADOS SIMULADO

List<Map<String, dynamic>> setores = [
  {
    "id": 1,
    "nome": "Setor A",
  },
  {
    "id": 2,
    "nome": "Setor B",
  },
  {
    "id": 3,
    "nome": "Setor C",
  },
];


List<Map<String, dynamic>> usuarios = [
  {
    "id": 1,
    "nome": "Admin",
    "senha": "1234",
    "papel": "admin",
    "setor": null,
  },
  {
    "id": 2,
    "nome": "Carlos",
    "senha": "1234",
    "papel": "gerente",
    "setor": 1,
  },
  {
    "id": 3,
    "nome": "Maria",
    "senha": "5678",
    "papel": "gerente",
    "setor": 2,
  },
  {
    "id": 4,
    "nome": "João",
    "senha": "abcd",
    "papel": "gerente",
    "setor": 3,
  },
  {
    "id": 5,
    "nome": "Gabriela",
    "senha": "efgh",
    "papel": "ti",
    "setor": 1,
  },
];

List<Map<String, dynamic>> sensores = [
  {
    "id": 1,
    "setor": 1,
    "data": "24/01",
    "hora": "08:00",
    "temperatura": 24.5,
    "ruido": 60,
    "ar": 50,
  },

  {
    "id": 2,
    "setor": 1,
    "data": "24/01",
    "hora": "09:00",
    "temperatura": 25.2,
    "ruido": 61,
    "ar": 51,
  },

  {
    "id": 3,
    "setor": 2,
    "data": "24/01",
    "hora": "08:00",
    "temperatura": 23.5,
    "ruido": 55,
    "ar": 45,
  },
  {
    "id": 4,
    "setor": 3,
    "data": "24/01",
    "hora": "08:00",
    "temperatura": 26.0,
    "ruido": 63,
    "ar": 52,
  },
];