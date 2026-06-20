package FRC.TournamentManagementSystem.dtos;

public record PontuacaoInputDTO(
    Long equipeId,
    int round,
    int pontos,
    double tempo
) {}