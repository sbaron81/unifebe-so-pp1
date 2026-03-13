#!/bin/bash

# ===== Estilo =====
GREEN="\e[32m"; RED="\e[31m"; BOLD="\e[1m"; RESET="\e[0m"
PASS_COLOR="${BOLD}[${GREEN}PASS${RESET}${BOLD}]${RESET}"
NOT_COLOR="${BOLD}[${RED}NOT${RESET}${BOLD}]${RESET}"
PASS_TEXT="[PASS]"; NOT_TEXT="[NOT]"

# Resultado final (sem cor)
RES_REQUISITOS="$NOT_TEXT"
RES_SISTEMA="$NOT_TEXT"
RES_SSH="$NOT_TEXT"
RES_ROOT="$NOT_TEXT"
RES_PACOTES="$NOT_TEXT"
RES_ARQUIVO="$NOT_TEXT"
RES_DOWNLOAD="$NOT_TEXT"
RES_PASTA="$NOT_TEXT"
RES_EXECUCAO="$NOT_TEXT"
RES_FINAL="$NOT_TEXT"

QUIZ_ACERTOS="N/A"

print_ok()  { echo -e "  $PASS_COLOR $1"; }
print_err() { echo -e "  $NOT_COLOR $1"; }
print_check(){ [[ "$1" -eq 1 ]] && print_ok "$2" || print_err "$2"; }

# Dependências
command -v git >/dev/null 2>&1 || { sudo apt-get update -y >/dev/null 2>&1; sudo apt-get install -y git >/dev/null 2>&1; }
command -v python3 >/dev/null 2>&1 || { sudo apt-get update -y >/dev/null 2>&1; sudo apt-get install -y python3 >/dev/null 2>&1; }

# ===== 1) Executar QUESTIONÁRIO primeiro =====
testa_execucao_questionario() {
  local repo="https://github.com/sbaron81/my-py.git"
  local dir="/tmp/my-py"
  rm -rf "$dir"
  echo -e "\n--- Executando questionario.py ---"
  if git clone "$repo" "$dir" >/dev/null 2>&1 && [[ -f "$dir/questionario.py" ]]; then
    if python3 "$dir/questionario.py" | tee /tmp/questionario.out ; then
      QUIZ_ACERTOS=$(grep -oE 'Acertos: *[0-9]+' /tmp/questionario.out | awk '{print $2}' | tail -n1)
      [[ -z "$QUIZ_ACERTOS" ]] && QUIZ_ACERTOS="N/A"

      # PASS somente se acertar TODAS (10); caso contrário, NOT
      if [[ "$QUIZ_ACERTOS" =~ ^[0-9]+$ ]] && [[ "$QUIZ_ACERTOS" -eq 10 ]]; then
        print_ok "Questionário executado (Acertos: $QUIZ_ACERTOS)"
        RES_EXECUCAO="$PASS_TEXT"
      else
        print_err "Questionário executado (Acertos: ${QUIZ_ACERTOS})"
        RES_EXECUCAO="$NOT_TEXT"
      fi
    else
      print_err "Falha ao executar questionário"
      RES_EXECUCAO="$NOT_TEXT"
    fi
  else
    print_err "Não foi possível clonar/achar questionario.py"
    RES_EXECUCAO="$NOT_TEXT"
  fi
  echo "----------------------------------"
}

