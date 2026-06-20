package FRC.TournamentManagementSystem.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import FRC.TournamentManagementSystem.models.equipes;
import FRC.TournamentManagementSystem.repositories.EquipeRepository;

@RestController
@RequestMapping("/api/equipes")
@CrossOrigin(origins = "*")
public class EquipeController {

    @Autowired
    private EquipeRepository equipeRepository;

    /**
     * Carga Inicial de Elite: Cadastra várias equipes de uma vez só.
     * Recebe um JSON contendo uma lista de strings (nomes).
     */
    @PostMapping("/carga-inicial")
    public ResponseEntity<String> cadastrarEquipesEmLote(@RequestBody List<String> nomesDasEquipes) {
        if (nomesDasEquipes == null || nomesDasEquipes.isEmpty()) {
            return ResponseEntity.badRequest().body("A lista de nomes não pode estar vazia.");
        }

        // Mapeia a lista de strings para objetos do seu modelo 'equipes' e salva tudo
        List<equipes> novasEquipes = nomesDasEquipes.stream()
                .map(nome -> {
                    equipes eq = new equipes();
                    eq.setEquipe(nome);
                    return eq;
                })
                .toList();

        equipeRepository.saveAll(novasEquipes); // Salva a lista inteira no Postgres de uma vez só!

        return ResponseEntity.ok(novasEquipes.size() + " equipes cadastradas com sucesso no torneio!");
    }
}