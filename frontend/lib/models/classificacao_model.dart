class ClassificacaoModel {
  final int id; // A NOVA CHAVE MESTRA: O ID real do banco
  final String nomeDaEquipe;
  final int notaRound1;
  final int notaRound2;
  final int notaRound3;
  final int notaTotal;

  ClassificacaoModel({
    required this.id,
    required this.nomeDaEquipe,
    required this.notaRound1,
    required this.notaRound2,
    required this.notaRound3,
    required this.notaTotal,
  });

  factory ClassificacaoModel.fromJson(Map<String, dynamic> json) {
    return ClassificacaoModel(
      // Tratamento de segurança: busca 'id' ou 'equipeId' dependendo de como o Java envia
      id: json['id'] ?? json['equipeId'] ?? 0, 
      nomeDaEquipe: json['nomeDaEquipe'] ?? 'Equipe Desconhecida',
      notaRound1: json['notaRound1'] ?? 0,
      notaRound2: json['notaRound2'] ?? 0,
      notaRound3: json['notaRound3'] ?? 0,
      notaTotal: json['notaTotal'] ?? 0,
    );
  }
}