package FRC.TournamentManagementSystem.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import FRC.TournamentManagementSystem.models.equipes;

public interface EquipeRepository extends JpaRepository<equipes, Long>{

    @Query("SELECT DISTINCT e FROM equipes e LEFT JOIN FETCH e.pontuacoes")
    List<equipes> findAllComPontuacoes();

    @Query("SELECT DISTINCT e FROM equipes e LEFT JOIN FETCH e.pontuacoes WHERE e.modalidade = :modalidade")
    List<equipes> findAllComPontuacoesByModalidade(@Param("modalidade") String modalidade);

    List<equipes> findByModalidade(String modalidade);

    List<equipes> findByModalidadeOrderById(String modalidade);
}
