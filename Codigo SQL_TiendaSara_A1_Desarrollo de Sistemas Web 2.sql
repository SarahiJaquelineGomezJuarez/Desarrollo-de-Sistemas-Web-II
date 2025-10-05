
-- 1) Crear la base de datos TiendaSara(desde cero)
CREATE DATABASE TiendaSara;
GO
---2)Usar la base de datos TiendaSara---
USE TiendaSara;
GO
-- 3) Crear las Tablas de Categoria y Marca (COLLATE explícito en columnas de texto)
CREATE TABLE Categoria (
    Id_Categoria           INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Descripcion_Categoria  NVARCHAR(100) COLLATE Latin1_General_CI_AI NOT NULL UNIQUE
);

USE TiendaSara;
GO
CREATE TABLE Marcas (
    Id_Marca           INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Descripcion_Marca   NVARCHAR(100) COLLATE Latin1_General_CI_AI NOT NULL UNIQUE
);

USE TiendaSara;
GO
-- Crear la Tablas de EstatusVenta para simular ENUM/SET en SQL Server
CREATE TABLE EstatusVenta (
    Id_EstatusVenta           INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Descripcion_EstatusVenta   NVARCHAR(30)  COLLATE Latin1_General_CI_AI NOT NULL UNIQUE
);

-- 3) Tablas principales:Producto,Carrito,CarritoDetalle
USE TiendaSara;
GO
CREATE TABLE Productos (
    Id_Producto  INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Descripcion_Producto  NVARCHAR(150) COLLATE Latin1_General_CI_AI NOT NULL,
    Precio       DECIMAL(10,2) NOT NULL CHECK (Precio >= 0),
    Cantidad     INT NOT NULL CHECK (Cantidad >= 0),
    Id_Categoria  INT NOT NULL,
    Id_Marca      INT NOT NULL,
    CONSTRAINT FK_Productos_Categoria FOREIGN KEY (Id_Categoria) REFERENCES Categoria(Id_Categoria),
    CONSTRAINT FK_Productos_Marcas FOREIGN KEY (Id_Marca)  REFERENCES Marcas(Id_Marca),
    CONSTRAINT UQ_Productos UNIQUE (Descripcion_Producto, Id_Marca)
);
USE TiendaSara;
GO
CREATE TABLE Carrito (
    Id_Carrito  INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Folio_Venta     VARCHAR(20) COLLATE Latin1_General_CI_AI NOT NULL UNIQUE,
    Total_Compra    DECIMAL(12,2) NOT NULL CONSTRAINT DF_Carrito_Total DEFAULT (0),
    Fecha          DATETIME2 NOT NULL CONSTRAINT DF_Carrito_Fecha DEFAULT (SYSUTCDATETIME()),
    Id_EstatusVenta INT NOT NULL,
    CONSTRAINT FK_Carrito_EstatusVenta FOREIGN KEY (Id_EstatusVenta) REFERENCES EstatusVenta(Id_EstatusVenta)
);
USE TiendaSara;
GO
CREATE TABLE CarritoDetalle (
    Id_CarritoDetalle  INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Id_Carrito    INT NOT NULL,
    Id_Producto   INT NOT NULL,
    Cantidad     INT NOT NULL CHECK (Cantidad > 0),
    Subtotal     DECIMAL(12,2) NOT NULL CHECK (Subtotal >= 0),
    CONSTRAINT FK_CarritoDetalle_Carrito  FOREIGN KEY (Id_Carrito)  REFERENCES Carrito(Id_Carrito) ON DELETE CASCADE,
    CONSTRAINT FK_CarritoDetalle_Producto FOREIGN KEY (Id_Producto) REFERENCES Productos(Id_Producto)
);

-- 4) Creacion de los Índices útiles (INDEX)
USE TiendaSara;
GO
CREATE INDEX IX_Categoria_Descripcion      ON Categoria(Descripcion_Categoria);
CREATE INDEX IX_Marcas_Descripcion         ON Marcas(Descripcion_Marca);
CREATE INDEX IX_EstatusVenta_Descripcion   ON EstatusVenta(Descripcion_EstatusVenta);

