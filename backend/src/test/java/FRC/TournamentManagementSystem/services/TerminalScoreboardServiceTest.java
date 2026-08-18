package FRC.TournamentManagementSystem.services;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.Test;

import FRC.TournamentManagementSystem.dtos.ClassificacaoDTO;

class TerminalScoreboardServiceTest {

    @Test
    void deveFormatarDashboardComCabecalhoEListaDePontuacoes() {
        TerminalScoreboardService service = new TerminalScoreboardService();

        List<ClassificacaoDTO> ranking = List.of(
                new ClassificacaoDTO("Equipe A", 10, 20, 30, 60, 1L),
                new ClassificacaoDTO("Equipe B", 15, 25, 10, 50, 2L)
        );

        String dashboard = service.buildDashboard(ranking, List.of(), "Nenhuma pontuação enviada ainda.");

        assertTrue(dashboard.contains("PAINEL DE CONTROLE"));
        assertTrue(dashboard.contains("Equipe A"));
        assertTrue(dashboard.contains("Equipe B"));
        assertTrue(dashboard.contains("ÚLTIMAS ATUALIZAÇÕES"));
    }
}
