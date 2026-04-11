<?php
if (session_status() === PHP_SESSION_NONE) session_start();

/*------------------------------------------------------------------*/
/**
 * @brief Genera el código HTML de un botón para regresar al inicio.
 * @param resource $conn Recurso de conexión a la base de datos.
 * @return string Cadena de texto con el botón HTML.
 */
function fn_boton_menu_principal($conn)
/*--------------------------------------------------------------------*/
{
    $url = "?opcion=menu_opciones";

    if (isset($_SESSION['usuario_id'])) {
        $user_id = (int)$_SESSION['usuario_id'];
        $sql = "SELECT token FROM usuarios WHERE id = $user_id";
        $res = procesar_query($sql, $conn);
        $token = $res->datos[0]['token'] ?? '';

        if ($token != '')
            $url .= "&token=$token";
    }

    $scr_menu = "window.open('$url', '_top');";
    return "<button onClick=\"$scr_menu\">Menu del programa</button>";
}

/*------------------------------------------------------------------*/
/**
 * @brief Controlador centralizado de navegación y seguridad.
 * @param resource $conn Recurso de conexión a la base de datos.
 * @return string Interfaz HTML (Login o Menú) basada en validación de Token y Roles.
 */
function fn_menu_opciones($conn)
{
    if (session_status() === PHP_SESSION_NONE) session_start();
    $retorno = "";
    $mostrar_login = false;

    // Manejo de salida (logout)
    if (isset($_REQUEST['accion']) && $_REQUEST['accion'] == 'salir') {
        session_destroy();
        $retorno = "<h2>Sesión cerrada correctamente</h2>";
        $mostrar_login = true;
    }

    // Procesamiento del intento de login
    if (!$mostrar_login && !isset($_SESSION['usuario_id']) && isset($_POST['login'])) {
        $login = $_POST['login'];
        $clave_plana = $_POST['clave'];

        $sql = "SELECT id
                FROM usuarios
                WHERE login = '$login'
                  AND clave = digest('$clave_plana', 'sha256')";
        $res = procesar_query($sql, $conn);

        if ($res->cantidad > 0) {
            $user_id = $res->datos[0]['id'];
            $nuevo_token = uniqid();

            // Actualizar el token del usuario
            procesar_query("UPDATE usuarios SET token = '$nuevo_token' WHERE id = $user_id", $conn);

            $_SESSION['usuario_id'] = $user_id;
            header("Location: index.php?token=$nuevo_token");
            exit;
        } else {
            $retorno = "<p class='ALERTA'>Usuario o contraseña incorrectos.</p>";
            $mostrar_login = true;
        }
    }

    // Validación de seguridad y delegación por rol
    if (!$mostrar_login && isset($_SESSION['usuario_id'])) {
        $user_id = $_SESSION['usuario_id'];
        $token_recibido = $_REQUEST['token'] ?? '';

        $res_val = procesar_query("SELECT token FROM usuarios WHERE id = $user_id", $conn);
        $token_real = $res_val->datos[0]['token'] ?? '';

        if ($token_recibido === '' || $token_recibido !== $token_real) {
            session_destroy();
            $retorno = "<p class='ALERTA'>Sesión expirada o acceso no autorizado.</p>";
            $mostrar_login = true;
        } else {
            $retorno = fn_generar_interfaz_por_rol($conn, $token_recibido);
        }
    } else {
        $mostrar_login = true;
    }

    // Mostrar el formulario de login si el usuario no está autenticado
    if ($mostrar_login) {
        $retorno .= fn_formulario_login();
    }

    return $retorno;
}

/*------------------------------------------------------------------*/
/**
 * @brief Genera la interfaz de usuario filtrando opciones según roles asignados.
 * @param resource $conn Recurso de conexión a la base de datos PostgreSQL.
 * @param string $token Token de seguridad validado contra la base de datos.
 * @return string Fragmento HTML con los botones permitidos para el usuario actual.
 */
