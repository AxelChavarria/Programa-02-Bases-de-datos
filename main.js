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
    //let informacion = cargarDatos() //traer datos

    //informacion.forEach(emp => { //${emp.} //pasar por las listas
        tablaEmpleados.innerHTML += `
            <tr data-id="1">
                <td>ref</td>
                <td>ref</td>
                <td>ref</td>
                <td>ref</td>
            </tr>`;
    //});

    const boton = document.getElementById("buscar");

    boton.addEventListener("click", function(event) {
        event.preventDefault();     

        const valor = document.getElementById("busqueda").value.trim()
        
        if (/^\d+$/.test(valor)){
            console.log("Si")
        }
        
    });


    tablaEmpleados.addEventListener("click", function(e) {
    const fila = e.target.closest("tr");
    if (!fila) return;

    const id = fila.dataset.id;

    sessionStorage.setItem("idSeleccionado", id);

    window.location.href = "botones.html";
});
}

//const id = sessionStorage.getItem("idSeleccionado");  //para llamar el id
