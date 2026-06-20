package FRC.TournamentManagementSystem.dtos;

public record ClassificacaoDTO(
    String nomeDaEquipe,
    int notaRound1,
    int notaRound2,
    int notaRound3,
    int notaTotal,
    Long id
) {}