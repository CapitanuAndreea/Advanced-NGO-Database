CREATE OR REPLACE PACKAGE pachet AS
    PROCEDURE atribuire_taskuri;
    PROCEDURE afisare_taskuri;
     FUNCTION actualizare_buget
        (p_id_proiect PROIECT.ID_PROIECT%TYPE)
      RETURN SPONSORI.SUMA%TYPE;
    PROCEDURE cel_mai_activ_membru;
 END pachet;
/
CREATE OR REPLACE PACKAGE BODY pachet AS
    PROCEDURE atribuire_taskuri
 IS 
        statusul TASK.STATUS%TYPE;

    TYPE TASK_TABLE IS TABLE OF TASK%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE TASK_VARRAY IS VARRAY(100) OF TASK%ROWTYPE;
    TYPE TASK_MEMBRI IS TABLE OF TASK.ID_MEMBRU%TYPE;
    
    contor NUMBER := 1;
    taskuri_realizate TASK_TABLE;
    taskuri_fara_membru TASK_VARRAY := TASK_VARRAY();
    id_membri_asignati TASK_MEMBRI := TASK_MEMBRI();
    
    CURSOR c_taskuri_realizate IS
        SELECT * 
        FROM TASK
        WHERE STATUS = 'Realizat';
    
    CURSOR c_taskuri_fara_membru IS
        SELECT *
        FROM TASK
        WHERE ID_MEMBRU IS NULL;
        
    CURSOR c_taskuri_cu_membru IS
        SELECT DISTINCT ID_MEMBRU
        FROM TASK
        WHERE ID_MEMBRU IS NOT NULL;
        
    CURSOR c_membri_activi IS
        SELECT ID_MEMBRU
        FROM MEMBRI_ACTIVI;
 BEGIN 
    FOR task_rec IN c_taskuri_realizate LOOP
        taskuri_realizate(taskuri_realizate.COUNT + 1) := task_rec;
    END LOOP;
    
    FOR i IN 1..taskuri_realizate.COUNT LOOP
        DELETE 
        FROM TASK
        WHERE ID_TASK = taskuri_realizate(i).ID_TASK;
    END LOOP;
    
    FOR task_rec IN c_taskuri_fara_membru LOOP
        taskuri_fara_membru.EXTEND;
        taskuri_fara_membru(taskuri_fara_membru.LAST) := task_rec;
    END LOOP;
    
    FOR task_rec IN c_taskuri_cu_membru LOOP
        id_membri_asignati.EXTEND;
        id_membri_asignati(id_membri_asignati.LAST) := task_rec.ID_MEMBRU;
    END LOOP;
    
    FOR membru_rec IN c_membri_activi LOOP
        IF contor <= taskuri_fara_membru.COUNT THEN 
            UPDATE TASK
            SET ID_MEMBRU = membru_rec.ID_MEMBRU
            WHERE ID_TASK = taskuri_fara_membru(contor).ID_TASK;
            contor := contor + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
 END atribuire_taskuri;
 
 PROCEDURE afisare_taskuri
 IS
    v_id_membru TASK.ID_MEMBRU%TYPE;
    
    CURSOR c_membri_activi IS
        SELECT ID_MEMBRU
        FROM MEMBRI_ACTIVI;
    
    CURSOR c_taskuri_membri(p_id_membru TASK.ID_MEMBRU%TYPE) IS
        SELECT *
        FROM TASK
        WHERE ID_MEMBRU = p_id_membru;
        
BEGIN 
    FOR membri_rec IN c_membri_activi LOOP
        v_id_membru := membri_rec.ID_MEMBRU;
        DBMS_OUTPUT.PUT_LINE('ID_MEMBRU: ' || v_id_membru);
        FOR task_rec IN c_taskuri_membri(v_id_membru) LOOP
            DBMS_OUTPUT.PUT_LINE(' TASK ID: ' || task_rec.ID_TASK || ', Status: ' || task_rec.STATUS);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('---------------------');
    END LOOP;
END afisare_taskuri;

 FUNCTION actualizare_buget
    (p_id_proiect PROIECT.ID_PROIECT%TYPE)
 RETURN SPONSORI.SUMA%TYPE IS
    buget SPONSORI.SUMA%TYPE;
    v_titlu_proiect PROIECT.TITLU_PROIECT%TYPE;
    v_nume_club CLUBURI.NUME_CLUB%TYPE;
     PROIECT_INTERN EXCEPTION;
    BUGET_INSUFICIENT EXCEPTION;
  BEGIN
    SELECT 
        SUM(S.SUMA) - 1500, P.TITLU_PROIECT, C.NUME_CLUB
        INTO buget, v_titlu_proiect, v_nume_club
        FROM SPONSORI S
        JOIN PROIECT P
        ON(S.ID_PROIECT = P.ID_PROIECT)
        JOIN CLUBURI C
        ON(P.ID_CLUB = C.ID_CLUB)
        WHERE S.ID_PROIECT = p_id_proiect
        GROUP BY P.TITLU_PROIECT, C.NUME_CLUB;
    
    IF buget + 1500 <= 300 THEN
        RAISE PROIECT_INTERN;
    END IF;

    IF buget < 0 THEN
        RAISE BUGET_INSUFICIENT;   
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Proiectul ' || v_titlu_proiect || ' din clubul ' || v_nume_club || ' va ramane cu un buget de ');
    RETURN buget;
    
 EXCEPTION
    WHEN NO_DATA_FOUND OR PROIECT_INTERN THEN
        RAISE_APPLICATION_ERROR(-20004, 'Proiectul este intern si nu are nevoie de materiale!');     
        
    WHEN BUGET_INSUFICIENT THEN
        RAISE_APPLICATION_ERROR(-20003, 'Bugetul este prea mic pentru realizarea cumparaturilor!');  
        
 END actualizare_buget;

PROCEDURE cel_mai_activ_membru
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
END pachet;
/
