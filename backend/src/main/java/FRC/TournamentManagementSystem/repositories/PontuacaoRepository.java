package FRC.TournamentManagementSystem.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import FRC.TournamentManagementSystem.models.pontuacao;

public interface PontuacaoRepository extends JpaRepository<pontuacao, Long>{

}
