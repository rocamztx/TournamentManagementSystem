# 🧪 Guia de Teste - APK Definitivo com Configuração Dinâmica

## ✅ Checklist de Testes

### **Fase 1: Compilação**

- [ ] Build sem erros: `build-apk-definitivo.bat`
- [ ] APK gerado em `frontend/build/app/outputs/flutter-apk/`
- [ ] Tamanho do APK arm64: ~70-100 MB
- [ ] Arquivo `app-arm64-v8a-release.apk` existente

### **Fase 2: Instalação**

```bash
# Conecte o celular via USB
adb devices

# Instale o APK (escolha a versão arm64)
adb install -r frontend\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

- [ ] Instalação bem-sucedida
- [ ] App aparece na tela do celular

### **Fase 3: Primeira Execução**

**Esperado:**
1. Tela de boas-vindas desaparece
2. Tela de "Configuração do Servidor" aparece
3. Campos vazios para IP e Porta
4. Botões: "Testar Conexão" e "Salvar e Continuar"

**Testes:**

- [ ] Tela de settings aparece na primeira execução
- [ ] Campos de entrada estão ativos
- [ ] Teclado numérico para porta
- [ ] Teclado alfanumérico para IP

### **Fase 4: Configuração**

**Teste 1: Validação de IP Vazio**

```
Ação: Deixar IP vazio → Clicar "Salvar e Continuar"
Esperado: Erro "Por favor, insira o IP do servidor"
```

- [ ] Validação funciona

**Teste 2: Validação de Porta Vazia**

```
Ação: Inserir IP → Deixar porta vazia → Clicar "Salvar e Continuar"
Esperado: Erro "Por favor, insira a porta do servidor"
```

- [ ] Validação funciona

**Teste 3: Validação de Porta Inválida**

```
Ação: IP: 192.168.1.100 → Porta: abc → Clicar "Salvar"
Esperado: Erro "Porta deve ser um número válido"
```

- [ ] Validação funciona

**Teste 4: Configuração Válida**

```
Ação: Obter IP do servidor (ipconfig)
      IP: 192.168.X.X → Porta: 8080 → Clicar "Testar Conexão"
```

- [ ] Botão "Testar" funciona
- [ ] Mensagem de sucesso ou erro apropriada

### **Fase 5: Conexão com Servidor**

**Pré-requisito: Servidor Java Rodando**

```bash
cd backend
start-server.bat
# OU
java -jar target/TournamentManagementSystem-0.0.1-SNAPSHOT.jar
```

**Teste 1: Servidor Acessível**

```
Ação: 
  1. Inicie o servidor Java
  2. Obtenha o IP: ipconfig
  3. Na tela de settings, insira IP:8080
  4. Clique "Testar Conexão"

Esperado: Mensagem "Servidor Configurado - URL: http://IP:8080/..."
```

- [ ] Conexão bem-sucedida
- [ ] URL exibida corretamente

**Teste 2: Servidor Inacessível**

```
Ação:
  1. DESLIGUE o servidor Java
  2. Na tela de settings, insira um IP fictício: 10.0.0.1
  3. Clique "Testar Conexão"

Esperado: Mensagem de erro apropriada
```

- [ ] Erro tratado graciosamente
- [ ] App não congela

### **Fase 6: Funcionamento Principal**

**Teste 1: Carregamento de Dados**

```
Ação:
  1. Configure servidor corretamente
  2. Clique "Salvar e Continuar"

Esperado:
  1. Tela de classificação carrega
  2. Tabela mostra dados do servidor
  3. Pull-to-refresh funciona
```

- [ ] Dados carregam corretamente
- [ ] Interface responsiva

**Teste 2: Modo Juiz**

```
Ação:
  1. Na tela de classificação, clique na aba "MODO JUIZ"
  2. Selecione uma equipe
  3. Insira pontos e tempo
  4. Clique "Enviar"

Esperado:
  1. Pontuação é enviada para o servidor
  2. Tabela atualiza (WebSocket)
```

- [ ] Envio de dados funciona
- [ ] Servidor recebe corretamente

**Teste 3: Telão**

```
Ação:
  1. Clique em "ABRIR TELÃO"

Esperado:
  1. Tela em landscape
  2. Placar em grande
  3. Dados atualizados em tempo real
```

- [ ] Telão aparece
- [ ] Dados corretos

### **Fase 7: Menu de Configuração**

```
Ação:
  1. Na tela de classificação, clique em ⋮ (três pontos)

