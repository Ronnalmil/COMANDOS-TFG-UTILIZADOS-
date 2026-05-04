#!/bin/bash
# ESTE FUNCIONA PERFECTO CON PARAMETROS COMPROBADO
# sino funciona upgrade antes instalar pkg que pide ubuntu luego ya funciona....
user_management() {
  while true; do
    echo
    echo "1) Crear usuario"
    echo "2) Modificar usuario"
    echo "3) Eliminar usuario"
    echo "4) Mostrar usuarios del sistema"
    echo "0) Volver al menú principal"
    read -p "Selecciona opción: " opcion
    case "$opcion" in
      1)
        while true; do
          read -p "Nombre del usuario: " nombre
          [ -n "$nombre" ] && break
        done
        if id -u "$nombre" >/dev/null 2>&1; then
          echo "El usuario '$nombre' ya existe."
          continue
        fi
        read -p "Shell (dejar vacío para defecto): " usuario_shell
        read -p "Grupo principal: " grupo_principal
        if [ -n "$grupo_principal" ]; then
          if ! getent group "$grupo_principal" >/dev/null 2>&1; then
            sudo groupadd "$grupo_principal" || continue
          fi
        fi
        read -p "Grupos secundarios (coma-separados, dejar vacío para omitir): " grupos_sec
        if [ -n "$grupos_sec" ]; then
          IFS=',' read -ra _garr <<< "$grupos_sec"
          glist=""
          for g in "${_garr[@]}"; do
            g="$(echo "$g" | xargs)"
            [ -z "$g" ] && continue
            if ! getent group "$g" >/dev/null 2>&1; then
              sudo groupadd "$g"
            fi
            if [ -z "$glist" ]; then
              glist="$g"
            else
              glist="$glist,$g"
            fi
          done
        fi
        echo "Opciones de HOME:"
        echo "1) Crear home por defecto (-m)"
        echo "2) No crear home (-M)"
        echo "3) Crear home en ruta personalizada"
        read -p "Elige 1/2/3: " opt_home
        add_opts=""
        case "$opt_home" in
          1) add_opts="-m" ;;
          2) add_opts="-M" ;;
          3)
            read -p "Ruta del HOME personalizado: " ruta_home
            add_opts="-m -d $ruta_home"
            ;;
          *) add_opts="-m" ;;
        esac
        cmd="sudo useradd"
        [ -n "$add_opts" ] && cmd="$cmd $add_opts"
        [ -n "$grupo_principal" ] && cmd="$cmd -g $grupo_principal"
        [ -n "$glist" ] && cmd="$cmd -G $glist"
        [ -n "$usuario_shell" ] && cmd="$cmd -s $usuario_shell"
        cmd="$cmd $nombre"
        if eval $cmd; then
          sudo passwd "$nombre"
        fi
        ;;
      2)
        read -p "Nombre del usuario a modificar: " nombre
        if ! id -u "$nombre" >/dev/null 2>&1; then
          continue
        fi
        while true; do
          echo
          echo "a) Cambiar shell"
          echo "b) Cambiar directorio HOME"
          echo "c) Añadir o quitar grupos (-G)"
          echo "d) Volver"
          read -p "Elige una opción: " subop
          case "$subop" in
            a)
              read -p "Nuevo shell: " nuevo_shell
              [ -n "$nuevo_shell" ] && sudo usermod -s "$nuevo_shell" "$nombre"
              ;;
            b)
              read -p "Nueva ruta HOME: " nueva_ruta_home
              if [ -n "$nueva_ruta_home" ]; then
                read -p "Mover archivos? (s/n): " mover
                if [[ "$mover" =~ ^[sS]$ ]]; then
                  sudo usermod -d "$nueva_ruta_home" -m "$nombre"
                else
                  sudo usermod -d "$nueva_ruta_home" "$nombre"
                fi
              fi
              ;;
            c)
              read -p "Acción (añadir/quitar): " accion
              if [[ "$accion" =~ ^(añadir|anadir)$ ]]; then
                read -p "Grupos a añadir: " grupos_a_aniadir
                if [ -n "$grupos_a_aniadir" ]; then
                  IFS=',' read -ra _add <<< "$grupos_a_aniadir"
                  glist=""
                  for g in "${_add[@]}"; do
                    g="$(echo "$g" | xargs)"
                    [ -z "$g" ] && continue
                    if ! getent group "$g" >/dev/null 2>&1; then
                      sudo groupadd "$g"
                    fi
                    if [ -z "$glist" ]; then
                      glist="$g"
                    else
                      glist="$glist,$g"
                    fi
                  done
                  [ -n "$glist" ] && sudo usermod -aG "$glist" "$nombre"
                fi
              elif [[ "$accion" =~ ^quitar$ ]]; then
                read -p "Grupos a quitar: " grupos_a_quitar
                if [ -n "$grupos_a_quitar" ]; then
                  IFS=',' read -ra _rem <<< "$grupos_a_quitar"
                  for g in "${_rem[@]}"; do
                    g="$(echo "$g" | xargs)"
                    [ -n "$g" ] && sudo gpasswd -d "$nombre" "$g" >/dev/null 2>&1
                  done
                fi
              fi
              ;;
            d) break ;;
          esac
        done
        ;;
      3)
        read -p "Nombre del usuario a eliminar: " nombre
        if id -u "$nombre" >/dev/null 2>&1; then
          echo "a) Eliminación segura"
          echo "b) Eliminación completa"
          echo "c) Cancelar"
          read -p "Elige: " optb
          case "$optb" in
            a) sudo userdel "$nombre" ;;
            b) sudo userdel -r "$nombre" ;;
          esac
        fi
        ;;
      4)
        while IFS=: read -r user pw uid gid gecos home shell; do
          echo "$user:$uid:$gid:$home:$shell"
        done < /etc/passwd
        ;;
      0) break ;;
    esac
  done
}

