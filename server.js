import sql from 'mssql';
import express from 'express';
import cors from 'cors';
import fs from 'fs';          
import { fileURLToPath } from 'url';
import path from 'path';      


const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json());
app.use(cors());

app.use(express.static(__dirname));

const config = {
    user: 'bdd_sql_2026', 
    password: 'Tec20IC26', 
    server: 'py-01-bdd-1s2026.database.windows.net', 
    database: 'Proyecto02BasesDeDatosIS2026',
    options: {
        encrypt: true, 
        trustServerCertificate: true 
    }
};

// Ruta principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '/login.html'));
});

app.post('/api/admin/cargar-todo', async (req, res) => {
    try {
        const xmlPath = path.join(__dirname, 'datosCarga.xml');
        
        if (!fs.existsSync(xmlPath)) {
            return res.status(404).json({ Codigo: -1, Mensaje: "El archivo datosCarga.xml no existe en el servidor" });
        }

        let xmlContent = fs.readFileSync(xmlPath, 'utf8');
        xmlContent = xmlContent.replace(/<\?xml.*\?>/, '');

        let pool = await sql.connect(config);
        let result = await pool.request()
            .input('inXmlData', sql.Xml, xmlContent)
            .execute('sp_CargarTodoXML');

        res.status(200).json(result.recordset[0]);
    } catch (err) {
        res.status(500).json({ Codigo: -1, Mensaje: err.message });
    }
});




app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;
    const ip = req.ip || '0.0.0.0';

    try {
        let pool = await sql.connect(config);
        let result = await pool.request()
            .input('inUsername', sql.VarChar, username)
            .input('inPassword', sql.VarChar, password)
            .input('inIP', sql.VarChar, ip)
            .output('outCodigo', sql.Int)
            .output('outMensaje', sql.VarChar(100))
            .output('outIdUsuario', sql.Int)
            .execute('sp_ValidarLogin');

        res.json(result.output);
    } catch (err) {
        res.status(500).json({ outCodigo: -1, outMensaje: err.message });
    }
});




app.post('/api/logout', async (req, res) => {
    const { idUsuario } = req.body;
    const ip = req.ip || '0.0.0.0';

    try {
        let pool = await sql.connect(config);
        let result = await pool.request()
            .input('inIdUsuario', sql.Int, idUsuario)
            .input('inIP', sql.VarChar, ip)
            .output('outCodigo', sql.Int)
            .output('outMensaje', sql.VarChar(100))
            .execute('sp_RegistrarLogout');

        res.json(result.output);
    } catch (err) {
        res.status(500).json({ outCodigo: -1, outMensaje: err.message });
    }
});



app.post('/api/empleados/insertar', async (req, res) => {
    const { valorDoc, nombre, idPuesto, idPostByUser } = req.body;
    const ip = req.ip || '127.0.0.1';
    try {
        let pool = await sql.connect(config);
        let result = await pool.request()
            .input('inValorDoc', sql.VarChar, valorDoc)
            .input('inNombre', sql.VarChar, nombre)
            .input('inIdPuesto', sql.Int, idPuesto)
            .input('inIdPostByUser', sql.Int, idPostByUser)
            .input('inPostInIP', sql.VarChar, ip)
            .output('outCodigo', sql.Int)
            .output('outMensaje', sql.VarChar(100))
            .execute('sp_InsertarEmpleado');

        res.json(result.output);
    }catch (err) {
        res.status(500).json({ outCodigo: -1, outMensaje: err.message });
    }
});



app.get('/api/empleados', async (req, res) => {
    const { filtro } = req.query;

    try {
        let pool = await sql.connect(config);
        let result = await pool.request()
            .input('inFiltro', sql.VarChar, filtro || '')
            .execute('sp_ListarEmpleados');

        res.json(result.recordset); 
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


app.listen(3001, () => console.log('Servidor corriendo en puerto 3001'));