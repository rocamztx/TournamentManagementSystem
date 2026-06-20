package FRC.TournamentManagementSystem.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

import FRC.TournamentManagementSystem.dtos.ClassificacaoDTO;
import FRC.TournamentManagementSystem.services.ClassificacaoService;

@Controller
public class WebSocketMessageController {

    @Autowired
    private ClassificacaoService classificacaoService;

    // Quando o Telão enviar uma mensagem para "/app/solicitar-classificacao", 
    // este método responde enviando a lista completa para "/topic/classificacao"
    @MessageMapping("/solicitar-classificacao")
    @SendTo("/topic/classificacao")
    public List<ClassificacaoDTO> enviarListaAtual() {
        return classificacaoService.obterClassificacaoGeral();
    }
}