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




ALTER PROCEDURE sp_ListarEmpleados
    @inFiltro VARCHAR(100),
    @inIdPostByUser INT,
    @inIP VARCHAR(50)
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
        INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
            VALUES (
                12, 
                'Consulta por documento de identidad exitosa.',
                @inIdPostByUser, @inIP, GETDATE()
            );
            
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

        INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
            VALUES (
                11, 
                'Consulta por nombre exitosa.',
                @inIdPostByUser, @inIP, GETDATE()
            );
    END
END;






CREATE PROCEDURE sp_InsertarMovimiento
    @inIdEmpleado INT,
    @inIdTipoMovimiento INT,
    @inMonto DECIMAL(10,2),
    @inIdPostByUser INT, 
    @inPostInIP VARCHAR(50),
    @outCodigo INT,
    @outMensaje VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @saldoActual DECIMAL(10,2), @tipoAccion INT, @nuevoSaldo DECIMAL(10,2);
    DECLARE @nombreEmp VARCHAR(100), @tipoMovNombre VARCHAR(100);

    BEGIN TRY
        -- Datos empleado
        SELECT @saldoActual = SaldoVacaciones, 
               @nombreEmp = Nombre 
               FROM Empleado WHERE Id = @inIdEmpleado;

        -- Datos de la accion
        SELECT @tipoAccion = TipoAccion,
               @tipoMovNombre = Nombre 
               FROM TipoMovimiento WHERE Id = @inIdTipoMovimiento;

        SET @nuevoSaldo = @saldoActual + (@inMonto * @tipoAccion); -- Calcular nuevo saldo


        -- Validación de saldo negativo
        IF @nuevoSaldo < 0
        BEGIN
            SELECT @outCodigo = Codigo, @outMensaje = Descripcion FROM Error WHERE Codigo = 50006;
            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
            VALUES (
                13, 
                CONCAT('INTENTO FALLIDO: Inserto movimiento de ', @tipoMovNombre, ' para ', @nombreEmp, '. Saldo insuficiente.'),
                @inIdPostByUser, @inPostInIP, GETDATE()
            );
            RETURN;
        END

        BEGIN TRANSACTION;

            -- Registrar el movimiento
            INSERT INTO Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
            VALUES (@inIdEmpleado, @inIdTipoMovimiento, GETDATE(), @inMonto, @nuevoSaldo, @inIdPostByUser, @inPostInIP, GETDATE());

            -- Actualizar el saldo del empleado
            UPDATE Empleado SET SaldoVacaciones = @nuevoSaldo WHERE Id = @inIdEmpleado;

            -- Inserción en BitacoraEvento 
            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
            VALUES (
                14, 
                CONCAT('Movimiento de ', @tipoMovNombre, ' para: ', @nombreEmp, '. Monto: ', @inMonto, '. Nuevo Saldo: ', @nuevoSaldo),
                @inIdPostByUser, 
                @inPostInIP, 
                GETDATE()
            );
        COMMIT TRANSACTION;
        SET @outCodigo = 0; SET @outMensaje = 'Movimiento registrado con éxito.';

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outCodigo = 50000; SET @outMensaje = ERROR_MESSAGE();
    END CATCH
END;



