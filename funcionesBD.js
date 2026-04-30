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