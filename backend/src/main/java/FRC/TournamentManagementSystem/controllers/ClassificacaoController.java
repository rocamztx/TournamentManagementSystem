package FRC.TournamentManagementSystem.controllers;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import FRC.TournamentManagementSystem.dtos.ClassificacaoDTO;
import FRC.TournamentManagementSystem.dtos.PontuacaoInputDTO;
import FRC.TournamentManagementSystem.services.ClassificacaoService;

@RestController
@RequestMapping("/api/classificacao")
@CrossOrigin(origins = "*")
public class ClassificacaoController {

    @Autowired
    private ClassificacaoService classificacaoService;

    @Value("${app.api-key}")
    private String apiKeyConfigurada;

    @GetMapping
    public ResponseEntity<List<ClassificacaoDTO>> buscarClassificacaoGeral() {
        return ResponseEntity.ok(classificacaoService.obterClassificacaoGeral());
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> status() {
        return ResponseEntity.ok(Map.of(
                "api", "online",
                "websocket", "/ws-torneio",
                "topic", "/topic/classificacao",
                "equipes", classificacaoService.obterClassificacaoGeral().size()
        ));
    }

    @PostMapping("/lancar-nota")
    public ResponseEntity<String> lancarNota(
            @RequestHeader(value = "X-API-KEY", required = false) String apiKey,
            @RequestBody PontuacaoInputDTO dto) {

        if (!apiKeyValida(apiKey)) {
            return ResponseEntity.status(401).body("Acesso negado: chave de API invalida ou ausente.");
        }

        classificacaoService.salvarPontuacao(dto);
        return ResponseEntity.ok("Pontuacao lancada com sucesso.");
    }

    @DeleteMapping("/zerar/{equipeId}")
    public ResponseEntity<Void> zerarPontuacao(
            @PathVariable Long equipeId,
            @RequestHeader(value = "X-API-KEY", required = false) String apiKey) {

        if (!apiKeyValida(apiKey)) {
            return ResponseEntity.status(403).build();
        }

        classificacaoService.zerarPontuacaoEquipe(equipeId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/editar-equipe/{id}")
    public ResponseEntity<Void> editarNomeEquipe(
            @PathVariable Long id,
            @RequestBody Map<String, String> payload,
            @RequestHeader(value = "X-API-KEY", required = false) String apiKey) {

        if (!apiKeyValida(apiKey)) {
            return ResponseEntity.status(403).build();
        }

        String nome = payload.get("nome");
        if (nome == null || nome.trim().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        classificacaoService.atualizarNomeEquipe(id, nome.trim());
        return ResponseEntity.ok().build();
    }

    private boolean apiKeyValida(String apiKey) {
        return apiKey != null && apiKey.equals(apiKeyConfigurada);
    }
}
