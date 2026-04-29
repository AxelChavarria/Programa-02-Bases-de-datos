//log in

const formLogin = document.getElementById("form-login");
if (formLogin) {
    let user = document.getElementById("user").value.trim()
    let password = document.getElementById("contra").value.trim()

    //aqui llamamos a la función para iniciar sesión

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
                <td>ref</td>
                <td>ref</td>
                <td>ref</td>
                <td>ref</td>
                <td class="acciones">
                    <button onclick="window.location.href='actualizar.html'" class="form-btn">Actualizar</button>
                    <button onclick="window.location.href='borrar.html'" class="form-btn">Borrar</button>
                    <button onclick="window.location.href='consultar.html'" class="form-btn">Consultar</button>
                    <button onclick="window.location.href='listar_movimientos.html'" class="form-btn">Listar movimientos</button>
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

}

//const id = sessionStorage.getItem("idSeleccionado");  //para llamar el id
//insertar empleado

const formInsertar = document.getElementById("form-insertar");
if (formInsertar) {

    formInsertar.addEventListener("submit", function(e) {
        event.preventDefault();
        
        let identificacion = document.getElementById("identidad").value.trim()
        let nombre = document.getElementById("nombre").value.trim()
        let puesto = document.getElementById("puesto").value.trim()

        //aqui va la funcion para llamar a la base
    });
}
