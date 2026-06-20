package FRC.TournamentManagementSystem.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
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
@CrossOrigin(origins = "*") // Permite que o Flutter (Web ou Mobile) se conecte sem tomar erro de CORS
public class ClassificacaoController {

    @Autowired
    private ClassificacaoService classificacaoService;

    /**
     * Endpoint que o Flutter vai acessar via GET para renderizar a tabela principal.
     */
    @GetMapping
    public ResponseEntity<List<ClassificacaoDTO>> buscarClassificacaoGeral() {
        List<ClassificacaoDTO> ranking = classificacaoService.obterClassificacaoGeral();
        return ResponseEntity.ok(ranking); // Retorna a lista dentro de uma resposta HTTP 200 (OK)
    }

   /**
     * Endpoint do Modo Juiz protegido por Senha Mestre (API Key).
     */
    @PostMapping("/lancar-nota")
    public ResponseEntity<String> lancarNota(
            @RequestHeader(value = "X-API-KEY", required = false) String apiKey,
            @RequestBody PontuacaoInputDTO dto) {

        // Defina a senha mestre do seu campeonato aqui
        String senhaMestreSegura = "OBR2026_ROBOTICA_ELITE";

        // Validação de Segurança: Se não enviou ou a senha está errada, retorna 401 Unauthorized
        if (apiKey == null || !apiKey.equals(senhaMestreSegura)) {
            return ResponseEntity.status(401).body("Acesso Negado: Chave de API inválida ou ausente.");
        }

        classificacaoService.salvarPontuacao(dto);
        return ResponseEntity.ok("Pontuação lançada com sucesso.");
    }
    
    @DeleteMapping("/zerar/{equipeId}")
    public ResponseEntity<Void> zerarPontuacao(
            @PathVariable Long equipeId,
            @RequestHeader("X-API-KEY") String apiKey) {
        // Mantém a trava de segurança para nenhum hacker zerar o torneio
        if (!"OBR2026_ROBOTICA_ELITE".equals(apiKey)) {
            return ResponseEntity.status(403).build();
        }

        classificacaoService.zerarPontuacaoEquipe(equipeId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/editar-equipe/{id}")
    public ResponseEntity<Void> editarNomeEquipe(
            @PathVariable Long id,
            @RequestBody java.util.Map<String, String> payload,
            @RequestHeader("X-API-KEY") String apiKey) {

        if (!"OBR2026_ROBOTICA_ELITE".equals(apiKey)) {
            return ResponseEntity.status(403).build();
        }

        // Pega o "nome" que o Flutter enviou no JSON
        classificacaoService.atualizarNomeEquipe(id, payload.get("nome"));
        return ResponseEntity.ok().build();
    }
}