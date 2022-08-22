-- Pregunta 1 -------------------------------
SELECT
    s.IdSucursal,
    s.Sucursal,
    SUM(v.precio * v.Cantidad - g.monto) as gan
FROM venta v
JOIN sucursal s ON (v.IdSucursal = S.IdSucursal)
JOIN gasto g ON (s.IdSucursal = g.IdSucursal)
WHERE YEAR(v.fecha) = 2020
GROUP BY s.IdSucursal
ORDER BY gan DESC;

-- Pregunta 2 ------------------
SELECT
    tp.TipoProducto,
    SUM(v.Precio*c.Cantidad - c.Precio*c.Cantidad) as gan
FROM venta v
JOIN compra c ON (v.IdProducto = c.IdProducto)
JOIN producto p ON (c.IdProducto = p.IdProducto)
JOIN tipo_producto tp ON (p.IdTipoProducto = tp.IdTipoProducto)
WHERE YEAR(v.Fecha) = 2020 AND YEAR(c.Fecha) = 2020
GROUP BY TipoProducto
ORDER BY gan DESC;

-- Pregunta 3 --------------------
# Tabla con la razón de clientes que compraron en 2020 en una sola Sucursal
# sobre los clientes que compraron en 2020
SELECT 
    COUNT(Clientes_1Suc_2020.Idcliente) / Clientes2020.Cantidad AS Promedio
FROM (  # Tabla con los clientes que compraron en una sola sucursal en 2020. 814 registros
    SELECT IdCliente, count(IdSucursal) as IdSucursal
    FROM ( # Tabla con cliente y sucursal de compra sin repetir el conjunto de ambos
        SELECT DISTINCT v.IdCliente, v.IdSucursal
        FROM venta v
        WHERE YEAR(v.Fecha) = 2020
        ) cliente_sucursal_distinto
    GROUP BY IdCliente
    HAVING IdSucursal = 1
    ) Clientes_1Suc_2020
JOIN ( #Tabla con el CONTEO de clientes que compraron en 2020. 1 registro
    SELECT COUNT(IdCliente) AS Cantidad
    FROM ( #Tabla con los clientes que compraron en 2020. 2415 Registros
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2020
        ) tabla
    ) Clientes2020 ;

-- Pregunta 4 --------------------
SELECT COUNT(IdCliente) / Clientes2020.cantidad As Prom 
FROM (#Clientes que compraron en 2020 pero no en 2019
    SELECT tab2020.IdCliente
    FROM(#Clientes que compraron en 2020
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2020) tab2020
    LEFT JOIN (#Clientes que compraron en 2019
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2019) tab2019 ON (tab2020.IdCliente = tab2019.IdCliente)
    WHERE tab2019.IdCliente IS NULL) t2020NOT2019
JOIN (#Cantidad de clientes que compraron en 2020
    SELECT COUNT(IdCliente) AS Cantidad
    FROM (#Clientes que compraron en 2020
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2020
        ) tabla
    ) Clientes2020;

-- Pregunta 5 --------------------
SELECT COUNT(IdCliente) / Clientes2019.cantidad As Prom 
FROM (# Clientes que compearon en 2020 y 2019
    SELECT tab2020.IdCliente
    FROM(#Clientes que compraron en 2020
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2020) tab2020
    INNER JOIN (# Clientes que compraron en 2019
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2019) tab2019 ON (tab2020.IdCliente = tab2019.IdCliente)
    ) t2020and2019
JOIN ( # Catidad de clientes que compraron en 2019
    SELECT COUNT(IdCliente) AS Cantidad
    FROM (# clientes que compraron en 2019
        SELECT DISTINCT v.IdCliente
        FROM venta v
        WHERE YEAR(v.Fecha) = 2019
    ) tabla
) Clientes2019;

-- Pregunta 6 -------------------------
SELECT count(*) as Cantidad
FROM ( # Clientes que compraron Online en 2020
    SELECT DISTINCT v.IdCliente
    FROM venta v 
    JOIN canal_venta cv ON (v.IdCanal = cv.IdCanal)
    WHERE cv.Canal = "OnLine" AND YEAR(v.Fecha) BETWEEN 2019 AND 2020
    ) clientesOnline2019_2020
WHERE IdCliente NOT IN ( #CLientes que compraron por un medio diferente al Online en 2020
    SELECT DISTINCT v.IdCliente
    FROM venta v 
    JOIN canal_venta cv ON (v.IdCanal = cv.IdCanal)
    WHERE cv.Canal != "OnLine" AND YEAR(v.Fecha) BETWEEN 2019 AND 2020    
);

-- Pegunta 7 --------------------------
SELECT
    Sucursal,
    SUM(TotalVenta) AS TOTAL
FROM ( # Tabla con la sucursal y provincia de sucursal en cada venta
    SELECT 
        v.IdVenta, 
        s.IdSucursal,
        S.Sucursal, 
        p.IdProvincia as Provincia_Sucursal,
        v.Cantidad * v.Precio AS TotalVenta
    FROM venta v
    JOIN sucursal s ON (v.IdSucursal = s.IdSucursal)
    JOIN localidad l ON (s.IdLocalidad = l.IdLocalidad)
    JOIN provincia p ON (l.IdProvincia = p.IdProvincia)
    WHERE YEAR(v.Fecha) = 2020
    ) Sucursal_p