# ===== 2) Testes com validações detalhadas =====
testa_requisitos() {
  echo -e "\n--- Requisitos ---"
  local ok_all=1
  local cpus memoria disco placas

  cpus=$(nproc)
  memoria=$(free -k | awk '/^Mem:/ {print $2}')
  disco=$(df -BG / | awk 'NR==2 {gsub("G",""); print $2}')
  placas=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | wc -l)

  local ok1=0 ok2=0 ok3=0 ok4=0
  [[ "$cpus" -eq 2 ]] && ok1=1
  [[ "$memoria" -ge 4000000 ]] && ok2=1
  [[ "$disco" -ge 25 ]] && ok3=1
  [[ "$placas" -eq 2 ]] && ok4=1

  print_check $ok1 "CPUs: $cpus (esperado: 2)"
  print_check $ok2 "Memória: ${memoria}KB (>= 4GB)"
  print_check $ok3 "Disco /: ${disco}GB (>= 25GB)"
  print_check $ok4 "Placas de rede: $placas (esperado: 2)"

  (( ok1 & ok2 & ok3 & ok4 )) || ok_all=0
  [[ $ok_all -eq 1 ]] && RES_REQUISITOS="$PASS_TEXT" || RES_REQUISITOS="$NOT_TEXT"
}

testa_sistema() {
  echo -e "\n--- Sistema ---"
  local ok_all=1
  local idioma teclado dhcp_count hostname openssh_instalado usuario_existe

  idioma=$(locale | grep '^LANG=' | cut -d= -f2)
  teclado=$( (localectl status 2>/dev/null | awk -F': ' '/X11 Layout/ {print $2}') || true )
  [[ -z "$teclado" ]] && teclado=$(setxkbmap -query 2>/dev/null | awk '/layout/ {print $2}')
  dhcp_count=$(ip address | grep -c ' dynamic ')
  hostname=$(hostname)
  dpkg -l | grep -q '^ii  openssh-server' && openssh_instalado=1 || openssh_instalado=0
  getent passwd ubuntu >/dev/null 2>&1 && usuario_existe=1 || usuario_existe=0

  local ok1=0 ok2=0 ok3=0 ok4=0 ok5=0 ok6=0
  [[ "$idioma" == "C.UTF-8" ]] && ok1=1
  [[ "$teclado" == "br" ]] && ok2=1
  [[ "$dhcp_count" -ge 2 ]] && ok3=1
  [[ $usuario_existe -eq 1 ]] && ok4=1
  [[ "$hostname" == "ubuntu" ]] && ok5=1
  [[ $openssh_instalado -eq 1 ]] && ok6=1

  print_check $ok1 "Idioma: $idioma (esperado: C.UTF-8)"
  print_check $ok2 "Layout de teclado: ${teclado:-indefinido} (esperado: br)"
  print_check $ok3 "DHCP em >= 2 interfaces (detectado: $dhcp_count)"
  print_check $ok4 "Usuário 'ubuntu' existente"
  print_check $ok5 "Hostname: $hostname (esperado: ubuntu)"
  print_check $ok6 "OpenSSH Server instalado"

  (( ok1 & ok2 & ok3 & ok4 & ok5 & ok6 )) || ok_all=0
  [[ $ok_all -eq 1 ]] && RES_SISTEMA="$PASS_TEXT" || RES_SISTEMA="$NOT_TEXT"
}

testa_ssh() {
  echo -e "\n--- SSH ---"
  local ssh_logins
  ssh_logins=$(last -i 2>/dev/null | grep -i "pts" | wc -l)
  print_check $([[ "$ssh_logins" -gt 0 ]] && echo 1 || echo 0) "Conexões SSH registradas: $ssh_logins"
  [[ "$ssh_logins" -gt 0 ]] && RES_SSH="$PASS_TEXT" || RES_SSH="$NOT_TEXT"
}

testa_usuario_root() {
  echo -e "\n--- Root ---"
  local is_root=$([[ "$(id -u)" -eq 0 ]] && echo 1 || echo 0)
  print_check $is_root "Usuário atual é root"
  [[ $is_root -eq 1 ]] && RES_ROOT="$PASS_TEXT" || RES_ROOT="$NOT_TEXT"
}

testa_pacotes() {
  echo -e "\n--- Pacotes ---"
  local ok_all=1
  local pacotes=(wget git vim cowsay)
  for p in "${pacotes[@]}"; do
    if dpkg -l | grep -q "^ii  $p"; then
      print_ok "$p instalado"
    else
      print_err "$p não instalado"
      ok_all=0
    fi
  done
  [[ $ok_all -eq 1 ]] && RES_PACOTES="$PASS_TEXT" || RES_PACOTES="$NOT_TEXT"
}

