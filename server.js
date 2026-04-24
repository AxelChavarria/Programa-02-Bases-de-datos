import sql from 'mssql';
import express from 'express';
import cors from 'cors';

const app = express();
app.use(express.json());
app.use(cors());

const config = {
    user: 'bdd_sql_2026', 
    password: 'Tec20IC26', 
    server: 'py-01-bdd-1s2026.database.windows.net', 
    database: 'PY01BDDIS2026',
    options: {
        encrypt: true, 
        trustServerCertificate: true 
    }
};
