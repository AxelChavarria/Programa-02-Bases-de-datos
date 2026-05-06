import { validarLogin, cerrarSesion, obtenerListaEmpleados, obtenerDetalleEmpleado, insertarMovimiento, actualizarEmpleado } from './funcionesBD.js';

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
 //cerrar la sesion
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

//boton para regresar
const btnAtras = document.getElementById("btnAtras")
if (btnAtras) {
    btnAtras.addEventListener("click", async function(event) {
        event.preventDefault();
        window.location.href='lista.html'
    
    
    });
}

const btnAtrasM = document.getElementById("btnAtrasMov")
if (btnAtrasM) {
    btnAtrasM.addEventListener("click", async function(event) {
        event.preventDefault();
        window.location.href='movimientos.html'
    
    
    });
}


//funcion auxiliar
function guardarDatos(){

    const fila = event.target.closest("tr");

    const datos = {

        id: fila.dataset.id,
        puesto: fila.children[0].textContent,
        identidad : fila.children[1].textContent,
        nombre : fila.children[2].textContent
    }

    console.log(datos)
    sessionStorage.setItem("empleado", JSON.stringify(datos));
}


//lista de empleados 

const tablaEmpleados = document.getElementById("tabla-empleados");
if (tablaEmpleados) {

    const admin = JSON.parse(sessionStorage.getItem("admin"))
    
    //obtenemos la información
    let informacion = await obtenerListaEmpleados("", admin, "190.171.113.80") //traer datos


    //desplegamos la información
    informacion.forEach(emp => {  //pasar por las listas
        tablaEmpleados.innerHTML += `
            <tr data-id="${emp.Id}">
                <td>${emp.NombrePuesto}</td>
                <td>${emp.ValorDocumentoIdentidad}</td>
                <td>${emp.Nombre}</td>
                
                <td class="acciones">
                    <button  class="form-btn actualizar" id="actualizar">Actualizar</button>
                    <button onclick="window.location.href='borrar.html'" class="form-btn">Borrar</button>
                    <button onclick="window.location.href='consultar.html'" class="form-btn">Consultar</button>
                    <button  id="mov" class="form-btn mov">Movimientos</button>
                </td>
            </tr>`;
    });

    //boton para filtrar con validaciones 
    const boton = document.getElementById("buscar");

    boton.addEventListener("click", async function(event) {
        event.preventDefault();     

        const valor = document.getElementById("busqueda").value.trim()
        
        let informacion = await obtenerListaEmpleados(valor, admin, "190.171.113.80") //traer datos

        tablaEmpleados.innerHTML = ""

        //desplegamos la información
        informacion.forEach(emp => {  //pasar por las listas
            tablaEmpleados.innerHTML += `
                <tr data-id="${emp.Id}">
                    <td>${emp.NombrePuesto}</td>
                    <td>${emp.ValorDocumentoIdentidad}</td>
                    <td>${emp.Nombre}</td>
                    
                    <td class="acciones">
                        <button class="form-btn actualizar" >Actualizar</button>
                        <button onclick="window.location.href='borrar.html'" class="form-btn">Borrar</button>
                        <button onclick="window.location.href='consultar.html'" class="form-btn">Consultar</button>
                        <button class="form-btn mov" >Movimientos</button>
                    </td>
                </tr>`;
        });
        
    });

    //botones
    tablaEmpleados.addEventListener("click", function(e) {

        // BOTÓN MOVIMIENTOS
        if (e.target.classList.contains("mov")) {

            e.preventDefault();

            const fila = e.target.closest("tr");
            const id = fila.dataset.id;

            guardarDatos(id);
            window.location.href = 'movimientos.html';
        }

        // BOTÓN ACTUALIZAR
        if (e.target.classList.contains("actualizar")) {

            e.preventDefault();

            const fila = e.target.closest("tr");
            const id = fila.dataset.id;

            guardarDatos(id);
            window.location.href = 'actualizar.html';
        }

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

        if (resultado["outCodigo"] == 0){
            alert("Insertado con éxito")
        } else if (resultado["outCodigo"] == 50005){
            alert("Empleado duplicado")
        }
     });
        
}

//actualizar empleado