function fn_generar_interfaz_por_rol($conn, $token)
{
    $uid = $_SESSION['usuario_id'];
    $opcion = $_REQUEST['opcion'] ?? '';
    $funcion = "fn_" . $opcion;

    // Opción pública
    if ($opcion == 'desplegar_menu' && is_callable($funcion)) {
        return $funcion($conn);
    }

    // Opciones con control por rol
    $autorizado = false;
    switch ($opcion) {
        case 'gestion_reservas':
        case 'reporte_estadistico':
            $autorizado = fn_validar_rol_db($conn, $uid, 'maitre');
            break;

        case 'realizar_pedidos':
            $autorizado = fn_validar_rol_db($conn, $uid, 'mesero');
            break;

        case 'cocina':
            $autorizado = fn_validar_rol_db($conn, $uid, 'cocinero');
            break;

        case 'admin_dashboard':  // Asegúrate de que esta línea esté aquí para el ADMINISTRADOR
            $autorizado = fn_validar_rol_db($conn, $uid, 'admin');
            break;
    }

    // Si el rol es autorizado para esa opción
    if ($autorizado && is_callable($funcion)) {
        return $funcion($conn);
    }

    // Menú principal
    $retorno = "<h1>Opciones del Programa</h1><div class='MENU_OPCIONES'>";

    // Menú para todos los roles
    $scr_menu = "window.open('?opcion=desplegar_menu&token=$token', '_top');";
    $retorno .= "<button onClick=\"$scr_menu\">Desplegar Menu</button>";

    // Menú para el rol ADMINISTRADOR
    if (fn_validar_rol_db($conn, $uid, 'admin')) {
    $scr_dashboard = "window.open('?opcion=admin_dashboard&token=$token', '_top');";
    $retorno .= "<button onClick=\"$scr_dashboard\">Dashboard Admin</button>";
}

    // Menú para el rol MAITRE
    if (fn_validar_rol_db($conn, $uid, 'maitre')) {
        $scr_reservas = "window.open('?opcion=gestion_reservas&token=$token', '_top');";
        $retorno .= "<button onClick=\"$scr_reservas\">Reservas</button>";

        $scr_reporte = "window.open('?opcion=reporte_estadistico&token=$token', '_top');";
        $retorno .= "<button onClick=\"$scr_reporte\">Reporte</button>";
    }

    // Menú para el rol MESERO
    if (fn_validar_rol_db($conn, $uid, 'mesero')) {
        $scr_pedido = "window.open('?opcion=realizar_pedidos&token=$token', '_top');";
        $retorno .= "<button onClick=\"$scr_pedido\">Registrar Pedido</button>";
    }

    // Menú para el rol COCINERO
    if (fn_validar_rol_db($conn, $uid, 'cocinero')) {
        $scr_cocina = "window.open('?opcion=cocina&token=$token', '_top');";
        $retorno .= "<button onClick=\"$scr_cocina\">Cocina</button>";
    }

    $uereele = "?opcion=menu_opciones&token=$token&accion=salir";
    $retorno .= "</div><br><a href='$uereele'>Cerrar Sesión</a>";

    return $retorno;
}

function fn_admin_dashboard($conn, $token)
{
    // Mostrar título del Dashboard
    $retorno = "<h1>Bienvenido al Dashboard de Administrador</h1>";
    $retorno .= "<p>Aquí puedes gestionar el sistema.</p>";

    // Opciones disponibles para el administrador
    $retorno .= "<h2>Opciones de Gestión</h2>";
    $retorno .= "<ul>";
    
    // Enlace para gestionar reservas
    $retorno .= "<li><a href='?opcion=gestion_reservas&token=$token'>Gestionar Reservas</a></li>";

    // Enlace para ver reportes estadísticos
    $retorno .= "<li><a href='?opcion=reporte_estadistico&token=$token'>Ver Reporte Estadístico</a></li>";
    
    // Enlace para administrar usuarios (nuevo caso de uso para el administrador)
    $retorno .= "<li><a href='?opcion=administrar_usuarios&token=$token'>Administrar Usuarios</a></li>";

    // Opción para ver el historial de reservas y pedidos
    $retorno .= "<li><a href='?opcion=ver_historial_reservas&token=$token'>Ver Historial de Reservas y Pedidos</a></li>";
    
    // Opción para ver estadísticas del sistema (por ejemplo, número de usuarios, pedidos, etc.)
    $retorno .= "<li><a href='?opcion=ver_estadisticas&token=$token'>Estadísticas del Sistema</a></li>";

    $retorno .= "</ul>";

    // Agregar un enlace para salir del sistema
    $retorno .= "<br><a href='?opcion=menu_opciones&token=$token&accion=salir'>Cerrar Sesión</a>";

    return $retorno;
}


function fn_administrar_usuarios($conn, $token)
{
    $retorno = "<h1>Administrar Usuarios</h1>";

    // Consulta para obtener todos los usuarios
    $sql = "SELECT id, nombre, login FROM usuarios";
    $res = procesar_query($sql, $conn);

    // Verificar si hay usuarios
    if ($res->cantidad > 0) {
        $retorno .= "<table><tr><th>ID</th><th>Nombre</th><th>Login</th></tr>";
        foreach ($res->datos as $usuario) {
            $retorno .= "<tr><td>" . $usuario['id'] . "</td><td>" . $usuario['nombre'] . "</td><td>" . $usuario['login'] . "</td></tr>";
        }
        $retorno .= "</table>";
    } else {
        $retorno .= "<p>No se encontraron usuarios.</p>";
    }

    // Agregar un enlace para regresar al menú de administración
    $retorno .= "<br><a href='?opcion=admin_dashboard&token=$token'>Volver al Dashboard Admin</a>";

    return $retorno;
}