testa_arquivo() {
  echo -e "\n--- Arquivo ---"
  local arq="/root/alunos.txt"
  if [[ -f "$arq" ]]; then
    local linhas; linhas=$(wc -l | awk '{print $1}' < "$arq")
    if [[ "$linhas" -ge 1 ]]; then
      print_ok "$arq existe (linhas: $linhas)"
      RES_ARQUIVO="$PASS_TEXT"
      echo "  -- conteúdo (primeiras 10 linhas) --"
      head -n 10 "$arq"
    else
      print_err "$arq encontrado porém vazio"
      RES_ARQUIVO="$NOT_TEXT"
    fi
  else
    print_err "$arq não encontrado"
    RES_ARQUIVO="$NOT_TEXT"
  fi
}

testa_download() {
  echo -e "\n--- Download ---"
  local path
  path=$(find / -name run-me.sh 2>/dev/null | head -n1)
  if [[ -n "$path" ]]; then
    print_ok "Encontrado: $path"
    RES_DOWNLOAD="$PASS_TEXT"
  else
    print_err "run-me.sh não encontrado no sistema"
    RES_DOWNLOAD="$NOT_TEXT"
  fi
}

testa_pasta() {
  echo -e "\n--- Pasta /opt/unifebe ---"
  local pasta="/opt/unifebe"; local arquivo="run-me.sh"; local ok_all=1

  [[ -d "$pasta" ]] && print_ok "Diretório existe" || { print_err "Diretório inexistente"; ok_all=0; }
  if [[ -f "$pasta/$arquivo" ]]; then
    print_ok "Arquivo presente: $pasta/$arquivo"
    local perms; perms=$(stat -c "%A" "$pasta/$arquivo" 2>/dev/null)
    local ok_u=$([[ ${perms:1:3} == "rwx" ]] && echo 1 || echo 0)
    local ok_g=$([[ ${perms:4:1} == "r"   ]] && echo 1 || echo 0)
    local ok_o=$([[ ${perms:7:3} == "---" ]] && echo 1 || echo 0)
    print_check $ok_u "Permissões usuário: ${perms:1:3} (esperado: rwx)"
    print_check $ok_g "Permissões grupo: ${perms:4:3} (esperado: r--)"
    print_check $ok_o "Permissões outros: ${perms:7:3} (esperado: ---)"
    (( ok_u & ok_g & ok_o )) || ok_all=0
  else
    print_err "Arquivo ausente: $pasta/$arquivo"
    ok_all=0
  fi

  [[ $ok_all -eq 1 ]] && RES_PASTA="$PASS_TEXT" || RES_PASTA="$NOT_TEXT"
}

testa_final() {
  echo -e "\n--- Final ---"
  print_ok "Validações concluídas"
  RES_FINAL="$PASS_TEXT"
}

# ===== Ordem =====
testa_execucao_questionario
testa_requisitos
testa_sistema
testa_ssh
testa_usuario_root
testa_pacotes
testa_arquivo
testa_download
testa_pasta
testa_final

# ===== Pausa, limpar e resumo =====
read -rp $'\nPressione ENTER para ver o resultado final...'
clear

echo "Questionário: ${QUIZ_ACERTOS}/10"
echo "Requisitos $RES_REQUISITOS"
echo "Sistema   $RES_SISTEMA"
echo "SSH       $RES_SSH"
echo "Root      $RES_ROOT"
echo "Pacotes   $RES_PACOTES"
echo "Arquivo   $RES_ARQUIVO"
echo "Download  $RES_DOWNLOAD"
echo "Pasta     $RES_PASTA"
echo "Execução  $RES_EXECUCAO"
echo "Final     $RES_FINAL"
