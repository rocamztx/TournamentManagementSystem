package FRC.TournamentManagementSystem.models;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Entity
public class BracketState {

    @Id
    @Column(length = 50)
    private String modalidade; // "cabo_guerra" or "sumo"

    @Column(columnDefinition = "TEXT")
    private String stateJson; // The JSON string representing the full UI state

    public BracketState() {}

    public BracketState(String modalidade, String stateJson) {
        this.modalidade = modalidade;
        this.stateJson = stateJson;
    }

    public String getModalidade() {
        return modalidade;
    }

    public void setModalidade(String modalidade) {
        this.modalidade = modalidade;
    }

    public String getStateJson() {
        return stateJson;
    }

    public void setStateJson(String stateJson) {
        this.stateJson = stateJson;
    }
}