function fn_ver_historial_reservas($conn, $token)
{
    $retorno = "<h1>Historial de Reservas y Pedidos</h1>";

    // Consulta para obtener todas las reservaciones y pedidos
    $sql = "
        SELECT R.id AS reservacion_id, U.nombre AS cliente, R.estado AS estado_reserva, H.mesa_id, 
               P.id AS pedido_id, P.solicitado AS estado_pedido  -- Aquí usamos 'solicitado' como estado del pedido
        FROM reservaciones R
        JOIN usuarios U ON R.cliente_id = U.id
        LEFT JOIN horarios H ON R.id = H.reservacion_id
        LEFT JOIN pedidos P ON H.mesa_id = P.mesa_id
        ORDER BY R.id DESC
    ";
    $res = procesar_query($sql, $conn);

    // Verificar si hay registros
    if ($res->cantidad > 0) {
        $retorno .= "<table><tr><th>Reserva ID</th><th>Cliente</th><th>Estado Reserva</th><th>Mesa</th><th>Pedido ID</th><th>Estado Pedido</th></tr>";
        foreach ($res->datos as $registro) {
            $retorno .= "<tr>
                <td>" . $registro['reservacion_id'] . "</td>
                <td>" . $registro['cliente'] . "</td>
                <td>" . $registro['estado_reserva'] . "</td>
                <td>" . $registro['mesa_id'] . "</td>
                <td>" . $registro['pedido_id'] . "</td>
                <td>" . $registro['estado_pedido'] . "</td>
            </tr>";
        }
        $retorno .= "</table>";
    } else {
        $retorno .= "<p>No se encontraron reservas ni pedidos.</p>";
    }

    // Agregar un enlace para regresar al menú de administración
    $retorno .= "<br><a href='?opcion=admin_dashboard&token=$token'>Volver al Dashboard Admin</a>";

    return $retorno;
}

function fn_ver_estadisticas($conn, $token)
{
    $retorno = "<h1>Estadísticas del Sistema</h1>";

    // Consulta para obtener el número total de usuarios registrados
    $sql_usuarios = "SELECT COUNT(*) AS total_usuarios FROM usuarios";
    $res_usuarios = procesar_query($sql_usuarios, $conn);
    $total_usuarios = $res_usuarios->datos[0]['total_usuarios'];

    // Consulta para obtener el número total de pedidos
    $sql_pedidos = "SELECT COUNT(*) AS total_pedidos FROM pedidos";
    $res_pedidos = procesar_query($sql_pedidos, $conn);
    $total_pedidos = $res_pedidos->datos[0]['total_pedidos'];

    // Mostrar las estadísticas
    $retorno .= "<p>Total de usuarios registrados: " . $total_usuarios . "</p>";
    $retorno .= "<p>Total de pedidos realizados: " . $total_pedidos . "</p>";

    // Agregar un enlace para regresar al menú de administración
    $retorno .= "<br><a href='?opcion=admin_dashboard&token=$token'>Volver al Dashboard Admin</a>";

    return $retorno;
}


function notificar_mesero($pedido_id, $mesero_id, $conn)
{
    // Consulta para obtener el nombre del mesero
    $sql = "SELECT nombre FROM usuarios WHERE id = $mesero_id";
    $resultado = procesar_query($sql, $conn);
    $mesero_nombre = $resultado->datos[0]['nombre'];

    // Mensaje de notificación
    $mensaje = "El pedido #$pedido_id está listo para ser entregado. Mesero: $mesero_nombre.";

    // Aquí podrías usar JavaScript para mostrar una notificación en la interfaz web
    echo "<script>alert('$mensaje');</script>";
}

/*------------------------------------------------------------------*/
/**
 * @brief Obtiene y valida el token presente en la petición actual.
 * @param resource $conn Recurso de conexión a la base de datos.
 * @return string El token si es válido, de lo contrario termina la ejecución.
 */
function fn_cargar_token_activo($conn)
/*--------------------------------------------------------------------*/
{
    $token_recibido = $_REQUEST['token'] ?? '';
    $user_id = $_SESSION['usuario_id'] ?? 0;

    $sql = "SELECT token FROM usuarios WHERE id = $user_id";
    $res = procesar_query($sql, $conn);
    $token_real = $res->datos[0]['token'] ?? '';

    if ($token_recibido === '' || $token_recibido !== $token_real) {
        session_destroy();
        header("Location: index.php");
        exit;
    }

    return $token_recibido;
}

/*------------------------------------------------------------------*/
/**
 * @brief Despliega el formulario de autenticación para el ingreso al sistema.
 * @return string Cadena de texto con el formulario HTML de inicio de sesión.
 */
function fn_formulario_login()
/*--------------------------------------------------------------------*/
{
    return "
    <form method='POST' action='?opcion=menu_opciones'>
        <h3>Ingreso al Sistema</h3>
        <input type='text' name='login' placeholder='Usuario' required><br>
        <input type='password' name='clave' placeholder='Contraseña' required><br><br>
        <button type='submit'>Ingresar</button>
    </form>";
}

