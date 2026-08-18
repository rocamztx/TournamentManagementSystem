import json
import os
import urllib.request
import urllib.error

BASE_URL = os.getenv('API_BASE_URL', 'http://localhost:8080/api/classificacao')
API_KEY = os.getenv('APP_API_KEY', 'OBR2026_ROBOTICA_ELITE')


def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')


def print_header(title):
    print('=' * 60)
    print(title.center(60))
    print('=' * 60)


def request_json(url, method='GET', payload=None):
    data = None
    headers = {'X-API-KEY': API_KEY}
    if payload is not None:
        data = json.dumps(payload).encode('utf-8')
        headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode('utf-8')
            return resp.status, body
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        return e.code, body
    except Exception as e:
        return None, str(e)


def listar_equipes():
    status, body = request_json(f'{BASE_URL}')
    if status != 200:
        print('Não foi possível buscar as equipes.')
        return []
    try:
        return json.loads(body)
    except Exception:
        return []


def mostrar_ranking():
    equipes = listar_equipes()
    clear_screen()
    print_header('RANKING ATUAL')
    if not equipes:
        print('Nenhuma equipe encontrada.')
        return
    for idx, equipe in enumerate(equipes, start=1):
        print(f"{idx:>2}. {equipe['nomeDaEquipe']:<25} | R1: {equipe['notaRound1']:<2} | R2: {equipe['notaRound2']:<2} | R3: {equipe['notaRound3']:<2} | TOTAL: {equipe['notaTotal']}")


def limpar_pontuacao_equipe():
    equipes = listar_equipes()
    clear_screen()
    print_header('APAGAR PONTUAÇÕES')
    if not equipes:
        print('Nenhuma equipe encontrada.')
        return
    for idx, equipe in enumerate(equipes, start=1):
        print(f'{idx}. {equipe["nomeDaEquipe"]} (ID: {equipe["id"]})')
    try:
        escolha = int(input('\nDigite o número da equipe para apagar as pontuações: ').strip()) - 1
        equipe = equipes[escolha]
    except Exception:
        print('Escolha inválida.')
        return

    equipe_id = equipe['id']
    status, body = request_json(f'{BASE_URL}/zerar/{equipe_id}', method='DELETE')
    if status == 200:
        print(f'Pontuações da equipe {equipe["nomeDaEquipe"]} apagadas com sucesso.')
    else:
        print(f'Erro ao apagar pontuações: {body}')


def menu():
    while True:
        clear_screen()
        print_header('PAINEL ADMINISTRATIVO')
        print('1. Ver ranking atual')
        print('2. Apagar pontuação de uma equipe')
        print('3. Ver status da API')
        print('0. Sair')
        print('-' * 60)
        opcao = input('Escolha uma opção: ').strip()
        if opcao == '1':
            mostrar_ranking()
            input('\nPressione Enter para voltar ao menu...')
        elif opcao == '2':
            limpar_pontuacao_equipe()
            input('\nPressione Enter para voltar ao menu...')
        elif opcao == '3':
            status, body = request_json(f'{BASE_URL}/status')
            clear_screen()
            print_header('STATUS DA API')
            if status == 200:
                print(body)
            else:
                print(f'Erro ao consultar status: {body}')
            input('\nPressione Enter para voltar ao menu...')
        elif opcao == '0':
            print('Encerrando painel administrativo...')
            break
        else:
            print('Opção inválida.')
            input('\nPressione Enter para tentar novamente...')


if __name__ == '__main__':
    menu()
