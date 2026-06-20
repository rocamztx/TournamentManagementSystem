# Tournament Management System

Um sistema de gerenciamento de torneios com backend em Java/Spring Boot e frontend em Flutter.

## Estrutura do Projeto

### Backend
- **Tecnologia**: Java 11+, Spring Boot
- **Build**: Maven
- **Localização**: `/backend`

#### Como executar o backend:
```bash
cd backend
./mvnw spring-boot:run
```

### Frontend
- **Tecnologia**: Flutter (Dart)
- **Localização**: `/frontend`

#### Como executar o frontend:
```bash
cd frontend
flutter pub get
flutter run
```

## Requisitos

### Backend
- Java 11 ou superior
- Maven 3.6+

### Frontend
- Flutter 3.x
- Dart 3.x

## Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/TournamentManagementSystem.git
cd TournamentManagementSystem
```

2. Configure o backend:
```bash
cd backend
./mvnw clean install
```

3. Configure o frontend:
```bash
cd frontend
flutter pub get
```

## Uso

Para desenvolver localmente:

1. Inicie o backend:
```bash
cd backend
./mvnw spring-boot:run
```

2. Em outro terminal, inicie o frontend:
```bash
cd frontend
flutter run
```

## Estrutura de Diretórios

```
TournamentManagementSystem/
├── backend/                    # Aplicação Spring Boot
│   ├── src/main/java/         # Código-fonte
│   ├── src/test/java/         # Testes
│   ├── pom.xml                # Configuração Maven
│   └── mvnw                   # Maven Wrapper
├── frontend/                   # Aplicação Flutter
│   ├── lib/                   # Código-fonte Dart
│   ├── test/                  # Testes
│   ├── android/               # Código Android nativo
│   ├── ios/                   # Código iOS nativo
│   ├── web/                   # Código Web
│   ├── windows/               # Código Windows nativo
│   ├── linux/                 # Código Linux nativo
│   ├── macos/                 # Código macOS nativo
│   └── pubspec.yaml           # Configuração Flutter
└── .gitignore                 # Arquivo de exclusão do Git
```

## Licença

[Adicione sua licença aqui]

## Autores

[Adicione informações do autor aqui]