/*------------------------------------------------------------------*/
/**
 * @brief Verifica en la base de datos si un usuario posee un rol determinado.
 * @param resource $conn Recurso de conexión a la base de datos.
 * @param int $usuario_id Identificador único del usuario.
 * @param string $nombre_rol Nombre del rol a validar.
 * @return bool True si el rol existe para el usuario, False en caso contrario.
 */
function fn_validar_rol_db($conn, $usuario_id, $nombre_rol)
{
    // Mapeo de los nombres de roles a los ID de rol en la base de datos
    $roles = [
        'admin' => 1,         // Administrador tiene ID 1
        'maitre' => 2,
        'mesero' => 3,
        'cocinero' => 4
    ];

    // Verifica si el nombre del rol es válido
    if (!isset($roles[$nombre_rol])) {
        echo "ROL NO VÁLIDO";  // Depuración si el rol no es reconocido
        return false;  // Si el rol no existe en el mapeo, devuelve falso
    }

    $rol_id = $roles[$nombre_rol];  // Obtiene el ID del rol correspondiente

    // Consulta para verificar si el usuario tiene asignado el rol correcto
    $sentencia = "
        SELECT count(*) as total
        FROM actuaciones AS act
        WHERE act.usuario_id = $usuario_id
          AND act.rol_id = $rol_id
    ";
    
    // Ejecución de la consulta
    $resultado = procesar_query($sentencia, $conn);
    
    if ($resultado->cantidad == 0) {
        echo "ROL NO ASIGNADO";  // Depuración si el rol no está asignado
    }

    return ($resultado->datos[0]['total'] > 0);  // Si el rol está asignado, retorna verdadero
}
/*------------------------------------------------------------------*/
/**
 * @brief Obtiene el ID del usuario asociado a un token de sesión activo.
 * @param resource $conn Recurso de conexión a PostgreSQL.
 * @param string $token El token de la sesión actual.
 * @return int|null El ID del usuario o null si la sesión no es válida.
 */
function fn_obtener_id_usuario_por_token($conn, $token)
/*--------------------------------------------------------------------*/
{
    $retorno = null;
    $token_clean = pg_escape_string($conn, $token);

    $sql = "SELECT id
            FROM usuarios
            WHERE token = '$token_clean'
            LIMIT 1";

    $res = procesar_query($sql, $conn);

    if ($res && $res->cantidad > 0)
        $retorno = (int)$res->datos[0]['id'];

    return $retorno;
}




function actualizar_estado_pedido($pedido_id, $mesero_id, $conn) {
    // Actualizar el estado del pedido a "entregado" (2)
    $sql_update = "UPDATE ordenes SET estado = 2 WHERE id = $pedido_id";
    procesar_query($sql_update, $conn);

    // Llamar a la función para notificar al mesero que el pedido está listo para ser entregado
    notificar_mesero($pedido_id, $mesero_id, $conn);
}




/*------------------------------------------------------------------*/
/**
 * @brief Consulta y visualiza la carta de platos agrupados por tipo.
 * @param resource $conn Recurso de conexión a la base de datos.
 * @return string Lista HTML con las secciones y platos del restaurante.
 */
function fn_desplegar_menu($conn)
/*--------------------------------------------------------------------*/
{
    $sentencia = "
    SELECT platos.id
         , platos.nombre
         , tipos.nombre AS tipo
         , descripcion
         , precio
    FROM platos
    LEFT JOIN tipos ON platos.tipo_id = tipos.id
    ORDER BY tipos.id, platos.nombre
    ;";
    $resultado = procesar_query($sentencia, $conn);

    $retorno = fn_boton_menu_principal($conn) . "<br />";
    $tipo = "<div class='SECCION'>";

    foreach ($resultado->datos as $plato) {
        if ($tipo != $plato['tipo']) {
            $retorno .= "</div><div class='SECCION'><h2>" . $plato['tipo'] . "</h2>";
            $tipo = $plato['tipo'];
        }

        $retorno .= "<div class='PLATO'>"
                 .      "<span class='NOMBRE'>" . $plato['nombre'] . "</span>"
                 .      "<span class='DESCRIPCION'>" . $plato['descripcion'] . "</span>"
                 .      "<span class='PRECIO'>$" . $plato['precio'] . "</span>"
                 .  "</div>";
    }

    $retorno .= "</div>";
    $retorno = "<ul>$retorno</ul>";

    return $retorno;
}

/*------------------------------------------------------------------*/
/**
 * @brief Gestión dinámica de mesas con selección de tiempo y actualización AJAX.
 * @param resource $conn Recurso de conexión a la base de datos PostgreSQL.
 * @return string Interfaz HTML con selector de tiempo o fragmento de tabla.
 */