CREATE INDEX IX_Productos_Id_Categoria     ON Productos(Id_Categoria);
CREATE INDEX IX_Productos_Id_Marca         ON Productos(Id_Marca);

CREATE INDEX IX_Carrito_IdEstatusVenta     ON Carrito(Id_EstatusVenta);

CREATE INDEX IX_CarritoDetalle_IdCarrito   ON CarritoDetalle(Id_Carrito);
CREATE INDEX IX_CarritoDetalle_IdProducto  ON CarritoDetalle(Id_Producto);
;

-- 5) Insercion de Datos a Cada Tabla con INSERT INTO (5 por tabla)
USE TiendaSara;
GO
INSERT INTO Categoria (Descripcion_Categoria) VALUES
('Electrónicos'), ('Hogar'), ('Ropa'), ('Juguetes'), ('Libros');

INSERT INTO Marcas (Descripcion_Marca) VALUES
('Acme'), ('NovaTech'), ('CasaPlus'), ('Kids&Fun'), ('LectorMx');

INSERT INTO EstatusVenta (Descripcion_EstatusVenta) VALUES
('Abierto'), ('Cancelado'), ('Pagado'), ('En_Proceso'), ('Enviado');

INSERT INTO Productos (Descripcion_Producto, Precio, Cantidad, Id_Categoria, Id_Marca) VALUES
('Auriculares inalámbricos',  899.00, 50, 1, 2),
('Batidora 500W',              749.50, 30, 2, 3),
('Playera algodón unisex',     199.90, 80, 3, 1),
('Bloques de construcción 1k', 649.00, 25, 4, 4),
('Libro "SQL para todos"',     329.00, 60, 5, 5);

INSERT INTO Carrito (Folio_Venta, Id_EstatusVenta) VALUES
('F0001', 1),
('F0002', 1),
('F0003', 3),
('F0004', 2),
('F0005', 4);

-- CarritoDetalle con Subtotal = Cantidad * Precio---
USE TiendaSara;
GO
INSERT INTO CarritoDetalle (Id_Carrito, Id_Producto, Cantidad, Subtotal) VALUES
(1, 1, 1, 1 * (SELECT Precio FROM Productos WHERE Id_Producto = 1)),
(1, 3, 2, 2 * (SELECT Precio FROM Productos WHERE Id_Producto = 3)),
(2, 2, 1, 1 * (SELECT Precio FROM Productos WHERE Id_Producto = 2)),
(2, 5, 3, 3 * (SELECT Precio FROM Productos WHERE Id_Producto = 5)),
(3, 4, 1, 1 * (SELECT Precio FROM Productos WHERE Id_Producto = 4));

-- Recalcular Total_Compra en Carrito 
USE TiendaSara;
GO
UPDATE Carrito
SET Total_Compra = (
    SELECT ISNULL(SUM(CarritoDetalle.Subtotal), 0)
    FROM CarritoDetalle
    WHERE CarritoDetalle.Id_Carrito = Carrito.Id_Carrito
);

--- 6) Consultas de evidencias usando INNER JOIN

-- a) Productos con sus marcas y sus categorías
USE TiendaSara;
GO
SELECT
    Productos.Id_Producto,
    Productos.Descripcion_Producto AS Productos,
    Productos.Precio,
    Productos.Cantidad,
    Marcas.Descripcion_Marca        AS Marcas,
    Categoria.Descripcion_Categoria AS Categoria
FROM Productos
INNER JOIN Marcas    ON Marcas.Id_Marca        = Productos.Id_Marca
INNER JOIN Categoria ON Categoria.Id_Categoria = Productos.Id_Categoria
ORDER BY Productos.Id_Producto;
GO

-- b) Carritos con su detalle y productos
USE TiendaSara;
GO
SELECT
    Carrito.Id_Carrito                   AS Carrito_Id,
    Carrito.Folio_Venta,
    EstatusVenta.Descripcion_EstatusVenta AS Estatus,
    Carrito.Total_Compra,
    Carrito.Fecha,
    CarritoDetalle.Id_CarritoDetalle     AS Detalle_Id,
    CarritoDetalle.Cantidad,
    CarritoDetalle.Subtotal,
    Productos.Descripcion_Producto       AS Productos
