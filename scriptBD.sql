-- Catálogos
CREATE TABLE Puesto (Id INT PRIMARY KEY, Nombre VARCHAR(100), SalarioxHora DECIMAL(10,2));
CREATE TABLE TipoMovimiento (Id INT PRIMARY KEY, Nombre VARCHAR(100));
CREATE TABLE TipoEvento (Id INT PRIMARY KEY, Nombre VARCHAR(100));
CREATE TABLE Error (Id INT PRIMARY KEY, Codigo INT, Descripcion VARCHAR(255));






--Tablas
CREATE TABLE Usuario (Id INT IDENTITY(1,1) PRIMARY KEY, Username VARCHAR(50), Password VARCHAR(50)); -- Para validar

CREATE TABLE Empleado (
    Id INT IDENTITY(1,1) PRIMARY KEY, 
    IdPuesto INT FOREIGN KEY REFERENCES Puesto(Id),
    ValorDocumentoIdentidad VARCHAR(50) UNIQUE,
    Nombre VARCHAR(100),
    SaldoVacaciones DECIMAL(10,2) DEFAULT 0,
    EsActivo BIT DEFAULT 1,
    FechaContratacion DATE
);


CREATE TABLE Movimiento (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT FOREIGN KEY REFERENCES Empleado(Id),
    IdTipoMovimiento INT FOREIGN KEY REFERENCES TipoMovimiento(Id),
    Fecha DATETIME DEFAULT GETDATE(),
    Monto DECIMAL(10,2),
    NuevoSaldo DECIMAL(10,2),
    IdPostByUser INT,
    PostInIP VARCHAR(50),
    PostTime DATETIME DEFAULT GETDATE()
);

CREATE TABLE BitacoraEvento (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    idTipoEvento INT FOREIGN KEY REFERENCES TipoEvento(Id),
    Descripcion VARCHAR(MAX),
    IdPostByUser INT,
    PostInIP VARCHAR(50),
    PostTime DATETIME DEFAULT GETDATE()
);