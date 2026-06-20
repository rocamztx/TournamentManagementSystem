# 📱 Build APK Definitivo com Configuração Dinâmica

## 🎯 O que mudou?

O novo APK foi otimizado para funcionar em **qualquer rede** sem necessidade de recompilação. Ele detecta e se conecta ao servidor dinamicamente!

### ✨ Principais Features:

✅ **Tela de Configuração ao Iniciar** - Na primeira execução, o app pede o IP do servidor
✅ **Armazenamento Persistente** - A configuração é salva e não precisa ser inserida novamente
✅ **Reconfiguração Fácil** - Menu de settings para mudar o servidor a qualquer momento
✅ **Validação de Entrada** - Valida IP e porta antes de conectar
✅ **Teste de Conexão** - Botão para testar se o servidor está acessível
✅ **Build Otimizado** - APK split por arquitetura para menor tamanho

---

## 🚀 Como Gerar o APK

### **Opção 1: Script Automatizado (Recomendado)**

Execute o script na raiz do projeto:

```batch
build-apk-definitivo.bat
```

Este script irá:
1. Limpar build anterior
2. Atualizar dependências
3. Compilar o projeto
4. Gerar APK otimizado

### **Opção 2: Comando Manual**

```bash
cd frontend

# Limpar build anterior
flutter clean

# Atualizar dependências
flutter pub get

# Gerar APK Release
flutter build apk --release --split-per-abi
```

---

## 📦 Saída da Build

Os APKs gerados estarão em:
```
frontend/build/app/outputs/flutter-apk/
```

Você terá 3 APKs (um para cada arquitetura):
- `app-armeabi-v7a-release.apk` - Para processadores ARM 32-bit
- `app-arm64-v8a-release.apk` - Para processadores ARM 64-bit (RECOMENDADO)
- `app-x86_64-release.apk` - Para emuladores ou tablets x86

**Tamanho aproximado:** 50-100 MB cada

---

## 🎮 Como Usar o APK

### **Primeira Execução:**

1. Instale o APK no celular
2. Abra o aplicativo
3. A **Tela de Configuração** aparecerá automaticamente
4. Insira:
   - **IP do Servidor**: Ex: `192.168.1.100` ou `192.168.10.50`
   - **Porta**: Ex: `8080`
5. Clique em **"Testar Conexão"** para validar
6. Clique em **"Salvar e Continuar"**

### **Execuções Posteriores:**

O app abrirá normalmente mostrando a tela de classificação!

### **Para Reconfigurar o Servidor:**

1. Toque no menu **⋮** (três pontos) no canto superior
2. Selecione **"Servidor Conectado - Configurar"**
3. Atualize o IP/Porta conforme necessário

---

## 🔍 Localizando o IP da Máquina Servidor

### **Windows (Backend Java):**

Execute no PowerShell ou CMD:

```batch
ipconfig
```

Procure por "IPv4 Address" em sua rede local.
Exemplo: `192.168.1.50`

### **Ou use este script:**

```batch
ver-ip-do-servidor.bat
```

---

## 🧪 Testando a Configuração

### **Teste Rápido:**

1. Certifique-se que o servidor Java está rodando:
   ```bash
   start-server.bat
   ```

2. Na tela de configuração do app, insira:
   - IP: (do seu computador)
   - Porta: `8080`

3. Clique em **"Testar Conexão"**

4. Se aparecer "Servidor Configurado" ✓, está funcionando!

### **Se Não Conectar:**

- ✓ Verifique se o servidor Java está realmente rodando
- ✓ Verifique se o IP está correto (`ipconfig`)
- ✓ Certifique-se que estão na mesma rede
- ✓ Verifique o firewall (porta 8080 liberada)
- ✓ Tente com `localhost` se testar no mesmo PC

---

## 📋 Arquitetura da Solução

```
┌─────────────────────────────────────────┐
│         APK Definitivo (Flutter)        │
├─────────────────────────────────────────┤
│                                         │
│  main.dart                              │
│  ├─ Inicializa ServerConfigService    │
│  ├─ Verifica se está configurado      │
│  └─ Mostra ServerSettingsView se não  │
│                                         │
│  ServerSettingsView                     │
│  ├─ Tela de configuração de IP/Porta  │
│  ├─ Validação de entrada              │
│  ├─ Teste de conexão                  │
│  └─ Salva em SharedPreferences        │
│                                         │
│  ServerConfigService                   │
│  ├─ Gerencia SharedPreferences        │
│  ├─ Getters dinâmicos para URL base   │
│  └─ Métodos de validação              │
│                                         │
│  ClassificacaoView                      │
│  ├─ Menu com opção de reconfiguração  │
│  ├─ Informações do servidor           │
│  └─ Botão "ABRIR TELÃO"               │
│                                         │
│  ApiService                             │
│  ├─ Usa NetworkConfig.baseUrl (dinâm) │
│  ├─ GET classificação                 │
│  ├─ POST pontuação                    │
│  └─ DELETE reset                      │
│                                         │
│  NetworkConfig                          │
│  └─ Getters que usam ServerConfigServ │
│                                         │
└─────────────────────────────────────────┘
         ↓↓↓
┌─────────────────────────────────────────┐
│   Backend Java/Spring Boot (8080)       │
│   http://<IP>:8080/api/classificacao   │
└─────────────────────────────────────────┘
```

---

## 🛠️ Customizações Possíveis

### **Mudar IP Padrão (Se quiser):**

Edite `lib/services/server_config_service.dart`:

```dart
static const String _defaultIp = 'localhost'; // Mude aqui
```

### **Adicionar Descoberta Automática de Servidor:**

Você pode implementar mDNS (Bonjour) para descobrir o servidor automaticamente:

```dart
// Adicionar package 'multicast_dns' ao pubspec.yaml
// Então implementar varredura de rede
```

### **Salvar Histórico de Servidores:**

Modifique `ServerConfigService` para manter lista de últimos servidores usados.

---

## 📊 Diferenças: APK Antigo vs Novo

| Aspecto | Antigo | Novo ✨ |
|---------|--------|---------|
| IP Fixo | ❌ Hardcoded | ✅ Dinâmico |
| Recompilação | ✅ Necessária | ❌ Não precisa |
| Portabilidade | ❌ Pior | ✅ Excelente |
| Tela Config | ❌ Não | ✅ Elegante |
| Menu Servidor | ❌ Não | ✅ Sim |
| Validação | ❌ Não | ✅ Completa |
| Teste Conexão | ❌ Não | ✅ Sim |

---

## 🐛 Troubleshooting

### **"Falha na conexão com a API Java"**
- Verifique se o servidor Java está rodando
- Confirme o IP correto com `ipconfig`
- Tente "Testar Conexão" na tela de settings

### **"Erro ao salvar configuração"**
- Verifique permissões do app (Configurações > Permissões)
- Reinicie o app

### **App abre mas não carrega dados**
- Clique no menu ⋮ e selecione "Servidor Conectado"
- Verifique o IP exibido
- Tente reconectar

---

## 📞 Suporte

Para problemas específicos, consulte:
- `lib/services/server_config_service.dart` - Gerenciamento de config
- `lib/views/server_settings_view.dart` - Interface de config
- `lib/config/network_config.dart` - URLs dinâmicas

---

**Gerado em:** 2026-06-20
**Versão:** 1.1.0 (Dynamic Config)
