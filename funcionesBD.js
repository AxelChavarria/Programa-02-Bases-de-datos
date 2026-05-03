import sql from 'mssql';

export async function cargarTodoXML() {
    console.log("Enviando fetch para carga masiva XML");
    try {
        const respuestaRaw = await fetch("http://localhost:3001/api/admin/cargar-todo", {
            method: "POST",
            headers: { "Content-Type": "application/json" }

        });

        const resultado = await respuestaRaw.json();
        return resultado;
        
    } catch (err) {
        console.error("Error en el fetch de carga:", err.message);
        return { Codigo: -1, Mensaje: err.message };
    }
}
 
//console.log(await cargarTodoXML())





// Entrada: datos = { username, password }
// Salida: { outCodigo, outMensaje, outIdUsuario }
export async function validarLogin(datos) {
    console.log("Iniciando validación de credenciales...");
    try {
        const respuestaRaw = await fetch("http://localhost:3001/api/login", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(datos) 
        });

        const resultado = await respuestaRaw.json(); 
        return resultado;
        
    } catch (err) {
        console.error("Error en conexión:", err.message);
        return { outCodigo: -1, outMensaje: err.message };
    }
}



// Entrada: id del usuario
// Salida: {outCodigo, outMensaje}
export async function cerrarSesion(idUsuario) {
    try {
        const respuestaRaw = await fetch("http://localhost:3001/api/logout", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ idUsuario })
        });
        return await respuestaRaw.json();
    } catch (err) {
        return { outCodigo: -1, outMensaje: err.message };
    }
}