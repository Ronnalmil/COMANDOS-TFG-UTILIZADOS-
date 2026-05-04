# ESTE ESTA DUPLICADO AQUI, esta en la flash nose si este en el github
#Script para Creacion de OUs, grupos y Usuarios.
param(
    [int]$numeroou,
    [int]$numerogrupos,
    [int]$numerousuarios
)
#Pido al usuario que diga el numero OUs,grupos,usuarios y si no ingresa datos se cierre. 
$numeroou = Read-Host "Número de Unidades Organizativas 'OUs' a crear " 
if (-not $numeroou) {      #si esta vacio la variable numeroou finaliza el script
exit
}
$numerogrupos = Read-Host "Número de grupos por unidad organizativa 'OU' "
if (-not $numerogrupos){    #si esta vacio la variable numerogrupos finaliza el script
exit
}
$numerousuarios = Read-Host "Número de usuarios por grupo "
if (-not $numerousuarios) {  #si esta vacio la variable numerousuarios finaliza el script
exit
}

# Interacciones para crear las Unidades Organizativas (OU) y dentro de ellas grupos y los usuarios
for ($i = 1; $i -le $numeroou; $i++) {
    # Pide el nombre de la OU a crear, si esta vacio se cierra.
    $ouNombre = Read-Host "Diga el nombre de la (OU)unidad organizativa $i "
    if (-not $ouNombre) {
        Write-Host "No se ingreso la unidad organizativa, finaliza el script ahora"
        exit
    }
    # Creo la OU con el comando New-ADOrganizationalUnit
    New-ADOrganizationalUnit -Name $ouNombre -Path "dc=milton,dc=local" -ProtectedFromAccidentalDeletion $false #aplico false para eliminarlo a futuro., si coloco true no se podra eliminar facilmente.
    Write-Host "        Unidad Organizativa '$ouNombre' esta creada      "

        # Pide el nombre del grupo a crear, si esta vacio se cierra.
        for ($j = 1; $j -le $numerogrupos; $j++) {
        $grupoNombre = Read-Host "Diga el nombre del grupo $j dentro de la OU '$ouNombre' " #guardo el nombre del grupo en $grupoNombre
            if (-not $grupoNombre) {
            Write-Host "No se ingreso el nombre del grupo, finaliza el script ahora"
            exit
            }
         # Crea el grupo dentro de la OU 
            $grupoRuta = "ou=$ouNombre,dc=milton,dc=local"                #guardo la ruta en la variable $grupoRuta
            New-ADGroup -Name $grupoNombre -Path $grupoRuta -GroupCategory Security -GroupScope Global #sino esta -GroupScope pedira al usuario que ingrese global, para ello es mejor añadirlo
            Write-Host "         El Grupo '$grupoNombre' creado en la OU '$ouNombre'    "
        
         # Crea los usuarios dentro del grupo
         # SamAccountName es el nombre de inicio de sesion de usuario
            for ($m = 1; $m -le $numerousuarios; $m++) {
            $usuarioNombre = Read-Host "Diga el nombre del usuario $m para el grupo '$grupoNombre'"      #guardo el nombre del usuario en $usuarioNombre.
            $usuarioSamAccountName = Read-Host "Cual será 'el Nombre de inicio de sesion de usuario' para el usuario '$usuarioNombre' (puede usar '$usuarioNombre')"
            $usuariocorreo = "$usuarioSamAccountName@$ouNombre.local" #guardamos el correo en la variable $usuariocorreo.
            
            # Pedimos que ingrese una contraseña para el usuario y le indicamos un ejemplo.
            Write-Host "........'Escriba una contraseña por ejemplo (Password123!)'........."
            $usuarioContrasena= Read-Host "Diga una contraseña para el usuario '$usuarioNombre' "
            $usuarioContrasena = ConvertTo-SecureString "Password123!" -AsPlainText -Force # asi no da error
            
            # Creo al usuario con el comando New-AdUser
            New-ADUser -Name "$usuarioNombre" -GivenName $usuarioNombre -SamAccountName $usuarioSamAccountName -UserPrincipalName $usuariocorreo -Path $grupoRuta -AccountPassword $usuarioContrasena -Enabled $true -ChangePasswordAtLogon $true
            Write-Host "        El Usuario '$usuarioSamAccountName' creado en la OU '$ouNombre'    "
            
            # Pregunto a qué grupo pertenecerá el usuario 
            $grupoPertenecera = Read-Host "Diga el nombre del grupo al que pertenecerá el usuario '$usuarioNombre'"

            # Verifico si el grupo existe para poder añadirlo al grupo correspondiente  
            $grupoExistente = Get-ADGroup -Filter { Name -eq $grupoPertenecera } -ErrorAction SilentlyContinue

            if ($grupoExistente) {
                # Agrega al usuario al grupo;  con el comando Add-ADGroupMember
                Add-ADGroupMember -Identity $grupoPertenecera -Members $usuarioNombre                       #$usuarioSamAccountName
                Write-Host "        El Usuario '$usuarioNombre' agregado al grupo '$grupoPertenecera'    "
            } else {
                Write-Host "El grupo '$grupoPertenecera' no existe. No se puede agregar el usuario."   
                exit
            }
        }
    }
}

Write-Host ".......Se completo con éxito la creación de las OUs, grupos y usuarios........"
