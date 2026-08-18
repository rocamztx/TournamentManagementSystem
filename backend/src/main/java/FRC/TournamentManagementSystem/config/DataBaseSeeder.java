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
        // Migra equipes existentes que não têm modalidade definida
        List<equipes> todasEquipes = equipeRepository.findAll();
        for (equipes eq : todasEquipes) {
            if (eq.getModalidade() == null || eq.getModalidade().isEmpty()) {
                eq.setModalidade("seguidor_linha");
            }
        }
        if (!todasEquipes.isEmpty()) {
            equipeRepository.saveAll(todasEquipes);
        }

        String[] modalidades = { "seguidor_linha", "cabo_guerra", "sumo" };
        String[] prefixos = { "SL", "CG", "SM" };

        for (int m = 0; m < modalidades.length; m++) {
            String modalidade = modalidades[m];
            String prefixo = prefixos[m];
            long count = equipeRepository.findByModalidade(modalidade).size();

            if (count == 0) {
                List<equipes> novasEquipes = new ArrayList<>();
                for (int i = 1; i <= 32; i++) {
                    equipes eq = new equipes();
                    eq.setEquipe("Equipe " + i);
                    eq.setModalidade(modalidade);
                    novasEquipes.add(eq);
                }
                equipeRepository.saveAll(novasEquipes);
                System.out.println("CARGA INICIAL [" + modalidade + "]: 32 equipes geradas com sucesso.");
            } else {
                System.out.println(
                        "CARGA INICIAL [" + modalidade + "]: já possui " + count + " equipes. Seeding ignorado.");
            }
        }
    }
}
