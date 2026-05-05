import { validarLogin, cerrarSesion, obtenerListaEmpleados } from './funcionesBD.js';

//log in

const formLogin = document.getElementById("form-login");
if (formLogin) {

    formLogin.addEventListener("submit", async function(event) {
        event.preventDefault();
        let datos = {
            username: document.getElementById("user").value.trim(),
            password: document.getElementById("contra").value.trim()
        }

        const resultado = await validarLogin(datos) 


        sessionStorage.setItem("admin", JSON.stringify(resultado["outIdUsuario"]));
 
        if (resultado["outCodigo"] == 0 ){
            window.location.href='lista.html'
        } else if (resultado["outCodigo"] == 50001 ){
            alert("Creedenciales incorrectas")
        } else if (resultado["outCodigo"] == 50002 ){
            alert("Muchos intentos, IP bloqueada")
        }

    });
}

function cerrarSesionMain(){

    const id = JSON.parse(sessionStorage.getItem("admin"))
    cerrarSesion(id)
    sessionStorage.removeItem('admin')
    window.location.href='login.html'
}

const btnCerrar = document.getElementById("btnCerrar")
if (btnCerrar) {
    btnCerrar.addEventListener("click", cerrarSesionMain);
}



function guardarDatos(){

    const fila = event.target.closest("tr");

    const datos = {

        id: fila.dataset.id,
        puesto: fila.children[0].textContent,
        identidad : fila.children[1].textContent,
        nombre : fila.children[2].textContent
    }
    sessionStorage.setItem("empleado", JSON.stringify(datos));
}


//lista de empleados 

const tablaEmpleados = document.getElementById("tabla-empleados");
if (tablaEmpleados) {

    //obtenemos la información
    let informacion = await obtenerListaEmpleados("") //traer datos


    //desplegamos la información
    informacion.forEach(emp => {  //pasar por las listas
        tablaEmpleados.innerHTML += `
            <tr data-id="${emp.Id}">
                <td>${emp.NombrePuesto}</td>
                <td>${emp.ValorDocumentoIdentidad}</td>
                <td>${emp.Nombre}</td>
                
                <td class="acciones">
                    <button  class="form-btn" id="actualizar">Actualizar</button>
                    <button onclick="window.location.href='borrar.html'" class="form-btn">Borrar</button>
                    <button onclick="window.location.href='consultar.html'" class="form-btn">Consultar</button>
                    <button onclick="window.location.href='movimientos.html'" class="form-btn">Movimientos</button>
                </td>
            </tr>`;
    });

    //boton para filtrar con validaciones 
    const boton = document.getElementById("buscar");

    boton.addEventListener("click", async function(event) {
        event.preventDefault();     

        const valor = document.getElementById("busqueda").value.trim()
        
        let informacion = await obtenerListaEmpleados(valor) //traer datos

        tablaEmpleados.innerHTML = ""

        //desplegamos la información
        informacion.forEach(emp => {  //pasar por las listas
            tablaEmpleados.innerHTML += `
                <tr data-id="${emp.Id}">
                    <td>${emp.NombrePuesto}</td>
                    <td>${emp.ValorDocumentoIdentidad}</td>
                    <td>${emp.Nombre}</td>
                    
                    <td class="acciones">
                        <button  class="form-btn" id="actualizar">Actualizar</button>
                        <button onclick="window.location.href='borrar.html'" class="form-btn">Borrar</button>
                        <button onclick="window.location.href='consultar.html'" class="form-btn">Consultar</button>
                        <button onclick="window.location.href='movimientos.html'" class="form-btn">Movimientos</button>
                    </td>
                </tr>`;
        });
        
    });

    //botones
    const botonActualizar = document.getElementById("actualizar");


    botonActualizar.addEventListener("click", function(event) {
        event.preventDefault();  

        guardarDatos();
        window.location.href='actualizar.html'
        
    });
    
}


//const id = sessionStorage.getItem("idSeleccionado");  //para llamar el id
//insertar empleado

const formInsertar = document.getElementById("form-insertar");
if (formInsertar) {

    formInsertar.addEventListener("submit", function(e) {
        event.preventDefault();
     
        const puesto = document.getElementById("puesto").value.trim()
        const admin = JSON.parse(sessionStorage.getItem("admin"))

        let idPuesto = 0;
        switch (puesto) {
            case "Albañil":
                idPuesto = 10
                break;
            case "Asistente":
                idPuesto = 5
                break;
            case "Cajero":
                idPuesto = 1
                break;
            case "Camarero":
                idPuesto = 2
                break;
            case "Conductor":
                idPuesto = 4
                break;
            case "Conserje":
                idPuesto = 9
                break;
            case "Cuidador":
                idPuesto = 3
                break;
            case "Fontanero":
                idPuesto = 7
                break;
            case "Niñera":
                idPuesto = 8
                break;
            case "Recepcionista":
                idPuesto = 6
                break;
        }

        let datos = {
            valorDoc:document.getElementById("identidad").value.trim(),
            nombre: document.getElementById("nombre").value.trim(),
            idPuesto: idPuesto,
            idPostByUser: admin
        }
        let resultado = registrarEmpleado(datos)

        if (resultado["outCodigo"] = 0){
            alert("Insertado con éxito")
        }
     });
        
}


const formActualizar = document.getElementById("form-actualizar");
if (formActualizar) {
    const empleado = JSON.parse(sessionStorage.getItem("empleado"))
    if (empleado) {
        document.getElementById("identidad").value = empleado.identidad;
        document.getElementById("nombre").value = empleado.nombre;
        document.getElementById("puesto").value = empleado.puesto;
    }

    const botonActualizar = document.getElementById("actualizar");


        botonActualizar.addEventListener("click", function(event) {
            event.preventDefault();  
            //aqui va la funcion para llamar a la base
        });
}