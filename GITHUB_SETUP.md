## 📤 Como fazer push para o GitHub

Seu projeto local foi preparado com sucesso! Agora siga estes passos para enviá-lo para o GitHub:

### Passo 1: Criar um novo repositório no GitHub

1. Acesse https://github.com/new
2. Preencha os campos:
   - **Repository name**: `TournamentManagementSystem`
   - **Description**: "Um sistema de gerenciamento de torneios com backend em Java/Spring Boot e frontend em Flutter"
   - Escolha **Public** ou **Private** conforme preferência
   - ❌ **NÃO** marque "Initialize this repository with a README"
   - ❌ **NÃO** adicione .gitignore (já temos um)

3. Clique em "Create repository"

### Passo 2: Adicionar o remote e fazer push

Após criar o repositório, GitHub mostrará instruções. Execute os comandos abaixo no PowerShell:

```powershell
cd d:\TournamentManagementSystem

# Adicionar o repositório remoto (substitua SEU_USUARIO pelo seu usuário GitHub)
git remote add origin https://github.com/SEU_USUARIO/TournamentManagementSystem.git

# Renomear branch para main (opcional, mas recomendado)
git branch -M main

# Fazer push do código
git push -u origin main
```

### Passo 3: Autenticação

Na primeira vez que fizer push, o Git pode pedir suas credenciais:

**Opção A: Token de Acesso Pessoal (Recomendado)**
1. Acesse https://github.com/settings/tokens
2. Clique em "Generate new token (classic)"
3. Selecione escopo `repo`
4. Copie o token gerado
5. Use como senha quando o Git solicitar

**Opção B: SSH (Alternativa)**
Se preferir usar SSH, configure suas chaves SSH no GitHub primeiro:
https://github.com/settings/ssh

Então use:
```powershell
git remote set-url origin git@github.com:SEU_USUARIO/TournamentManagementSystem.git
git push -u origin main
```

### Passo 4: Verificar

Após o push, acesse seu repositório em:
```
https://github.com/SEU_USUARIO/TournamentManagementSystem
```

Você deverá ver:
- ✅ Todos os arquivos do backend
- ✅ Todos os arquivos do frontend
- ✅ O arquivo README.md
- ✅ O arquivo .gitignore

### Comandos Úteis para o Futuro

```powershell
# Ver status do repositório
git status

# Fazer commit de mudanças
git add .
git commit -m "Descrição das mudanças"

# Fazer push das mudanças
git push

# Ver histórico de commits
git log --oneline

# Criar nova branch para desenvolver
git checkout -b nome-da-branch
```

### Informações do Seu Repositório Local

- **Branch padrão**: master → será renomeado para main no GitHub
- **Commits criados**:
  1. Initial commit: Tournament Management System
  2. Add README.md with project documentation

✅ Seu projeto está pronto para ser enviado para o GitHub!