Create PROCEDURE sp_ActualizarEmpleado
    @inIdPostByUser INT,
    @inId INT,
    @inValorDoc VARCHAR(50),
    @inNombre VARCHAR(100),
    @inIdPuesto INT,
    @inIP VARCHAR(50),
    @outCodigo INT OUTPUT,
    @outMensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validar que exista
        IF NOT EXISTS (
            SELECT 1 
            FROM Empleado 
            WHERE Id = @inId AND EsActivo = 1
        )
        BEGIN
            SET @outCodigo = 50001;
            SET @outMensaje = 'Empleado no existe';

            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (
                7,
                'Actualización fallida, empleado no existe. Id: ' + CAST(@inId AS VARCHAR),
                @inIdPostByUser,
                @inIP
            );

            RETURN;
        END

        -- Validar documento duplicado
        IF EXISTS (
            SELECT 1 
            FROM Empleado 
            WHERE ValorDocumentoIdentidad = @inValorDoc AND Id <> @inId AND EsActivo =)
        BEGIN
            SELECT @outCodigo = Codigo, @outMensaje = Descripcion 
            FROM Error WHERE Codigo = 50006;

            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (
                7,
                'Actualización fallida, documento duplicado. Id: ' + CAST(@inId AS VARCHAR),
                @inIdPostByUser,
                @inIP
            );

            RETURN;
        END

        -- Validar nombre duplicado
        IF EXISTS (
            SELECT 1 
            FROM Empleado 
            WHERE Nombre = @inNombre
            AND Id <> @inId
            AND EsActivo = 1
        )
        BEGIN
            SELECT @outCodigo = Codigo, @outMensaje = Descripcion 
            FROM Error WHERE Codigo = 50007;

            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (
                7,
                'Actualización fallida, nombre duplicado. Id: ' + CAST(@inId AS VARCHAR),
                @inIdPostByUser,
                @inIP
            );

            RETURN;
        END

        BEGIN TRANSACTION;

            UPDATE Empleado
            SET ValorDocumentoIdentidad = @inValorDoc,
                Nombre = @inNombre,
                IdPuesto = @inIdPuesto
            WHERE Id = @inId;

            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (
                8,
                'Empleado actualizado correctamente. Id: ' + CAST(@inId AS VARCHAR),
                @inIdPostByUser,
                @inIP
            );

        COMMIT TRANSACTION;

        SET @outCodigo = 0;
        SET @outMensaje = 'Empleado actualizado correctamente';

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @outCodigo = 50000;
        SET @outMensaje = ERROR_MESSAGE();
    END CATCH

END;




CREATE PROCEDURE sp_EliminarEmpleado
    @inId INT,
    @inIdPostByUser INT,
    @inIP VARCHAR(50),
    @outCodigo INT OUTPUT,
    @outMensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Validar existencia
        IF NOT EXISTS (
            SELECT 1 
            FROM Empleado 
            WHERE Id = @inId AND EsActivo = 1
        )
        BEGIN
            SET @outCodigo = 50001;
            SET @outMensaje = 'Empleado no existe o ya está inactivo';

            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (
                9,
                'Eliminación fallida. Empleado no existe. Id: ' + CAST(@inId AS VARCHAR),
                @inIdPostByUser,
                @inIP
            );

            RETURN;
        END

        BEGIN TRANSACTION;

            -- Borrado lógico
            UPDATE Empleado
            SET EsActivo = 0
            WHERE Id = @inId;

            INSERT INTO BitacoraEvento (idTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (
                10,
                'Empleado eliminado (lógico) de Id: ' + CAST(@inId AS VARCHAR),
                @inIdPostByUser,
                @inIP
            );

        COMMIT;

        SET @outCodigo = 0;
        SET @outMensaje = 'Empleado eliminado correctamente';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @outCodigo = 50000;
        SET @outMensaje = ERROR_MESSAGE();
    END CATCH
END;



CREATE PROCEDURE sp_ConsultarEmpleadoDetalle
    @inIdEmpleado INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Datos empleado
    SELECT 
        e.ValorDocumentoIdentidad,
        e.Nombre,
        e.SaldoVacaciones
    FROM Empleado e
    WHERE e.Id = @inIdEmpleado AND e.EsActivo = 1;

    -- Movimientos
    SELECT 
        m.Fecha,
        tm.Nombre AS TipoMovimiento,
        m.Monto,
        m.NuevoSaldo,
        u.Username AS UsuarioRegistro,
        m.PostInIP,
        m.PostTime
    FROM Movimiento m
    INNER JOIN TipoMovimiento tm ON m.IdTipoMovimiento = tm.Id
    INNER JOIN Usuario u ON m.IdPostByUser = u.Id
    WHERE m.IdEmpleado = @inIdEmpleado
    ORDER BY m.Fecha DESC;
END;