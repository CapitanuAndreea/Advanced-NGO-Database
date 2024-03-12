CREATE OR REPLACE PROCEDURE cel_mai_activ_membru
IS
    v_id_membru MEMBRI_ACTIVI.ID_MEMBRU%TYPE;
    v_punctaj NUMBER;
BEGIN
    SELECT ID_MEMBRU, punctaj INTO v_id_membru, v_punctaj
    FROM (
        SELECT M.ID_MEMBRU,
               COUNT(T.ID_MEMBRU) + 2 * COUNT(P.ID_COORDONATOR) AS punctaj,
               RANK() OVER (ORDER BY COUNT(T.ID_MEMBRU) + 2 * COUNT(P.ID_COORDONATOR) DESC) AS rnk
        FROM CLUBURI C
        JOIN DEPARTAMENTE D ON (C.ID_CLUB = D.ID_CLUB)
        JOIN MEMBRI_ACTIVI M ON (D.ID_DEPARTAMENT = M.ID_DEPARTAMENT)
        LEFT JOIN TASK T ON (M.ID_MEMBRU = T.ID_MEMBRU)
        LEFT JOIN PROIECT P ON (M.ID_MEMBRU = P.ID_COORDONATOR)
        GROUP BY M.ID_MEMBRU
    ) WHERE rnk = 1;

    DBMS_OUTPUT.PUT_LINE('ID Membru cu punctaj maxim: ' || v_id_membru || ', Punctaj: ' || v_punctaj);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Un departament nu are membri.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Un departament are mai multi membri cu acelasi punctaj.');
END cel_mai_activ_membru;
/

BEGIN 
    cel_mai_activ_membru;
END;
/   