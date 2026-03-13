import random
import string

# Perguntas e respostas
perguntas = [
    {
        "pergunta": "Qual é a principal função de um sistema operacional?",
        "opcoes": ["Gerenciar hardware e software", "Executar planilhas", "Editar imagens", "Navegar na internet"],
        "resposta": "Gerenciar hardware e software"
    },
    {
        "pergunta": "Qual desses NÃO é um sistema operacional?",
        "opcoes": ["Linux", "Windows", "Android", "Oracle"],
        "resposta": "Oracle"
    },
    {
        "pergunta": "O que significa a sigla 'GUI'?",
        "opcoes": ["Graphical User Interface", "General User Instruction", "Global Utility Interaction", "General Unit Interface"],
        "resposta": "Graphical User Interface"
    },
    {
        "pergunta": "Qual sistema operacional é baseado em código aberto?",
        "opcoes": ["Linux", "Windows", "macOS", "iOS"],
        "resposta": "Linux"
    },
    {
        "pergunta": "O Windows utiliza qual sistema de arquivos por padrão?",
        "opcoes": ["NTFS", "EXT4", "FAT16", "XFS"],
        "resposta": "NTFS"
    },
    {
        "pergunta": "Qual comando do Linux é usado para listar arquivos em um diretório?",
        "opcoes": ["ls", "dir", "list", "show"],
        "resposta": "ls"
    },
    {
        "pergunta": "Qual desses sistemas é utilizado em smartphones?",
        "opcoes": ["Android", "Debian", "Ubuntu Server", "FreeBSD"],
        "resposta": "Android"
    },
    {
        "pergunta": "Qual parte do sistema operacional é responsável pela comunicação com o hardware?",
        "opcoes": ["Kernel", "Shell", "Aplicativo", "Driver"],
        "resposta": "Kernel"
    },
    {
        "pergunta": "Em sistemas multitarefa, o que o SO faz?",
        "opcoes": ["Gerencia a execução de múltiplos processos", "Executa apenas um processo por vez", "Impede paralelismo", "Desativa a memória virtual"],
        "resposta": "Gerencia a execução de múltiplos processos"
    },
    {
        "pergunta": "Qual comando no Windows mostra os processos em execução?",
        "opcoes": ["tasklist", "ps", "ls", "jobs"],
        "resposta": "tasklist"
    }
]

# Embaralhar perguntas
random.shuffle(perguntas)

respostas_usuario = []
gabarito = []

# Mostrar todas as perguntas
for i, q in enumerate(perguntas, 1):
    print(f"\nPergunta {i}: {q['pergunta']}")
    opcoes = q['opcoes'][:]
    random.shuffle(opcoes)

    letras = list(string.ascii_uppercase)[:len(opcoes)]
    mapa = dict(zip(letras, opcoes))

    for letra, opcao in mapa.items():
        print(f"  {letra}) {opcao}")

    escolha = input("Sua resposta (letra): ").strip().upper()
    resposta_escolhida = mapa.get(escolha)

    respostas_usuario.append(resposta_escolhida)
    gabarito.append(q['resposta'])

# Corrigir ao final
acertos = []
erros = []

for i, (resp_user, resp_certa, q) in enumerate(zip(respostas_usuario, gabarito, perguntas), 1):
    if resp_user == resp_certa:
        acertos.append(q['pergunta'])
    else:
        erros.append((q['pergunta'], resp_certa, resp_user))

# Resultado final
print("\n=== RESULTADO FINAL ===")
print(f"Acertos: {len(acertos)} | Erros: {len(erros)}")

if acertos:
    print("\n✔ Perguntas que você acertou:")
    for a in acertos:
        print("-", a)

if erros:
    print("\n✘ Perguntas que você errou:")
    for e, certa, user in erros:
        print(f"- {e}\n   Sua resposta: {user}\n   Resposta correta: {certa}")

