function nuevoAjax(){
//----------------------------------------------------------------------
// PROPOSITO:
// Crea un nuevo objeto ajax.
//----------------------------------------------------------------------
    var xmlhttp=false;
    try {
        xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
    } catch (e) {
        try {
            xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
        } catch (E) {
            xmlhttp = false;
        }
    }

    if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
        xmlhttp = new XMLHttpRequest();
    }
    return xmlhttp;
}
function llamarProceso(script, division, datos, mensaje) {
//------------------------------------------------------------------
// PROPOSITO:
// Carga el resultado del script indicado en la division
// correspondiente presentando el mensaje en la posición indicada.
//------------------------------------------------------------------

    contenedor = document.getElementById(division);
    if (contenedor == null)
        alert('ERROR: Ncontainer - llamarProceso ['+division+']');

    if (mensaje != '')
        contenedor.innerHTML = mensaje;

    ajax = nuevoAjax();
    ajax.open("POST", script, true);
    ajax.onreadystatechange = function() {
        if (ajax.readyState == 4) {
            contenedor.innerHTML = ajax.responseText;
        }
    }
    ajax.setRequestHeader( "Content-Type"
                         , "application/x-www-form-urlencoded"
                         );
    ajax.send("datos=" + datos)
}

/*------------------------------------------------------------------*/
/**
 * @brief Inicia un ciclo de actualización automática genérico vía AJAX.
 * @param {string} opcion El nombre de la opción/función en PHP (ej: 'cocina', 'gestion_reservas').
 * @param {string} division El ID del contenedor HTML donde se inyectará el contenido.
 * @param {string} token Token de seguridad validado.
 * @param {string} filtros Cadena con parámetros extra de URL (ej: '&fecha=...&hora=...')
 * @post Llama a la versión plana de la opción y reprograma su ejecución cada 10 segundos.
 */
function fn_refrescar_automatico(opcion, division, token, filtros) 
/*--------------------------------------------------------------------*/
{
    // Si no se envían filtros, aseguramos que sea una cadena vacía
    var p_filtros = filtros || "";
    
    // Construimos la URL agregando los filtros al final
    var script = "index.php?opcion=" + opcion + "&token=" + token + "&plano=1" + p_filtros;
    
    llamarProceso(script, division, '', '');

    // Programamos la recursividad manteniendo todos los parámetros
    setTimeout(function() {
        fn_refrescar_automatico(opcion, division, token, p_filtros);
    }, 10000);
}

function mostrarNotificacion(mensaje) {
    var notification = new Notification("Pedido Listo", {
        body: mensaje,
        icon: "path_to_icon.png"
    });

    notification.onclick = function() {
        window.location.href = "url_de_interfaz_del_mesero";  // Redirigir a una página específica si el mesero hace clic
    };
}
