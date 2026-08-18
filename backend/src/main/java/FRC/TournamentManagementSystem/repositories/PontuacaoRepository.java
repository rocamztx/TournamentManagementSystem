package FRC.TournamentManagementSystem.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import FRC.TournamentManagementSystem.models.pontuacao;

public interface PontuacaoRepository extends JpaRepository<pontuacao, Long>{

    @Modifying
    @Query("DELETE FROM pontuacao p WHERE p.equipe.id = :equipeId")
    int deleteByEquipeId(@Param("equipeId") Long equipeId);
}
