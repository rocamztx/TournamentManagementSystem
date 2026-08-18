#!/usr/bin/env bash
set -e

# Executa o backend no Linux usando o Maven Wrapper.
# Deve ser chamado a partir do diretório raiz do projeto.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/backend"

if [ ! -x ./mvnw ]; then
  chmod +x ./mvnw
fi

./mvnw spring-boot:run
