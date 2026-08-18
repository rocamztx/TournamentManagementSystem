package FRC.TournamentManagementSystem.services;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.stereotype.Service;

import FRC.TournamentManagementSystem.dtos.ClassificacaoDTO;

@Service
public class TerminalScoreboardService {

    private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("dd/MM HH:mm:ss");
    private final List<String> logEntries = new CopyOnWriteArrayList<>();

    public TerminalScoreboardService() {
    }

    public void registrarAtualizacao(String equipe, int round, int pontos, double tempo, List<ClassificacaoDTO> ranking) {
        String entry = String.format("[%s] ROUND %d | Equipe: %s | Pontos: %d | Tempo: %.1f s",
                LocalDateTime.now().format(TIMESTAMP_FORMAT), round, equipe, pontos, tempo);
        logEntries.add(0, entry);
        while (logEntries.size() > 12) {
            logEntries.remove(logEntries.size() - 1);
        }
        System.out.println("\n[PAINEL] " + entry);
        System.out.println("[PAINEL] Status: nova pontuação registrada com sucesso.");
        System.out.println(buildDashboard(ranking, getRecentUpdates(), "Nenhuma pontuação enviada ainda."));
        System.out.flush();
    }

    public String buildDashboard(List<ClassificacaoDTO> ranking, List<String> updates, String emptyMessage) {
        StringBuilder builder = new StringBuilder();
        builder.append("\n========================================");
        builder.append("\n           PAINEL DE CONTROLE");
        builder.append("\n========================================");
        builder.append("\nStatus: monitor ativo");
        builder.append("\nTotal de equipes: ").append(ranking.size());
        builder.append("\n");
        builder.append("\nRANKING ATUAL");
        builder.append("\n----------------------------------------");
        if (ranking.isEmpty()) {
            builder.append("\nNenhuma equipe cadastrada.");
        } else {
            for (int i = 0; i < ranking.size(); i++) {
                ClassificacaoDTO equipe = ranking.get(i);
                builder.append("\n").append(i + 1).append(". ")
                        .append(equipe.nomeDaEquipe())
                        .append(" | R1: ").append(equipe.notaRound1())
                        .append(" | R2: ").append(equipe.notaRound2())
                        .append(" | R3: ").append(equipe.notaRound3())
                        .append(" | TOTAL: ").append(equipe.notaTotal());
            }
        }

        builder.append("\n\nÚLTIMAS ATUALIZAÇÕES");
        builder.append("\n----------------------------------------");
        if (updates == null || updates.isEmpty()) {
            builder.append("\n").append(emptyMessage);
        } else {
            for (String update : updates) {
                builder.append("\n").append(update);
            }
        }
        builder.append("\n========================================\n");
        return builder.toString();
    }

    public List<String> getRecentUpdates() {
        return new ArrayList<>(logEntries);
    }
}