function fn_gestion_reservas($conn)
/*--------------------------------------------------------------------*/
{
    $token = fn_cargar_token_activo($conn);

    $fecha_filtro = $_REQUEST['fecha_filtro'] ?? date('Y-m-d');
    $hora_filtro  = $_REQUEST['hora_filtro']  ?? date('H:i');

    $timestamp_busqueda = "$fecha_filtro $hora_filtro:00";

    if (!isset($_REQUEST['plano'])) {
        $retorno = fn_boton_menu_principal($conn) . "<br />";
        $retorno .= "<h1>Gestión de Mesas</h1>";

        $retorno .= "
        <form method='GET' class='FRM_RESERVAS'>
            <input type='hidden' name='opcion' value='gestion_reservas'>
            <input type='hidden' name='token' value='$token'>
            <strong>Consultar disponibilidad:</strong> &nbsp;
            Fecha: <input type='date' name='fecha_filtro' value='$fecha_filtro'>
            Hora: <input type='time' name='hora_filtro' value='$hora_filtro'>
            <button type='submit'>Consultar</button>
        </form><br>";

        $retorno .= "<div id='capa_gestion_reservas'>Cargando estado de mesas...</div>";

        $filtros_js = "&fecha_filtro=$fecha_filtro&hora_filtro=$hora_filtro";

        $script = "fn_refrescar_automatico( 'gestion_reservas'"
                .                         ", 'capa_gestion_reservas'"
                .                         ", '$token'"
                .                         ", '$filtros_js');";
        $retorno .= "<script>$script</script>";

        return $retorno;
    }

    $sentencia = "
        SELECT
            M.id as mesa_id,
            M.sillas,
            CASE
                WHEN (SELECT COUNT(*) FROM pedidos P
                      WHERE P.cliente_id = U.id
                      AND P.solicitado::date = CAST('$fecha_filtro' AS DATE)) > 0 THEN 'Ocupada'
                WHEN R.id IS NOT NULL THEN 'Reservada'
                ELSE 'Libre'
            END as estado_actual,
            U.nombre as cliente
        FROM mesas M
        LEFT JOIN horarios H ON M.id = H.mesa_id
             AND CAST('$timestamp_busqueda' AS TIMESTAMP) BETWEEN H.inicio AND (H.inicio + H.duracion)
        LEFT JOIN reservaciones R ON H.reservacion_id = R.id
        LEFT JOIN usuarios U ON R.cliente_id = U.id
        ORDER BY M.id";

    $resultado = procesar_query($sentencia, $conn);

    $tabla = "<table class='RESERVAS'>
                <tr>
                    <th>Mesa #</th>
                    <th>Capacidad</th>
                    <th>Estado Actual</th>
                    <th>Cliente / Asignado</th>
                </tr>";

    if (isset($resultado->datos) && count($resultado->datos) > 0) {
        foreach ($resultado->datos as $m) {
            $color = "#E6FFE6";
            if ($m['estado_actual'] == 'Reservada') $color = "#FFF4E6";
            if ($m['estado_actual'] == 'Ocupada')   $color = "#FFE6E6";

            $tabla .= "<tr bgcolor='$color'>
                        <td class='MESA'>" . $m['mesa_id'] . "</td>
                        <td>" . $m['sillas'] . "</td>
                        <td>" . $m['estado_actual'] . "</td>
                        <td>" . ($m['cliente'] ? htmlspecialchars($m['cliente']) : "---") . "</td>
                      </tr>";
        }
    } else {
        $tabla .= "<tr><td colspan='4'>No se encontraron mesas en la base de datos.</td></tr>";
    }

    $tabla .= "</table>";
    $tabla .= "<div class='NOTA_PIE'>Sincronización: " . date("H:i:s") . "</div>";

    return $tabla;
}

/*------------------------------------------------------------------*/
/**
 * @brief Sistema de pedidos vinculado a reservaciones activas.
 * @param resource $conn Recurso de conexión a la base de datos PostgreSQL.
 * @return string Interfaz de orden.
 */