JOIN ( # Tabla con el cliente y provincia de cliente en cada venta
    SELECT 
        v.IdVenta, 
        c.IdCliente, 
        p.IdProvincia as Provincia_Cliente
    FROM venta v
    JOIN cliente c ON (v.IdCliente = c.IdCliente)
    JOIN localidad l ON (c.IdLocalidad = l.IdLocalidad)
    JOIN provincia p ON (l.IdProvincia = p.IdProvincia)
    WHERE YEAR(v.Fecha) = 2020
    ) Cliente_p ON (Sucursal_p.IdVenta = Cliente_p.IdVenta)
WHERE Provincia_Sucursal != Provincia_Cliente
GROUP BY Sucursal
ORDER BY TOTAL DESC;

-- Pregunta 8 --------------------------------------------
SELECT Dif_Ventas.Mes, Dif_Ventas.Ventas-Dif_Gastos.Gastos-Dif_Compras.Compras as Balance
FROM ( #Tabla con la diferencia de ventas entre 2020 y 2019 por mes
    SELECT 
        vent2020.Mes as Mes,
        vent2020.Venta - vent2019.Venta as Ventas
    FROM( #Tabla con la venta de 2020 por mes 
        SELECT 
            MONTH(fecha) as Mes,
            SUM(Precio * Cantidad) as Venta
        FROM venta v
        WHERE YEAR(Fecha) = 2020
        GROUP BY Mes
        ) vent2020
    JOIN( #Tabla con la venta de 2019 por mes 
        SELECT 
            MONTH(fecha) as Mes, 
            SUM(Precio * Cantidad) as Venta
        FROM venta v
        WHERE YEAR(Fecha) = 2019
        GROUP BY Mes
        ) vent2019 ON (vent2020.Mes = vent2019.Mes)
    ) Dif_Ventas
JOIN ( # Tabla con la diferencia de compra entre 2020 y 2019 por mes
    SELECT 
        comp2020.Mes as Mes,
        comp2020.Compra - comp2019.Compra as Compras
    FROM( #Compra de 2020 por mes
        SELECT 
            MONTH(fecha) as Mes,
            SUM(Precio * Cantidad) as Compra
        FROM compra c
        WHERE YEAR(Fecha) = 2020
        GROUP BY Mes
        ) comp2020
    JOIN(# Compra de 2019 por mes
        SELECT 
            MONTH(fecha) as Mes, 
            SUM(Precio * Cantidad) as Compra
        FROM compra c
        WHERE YEAR(Fecha) = 2019
        GROUP BY Mes
        ) comp2019 ON (comp2020.Mes = comp2019.Mes)
    ) Dif_Compras ON (Dif_Ventas.Mes = Dif_Compras.Mes)
JOIN (#Tabla con diferencia de gastos de 2020 y 2019 por mes
        SELECT 
        gast2020.Mes as Mes,
        gast2020.Gasto - gast2019.Gasto as Gastos
    FROM( # Tabla gastos por mes 2020
        SELECT 
            MONTH(fecha) as Mes,
            SUM(Monto) as Gasto
        FROM gasto g
        WHERE YEAR(Fecha) = 2020
        GROUP BY Mes
        ) gast2020
    JOIN( # Tabla Gastos por mes 2019
        SELECT 
            MONTH(fecha) as Mes, 
            SUM(Monto) as Gasto
        FROM gasto g
        WHERE YEAR(Fecha) = 2019
        GROUP BY Mes
        ) gast2019 ON (gast2020.Mes = gast2019.Mes)
    ) Dif_Gastos ON (Dif_Ventas.Mes = Dif_Gastos.Mes)
ORDER BY Balance DESC;

-- Pregunta 9
Select	cl.Rango_Etario,
		tp.TipoProducto,
        sum(v.Precio * v.Cantidad) as Venta
from 	venta v Join cliente cl
		On (v.IdCliente = cl.IdCliente
			And Year(v.Fecha) = 2020
            And Month(v.Fecha) >= 6)
	Join producto p
		On (v.IdProducto = p.IdProducto)
	Join tipo_producto tp
		On (p.IdTipoProducto = tp.IdTipoProducto
			And TipoProducto In ('Estucheria','Informatica','Impresión','Audio'))
	Join canal_venta cp
		On (cp.IdCanal = v.IdCanal
			And cp.Canal = 'OnLine')
	Join sucursal s
		On (s.IdSucursal = v.IdSucursal)
	Join localidad lo
		On (s.IdLocalidad = lo.IdLocalidad)
	Join provincia pr
		On (lo.IdProvincia = pr.IdProvincia
			And pr.Provincia = 'Buenos Aires')
Group by cl.Rango_Etario,
		tp.TipoProducto
Order by cl.Rango_Etario,
		Venta Desc;


-- Pregunta 10 ----
SELECT 
    c.CodigoEmpleado,
    SUM(c.Porcentaje) as TotalPercent,
    e.Salario*SUM(c.Porcentaje)/100 as TotalComision
FROM comision c
JOIN empleado e ON (e.CodigoEmpleado = c.CodigoEmpleado)
WHERE Anio = 2020
GROUP BY CodigoEmpleado
ORDER BY TotalPercent DESC;

