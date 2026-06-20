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

    public DataBaseSeeder(EquipeRepository equipeRepository) {
        this.equipeRepository = equipeRepository;
    }

    @Override
    public void run(String... args) {
        if (equipeRepository.count() == 0) {
            List<equipes> novasEquipes = new ArrayList<>();

            for (int i = 1; i <= 32; i++) {
                equipes eq = new equipes();
                eq.setEquipe("Equipe " + i);
                novasEquipes.add(eq);
            }

            equipeRepository.saveAll(novasEquipes);
            System.out.println("CARGA INICIAL: 32 equipes geradas com sucesso no banco de dados.");
        } else {
            System.out.println("CARGA INICIAL: o banco ja possui equipes cadastradas. Seeding ignorado.");
        }
    }
}