paquetes_management() {
  while true; do
    echo
    echo "1) Actualizar repositorios"
    echo "2) Actualizar el sistema"
    echo "3) Instalar paquete"
    echo "4) Desinstalar paquete"
    echo "5) Purgar un paquete"
    echo "0) Volver"
    read -p "Selecciona opción: " pop
    case "$pop" in
      1) sudo apt update >/dev/null 2>&1 && echo "Hecho" || echo "No realizado" ;;
      2) sudo apt upgrade -y >/dev/null 2>&1 && echo "Hecho" || echo "No realizado" ;;
      3) read -p "Paquete: " pkg; [ -n "$pkg" ] && sudo apt install -y "$pkg" >/dev/null 2>&1 ;;
      4) read -p "Paquete: " pkg; [ -n "$pkg" ] && sudo apt remove -y "$pkg" >/dev/null 2>&1 ;;
      5) read -p "Paquete: " pkg; [ -n "$pkg" ] && sudo apt purge -y "$pkg" >/dev/null 2>&1 ;;
      0) break ;;
    esac
  done
}

procesos_management() {
  while true; do
    echo
    echo "1) Ver todos los procesos"
    echo "2) Ver árbol de procesos"
    echo "3) Buscar procesos por nombre"
    echo "4) Ver procesos en tiempo real"
    echo "5) Matar proceso por PID"
    echo "6) Matar procesos por nombre"
    echo "0) Volver"
    read -p "Selecciona opción: " p
    case "$p" in
      1) ps aux ;;
      2) ps axjf ;;
      3) read -p "Nombre: " nom; [ -n "$nom" ] && ps aux | grep -i "$nom" | grep -v grep ;;
      4) top ;;
      5) read -p "PID: " pid; [[ "$pid" =~ ^[0-9]+$ ]] && kill "$pid" ;;
      6) read -p "Nombre: " nom; [ -n "$nom" ] && pkill "$nom" ;;
      0) break ;;
    esac
  done
}

permisos_management() {
  while true; do
    read -p "Ruta del archivo o carpeta: " ruta
    [ -e "$ruta" ] || { echo "Ruta no existe"; break; }
    echo "Permisos actuales:"
    ls -ld "$ruta"
    read -p "Permisos en octal (ej. 644, 755): " perms
    [[ "$perms" =~ ^[0-7]{3,4}$ ]] || { echo "Permisos inválidos"; break; }
    read -p "Propietario: " usuario
    [ -n "$usuario" ] || break
    read -p "Grupo: " grupo
    [ -n "$grupo" ] || break
    chmod "$perms" "$ruta"
    chown "$usuario":"$grupo" "$ruta"
    echo "Permisos después del cambio:"
    ls -ld "$ruta"
    break
  done
}

tareas_management() {
  while true; do
    echo
    echo "1) Crear tarea programada"
    echo "0) Volver"
    read -p "Selecciona opción: " topa
    case "$topa" in
      1)
        read -p "Minuto (0-59, *): " minuto
        [[ "$minuto" =~ ^([0-9]|[1-5][0-9]|\*)$ ]] || { echo "Minuto inválido"; continue; }
        read -p "Hora (0-23, *): " hora
        [[ "$hora" =~ ^([0-9]|1[0-9]|2[0-3]|\*)$ ]] || { echo "Hora inválida"; continue; }
        read -p "Día del mes (1-31, *): " dia
        [[ "$dia" =~ ^([1-9]|[12][0-9]|3[01]|\*)$ ]] || { echo "Día inválido"; continue; }
        read -p "Mes (1-12, *): " mes
        [[ "$mes" =~ ^([1-9]|1[0-2]|\*)$ ]] || { echo "Mes inválido"; continue; }
        read -p "Día de semana (0-7, *): " semana
        [[ "$semana" =~ ^([0-7]|\*)$ ]] || { echo "Día inválido"; continue; }
        read -p "Comando: " comando
        [ -n "$comando" ] || { echo "Comando vacío"; continue; }
        (sudo crontab -l 2>/dev/null; echo "$minuto $hora $dia $mes $semana $comando") | sudo crontab -
        echo "Tarea agregada"
        ;;
      0) break ;;
    esac
  done
}

if [ $# -ge 1 ]; then
  case "$1" in
    usuarios) user_management; exit 0 ;;
    paquetes) paquetes_management; exit 0 ;;
    procesos) procesos_management; exit 0 ;;
    permisos) permisos_management; exit 0 ;;
    tareas) tareas_management; exit 0 ;;
    help|-h|--help)
      echo "Uso: $0 [usuarios|paquetes|procesos|permisos|tareas]"
      exit 0
      ;;
    *)
      echo "Parámetro no reconocido: $1"
      echo "Uso: $0 [usuarios|paquetes|procesos|permisos|tareas]"
      exit 1
      ;;
  esac
fi

while true; do
  echo
  echo "1) Gestión de usuarios"
  echo "2) Opción paquetes"
  echo "3) Opción procesos"
  echo "4) Opción permisos"
  echo "5) Opción tareas"
  echo "0) Salir"
  read -p "Selecciona opción: " mainop
  case "$mainop" in
    1) user_management ;;
    2) paquetes_management ;;
    3) procesos_management ;;
    4) permisos_management ;;
    5) tareas_management ;;
    0) exit 0 ;;
  esac
done
