package FRC.TournamentManagementSystem.models;

import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;

@Entity
public class equipes {

    @Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    private Long id;

    private String equipe; // Este atributo guarda o nome da equipe (Ex: "Equipe 1")

    @OneToMany(mappedBy = "equipe", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<pontuacao> pontuacoes;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEquipe() {
        return equipe;
    }

    public void setEquipe(String equipe) {
        this.equipe = equipe;
    }

    // Getter e Setter da lista de pontuações para a nossa Service conseguir ler os dados!
    public List<pontuacao> getPontuacoes() {
        return pontuacoes;
    }

    public void setPontuacoes(List<pontuacao> pontuacoes) {
        this.pontuacoes = pontuacoes;
    }
}