function fn_realizar_pedidos($conn)
/*--------------------------------------------------------------------*/
{
    $token = fn_cargar_token_activo($conn);
    $uid_mesero = $_SESSION['usuario_id'];
    $retorno = fn_boton_menu_principal($conn) . "<br />";

    $accion = $_REQUEST['accion'] ?? 'seleccionar_cliente';
    $cliente_id = $_REQUEST['cliente_id'] ?? null;

    switch ($accion) {
        case 'seleccionar_cliente':
            $retorno .= "<h1>Nueva Orden: Seleccione Cliente y Mesa</h1>";

            $sql = "SELECT U.id as cliente_id, U.nombre, R.id as reservacion_id, H.mesa_id
                    FROM usuarios U
                    JOIN reservaciones R ON U.id = R.cliente_id
                    JOIN horarios H ON R.id = H.reservacion_id
                    WHERE CURRENT_TIMESTAMP BETWEEN H.inicio AND (H.inicio + H.duracion)
                    ORDER BY U.nombre, H.mesa_id";
            $res = procesar_query($sql, $conn);

            if (isset($res->datos) && count($res->datos) > 0) {
                foreach ($res->datos as $c) {
                    $url = "?opcion=realizar_pedidos&token=$token&cliente_id="
                         . $c['cliente_id'] . "&accion=tomar_orden";
                    $retorno .= "<button onClick=\"window.open('$url', '_top')\" class='BTN_MESA'>
                                    <strong>" . $c['nombre'] . "</strong><br><small>Mesa: " . $c['mesa_id'] . "</small>
                                 </button>";
                }
            } else {
                $retorno .= "<p>No hay clientes con reservaciones activas en este momento.</p>";
            }
            break;

        case 'tomar_orden':
            $retorno .= "<h1>Orden para Cliente #$cliente_id</h1>";
            $sql_p = "SELECT P.id, P.nombre, P.precio, T.nombre as categoria
                      FROM platos P
                      JOIN tipos T ON P.tipo_id = T.id
                      ORDER BY T.id ASC, P.nombre ASC";
            $res_p = procesar_query($sql_p, $conn);

            $retorno .= "
            <script>
                function actualizarTotal() {
                    let total = 0;
                    document.querySelectorAll('.cant-plato').forEach(input => {
                        let cantidad = parseInt(input.value) || 0;
                        let precio = parseFloat(input.getAttribute('data-precio'));
                        if (cantidad > 0) total += (precio * cantidad);
                    });
                    document.getElementById('total_pedido').innerHTML
                        = new Intl.NumberFormat('es-CO').format(total);
                }
            </script>";

            $accion = "?opcion=realizar_pedidos&token=$token&cliente_id=$cliente_id&accion=guardar_todo";
            $retorno .= "<form method='POST' action='$accion'>";
            $retorno .= "<table class='TBL_PEDIDOS'>";

            $categoria_actual = "";
            foreach ($res_p->datos as $p) {
                if ($categoria_actual != $p['categoria']) {
                    $categoria_actual = $p['categoria'];
                    $retorno .= "<tr class='TIPO_PLT'><td colspan='3'>"
                              . strtoupper($categoria_actual)
                              . "</td></tr>";
                    $retorno .= "<tr class='ENCB_PLT'><th>Plato</th><th>Precio</th><th>Cantidad</th></tr>";
                }

                $retorno .= "
                <tr>
                    <td>" . htmlspecialchars($p['nombre']) . "</td>
                    <td class='DERECHA'>$" . number_format($p['precio'], 0, ',', '.') . "</td>
                    <td class='CENTRADO'>
                        <input type='number' class='cant-plato' name='cantidades[" . $p['id'] . "]'
                               value='0' min='0' data-precio='" . $p['precio'] . "' onInput='actualizarTotal()'>
                    </td>
                </tr>";
            }

            $retorno .= "</table>
            <div class='CONT_TOTAL'>
                TOTAL: $ <span id='total_pedido'>0</span>
            </div>
            <br><button type='submit' class='BTN_PEDIDOS'>CONFIRMAR PEDIDO</button></form>";
            break;

        case 'guardar_todo':
            $cantidades = $_POST['cantidades'] ?? [];
            $items = array_filter($cantidades, function($v) { return (int)$v > 0; });

            if (empty($items))
                return $retorno . "<p class='ALERTA'>El pedido está vacío.</p>";

            $sql_cab = "INSERT INTO pedidos (cliente_id, mesero_id, solicitado)
                        VALUES ($cliente_id, $uid_mesero, CURRENT_TIMESTAMP) RETURNING id";
            $res_cab = procesar_query($sql_cab, $conn);

            $id_pedido = $res_cab->datos[0]['id'] ?? null;
            if (!$id_pedido) {
                $res_seq = procesar_query("SELECT lastval() as id", $conn);
                $id_pedido = $res_seq->datos[0]['id'] ?? null;
            }

            foreach ($items as $plato_id => $cantidad) {
                $sql_det = "INSERT INTO ordenes (pedido_id, plato_id, cantidad, estado)
                            VALUES ($id_pedido, " . (int)$plato_id . ", " . (int)$cantidad . ", 0)";
                procesar_query($sql_det, $conn);
            }

            $script_js = "window.open('?opcion=realizar_pedidos&token=$token','_top')";
            $retorno .= "<div class='REGISTRADO'>
                            <h2>Pedido #$id_pedido Registrado</h2>
                            <button onClick=\"$script_js\">Nuevo Pedido</button>
                         </div>";
            break;
    }

    return $retorno;
}

/*------------------------------------------------------------------*/
/**
 * @brief Genera la tabla HTML del panel de cocina.
 * @param array $datos Órdenes pendientes.
 * @param string $token Token activo de sesión.
 * @return string Tabla HTML para cocina.
 */
