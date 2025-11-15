-- Llamamos la base de datos --

USE Monedas;
GO

-- Paises qye usan la moneda --

WITH ConteoPaises AS (
    SELECT IdMoneda,
        COUNT(*) AS TotalPaises
        FROM Pais
        GROUP BY IdMoneda
    ),
-- Fecha del último cambio registrado --
    UltimoCambio AS (
    SELECT IdMoneda, 
        Fecha AS UltimaFecha,
        Cambio AS UltimoCambio
    FROM CambioMoneda CM1
    WHERE CM1.Fecha = (
        SELECT MAX(CM2.Fecha)
        FROM CambioMoneda CM2
        WHERE CM2.IdMoneda = CM1.IdMoneda
        )
    ),
-- El valor del último cambio --
    UltimoCambioUnico AS (
    SELECT DISTINCT IdMoneda, UltimaFecha, UltimoCambio
    FROM UltimoCambio
    ),
-- El promedio de cambio en los últimos 30 días --
    Promedio30Dias AS (
    SELECT IdMoneda,
        CASE WHEN COUNT(*) > 0
        THEN CAST(SUM(Cambio) AS FLOAT) / COUNT(*)
        ELSE NULL 
        END AS Promedio30Dias
    FROM CambioMoneda
    WHERE Fecha >= '2025-10-16' 
      AND Fecha < '2025-11-15'
    GROUP BY IdMoneda
    ),
-- Clasificación de volatilidad --
    VolatilidadDias AS (
    SELECT IdMoneda,
        CASE WHEN COUNT(*) > 1 
        AND (MAX(Cambio) - MIN(Cambio)) / (CAST(SUM(Cambio) AS FLOAT) / COUNT(*)) < 0.05
        THEN 'Estable'
        ELSE 'Volátil'
        END AS Volatilidad
    FROM CambioMoneda
    WHERE Fecha >= '2025-10-16' 
      AND Fecha < '2025-11-15'
    GROUP BY IdMoneda
    )
-- Ranking por cantidad de países que usan la moneda --
    SELECT M.Id, M.Moneda, M.Sigla,
        CASE WHEN CP.TotalPaises IS NULL 
        THEN 0 
        ELSE CP.TotalPaises 
        END AS TotalPaises,
        UCU.UltimaFecha, UCU.UltimoCambio,ROUND(p30.Promedio30Dias, 10) AS Promedio30Dias,
        CASE WHEN V.Volatilidad IS NULL THEN 'Estable'
        ELSE V.Volatilidad 
        END AS Volatilidad,
        (   SELECT COUNT(*) + 1
            FROM ConteoPaises CP2
            JOIN Moneda M2 ON CP2.IdMoneda = M2.Id
            WHERE CP2.TotalPaises > ISNULL(CP.TotalPaises, 0)
            OR (CP2.TotalPaises = ISNULL(CP.TotalPaises, 0) AND M2.Moneda < M.Moneda)
        ) AS RankingUso
-- Union de la tabla y clacullos--
        FROM Moneda M
        LEFT JOIN ConteoPaises CP ON M.Id = CP.IdMoneda
        LEFT JOIN UltimoCambioUnico UCU ON M.Id = UCU.IdMoneda
        LEFT JOIN Promedio30Dias P30 ON M.Id = P30.IdMoneda
        LEFT JOIN VolatilidadDias V ON M.Id = V.IdMoneda
        ORDER BY RankingUso;

-----------------------------------------------------------------------
-- 650202005-2 FUNDAMENTOS Y DISEÑO DE BASES DE DATOS-VIRTUAL 2025-2 --
-- JAVIER ORLANDO DELGADO PIEDRAHITA                                 -- 
-- SANTIAGO HERRERA MUNERA                                           --
-----------------------------------------------------------------------