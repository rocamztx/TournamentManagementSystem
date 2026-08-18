package FRC.TournamentManagementSystem.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import FRC.TournamentManagementSystem.models.BracketState;

public interface BracketStateRepository extends JpaRepository<BracketState, String> {
}