FROM Carrito
INNER JOIN EstatusVenta   ON EstatusVenta.Id_EstatusVenta = Carrito.Id_EstatusVenta
INNER JOIN CarritoDetalle ON CarritoDetalle.Id_Carrito    = Carrito.Id_Carrito
INNER JOIN Productos      ON Productos.Id_Producto        = CarritoDetalle.Id_Producto
ORDER BY Carrito.Id_Carrito, CarritoDetalle.Id_CarritoDetalle;
GO

-- c) Carritos con detalle, productos, marcas y categorías
USE TiendaSara;
GO
SELECT
    Carrito.Id_Carrito                    AS Carrito_Id,
    Carrito.Folio_Venta,
    EstatusVenta.Descripcion_EstatusVenta AS Estatus,
    Carrito.Total_Compra,
    Carrito.Fecha,
    CarritoDetalle.Id_CarritoDetalle      AS Detalle_Id,
    CarritoDetalle.Cantidad,
    CarritoDetalle.Subtotal,
    Productos.Descripcion_Producto        AS Productos,
    Marcas.Descripcion_Marca              AS Marcas,
    Categoria.Descripcion_Categoria       AS Categoria
FROM Carrito
INNER JOIN EstatusVenta   ON EstatusVenta.Id_EstatusVenta = Carrito.Id_EstatusVenta
INNER JOIN CarritoDetalle ON CarritoDetalle.Id_Carrito    = Carrito.Id_Carrito
INNER JOIN Productos      ON Productos.Id_Producto        = CarritoDetalle.Id_Producto
INNER JOIN Marcas         ON Marcas.Id_Marca              = Productos.Id_Marca
INNER JOIN Categoria      ON Categoria.Id_Categoria       = Productos.Id_Categoria
ORDER BY Carrito.Id_Carrito, CarritoDetalle.Id_CarritoDetalle;
GO
-- 7) Vista opcional útil para reportes ---
USE TiendaSara;
GO
IF OBJECT_ID('vCarritoDetalleInfo', 'V') IS NOT NULL
    DROP VIEW vCarritoDetalleInfo;
GO
CREATE VIEW vCarritoDetalleInfo
AS
SELECT
    Carrito.Id_Carrito                    AS Carrito_Id,
    Carrito.Folio_Venta,
    Carrito.Total_Compra,
    Carrito.Fecha,
    EstatusVenta.Descripcion_EstatusVenta AS Estatus,
    CarritoDetalle.Id_CarritoDetalle      AS CarritoDetalle_Id,
    CarritoDetalle.Cantidad,
    CarritoDetalle.Subtotal,
    Productos.Id_Producto                 AS Producto_Id,
    Productos.Descripcion_Producto        AS Productos,
    Productos.Precio,
    Categoria.Descripcion_Categoria       AS Categoria,
    Marcas.Descripcion_Marca              AS Marcas
FROM Carrito
INNER JOIN EstatusVenta   ON EstatusVenta.Id_EstatusVenta = Carrito.Id_EstatusVenta
INNER JOIN CarritoDetalle ON CarritoDetalle.Id_Carrito    = Carrito.Id_Carrito
INNER JOIN Productos      ON Productos.Id_Producto        = CarritoDetalle.Id_Producto
INNER JOIN Categoria      ON Categoria.Id_Categoria       = Productos.Id_Categoria
INNER JOIN Marcas         ON Marcas.Id_Marca              = Productos.Id_Marca;
GO
-- 8) Procedimiento almacenado --— 
USE TiendaSara;
GO
IF OBJECT_ID('RecalcularTotalesCarrito', 'P') IS NOT NULL
    DROP PROCEDURE RecalcularTotalesCarrito;
GO
CREATE PROCEDURE RecalcularTotalesCarrito
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Carrito
    SET Total_Compra = (
        SELECT ISNULL(SUM(CarritoDetalle.Cantidad * Productos.Precio), 0)
        FROM CarritoDetalle
        INNER JOIN Productos ON Productos.Id_Producto = CarritoDetalle.Id_Producto
        WHERE CarritoDetalle.Id_Carrito = Carrito.Id_Carrito
    );
END;
GO
