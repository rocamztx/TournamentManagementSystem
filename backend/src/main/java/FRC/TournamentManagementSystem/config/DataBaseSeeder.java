package FRC.TournamentManagementSystem.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import FRC.TournamentManagementSystem.models.equipes;
import FRC.TournamentManagementSystem.repositories.EquipeRepository;

@Component
public class DataBaseSeeder implements CommandLineRunner {

    private final EquipeRepository equipeRepository;

    // Injeção de dependência via construtor
    public DataBaseSeeder(EquipeRepository equipeRepository) {
        this.equipeRepository = equipeRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        // Trava de Segurança: Verifica se o banco está vazio antes de inserir
        if (equipeRepository.count() == 1) {
            
            List<equipes> novasEquipes = new ArrayList<>();
            
            // Loop de Elite: Gera as 32 equipes automaticamente
            for (int i = 1; i <= 32; i++) {
                equipes eq = new equipes();
                eq.setEquipe("Equipe " + i); // Cria nomes como "Equipe 1", "Equipe 2"...
                novasEquipes.add(eq);
            }
            
            // Salva a lista inteira no banco de dados com um único comando
            equipeRepository.saveAll(novasEquipes);
            
            // Log no terminal para avisar que a mágica aconteceu
            System.out.println("✅ CARGA INICIAL: 32 Equipes geradas com sucesso no banco de dados!");
        } else {
            System.out.println("⚡ CARGA INICIAL: O banco já possui equipes cadastradas. Seeding ignorado.");
        }
    }
}