function fn_generar_tabla_cocina($datos, $token)
/*--------------------------------------------------------------------*/
{
    $retorno = "<table class='TBL_COCINA'>";
    $retorno .= "<tr class='ENCABEZADO'>
                    <th>Orden</th>
                    <th>Plato</th>
                    <th>Cantidad</th>
                    <th>Cliente</th>
                    <th class='MESA'>Mesa</th>
                    <th>Solicitado</th>
                    <th>Acción</th>
                 </tr>";

    foreach ($datos as $fila) {
        $orden_id = (int)$fila['orden_id'];
        $div_id = "orden_" . $orden_id;

        $mensaje = "<b class='PREPARADO'>PREPARADO</b>";
        $datos_ajax = "orden_id=" . $orden_id;

        $boton = "<button onClick=\"llamarProceso('index.php?opcion=cocina&token=$token&plano=1', '$div_id', '$datos_ajax', '$mensaje')\">Preparado</button>";

        $retorno .= "<tr class='DATOS'>
                        <td>" . $orden_id . "</td>
                        <td>" . htmlspecialchars($fila['plato']) . "</td>
                        <td class='CENTRADO'>" . $fila['cantidad'] . "</td>
                        <td>" . htmlspecialchars($fila['cliente']) . "</td>
                        <td class='MESA'>" . ($fila['mesa_id'] ?? '---') . "</td>
                        <td>" . $fila['solicitado'] . "</td>
                        <td id='$div_id'>" . $boton . "</td>
                    </tr>";
    }

    $retorno .= "</table>";
    return $retorno;
}

/*------------------------------------------------------------------*/
/**
 * @brief Panel de cocina filtrado por especialidad.
 * @param resource $conn Recurso de conexión a PostgreSQL.
 * @return string Interfaz, Tabla completa o solo el estado "PREPARADO".
 */
function fn_cocina($conn)
{
    $retorno = "";
    $token = fn_cargar_token_activo($conn);
    $id_cocinero = fn_obtener_id_usuario_por_token($conn, $token);

    // CASO A: actualización puntual
    if (isset($_POST['datos']) && $_POST['datos'] != '') {
        parse_str($_POST['datos'], $datos_recibidos);
        $id_update = (int)($datos_recibidos['orden_id'] ?? 0);

        if ($id_update > 0) {
            procesar_query("UPDATE ordenes SET estado = 1 WHERE id = $id_update", $conn);
            return "<b class='PREPARADO'>PREPARADO</b>";
        }
    }

    // CASO B: vista inicial
    if (!isset($_REQUEST['plano'])) {
        $retorno .= fn_boton_menu_principal($conn) . "<br />";
        $retorno .= "<h1>Estación de Trabajo</h1>";
        $retorno .= "<div id='capa_panel_cocina'>Cargando...</div>";
        $retorno .= "<script>fn_refrescar_automatico('cocina', 'capa_panel_cocina', '$token', '');</script>";
        return $retorno;
    }

    // CASO C: tabla refrescada por AJAX
    $sql = "
        SELECT O.id as orden_id, P.nombre as plato, O.estado, O.cantidad,
               U.nombre as cliente, H.mesa_id, O.solicitado
        FROM ordenes O
        JOIN platos P ON O.plato_id = P.id
        JOIN pedidos PED ON O.pedido_id = PED.id
        JOIN usuarios U ON PED.cliente_id = U.id
        LEFT JOIN reservaciones R ON U.id = R.cliente_id
        LEFT JOIN horarios H ON R.id = H.reservacion_id
        JOIN especialidades E ON P.id = E.plato_id
        WHERE E.cocinero_id = $id_cocinero
          AND O.estado IN (0, 1)  -- Filtramos por estado pendiente (0) o en preparación (1)
        ORDER BY O.solicitado ASC";

    // Ejecutamos la consulta
    $res = procesar_query($sql, $conn);

    // Si la consulta falla, mostramos el mensaje de error
    if (!$res) {
        return "<p>Error en la consulta: " . pg_last_error($conn) . "</p>";
    }

    // Mostrar los resultados en la interfaz
    if ($res->cantidad == 0) {
        $retorno .= "<p>No se encontraron pedidos pendientes.</p>";
    } else {
        // Mostrar los pedidos en una tabla limpia
        $retorno .= "<table class='TBL_COCINA'>";
        $retorno .= "<tr>
                        <th>Orden</th>
                        <th>Plato</th>
                        <th>Cantidad</th>
                        <th>Cliente</th>
                        <th>Mesa</th>
                        <th>Solicitado</th>
                        <th>Acción</th>
                     </tr>";

        // Iteramos por cada pedido
        foreach ($res->datos as $pedido) {
            $retorno .= "<tr>
                            <td>" . $pedido['orden_id'] . "</td>
                            <td>" . htmlspecialchars($pedido['plato']) . "</td>
                            <td>" . $pedido['cantidad'] . "</td>
                            <td>" . htmlspecialchars($pedido['cliente']) . "</td>
                            <td>" . $pedido['mesa_id'] . "</td>
                            <td>" . $pedido['solicitado'] . "</td>
                            <td><button class='BTN_ACCION'>Preparado</button></td>
                         </tr>";
        }
        $retorno .= "</table>";
    }

    // Agregamos la hora de la última actualización
    $reloj = "<div class='NOTA_PIE'>Actualizado: " . date("H:i:s") . "</div>";

    return $retorno . $reloj;
}

