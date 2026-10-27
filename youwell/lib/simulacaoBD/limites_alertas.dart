// LIMITES DE REFERÊNCIA DA SIMULAÇÃO
// Estes valores são configuráveis e não representam, por si só, limites legais da NR-17.

const Map<String, Map<String, double>> limitesAlertas = {
  "temperatura": {
    "minimo": 20.0,
    "maximo": 26.0,
    "margemAtencao": 2.0,
  },
  "ruido": {
    "minimo": 0.0,
    "maximo": 65.0,
    "margemAtencao": 5.0,
  },
  "ar": {
    "minimo": 0.0,
    "maximo": 70.0,
    "margemAtencao": 10.0,
  },
};