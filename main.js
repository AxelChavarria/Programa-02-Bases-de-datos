import { validarLogin } from funcionesBD.js

//log in

const formLogin = document.getElementById("form-login");
if (formLogin) {

    let datos = {
        username: document.getElementById("user").value.trim(),
        password: document.getElementById("contra").value.trim()
    }

    let resultado = validarLogin(datos) 

    sessionStorage.setItem("admin", JSON.stringify(resultado[outIdUsuario]));

    if (resultado == 0 ){
        window.location.href='lista.html'
    }
    //terminar los códigos
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

const tablaEmpleados = document.getElementById("empleados");
if (tablaEmpleados) {

    //obtenemos la información
    //let informacion = cargarDatos() //traer datos


    //desplegamos la información
    //informacion.forEach(emp => { //${emp.} //pasar por las listas
        tablaEmpleados.innerHTML += `
            <tr data-id="1">
                <td>Albañil</td>
                <td>ref 123</td>
                <td>Ref Ref</td>
                <td>ref</td>
                <td class="acciones">
                    <button  class="form-btn" id="actualizar">Actualizar</button>
                    <button onclick="window.location.href='borrar.html'" class="form-btn">Borrar</button>
                    <button onclick="window.location.href='consultar.html'" class="form-btn">Consultar</button>
                    <button onclick="window.location.href='movimientos.html'" class="form-btn">Movimientos</button>
                    <button onclick="window.location.href='agregar_movimiento.html'" class="form-btn">Agregar movimientos</button>
                </td>
            </tr>`;
    //});

    //boton para filtrar con validaciones 
    const boton = document.getElementById("buscar");

    boton.addEventListener("click", function(event) {
        event.preventDefault();     

        const valor = document.getElementById("busqueda").value.trim()
        
        if (/^\d+$/.test(valor)){
            console.log("numeros")
        }
        
        if (/^[a-zA-Z]+$/.test(texto)) {
            console.log("Solo letras");
        }
        
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
     
        const admin = JSON.parse(sessionStorage.getItem("admin"))
        let datos = {
            valorDoc:document.getElementById("identidad").value.trim(),
            nombre: document.getElementById("nombre").value.trim(),
            idPuesto:document.getElementById("puesto").value.trim(),
            idPostByUser: admin
        }
        registrarEmpleado(datos)
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