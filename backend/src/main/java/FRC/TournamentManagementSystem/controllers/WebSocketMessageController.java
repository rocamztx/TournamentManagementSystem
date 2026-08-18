package FRC.TournamentManagementSystem.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import FRC.TournamentManagementSystem.dtos.ClassificacaoDTO;
import FRC.TournamentManagementSystem.services.ClassificacaoService;
import FRC.TournamentManagementSystem.models.BracketState;
import FRC.TournamentManagementSystem.repositories.BracketStateRepository;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import java.util.Optional;

@Controller
public class WebSocketMessageController {

    @Autowired
    private ClassificacaoService classificacaoService;

    @Autowired
    private BracketStateRepository bracketStateRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/solicitar-classificacao/{modalidade}")
    public void enviarListaAtual(@DestinationVariable String modalidade) {
        messagingTemplate.convertAndSend("/topic/classificacao/" + modalidade, classificacaoService.obterClassificacaoGeral(modalidade));
    }

    // Recebe atualização de um tablet, salva no banco e faz broadcast para o telão
    @MessageMapping("/update-bracket/{modalidade}")
    public void updateBracket(@DestinationVariable String modalidade, String stateJson) {
        BracketState state = new BracketState(modalidade, stateJson);
        bracketStateRepository.save(state);
        messagingTemplate.convertAndSend("/topic/bracket/" + modalidade, stateJson);
    }

    // Telão acabou de conectar e pede o estado atual do bracket
    @MessageMapping("/solicitar-bracket/{modalidade}")
    public void solicitarBracket(@DestinationVariable String modalidade) {
        Optional<BracketState> stateOpt = bracketStateRepository.findById(modalidade);
        if (stateOpt.isPresent()) {
            messagingTemplate.convertAndSend("/topic/bracket/" + modalidade, stateOpt.get().getStateJson());
        } else {
            messagingTemplate.convertAndSend("/topic/bracket/" + modalidade, "{}");
        }
    }
}