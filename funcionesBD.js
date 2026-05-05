

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
/*
let datos = { username:'Axel',password:'Axel' }
const res = await validarLogin(datos)
console.log(res)
*/




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





// Entrada: datos = { valorDoc, nombre, idPuesto, idPostByUser }

export async function registrarEmpleado(datos) {
    console.log("Enviando fetch para carga de empleado...");
    try {
        const respuestaRaw = await fetch("http://localhost:3001/api/empleados/insertar", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(datos)
        });

        if (!respuestaRaw.ok) {
            const texto = await respuestaRaw.text();
            throw new Error(`HTTP ${respuestaRaw.status}: ${texto}`);
        }

        const resultado = await respuestaRaw.json();
        console.log("RESPUESTA DEL API:", resultado);

        return resultado;

    } catch (err) {
        console.error("Error en registrarEmpleado:", err);
        return { outCodigo: -1, outMensaje: err.message };
    }
}


/*
const nuevoEmpleado = {
        valorDoc: "2026",            
        nombre: "Fabián Gutiérrez",         
        idPuesto: 2,                      
        idPostByUser: 1   // Id del usuario que inserta al empleado
    };

console.log("Intentando registrar empleado...");
const respuesta = await registrarEmpleado(nuevoEmpleado)
*/

// Entrada: filtro
// Salida: array de empleados
export async function obtenerListaEmpleados(filtro,idPostByUser, ip) {
    
    try {
        const url = `http://localhost:3001/api/empleados?filtro=${encodeURIComponent(filtro || '')}&idPostByUser=${idPostByUser}&ip=${ip}`;

        const respuestaRaw = await fetch(url);

        if (!respuestaRaw.ok) {
            const text = await respuestaRaw.text();
            throw new Error(`Error HTTP: ${text}`);
        }

        const empleados = await respuestaRaw.json();

        return empleados; // [{Id, Nombre, ...}]

    } catch (err) {
        console.error("Error en obtenerListaEmpleados:", err.message);
        return [];
    }
}


const res = await obtenerListaEmpleados("Axel", 1, "222.111.111")
console.log(res)




export async function insertarMovimiento(movimiento) {
    try {
        const respuestaRaw = await fetch(`http://localhost:3001/api/movimientos/insertar`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(movimiento)
        });

        if (!respuestaRaw.ok) {
            throw new Error(`Error en el servidor: ${respuestaRaw.statusText}`);
        }

        const resultado = await respuestaRaw.json();
        
        // El resultado contiene outCodigo y outMensaje del SP
        return resultado; 

    } catch (error) {
        console.error("Error en la comunicación con el API:", error.message);
        return { outCodigo: -1, outMensaje: error.message };
    }
}

/*
const datos= { IdEmpleado : 1, IdTipoMovimiento : 2, monto : 5.5, postByUser : 1, postInIP : "121.111"}
    
const respuesta = await insertarMovimiento(datos);
console.log(respuesta)
*/




  
/*
   const datos ={
        valorDoc: "2024252331",
        nombre: "Axel",
        id: 1,
        idPuesto: 2,
        idPostByUser: 1,
        ip: "192.168.1.1"
    }
*/
export async function actualizarEmpleado(datos) {
    const res = await fetch("http://localhost:3001/api/empleados/actualizar", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(datos)
    });

    const text = await res.text(); // 👈 clave

    console.log("RESPUESTA CRUDA:", text);

    try {
        return JSON.parse(text);
    } catch {
        throw new Error("La API no devolvió JSON válido");
    }
}
/*
const res = await actualizarEmpleado(datos)
console.log(res)
*/




export async function eliminarEmpleado(datos) {
    const res = await fetch("http://localhost:3001/api/empleados/eliminar", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(datos)
    });

    const text = await res.text(); 

    try {
        return JSON.parse(text);
    } catch {
        throw new Error("La API no devolvió JSON válido");
    }
}
/*
const datos = {id : 15, idPostByUser : 1, ip: "11.22.3.4"}
const res = await eliminarEmpleado(datos)
console.log(res)
*/