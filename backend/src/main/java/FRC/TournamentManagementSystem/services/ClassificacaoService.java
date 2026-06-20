package FRC.TournamentManagementSystem.services;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import FRC.TournamentManagementSystem.dtos.ClassificacaoDTO;
import FRC.TournamentManagementSystem.dtos.PontuacaoInputDTO;
import FRC.TournamentManagementSystem.models.equipes;
import FRC.TournamentManagementSystem.models.pontuacao;
import FRC.TournamentManagementSystem.repositories.EquipeRepository;
import FRC.TournamentManagementSystem.repositories.PontuacaoRepository;

@Service
public class ClassificacaoService {

    @jakarta.persistence.PersistenceContext
    private jakarta.persistence.EntityManager entityManager;

    @Autowired
    private EquipeRepository equipeRepository;

    @Autowired
    private PontuacaoRepository pontuacaoRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate; // INJEÇÃO DO WEBSOCKET

    @Transactional
    public void salvarPontuacao(PontuacaoInputDTO dto) {
        equipes equipe = equipeRepository.findById(dto.equipeId())
                .orElseThrow(() -> new RuntimeException("Equipe não encontrada!"));

        pontuacao novaPontuacao = new pontuacao();
        novaPontuacao.setRound(dto.round());
        novaPontuacao.setPoints(dto.pontos());
        novaPontuacao.setTime(dto.tempo());
        novaPontuacao.setEquipes(equipe); 

        equipe.getPontuacoes().add(novaPontuacao);
        pontuacaoRepository.save(novaPontuacao);

        messagingTemplate.convertAndSend("/topic/classificacao", obterClassificacaoGeral());
    }

    public int calcularPontuacaoFinal(int r1, int r2, int r3) {
        return Stream.of(r1, r2, r3)
                .sorted(Comparator.reverseOrder())
                .limit(2)
                .mapToInt(Integer::intValue)
                .sum();
    }

    private int extrairNotaPorRound(List<pontuacao> pontuacoes, int round) {
        if (pontuacoes == null || pontuacoes.isEmpty()) return 0;
        return pontuacoes.stream()
                .filter(p -> p != null && p.getRound() == round)
                .sorted(Comparator.comparingLong(pontuacao::getId).reversed())
                .map(pontuacao::getPoints)
                .findFirst() 
                .orElse(0);
    }

    @Transactional
    public void zerarPontuacaoEquipe(Long equipeId) {
        equipes equipe = equipeRepository.findById(equipeId)
                .orElseThrow(() -> new RuntimeException("Equipe não encontrada!"));
        
        pontuacaoRepository.deleteAll(equipe.getPontuacoes());
        equipe.getPontuacoes().clear();
        
        messagingTemplate.convertAndSend("/topic/classificacao", obterClassificacaoGeral());
    }

    @Transactional
    public void atualizarNomeEquipe(Long id, String novoNome) {
        equipes equipe = equipeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Equipe não encontrada!"));
        
        equipe.setEquipe(novoNome);
        equipeRepository.save(equipe);
        
        messagingTemplate.convertAndSend("/topic/classificacao", obterClassificacaoGeral());
    }

    public List<ClassificacaoDTO> obterClassificacaoGeral() {
        entityManager.clear(); 
        List<equipes> listaEquipes = equipeRepository.findAllComPontuacoes();
        
        return listaEquipes.stream()
                .map(equipe -> {
                    List<pontuacao> pontuacoesEquipe = equipe.getPontuacoes();
                    int r1 = extrairNotaPorRound(pontuacoesEquipe, 1);
                    int r2 = extrairNotaPorRound(pontuacoesEquipe, 2);
                    int r3 = extrairNotaPorRound(pontuacoesEquipe, 3);
                    int total = calcularPontuacaoFinal(r1, r2, r3);
                    return new ClassificacaoDTO(equipe.getEquipe(), r1, r2, r3, total, equipe.getId());
                })
                .sorted(Comparator.comparingInt(ClassificacaoDTO::notaTotal).reversed()
                        .thenComparingLong(ClassificacaoDTO::id))
                .collect(Collectors.toList());
    }
}
