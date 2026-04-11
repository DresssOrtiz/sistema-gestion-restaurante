<?php
//------------------------------------------------------------
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once("etc/parametros.php");
require_once("lib/libreria.php");
require_once("lib/restaurante.php");

//------------------------------------------------------------
$conn = pg_conectar($host, $dbname, $user, $password);
$contenido = "";

// Obtener el token de la solicitud
$token = $_REQUEST['token'] ?? ''; // Obtener el token desde la URL

// Determinar qué opción mostrar
$opcion = "";
if (isset($_REQUEST['opcion'])) {
    $opcion = $_REQUEST['opcion'];
}

// Verificar qué función se debe ejecutar según la opción seleccionada
if ($opcion != "") {
    $funcion = "fn_" . $opcion;
    if (function_exists($funcion)) {
        // Llamamos a la función correspondiente pasando $conn y $token
        $contenido = $funcion($conn, $token); 
    } else {
        // Si la opción no existe, mostramos el menú
        $contenido = fn_menu_opciones($conn); 
    }
} else {
    // Si no hay opción seleccionada, mostramos el menú por defecto
    $contenido = fn_menu_opciones($conn); 
}

//------------------------------------------------------------
// Cargar la estructura HTML básica con el contenido correspondiente
if (!isset($_REQUEST['plano'])) {
    $esqueleto = file_get_contents("esqueleto.html");
    $html = sprintf($esqueleto, $contenido);
} else {
    // Si la opción es plana, solo mostramos el contenido sin el esqueleto
    $html = $contenido;
}

print $html;

//------------------------------------------------------------
?>
