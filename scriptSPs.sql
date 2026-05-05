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
    DECLARE @intentosFallidos INT;
    SET @outIdUsuario = NULL;

    -- Consultar intentos fallidos 
    SELECT @intentosFallidos = COUNT(*)
    FROM BitacoraEvento
    WHERE PostInIP = @inIP 
      AND idTipoEvento = 2 -- Login No Exitoso
      AND PostTime > DATEADD(MINUTE, -20, GETDATE());


    IF @intentosFallidos >= 5 -- Muchos intentos fallidos
    BEGIN
        SELECT @outCodigo = Codigo, @outMensaje = Descripcion 
        FROM Error WHERE Codigo = 50002;
        RETURN;
    END


    -- Validar Credenciales
    SELECT @outIdUsuario = Id FROM Usuario 
    WHERE Username = @inUsername AND Password = @inPassword;


    IF @outIdUsuario IS NOT NULL -- Si hay usuario
    BEGIN
        INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
        VALUES (1, 'Login Exitoso', @outIdUsuario, @inIP);
        SET @outCodigo = 0; SET @outMensaje = 'Éxito';
    END



    ELSE -- El usuario metió credenciales incorrectas
    BEGIN  
        INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
        VALUES (2, 'Login No Exitoso: ' + @inUsername, 1, @inIP);
        
        SELECT @outCodigo = Codigo, @outMensaje = Descripcion 
        FROM Error WHERE Codigo = 50001; 
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



CREATE PROCEDURE sp_InsertarEmpleado
    @inValorDoc VARCHAR(50),
    @inNombre VARCHAR(100),
    @inIdPuesto INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(50),
    @outCodigo INT OUTPUT,
    @outMensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Validar que no se repita nombre o documento de indentidad
    IF EXISTS (SELECT 1 FROM Empleado WHERE ValorDocumentoIdentidad = @inValorDoc OR Nombre = @inNombre)
    BEGIN
        SELECT @outCodigo = Codigo, @outMensaje = Descripcion 
        FROM Error WHERE Codigo = 50005;
        RETURN;
    END


    -- Si no existe, insertar
    INSERT INTO Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, EsActivo)
    VALUES (@inIdPuesto, @inValorDoc, @inNombre, GETDATE(), 1);

    -- Insertar en bitácora
    INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
    VALUES (11, 'Inserción Empleado: ' + @inValorDoc, @inIdPostByUser, @inPostInIP);

    SET @outCodigo = 0; SET @outMensaje = 'Éxito';
END;

CREATE PROCEDURE sp_ListarEmpleados
    @inFiltro VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Sin filtro (retorna todo)
    IF @inFiltro IS NULL OR @inFiltro = ''
    BEGIN
        SELECT 
            E.Id, 
            E.Nombre, 
            E.ValorDocumentoIdentidad, 
            P.Nombre AS NombrePuesto, 
            E.SaldoVacaciones
        FROM Empleado E
        INNER JOIN Puesto P ON E.IdPuesto = P.Id
        WHERE E.EsActivo = 1
        ORDER BY E.Nombre ASC;
    END


    -- solo números (cédula)
    ELSE IF @inFiltro NOT LIKE '%[^0-9]%'
    BEGIN
        SELECT 
            E.Id, 
            E.Nombre, 
            E.ValorDocumentoIdentidad, 
            P.Nombre AS NombrePuesto, 
            E.SaldoVacaciones
        FROM Empleado E
        INNER JOIN Puesto P ON E.IdPuesto = P.Id
        WHERE E.ValorDocumentoIdentidad LIKE '%' + @inFiltro + '%'
          AND E.EsActivo = 1
        ORDER BY E.Nombre ASC;
    END

    
    --letras (por Nombre)
    ELSE
    BEGIN
        SELECT 
            E.Id, 
            E.Nombre, 
            E.ValorDocumentoIdentidad, 
            P.Nombre AS NombrePuesto, 
            E.SaldoVacaciones
        FROM Empleado E
        INNER JOIN Puesto P ON E.IdPuesto = P.Id
        WHERE E.Nombre LIKE '%' + @inFiltro + '%'
          AND E.EsActivo = 1
        ORDER BY E.Nombre ASC;
    END
END;