const formActualizar = document.getElementById("form-actualizar");
if (formActualizar) {
    const empleado = JSON.parse(sessionStorage.getItem("empleado"))
    if (empleado) {
        document.getElementById("identidad").value = empleado.identidad;
        document.getElementById("nombre").value = empleado.nombre;
        document.getElementById("puesto").value = empleado.puesto;
    }


    formActualizar.addEventListener("submit", async function(e) {
        event.preventDefault();

        const puesto = document.getElementById("puesto").value.trim()

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

        const admin = JSON.parse(sessionStorage.getItem("admin"))

        const datos = {
            valorDoc: document.getElementById("identidad").value.trim(),
            nombre: document.getElementById("nombre").value.trim(),
            id: empleado.id,
            idPuesto: idPuesto,
            idPostByUser: admin,
            ip: "190.171.113.80"
        }

        const resultado = await actualizarEmpleado(datos)

        if (resultado["outCodigo"] == 0){
            alert("Actualización exitosa")
        } else if (resultado["outCodigo"] == 50001){
            alert("Empleado no existe")
        } else if (resultado["outCodigo"] == 50006){
            alert("Documento duplicado")
        } else if (resultado["outCodigo"] == 50007){
            alert("Nombre duplicado")
        }
    });
    
}

//listar movimientos 

const tablaMovimientos = document.getElementById("tabla-movimientos");
if (tablaMovimientos) {


    
    const empleado = JSON.parse(sessionStorage.getItem("empleado"))
    
    //obtenemos la información
    
    let informacion = await obtenerDetalleEmpleado(empleado.id) //traer datos
    
    const infoEmpleado = informacion.empleado;

    console.log(infoEmpleado)
    document.getElementById("identificacionEmpleado").textContent = infoEmpleado.ValorDocumentoIdentidad;
    document.getElementById("nombreEmpleado").textContent = infoEmpleado.Nombre;
    document.getElementById("saldoEmpleado").textContent = infoEmpleado.SaldoVacaciones;

    const movEmpleado = informacion.movimientos

    

    console.log(movEmpleado)
    //desplegamos la información
    movEmpleado.forEach(emp => {  //pasar por las listas
        tablaMovimientos.innerHTML += `
            <tr >
                <td>${emp.Fecha}</td>
                <td>${emp.TipoMovimiento}</td>
                <td>${emp.Monto}</td>
                <td>${emp.NuevoSaldo}</td>
                <td>${emp.UsuarioRegistro}</td>
                <td>${emp.PostInIP}</td>
                <td>${emp.PostTime}</td>
            </tr>`;
    });
   
}


//agregar movimiento

const formInsertarMov = document.getElementById("form-insertar-mov");
if (formInsertarMov) {

    const empleado = JSON.parse(sessionStorage.getItem("empleado"))
    
    //obtenemos la información
    
    let informacion = await obtenerDetalleEmpleado(empleado.id) //traer datos
    
    const infoEmpleado = informacion.empleado;

    document.getElementById("identificacionEmpleado").textContent = infoEmpleado.ValorDocumentoIdentidad;
    document.getElementById("nombreEmpleado").textContent = infoEmpleado.Nombre;
    document.getElementById("saldoEmpleado").textContent = infoEmpleado.SaldoVacaciones;

    formInsertarMov.addEventListener("submit", async function(e) {
        event.preventDefault();
     
        const tipo = document.getElementById("tipo-movimiento").value.trim()
        const monto = document.getElementById("monto").value.trim()
        const empleado = JSON.parse(sessionStorage.getItem("empleado"))
        const admin = JSON.parse(sessionStorage.getItem("admin"))


        let idMov = 0;
        switch (tipo) {
            case "Cumplir mes":
                idMov = 1
                break;
            case "Bono vacacional":
                idMov = 2
                break;
            case "Reversion Debito":
                idMov = 3
                break;
            case "Disfrute de vacaciones":
                idMov = 4
                break;
            case "Venta de vacaciones":
                idMov = 5
                break;
            case "Reversion de Credito":
                idMov = 6
                break;
        }
        
        let datos = {
            IdEmpleado: empleado.id,
            IdTipoMovimiento: idMov,
            monto: monto,
            postByUser: admin,
            postInIP: "190.171.113.80"
        }
        let resultado = await insertarMovimiento(datos);

        if (resultado["outCodigo"] == 0){
            alert("Movimiento insertado con éxito")
        } else if (resultado["outCodigo"] == 50006){
            alert("Saldo insuficiente")
        } else if (resultado["outCodigo"] == 50000){
            alert("Error inesperado")
        }
     });
        
}