/*------------------------------------------------------------------*/
/**
 * @brief Reporte estadístico del día.
 * @param resource $conn Recurso de conexión a la base de datos PostgreSQL.
 * @return string Interfaz HTML con el resumen estadístico de la jornada actual.
 */
function fn_reporte_estadistico($conn)
/*--------------------------------------------------------------------*/
{
    $retorno = fn_boton_menu_principal($conn) . "<br />";
    $retorno .= "<h1>Reporte Estadístico del Día</h1>";

    $sql_total_ordenes = "
        SELECT COUNT(id) as total
        FROM pedidos
        WHERE solicitado::date = CURRENT_DATE";
    $res_total = procesar_query($sql_total_ordenes, $conn);
    $total_ordenes = $res_total->datos[0]['total'] ?? 0;

    $sql_plato_estrella = "
        SELECT P.nombre, COUNT(O.id) as cantidad
        FROM ordenes O
        JOIN platos P ON O.plato_id = P.id
        JOIN pedidos PED ON O.pedido_id = PED.id
        WHERE PED.solicitado::date = CURRENT_DATE
        GROUP BY P.nombre
        ORDER BY cantidad DESC
        LIMIT 1";
    $res_plato = procesar_query($sql_plato_estrella, $conn);
    $plato_nombre = ($res_plato->cantidad > 0) ? $res_plato->datos[0]['nombre'] : "Sin datos";
    $plato_cantidad = ($res_plato->cantidad > 0) ? $res_plato->datos[0]['cantidad'] : 0;

    $sql_ingresos = "
        SELECT SUM(P.precio * O.cantidad) as total_dinero
        FROM ordenes O
        JOIN platos P ON O.plato_id = P.id
        JOIN pedidos PED ON O.pedido_id = PED.id
        WHERE PED.solicitado::date = CURRENT_DATE";
    $res_ingresos = procesar_query($sql_ingresos, $conn);
    $total_dinero = $res_ingresos->datos[0]['total_dinero'] ?? 0;

    if ($total_ordenes > 0) {
        $retorno .= "
        <div class='REPORTE'>
            <table>
                <tr>
                    <td>
                        <span class='NOMBRE'>Órdenes del Día</span><br>
                        <span class='DATO'>$total_ordenes</span>
                    </td>
                    <td>
                        <span class='NOMBRE'>Plato más pedido</span><br>
                        <span class='DATO'>" . htmlspecialchars($plato_nombre) . "</span><br>
                        <span class='NOMBRE'>($plato_cantidad veces)</span>
                    </td>
                    <td>
                        <span class='NOMBRE'>Ingreso Total</span><br>
                        <span class='DATO'>$" . number_format($total_dinero, 0, ',', '.') . "</span>
                    </td>
                </tr>
            </table>
        </div>";
    } else {
        $retorno .= "
        <div class='SIN_DATOS'>
            <p>No se han registrado transacciones el día de hoy (" . date("d/m/Y") . ").</p>
        </div>";
    }

    $retorno .= "<br /><div class='NOTA_PIE'>Reporte generado a las: " . date("H:i:s") . "</div>";

    return $retorno;
}

function fn_gestionar_empleados($conn) {
    $retorno = "<h1>Gestión de Empleados</h1>";

    // Formulario para crear un nuevo empleado
    $retorno .= "<form method='POST' action='?opcion=crear_empleado'>
                    <label for='nombre'>Nombre:</label><br>
                    <input type='text' name='nombre' required><br>
                    <label for='rol'>Rol:</label><br>
                    <select name='rol'>
                        <option value='maitre'>Maitre</option>
                        <option value='mesero'>Mesero</option>
                        <option value='cocinero'>Cocinero</option>
                    </select><br>
                    <label for='login'>Login:</label><br>
                    <input type='text' name='login' required><br>
                    <label for='clave'>Contraseña:</label><br>
                    <input type='password' name='clave' required><br>
                    <button type='submit'>Crear Empleado</button>
                  </form>";

    // Listar empleados
    $sql = "SELECT id, nombre, rol_id FROM usuarios";
    $res = procesar_query($sql, $conn);
    
    $retorno .= "<table><tr><th>Nombre</th><th>Rol</th><th>Acciones</th></tr>";

    foreach ($res->datos as $empleado) {
        $retorno .= "<tr>
                        <td>" . htmlspecialchars($empleado['nombre']) . "</td>
                        <td>" . htmlspecialchars($empleado['rol_id']) . "</td>
                        <td><a href='?opcion=editar_empleado&id=" . $empleado['id'] . "'>Editar</a> | <a href='?opcion=eliminar_empleado&id=" . $empleado['id'] . "'>Eliminar</a></td>
                     </tr>";
    }

    $retorno .= "</table>";
    return $retorno;
}
//------------------------------------------------------------
?>
