CREATE PROCEDURE sp_CargarTodoXML
    @inXmlData XML
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

    

        INSERT INTO Puesto (Nombre, SalarioxHora)
        SELECT 
            T.c.value('@Nombre', 'VARCHAR(100)'),
            T.c.value('@SalarioxHora', 'DECIMAL(10,2)')
        FROM @inXmlData.nodes('/Datos/Puestos/Puesto') AS T(c);



        INSERT INTO TipoEvento (Id, Nombre)
        SELECT 
            T.c.value('@Id', 'INT'),
            T.c.value('@Nombre', 'VARCHAR(100)')
        FROM @inXmlData.nodes('/Datos/TiposEvento/TipoEvento') AS T(c);



        INSERT INTO TipoMovimiento (Id, Nombre)
        SELECT 
            T.c.value('@Id', 'INT'),
            T.c.value('@Nombre', 'VARCHAR(100)')
        FROM @inXmlData.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(c);

       
        INSERT INTO Usuario (Username, Password)
        SELECT 
            T.c.value('@Nombre', 'VARCHAR(50)'),
            T.c.value('@Pass', 'VARCHAR(50)')
        FROM @inXmlData.nodes('/Datos/Usuarios/usuario') AS T(c);

       
        INSERT INTO Error (Id, Codigo, Descripcion)
        SELECT 
            ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), -- Generar id automático
            T.c.value('@Codigo', 'INT'),
            T.c.value('@Descripcion', 'VARCHAR(255)')
        FROM @inXmlData.nodes('/Datos/Error/error') AS T(c);

    
        INSERT INTO Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
        SELECT 
            P.Id,
            T.c.value('@ValorDocumentoIdentidad', 'VARCHAR(50)'),
            T.c.value('@Nombre', 'VARCHAR(100)'),
            T.c.value('@FechaContratacion', 'DATE'),
            0, 1
        FROM @inXmlData.nodes('/Datos/Empleados/empleado') AS T(c)
        INNER JOIN Puesto P ON P.Nombre = T.c.value('@Puesto', 'VARCHAR(100)');

      
        INSERT INTO Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
        SELECT 
            E.Id,
            TM.Id,
            T.c.value('@Fecha', 'DATETIME'),
            T.c.value('@Monto', 'DECIMAL(10,2)'),
            0, 
            U.Id,
            T.c.value('@PostInIP', 'VARCHAR(50)'),
            T.c.value('@PostTime', 'DATETIME')
        FROM @inXmlData.nodes('/Datos/Movimientos/movimiento') AS T(c)
        INNER JOIN Empleado E ON E.ValorDocumentoIdentidad = T.c.value('@ValorDocId', 'VARCHAR(50)')
        INNER JOIN TipoMovimiento TM ON TM.Nombre = T.c.value('@IdTipoMovimiento', 'VARCHAR(100)')
        INNER JOIN Usuario U ON U.Username = T.c.value('@PostByUser', 'VARCHAR(50)');

        COMMIT TRANSACTION;
        SELECT 0 AS Codigo, 'Carga masiva completa exitosa' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT -1 AS Codigo, ERROR_MESSAGE() AS Mensaje;
    END CATCH
END;



CREATE PROCEDURE sp_ValidarLogin
    @inUsername VARCHAR(50),
    @inPassword VARCHAR(50),
    @inIP VARCHAR(50),
    @outCodigo INT OUTPUT,
    @outMensaje VARCHAR(100) OUTPUT,
    @outIdUsuario INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outIdUsuario = NULL;

    SELECT @outIdUsuario = Id FROM Usuario 
    WHERE Username = @inUsername AND Password = @inPassword;

    IF @outIdUsuario IS NOT NULL -- usuario existe
    BEGIN
        INSERT INTO BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime, Descripcion)
        VALUES (1, @outIdUsuario, @inIP, GETDATE(), 'Login exitoso'); -- 1 Login Exitoso
        
        SET @outCodigo = 0;
        SET @outMensaje = 'Éxito';
    END



    ELSE -- usuario no existe
    BEGIN
        INSERT INTO BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime, Descripcion)
        VALUES (2, 1, @inIP, GETDATE(), 'Intento fallido: ' + @inUsername); -- 2: Login No Exitoso
        
        SET @outCodigo = 50001; 
        SET @outMensaje = 'Credenciales inválidas';
    END
END;




CREATE PROCEDURE sp_RegistrarLogout
    @inIdUsuario INT,
    @inIP VARCHAR(50),
    @outCodigo INT OUTPUT,
    @outMensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime, Descripcion)
    VALUES (4, @inIdUsuario, @inIP, GETDATE(), 'Cierre de sesión'); -- 4: Logout
    
    SET @outCodigo = 0;
    SET @outMensaje = 'Logout registrado';
END;