Esperado:
  1. Menu aparece com opções:
     - Servidor Conectado - Configurar
     - Informações do Servidor
```

- [ ] Menu funciona
- [ ] Opções aparecem

**Teste 1: Reconfigurar Servidor**

```
Ação:
  1. Clique "Servidor Conectado - Configurar"
  2. Mude o IP/Porta
  3. Clique "Salvar e Continuar"

Esperado:
  1. App reconecta ao novo servidor
  2. Dados atualizam
```

- [ ] Reconfiguração funciona
- [ ] Reconexão automática

**Teste 2: Informações do Servidor**

```
Ação:
  1. Clique em ⋮ → "Informações do Servidor"

Esperado:
  1. Dialog mostra IP configurado
  2. Porta configurada
  3. URL completa
```

- [ ] Informações corretas
- [ ] Format legível

### **Fase 8: Armazenamento Persistente**

```
Ação:
  1. Configure o servidor (IP + Porta)
  2. Feche o app completamente
  3. Reabra o app

Esperado:
  1. App abre diretamente na tela de classificação
  2. NÃO mostra tela de configuração
  3. Conecta ao mesmo servidor
```

- [ ] Dados persistem corretamente
- [ ] Não pede config novamente

### **Fase 9: Diferentes Redes**

**Teste 1: Mesma Rede (WiFi)**

```
Ação:
  1. Celular e PC na mesma WiFi
  2. Configure com IP correto
  3. Funciona tudo normalmente

Esperado: Conexão completa ✓
```

- [ ] Funciona

**Teste 2: Mesmo PC (localhost)**

```
Ação:
  1. Se testar em emulador na mesma máquina
  2. Use IP: 10.0.2.2 (padrão do Android)
  3. Ou localhost

Esperado: Conexão com servidor local
```

- [ ] Funciona

---

## 🚀 Teste Completo em 5 Minutos

```bash
# 1. Limpar build
cd frontend && flutter clean

# 2. Atualizar deps
flutter pub get

# 3. Build
flutter build apk --release

# 4. Instalar
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 5. Abrir app e testar:
#    - Tela de settings aparece ✓
#    - Insira IP:8080 ✓
#    - Teste conexão ✓
#    - Veja dados carregando ✓
```

---

## 📊 Relatório de Teste

Use este template para documentar resultados:

```
[DATA] - Teste APK Definitivo
Tester: [Nome]
Device: [Modelo do celular]
Android: [Versão]

=== COMPILAÇÃO ===
Build: ✓ / ✗
Tamanho: ___ MB
Erro: [Se houver]

=== INSTALAÇÃO ===
Status: ✓ / ✗
Erro: [Se houver]

=== CONFIGURAÇÃO DINÂMICA ===
Tela de settings: ✓ / ✗
Validação IP: ✓ / ✗
Validação Porta: ✓ / ✗
Teste Conexão: ✓ / ✗
Salvar & Continuar: ✓ / ✗

=== FUNCIONAMENTO ===
Carrega dados: ✓ / ✗
Modo Juiz: ✓ / ✗
Telão: ✓ / ✗
WebSocket (atualização): ✓ / ✗

=== PERSISTÊNCIA ===
Dados salvos: ✓ / ✗
Próxima abertura (sem config): ✓ / ✗

=== PROBLEMAS ===
[Listar problemas encontrados]

=== CONCLUSÃO ===
PRONTO PARA PRODUÇÃO: SIM / NÃO
```

---

## 🔍 Debug em Desenvolvimento

Se precisar fazer testes durante desenvolvimento:

```bash
# Build em debug mode
flutter build apk --debug

# Ou rodar direto (requer device conectado)
flutter run
```

---

## 🎯 Teste de Stress

**Múltiplas Reconfigurations:**

```
1. Mude servidor 5x
2. Reconecte a cada mudança
3. Verifique se dados carregam corretamente
4. Feche e reabra app
```

**Múltiplas Requisições:**

```
1. Envie 10 pontuações rápidas
2. Verifique se todas foram registradas
3. Verifique atualização em tempo real
```

---

## ✨ Sucesso!

Se todos os testes passarem, o APK está pronto para distribuição! 🎉

**Próximos Passos:**
1. Publicar no Google Play Store (opcional)
2. Distribuir via APK direto
3. Documentar para usuários finais
4. Fazer backup do APK

---

**Versão:** 1.0
**Atualizado:** 2026-06-20
